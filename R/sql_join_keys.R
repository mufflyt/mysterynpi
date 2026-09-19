# =============================================================================
# UDF-free SQL builders that provably agree with the R-side join keys
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR is R/SQL normaliser drift, and it has two
# documented specimens from the isochrones ABMS matcher (2026-09-18 QA):
#
#   1. THE INERT REGEX. A suffix-stripping pattern written with doubled
#      backslashes in R source put the two-byte sequence `\\b` into the SQL
#      literal; DuckDB's RE2 read a LITERAL backslash, so the pass matched
#      NOTHING from the day it was written (2026-01-24) while the comment
#      beside it claimed "SMITH JR" equalled "SMITH". Twenty months, zero
#      matches, no error.
#   2. THE PUNCTUATION SPLIT. The SQL side spaced punctuation out
#      ("JONES-COX" -> "JONES COX") while the R side kept it ("JONES-COX"),
#      so equality was impossible for every punctuated surname.
#
# Both survive any amount of unit testing done on ONE side. The only guard
# that works is a parity test that runs the generated SQL in a real database
# against the R function on the same inputs -- this package's test suite does
# exactly that (test-sql_join_keys.R), which is why these builders live here
# and not in a caller.
#
# RE2 NOTES that shaped the patterns: RE2 has NO lookahead, so the perl
# `(?=\s|$)` idiom cannot be mirrored; the suffix strip is TRAILING-ANCHORED
# (`(\s+(TOKEN))+$`) instead, which also means a bare surname `DO` (common
# Vietnamese), a bare `JR`, or `DOOLEY` can never be eaten -- only a genuine
# trailing credential or generation token preceded by whitespace is.
#
# Relationship to [sql_npi_name()]: that builder handles ACCENTS and needs a
# `strip_accents` UDF registered on the connection. These are UDF-free and
# letters-only; on ASCII registry data (NPPES name fields are ASCII) the two
# approaches agree, and the parity tests pin that. Use sql_npi_name() when
# the database column carries accents and the UDF is available; use these
# when the join must run on a bare connection.
# =============================================================================

#' SQL: normalise a name column for matching (UDF-free, DuckDB/RE2)
#'
#' Upper-cases and trims, strips TRAILING credential and generation suffixes
#' (`MD`, `M.D.`, `DO`, `D.O.`, `JR`, `SR`, `II`, `III`, `IV`, `PH.D.`,
#' iterated so `"SMITH JR MD"` fully unwinds), then replaces every remaining
#' non-letter with a space and trims again.
#'
#' @param col character(1): a SQL column expression.
#' @return character(1) SQL expression.
#' @family sql-join-keys
#' @export
sql_name_clean <- function(col) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_name_clean() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  # Each token may carry a trailing period ("Jr.", "MD.") - a dotted suffix
  # is the same suffix, and requiring the bare form silently kept "SMITH JR."
  # unstripped (caught by this package's own executable test, not by reading).
  sprintf(
    "TRIM(REGEXP_REPLACE(REGEXP_REPLACE(UPPER(TRIM(%s)), '(\\s+(MD|M\\.D\\.|DO|D\\.O\\.|JR|SR|III|II|IV|PH\\.\\s?D\\.)\\.?)+$', '', 'g'), '[^A-Z]', ' ', 'g'))",
    col)
}

#' SQL: letters-only compact join key (UDF-free, DuckDB/RE2)
#'
#' [sql_name_clean()] with every non-letter removed instead of spaced:
#' the database-side twin of [compact_name_key()]. `"JONES-COX"`,
#' `"JONES COX"` and `"JONESCOX"` all reduce to `"JONESCOX"`; `"VAN HOUTEN"`
#' and `"VANHOUTEN"` both reduce to `"VANHOUTEN"`.
#'
#' @param col character(1): a SQL column expression.
#' @return character(1) SQL expression.
#' @family sql-join-keys
#' @export
sql_name_compact <- function(col) {
  sprintf("REGEXP_REPLACE(%s, '[^A-Z]', '', 'g')", sql_name_clean(col))
}

