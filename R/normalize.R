# =============================================================================
# The general normaliser, and the data-frame helpers built on it
# =============================================================================
#
# name_key() is the NAME JOIN KEY: it removes parenthesised alternate names,
# because a bracket in a person's name is an alternate spelling, not identity.
# normalize_string() is the GENERAL normaliser and does NOT, because it also
# serves fields where a bracket is part of the value -- organisation names like
# "Michigan Otolaryngology Surgery Associates (MOSA)", or 1,104 shortage-area
# names like "American Indian/Ho-Chunk (Simplified)". Stripping there would be
# wrong, so the two are deliberately different functions rather than one with a
# flag the caller can forget.
# =============================================================================

#' Normalise a string: transliterate, upper-case, trim
#'
#' Transliteration is the point. A hand-rolled `toupper(trimws(...))` does not
#' delete accented characters -- it PRESERVES them, so an accented name can
#' never reach its unaccented spelling by any exact or initial-based route.
#'
#' Internal whitespace is deliberately left alone: some callers need
#' `"VAN  DER BERG"` preserved. [name_key()] collapses it, because a join key
#' needs the opposite.
#'
#' @param x character vector.
#' @param remove_apostrophes logical: drop `'` (so `O'BRIEN` becomes `OBRIEN`).
#' @param remove_internal_spaces logical: drop all whitespace.
#' @return character vector, `NA` preserved.
#' @export
normalize_string <- function(x, remove_apostrophes = FALSE,
                             remove_internal_spaces = FALSE) {
  if (is.null(x) || length(x) == 0L) return(character(0))
  x <- as.character(x)
  # A NUL byte terminates a PCRE string and silently truncates the rest.
  out <- gsub("\\x00", " ", x, perl = TRUE)
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("stringi is required: without it accented names cannot be ",
         "transliterated and every non-ASCII person silently fails to match.",
         call. = FALSE)
  }
  out <- stringi::stri_trans_nfc(out)
  # German romanisation BEFORE the Latin-ASCII strip, which would otherwise
  # degrade the umlauts to bare vowels.
  for (p in list(c("\u00fc", "UE"), c("\u00dc", "UE"), c("\u00f6", "OE"),
                 c("\u00d6", "OE"), c("\u00e4", "AE"), c("\u00c4", "AE"),
                 c("\u00df", "SS"))) {
    out <- gsub(p[1], p[2], out, fixed = TRUE)
  }
  out <- stringi::stri_trans_general(out, "Latin-ASCII")
  out <- toupper(trimws(out))
  if (isTRUE(remove_apostrophes))     out <- gsub("'", "", out, fixed = TRUE)
  if (isTRUE(remove_internal_spaces)) out <- gsub("\\s+", "", out)
  out[is.na(x)] <- NA_character_
  out
}

#' Add normalised copies of named columns to a data frame
#'
#' Originals are preserved. A crosswalk showing only the normalised form cannot
#' be audited: a reviewer has no way to see that `"ALVAREZ"` came from
#' `"Álvarez"`.
#'
#' @param df data frame.
#' @param cols character: columns to normalise.
#' @param remove_apostrophes,remove_internal_spaces passed to [normalize_string()].
#' @param suffix appended to each new column name.
#' @return `df` with one added column per entry in `cols`.
#' @export
normalize_name_columns <- function(df, cols, remove_apostrophes = FALSE,
                                   remove_internal_spaces = FALSE,
                                   suffix = "_norm") {
  if (!is.data.frame(df)) stop("Input must be a data frame", call. = FALSE)
  missing <- setdiff(cols, names(df))
  if (length(missing)) {
    stop(sprintf("Missing columns: %s", paste(missing, collapse = ", ")),
         call. = FALSE)
  }
  for (col in cols) {
    df[[paste0(col, suffix)]] <- normalize_string(
      df[[col]], remove_apostrophes = remove_apostrophes,
      remove_internal_spaces = remove_internal_spaces)
  }
  df
}

