# =============================================================================
# Input structures: accept more shapes, and say so when a conversion loses
# =============================================================================
# WHY THIS EXISTS. The entry points took a data.frame and nothing else, and
# said nothing when a column arrived as the wrong type. Both are fine until a
# caller passes a tibble (it works, silently, because a tibble IS a
# data.frame), a data.table (it works, until a sub-function subsets with
# drop = TRUE semantics it does not have), or a roster whose identifier column
# was read as numeric while the reference's was read as character -- which
# compares nothing to nothing and reports zero matches with no error.
#
# These helpers are the one place input shape is decided, so the entry points
# stop each making their own partial version of it. They implement the srr
# input-structure standards G2.2, G2.4, G2.6, G2.7, G2.9, G2.11 and G2.12, and
# the EDA index standards EA2.5 and EA2.6.
# =============================================================================

#' Coerce any tabular input to a plain data frame, loudly
#'
#' @description
#' Accepts a `data.frame` and anything that subclasses or converts to one --
#' `tbl_df`, `data.table`, a matrix with column names -- and returns a plain
#' `data.frame`. The conversion is announced when it discards anything a
#' caller might expect to survive, which is the point: a silent conversion is
#' how a `data.table`'s reference semantics or an `sf` geometry column
#' disappears between the call and the join (srr G2.7, G2.9).
#'
#' @param x tabular input.
#' @param arg [character(1)] the argument name, for messages.
#' @param quiet [logical(1)] suppress the conversion message. Defaults to
#'   `FALSE`, because the message is the standard.
#' @return [data.frame] a plain data frame with the same columns and rows.
#' @examples
#' as_linkage_table(data.frame(id = 1:2, surname = c("A", "B")), "roster")
#' as_linkage_table(matrix(c("1", "A"), nrow = 1,
#'                         dimnames = list(NULL, c("id", "surname"))), "roster")
#' @export
as_linkage_table <- function(x, arg = "input", quiet = FALSE) {
  if (!length(dim(x)) && !is.data.frame(x)) {
    stop(sprintf("%s must be a two-dimensional tabular object, not %s",
                 arg, class(x)[1]), call. = FALSE)
  }
  extra <- setdiff(class(x), c("data.frame", "tbl", "tbl_df", "matrix", "array"))
  if (is.matrix(x)) {
    if (is.null(colnames(x))) {
      stop(sprintf("%s is a matrix with no column names; the join needs names",
                   arg), call. = FALSE)
    }
    if (!quiet) {
      message(sprintf(paste0("%s converted from matrix to data.frame: every ",
                             "column becomes %s, because a matrix has one type"),
                      arg, typeof(x)))
    }
    x <- as.data.frame(x, stringsAsFactors = FALSE)
  } else if (length(extra)) {
    if (!quiet) {
      message(sprintf(paste0("%s converted from <%s> to a plain data.frame; ",
                             "class-specific behaviour (reference semantics, ",
                             "grouping, geometry) does not survive"),
                      arg, paste(extra, collapse = "/")))
    }
    x <- as.data.frame(x, stringsAsFactors = FALSE)
  }
  if (anyDuplicated(names(x))) {
    stop(sprintf(paste0("%s has duplicated column name(s): %s. A column lookup ",
                        "by name reads only the first, so the duplicates are ",
                        "refused rather than silently shadowed."),
                 arg,
                 paste(unique(names(x)[duplicated(names(x))]),
                       collapse = ", ")),
         call. = FALSE)
  }
  reject_list_columns(x, arg)
  x
}

#' Refuse list columns, with the reason
#'
#' @description
#' A list column reaching a string comparison does not error: it stringifies,
#' and the comparison then runs on `"c(\"A\", \"B\")"`. That is worse than
#' failing, so this fails (srr G2.12).
#'
#' @param x [data.frame] to inspect.
#' @param arg [character(1)] the argument name, for the message.
#' @return `x`, invisibly, when no column is a list.
#' @examples
#' reject_list_columns(data.frame(a = 1:2), "roster")
#' @export
reject_list_columns <- function(x, arg = "input") {
  bad <- names(x)[vapply(x, function(col) is.list(col) && !is.data.frame(col),
                         logical(1))]
  if (length(bad)) {
    stop(sprintf(paste0("%s has list column(s): %s. A list column ",
                        "stringifies silently in a name comparison, so it is ",
                        "refused rather than coerced; unnest or drop it."),
                 arg, paste(bad, collapse = ", ")), call. = FALSE)
  }
  invisible(x)
}