#' SQL: first initial of a name column (UDF-free, DuckDB/RE2)
#'
#' The database-side twin of [extract_first_initial()]: strips non-letters
#' BEFORE taking the character, so `"(Sandra) Theresa"` yields `'S'` and a
#' punctuation-only or empty value yields `NULL` -- never `''`, never a
#' punctuation byte. The 2026-09-19 isochrones survey found candidate
#' queries hand-rolling `SUBSTR(UPPER(TRIM(col)), 1, 1)`, which hands back
#' `'('` or `'-'` for exactly the inputs above and then blocks that person
#' against nobody.
#'
#' PARITY DOMAIN IS ASCII, same as [sql_name_compact()]: UDF-free SQL cannot
#' transliterate, so an accented FIRST letter diverges from the R side
#' (`"Émile"`: R gives `"E"` via [normalize_string()]'s transliteration; this
#' expression strips the non-ASCII letter and yields `'M'` from `"MILE"`).
#' The parity test pins agreement on ASCII AND pins that divergence
#' explicitly, so it is a documented boundary, not a surprise. For accented
#' columns use the [sql_npi_name()] UDF path.
#'
#' @param col character(1): a SQL column expression.
#' @return character(1) SQL expression yielding a single upper-case letter,
#'   `NULL` where no ASCII letter is present.
#' @family sql-join-keys
#' @export
sql_first_initial <- function(col) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_first_initial() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  sprintf(
    "NULLIF(SUBSTR(REGEXP_REPLACE(UPPER(TRIM(%s)), '[^A-Z]', '', 'g'), 1, 1), '')",
    col)
}

#' SQL: a character value as a SQL string literal
#'
#' Doubles embedded single quotes and wraps in quotes; `NA` becomes the SQL
#' keyword `NULL`. The defect class is a CORRECTNESS one measured in this
#' data, not a security posture: physician rosters are full of `O'Brien` and
#' `D'Angelo`, and an extractor that pastes a name into SQL with
#' `sprintf("... = '%s'", name)` either dies on the apostrophe or gets
#' patched with a one-off `gsub` that the next call site forgets. One
#' governed literal-builder, tested by ROUND-TRIP (the value comes back out
#' of a real DuckDB byte-identical), replaces the per-site patches.
#'
#' Vectorised: a character vector in, one literal per element out.
#'
#' @param x character vector of values (NOT column expressions).
#' @return character vector of SQL literals; `"NULL"` where `x` is `NA`.
#' @family sql-join-keys
#' @export
sql_quote_literal <- function(x) {
  if (!is.character(x)) {
    stop("sql_quote_literal() requires a character vector; got ",
         paste(class(x), collapse = "/"),
         ". Coercing silently would turn factor levels or numbers into ",
         "literals nobody reviewed.", call. = FALSE)
  }
  # paste0() recycles a zero-length vector against its scalar quotes to "''"
  # on this R (caught by the executable test), so the empty case is explicit.
  if (length(x) == 0L) return(character(0))
  out <- paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
  out[is.na(x)] <- "NULL"
  out
}

#' SQL: middle initials must not contradict (absence is never contradiction)
#'
#' Boolean predicate for a join: passes when EITHER side lacks a middle
#' initial, fails only on a live mismatch of first letters. Measured origin:
#' the isochrones matcher's fallback tiers carried NO middle-initial
#' condition and ran 7.5%-24.1% contradiction rates against 0.3% where the
#' guard existed -- a contradicting initial on a name-only match is close to
#' direct wrong-person evidence, and this predicate is how a candidate query
#' refuses those rows without ever treating a missing initial as evidence.
#'
#' @param left_initial_expr character(1): SQL expression yielding the roster
#'   side's single-letter initial (may be a bound column or a literal).
#' @param right_middle_col character(1): SQL column expression holding the
#'   registry side's middle NAME (the first letter is extracted in SQL).
#' @return character(1) SQL boolean expression.
#' @family sql-join-keys
#' @export
sql_middle_initial_guard <- function(left_initial_expr, right_middle_col) {
  for (a in list(left_initial_expr, right_middle_col)) {
    if (!is.character(a) || length(a) != 1L || is.na(a) || !nzchar(a)) {
      stop("sql_middle_initial_guard() requires non-empty single-string expressions",
           call. = FALSE)
    }
  }
  sprintf(
    "(%s IS NULL OR TRIM(%s) = '' OR %s IS NULL OR TRIM(%s) = '' OR SUBSTR(REGEXP_REPLACE(UPPER(COALESCE(%s, '')), '[^A-Z]', '', 'g'), 1, 1) = %s)",
    left_initial_expr, left_initial_expr, right_middle_col, right_middle_col,
    right_middle_col, left_initial_expr)
}
