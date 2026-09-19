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
#' a `strip_accents` UDF registered on the connection (DuckDB ships one built
#' in).
#'
#' GERMAN DIGRAPHS, BEFORE `strip_accents()`, FOR THE SAME REASON
#' [normalize_string()] ORDERS ITS OWN SUBSTITUTION FIRST. `strip_accents()`
#' only knows how to drop a diacritic: `"Müller"` becomes `"MULLER"`,
#' losing the letter the umlaut stood in for. German romanises umlauts as a
#' digraph, not a bare vowel -- `"Müller"` is `"MUELLER"` -- and once
#' `strip_accents()` has already dropped the dots there is no way to recover
#' that. So the digraph substitution runs on the RAW column expression,
#' before `TRIM`/`UPPER`/`strip_accents()` ever see it, mirroring
#' [normalize_string()]'s own ordering exactly. Confirmed against a live
#' DuckDB connection: pre-fix, `sql_npi_name()` emitted `"MULLER"` /
#' `"SCHON"` for `"Müller"` / `"Schön"` while
#' `normalize_string()` gave `"MUELLER"` / `"SCHOEN"` -- the exact silent
#' R/SQL parity break this function exists to prevent, caught by the
#' isochrones downstream parity test this function's contract is written
#' for.
#'
#' @param col character(1): a column expression.
#' @return character(1) SQL.
#' @export
sql_npi_name <- function(col) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_npi_name() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  .sql_translit_upper(col)
}

# The ONE transliterating SQL base every database twin of an R identity
# primitive builds on (sql_npi_name, sql_name_clean/compact,
# sql_first_initial). PACKAGE-LEVEL PARITY CONTRACT: executing this on a
# supported input must produce what normalize_string() produces, and the
# per-pair tests in test-sql-r-parity-contract.R prove it by execution, on
# a Unicode corpus, against a live DuckDB. Mirrors normalize_string()'s own
# order exactly:
#
#   1. nfc_normalize(): normalize_string() runs stri_trans_nfc() FIRST, so a
#      DECOMPOSED umlaut (u + combining diaeresis) reaches the digraph table
#      as one character. Without this the SQL side fell through to
#      strip_accents() and emitted a bare vowel for decomposed input - a
#      silent parity break invisible on composed test data.
#   2. The REPLACE chain, BEFORE UPPER, in two measured families:
#      - German digraphs (u-umlaut -> "ue", sharp-s -> "ss"): strip_accents()
#        only drops the diacritic ("MULLER"), and UPPER of a sharp-s is
#        U+1E9E, which strip_accents() KEEPS (measured: "Gross" with sharp-s
#        upper-cased to "GRO<U+1E9E>") - so both substitutions must run on
#        the raw lower/mixed-case text.
#      - Latin SPECIAL LETTERS that are not accents at all, so
#        strip_accents() leaves them whole (measured on DuckDB: OYVIND with
#        O-slash, LUKASZ with L-stroke, DORDE with D-stroke and AESA with
#        the AE ligature all came back UNCHANGED): O-slash -> "o",
#        L-stroke -> "l", D-stroke -> "d", AE -> "ae", OE ligature -> "oe",
#        thorn -> "th" - each mapping taken from what
#        stringi's Latin-ASCII actually produces, not assumed.
#   3. strip_accents(UPPER(TRIM(...))) for everything that IS an accent.
#
# strip_accents() and nfc_normalize() are DuckDB built-ins - no
# user-registered UDF is needed on a bare DuckDB connection.
# \uxxxx escapes keep this file ASCII-portable (R CMD check).
.sql_translit_map <- c(
  "\u00df" = "ss",
  "\u00fc" = "ue", "\u00dc" = "ue",
  "\u00f6" = "oe", "\u00d6" = "oe",
  "\u00e4" = "ae", "\u00c4" = "ae",
  "\u00f8" = "o",  "\u00d8" = "o",
  "\u0142" = "l",  "\u0141" = "l",
  "\u0111" = "d",  "\u0110" = "d",
  "\u00e6" = "ae", "\u00c6" = "ae",
  "\u0153" = "oe", "\u0152" = "oe",
  "\u00fe" = "th", "\u00de" = "th")

.sql_translit_upper <- function(col) {
  expr <- sprintf("nfc_normalize(%s)", col)
  for (ch in names(.sql_translit_map)) {
    expr <- sprintf("REPLACE(%s, '%s', '%s')", expr, ch, .sql_translit_map[[ch]])
  }
  sprintf("strip_accents(UPPER(TRIM(%s)))", expr)
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