#' Read one column as character, announcing any loss
#'
#' @description
#' The explicit conversion srr G2.4c asks for, with the diagnostic G2.9 asks
#' for. A factor becomes its labels (never its integer codes, which is the
#' classic silent corruption); a numeric identifier becomes character with a
#' warning, because `1e+05` is not the identifier `100000`; a column with a
#' non-standard class (`units`, `difftime`, `POSIXct`) is stripped to its
#' underlying vector and said so (srr G2.4, G2.9, G2.11).
#'
#' @param x a column from a tabular input.
#' @param nm [character(1)] the column name, for messages.
#' @param quiet [logical(1)] suppress messages.
#' @return [character] the column as character.
#' @examples
#' read_name_column(factor(c("SMITH", "JONES")), "surname")
#' read_name_column(c(1001, 1002), "npi")
#' @export
read_name_column <- function(x, nm = "column", quiet = FALSE) {
  # A data.frame reaching as.character() DEPARSES to the literal text
  # `c("a", "b")` -- the exact corruption reject_list_columns() refuses, so
  # a frame passed where a column was meant is an error, not a coercion.
  if (is.data.frame(x) || length(dim(x))) {
    stop(sprintf(paste0("column %s is a %s, not a column; coercing it would ",
                        "deparse its contents into one string. Pass the ",
                        "column itself."), nm, class(x)[1]),
         call. = FALSE)
  }
  # CLASS FIRST, THEN TYPE. An earlier version checked is.character() first and
  # returned early, so a character vector carrying a units-like class and its
  # attributes passed through untouched -- which is exactly the input G2.6 and
  # G2.11 are about. The class check has to come before the type check,
  # because the awkward objects are the ones that are both.
  cls <- setdiff(class(x), c("character", "numeric", "integer", "logical",
                             "factor"))
  if (length(cls)) {
    if (!quiet) {
      message(sprintf(paste0("column %s stripped from <%s> to a bare vector ",
                             "before comparison; its attributes do not survive"),
                      nm, paste(cls, collapse = "/")))
    }
    x <- drop_vector_attributes(x)
    if (is.character(x)) return(x)
  }
  if (is.character(x)) return(x)
  if (is.factor(x)) {
    if (!quiet) {
      message(sprintf(paste0("column %s converted from factor to character ",
                             "(labels, not codes); level order is discarded"),
                      nm))
    }
    return(as.character(x))
  }
  if (is.numeric(x)) {
    out <- format(x, scientific = FALSE, trim = TRUE, justify = "none")
    out[is.na(x)] <- NA_character_
    if (!quiet) {
      warning(sprintf(paste0("column %s converted from %s to character; a ",
                             "numeric identifier loses leading zeros and can ",
                             "round. Read it as character upstream."),
                      nm, typeof(x)), call. = FALSE)
    }
    return(out)
  }
  as.character(drop_vector_attributes(x))
}

#' Strip attributes from one-dimensional input
#'
#' @description
#' Objects that behave like vectors but do not inherit from `vector` -- those
#' the `units` package creates, for instance -- reach string functions with a
#' class that dispatches somewhere unhelpful. This returns the underlying
#' values with names and other attributes removed, so every downstream
#' comparison sees the same thing regardless of how the caller stored it (srr
#' G2.6, EA2.6).
#'
#' @param x one-dimensional input.
#' @return `x` with attributes removed.
#' @examples
#' drop_vector_attributes(structure(c(a = "X", b = "Y"), class = "odd"))
#' @export
drop_vector_attributes <- function(x) {
  if (is.null(x) || is.data.frame(x) || length(dim(x))) return(x)
  attributes(x) <- NULL
  x
}

#' Assert that an argument is a single value
#'
#' @description
#' The length assertion srr G2.2 asks for, on the arguments that are scalar by
#' contract: a seed, a table name, an entity filter. A length-2 `seed` would
#' silently use its first element and make the draw irreproducible from the
#' methods section, which is the failure `clerical_sample()` exists to prevent.
#'
#' @param x the value to check.
#' @param arg [character(1)] the argument name, for the message.
#' @param null_ok [logical(1)] whether `NULL` is acceptable.
#' @return `x`, invisibly.
#' @examples
#' check_scalar(1L, "seed")
#' check_scalar(NULL, "table", null_ok = TRUE)
#' @export
check_scalar <- function(x, arg = "argument", null_ok = FALSE) {
  if (is.null(x)) {
    if (null_ok) return(invisible(x))
    stop(sprintf("%s must be a single value, not NULL", arg), call. = FALSE)
  }
  if (length(x) != 1L) {
    stop(sprintf(paste0("%s must be a single value, not length %d. A ",
                        "multi-valued %s would be silently truncated to its ",
                        "first element."), arg, length(x), arg),
         call. = FALSE)
  }
  invisible(x)
}