#' Normalise the first/middle/last columns of a provider table
#'
#' Writes `first_clean`, `last_clean` and, when the column exists,
#' `middle_clean`. A missing middle name is normal and is not an error; a
#' missing given or family name is.
#'
#' @param df data frame.
#' @param first_col,last_col,middle_col column names.
#' @param advanced_norm logical: also drop apostrophes and internal spaces.
#' @return `df` with the `_clean` columns added.
#' @export
normalize_physician_names <- function(df, first_col = "first_name",
                                      last_col = "last_name",
                                      middle_col = "middle_name",
                                      advanced_norm = FALSE) {
  missing <- setdiff(c(first_col, last_col), names(df))
  if (length(missing)) {
    stop(sprintf("Missing required columns: %s", paste(missing, collapse = ", ")),
         call. = FALSE)
  }
  norm <- function(v) normalize_string(v, remove_apostrophes = advanced_norm,
                                       remove_internal_spaces = advanced_norm)
  df$first_clean <- norm(df[[first_col]])
  df$last_clean  <- norm(df[[last_col]])
  # middle_clean is ALWAYS created, NA when the source column is absent, so a
  # caller's downstream code sees the same shape whether or not middle names
  # were supplied -- a conditional column is a conditional bug.
  df$middle_clean <- if (middle_col %in% names(df)) norm(df[[middle_col]]) else NA_character_
  # Initials come from the _clean columns, NOT the raw ones. With
  # advanced_norm = TRUE the cleaned value has apostrophes and internal spaces
  # removed, so "O'Brien" and "O Brien" can yield a different first letter than
  # the raw string would. The initial must agree with the key it sits beside.
  df$first_initial  <- extract_first_initial(df$first_clean)
  df$middle_initial <- extract_first_initial(df$middle_clean)
  df
}

#' First initial of a name, punctuation and accents removed
#'
#' Distinct from [first_initial()], and the difference is load-bearing. This one
#' strips non-letters BEFORE taking the character, so `"(Sandra) Theresa"`
#' yields `"S"`. [first_initial()] takes the first character of the normalised
#' key, which for that input is `"("` unless alternate names were stripped.
#'
#' Neither is wrong; they answer different questions. Use this to summarise a
#' name for display or a coarse block; use [first_initial()] when the initial
#' must agree with the join key the rest of the match is built on, because an
#' initial that disagrees with its own key matches nothing.
#'
#' @param x character vector.
#' @return character vector of single upper-case letters, `NA` where no letter
#'   is present.
#' @export
extract_first_initial <- function(x) {
  if (is.null(x) || length(x) == 0L) return(character(0))
  k <- normalize_string(x)
  k <- gsub("[^A-Z]", "", k)
  out <- substr(k, 1L, 1L)
  out[is.na(k) | !nzchar(k)] <- NA_character_
  out
}

#' SQL expression normalising a name column the same way R does
#'
#' The join key must be built identically on both sides or the database half of
#' a pipeline quietly disagrees with the R half about who matched whom. Requires
#' a `strip_accents` UDF registered on the connection.
#'
#' @param col character(1): a column expression.
#' @return character(1) SQL.
#' @export
sql_npi_name <- function(col) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_npi_name() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  sprintf("strip_accents(UPPER(TRIM(%s)))", col)
}

#' Would normalising this vector change it?
#'
#' A cheap pre-check for mixed case or untrimmed whitespace. It does NOT detect
#' accents, so `FALSE` means "no case or spacing work to do", not "already a
#' valid join key" -- use [name_key()] for that.
#'
#' @param x character vector.
#' @return logical(1).
#' @export
needs_normalization <- function(x) {
  if (is.null(x) || length(x) == 0L || all(is.na(x))) return(FALSE)
  v <- x[!is.na(x)]
  any(v != toupper(v)) || any(v != trimws(v))
}