#' Affirm that an index column is unique
#'
#' @description
#' EDA standards EA2.1 and EA2.5 ask that index uniqueness be affirmed as a
#' pre-processing step rather than assumed. `resolve_one_to_one()` already
#' affirms it on the roster side; this is the same check, exported so it can be
#' applied to the reference table too, where the package previously assumed it.
#'
#' @param x [data.frame] the table.
#' @param col [character(1)] the index column name.
#' @param arg [character(1)] the table's argument name, for the message.
#' @param action [character(1)] `"error"` (default) or `"warn"`.
#' @return `x`, invisibly.
#' @examples
#' affirm_unique_index(data.frame(id = c("a", "b")), "id", "roster")
#' @export
affirm_unique_index <- function(x, col, arg = "input",
                                action = c("error", "warn")) {
  action <- match.arg(action)
  if (!col %in% names(x)) {
    stop(sprintf("%s has no column %s to use as an index", arg, col),
         call. = FALSE)
  }
  n_na <- sum(is.na(x[[col]]))
  dup <- unique(x[[col]][duplicated(x[[col]])])
  dup <- dup[!is.na(dup)]   # NA repetition is completeness, reported with n_na
  if (!n_na && !length(dup)) return(invisible(x))
  parts <- c(if (n_na) sprintf("%d missing value(s)", n_na),
             if (length(dup)) {
               sprintf("%d repeated value(s), e.g. %s", length(dup),
                       paste(utils::head(as.character(dup), 3),
                             collapse = ", "))
             })
  msg <- sprintf(paste0("%s index column %s is %s: %s. A one-to-one ",
                        "constraint over an incomplete or repeated index ",
                        "enforces nothing."),
                 arg, col,
                 if (n_na && length(dup)) "incomplete and not unique"
                 else if (n_na) "incomplete" else "not unique",
                 paste(parts, collapse = "; "))
  if (action == "error") stop(msg, call. = FALSE) else warning(msg, call. = FALSE)
  invisible(x)
}

#' Input structures: shapes accepted, losses announced
#'
#' @description
#' The srr standards this file implements, tagged so `srr::srr_stats_pre_submit()`
#' can count them. The implementations and their reasoning are in the functions
#' below; this block only records which standard each one serves.
#'
#' @srrstats {G2.2} `check_scalar()` refuses a value of length other than
#'   one for a parameter documented as scalar, naming the argument and the
#'   length it received. `match_npi()` applies it to `seed`, `table` and
#'   `entity_filter`; before it existed, a two-element `entity_filter` was
#'   silently truncated to its first element.
#' @srrstats {G2.4} `read_name_column()` is the single conversion point for
#'   a comparable column. It dispatches on class before type, converts a
#'   factor to its labels, a numeric to its digits and anything else to a
#'   bare vector, and reports what each conversion costs.
#' @srrstats {G2.4c} `read_name_column()` converts a numeric column with
#'   `format(x, scientific = FALSE, trim = TRUE)` rather than
#'   `as.character()`, because `as.character(1.23e+09)` yields the string
#'   "1.23e+09" and that string is the defect this function exists to
#'   prevent. Neither `paste()` nor `paste0()` appears anywhere in the
#'   conversion path.
#' @srrstats {G2.6} `drop_vector_attributes()` returns the underlying
#'   values with class and other attributes removed, and
#'   `read_name_column()` calls it before any comparison, so a character
#'   vector carrying a `units`-like class is pre-processed rather than
#'   dispatched on. The class check runs before the type check for exactly
#'   this input: checking type first let such a vector through untouched,
#'   which is the bug the test for this standard found.
#' @srrstats {G2.7} `as_linkage_table()` accepts `data.frame`, `tbl_df`,
#'   `data.table` and a named matrix, converts each to a plain
#'   `data.frame`, and messages when the conversion drops something the
#'   caller may expect to keep.
#' @srrstats {G2.9} Every lossy conversion in `read_name_column()` says
#'   what it cost: factor to character reports that level order is
#'   discarded, numeric to character warns that leading zeros are lost and
#'   the value can round, and an unrecognised class reports that its
#'   attributes do not survive.
#' @srrstats {G2.11} `read_name_column()` inspects `class()` before
#'   `is.character()`, so a column whose class is not one of the standard
#'   ones is stripped to a bare vector instead of reaching a comparison
#'   with its attributes intact.
#' @srrstats {G2.12} `reject_list_columns()` refuses a list column by name
#'   rather than letting it stringify into a comparison, where a
#'   two-element entry would arrive as the literal text `c("A", "B")` and
#'   conflict with every real name.
#' @srrstats {EA2.5} `affirm_unique_index()` affirms that the named index
#'   column is present, complete and unique, and names the duplicated
#'   values when it is not, rather than assuming an index the caller never
#'   promised.
#' @srrstats {EA2.6} `drop_vector_attributes()`, called from
#'   `read_name_column()` ahead of the type checks, means a vector's
#'   additional attributes never reach a comparison regardless of how the
#'   caller stored it.
#' @name srr-input-structures
#' @keywords internal
NULL

