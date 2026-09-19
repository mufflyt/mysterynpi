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
# Relationship to [sql_npi_name()]: every builder in this family now stands
# on the SAME transliterating base (`.sql_translit_upper()`, R/normalize.R)
# that sql_npi_name() is - NFC, German digraphs and Latin special letters
# mapped the way normalize_string() maps them, then
# strip_accents(UPPER(TRIM(...))). PACKAGE-LEVEL PARITY CONTRACT: for every
# SQL helper advertised as the database twin of an R identity primitive,
# executing the SQL on a supported input must produce the same normalized
# value as the R primitive - proven by execution on a Unicode corpus in
# test-sql-r-parity-contract.R. An earlier revision kept this family
# "UDF-free" and pinned an ASCII-only parity domain with a DOCUMENTED accent
# divergence ("Emile"-with-acute keyed E in R and M in SQL); that was
# retracted by owner review 2026-09-19: a documented disagreement is still a
# disagreement, and candidate generation is exactly where R/SQL
# normalization must agree byte-for-byte, or the same person lands in two
# different blocks. strip_accents() and nfc_normalize() are DuckDB
# BUILT-INS, so a bare DuckDB connection still needs no user-registered UDF.
# =============================================================================

#' SQL: normalise a name column for matching (DuckDB/RE2)
#'
#' Transliterates on the shared base every SQL twin uses (NFC, German
#' digraphs and Latin special letters mapped as [normalize_string()] maps
#' them, then `strip_accents(UPPER(TRIM(...)))` - see the parity contract
#' note on [sql_npi_name()]), strips parenthesised alternate names (the
#' same `strip_alternates` behaviour [name_key()] applies, so
#' `"SMITH (JONES)"` cleans to `"SMITH"`, never `"SMITH JONES"`), strips
#' TRAILING credential and generation suffixes (`MD`, `M.D.`, `DO`,
#' `D.O.`, `JR`, `SR`, `II`, `III`, `IV`, `PH.D.`, iterated so
#' `"SMITH JR MD"` fully unwinds), then replaces every remaining
#' non-letter with a space and trims again.
#'
#' `strip_accents()` and `nfc_normalize()` are DuckDB built-ins; no
#' user-registered UDF is needed on a bare DuckDB connection.
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
  # Order mirrors name_key(): transliterate/upper first, THEN the full
  # four-rule parenthetical strip, THEN the trailing suffixes (the ONE
  # shared pattern .TRAILING_CREDENTIAL_RE; each token may carry a trailing
  # period - "Jr.", "MD." - a dotted suffix is the same suffix, and
  # requiring the bare form silently kept "SMITH JR." unstripped, caught by
  # this package's own executable test, not by reading).
  sprintf(
    "TRIM(REGEXP_REPLACE(REGEXP_REPLACE(%s, '%s', '', 'g'), '[^A-Z]', ' ', 'g'))",
    sql_strip_parenthetical(.sql_translit_upper(col)),
    .TRAILING_CREDENTIAL_RE)
}

#' SQL: strip parenthesised alternate names (DuckDB/RE2)
#'
#' The database-side twin of [strip_parenthetical()], transformation for
#' transformation, in the same order - because the R rule is NOT "delete
#' everything in brackets". Two conventions appear in rosters and they mean
#' OPPOSITE things, and a single delete-the-group regex collapses them:
#'
#' \preformatted{
#'   "Cynthia (Cindi) A."   separate token  -> an alternate name, DROPPED
#'   "C(arolyn) Diane"      inside a token  -> optional letters, UNWRAPPED
#'                                             ("CAROLYN DIANE", never "C DIANE")
#' }
#'
#' The four ordered rules, each mirrored one-for-one from the R body:
#' word-internal groups unwrap (backreferences `\\1\\2` - executed against
#' DuckDB to confirm RE2's replacement syntax); standalone groups become a
#' space; an UNCLOSED group runs to end-of-string and becomes a space; any
#' residual stray bracket becomes a space. Every branch carries an executed
#' parity fixture in `test-sql-r-parity-contract.R`, derived by calling the
#' real R primitive.
#'
#' @param col character(1): a SQL column expression.
#' @return character(1) SQL expression.
#' @family sql-join-keys
#' @export
sql_strip_parenthetical <- function(col) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_strip_parenthetical() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  # 1. word-internal: unwrap, keeping the letters
  s <- sprintf(
    "REGEXP_REPLACE(%s, '([A-Za-z''])\\(([^)]*)\\)', '\\1\\2', 'g')", col)
  # 2. standalone: drop (a SPACE, as in R, so tokens cannot fuse)
  s <- sprintf("REGEXP_REPLACE(%s, '\\([^)]*\\)', ' ', 'g')", s)
  # 3. unclosed: runs to end-of-string
  s <- sprintf("REGEXP_REPLACE(%s, '\\([^)]*$', ' ', 'g')", s)
  # 4. residual stray brackets ("]" first in the class = literal, in RE2 as
  #    in TRE - confirmed by execution)
  sprintf("REGEXP_REPLACE(%s, '[][()]', ' ', 'g')", s)
}

#' SQL: letters-only compact join key (DuckDB/RE2)
#'
#' The database-side twin of [compact_name_key()], UNCONDITIONALLY: same
#' preprocessing, same supported domain, same output, in BOTH modes -
#' `strip_suffixes` mirrors the R primitive's own argument, so "twin" never
#' means "the same plus preprocessing a caller must remember". (Until
#' 2026-09-19 this builder silently included the trailing credential strip
#' the R primitive does not perform, and the parity test had to restrict
#' itself to a suffix-free domain - evidence of two contracts wearing one
#' name; retired by owner review.)
#'
#' `"JONES-COX"`, `"JONES COX"` and `"JONESCOX"` all reduce to
#' `"JONESCOX"`; `"Muñoz"` and `"Munoz"` to `"MUNOZ"`; `"Müller"` and
#' `"Mueller"` to `"MUELLER"`; `"C(arolyn)"` unwraps to `"CAROLYN"`. An
#' input with no letters is `NULL`, never `''` - [compact_name_key()]
#' returns `NA` there for the same reason: absence must not join to
#' absence.
#'
#' @param col character(1): a SQL column expression.
#' @param strip_suffixes logical(1), default `FALSE`: mirror of
#'   [compact_name_key()]'s `strip_suffixes` - when `TRUE`, trailing
#'   credential/generation tokens strip first, via the SAME shared pattern
#'   (`.TRAILING_CREDENTIAL_RE`) the R side applies.
#' @return character(1) SQL expression.
#' @family sql-join-keys
#' @export
sql_name_compact <- function(col, strip_suffixes = FALSE) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_name_compact() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  if (!is.logical(strip_suffixes) || length(strip_suffixes) != 1L ||
      is.na(strip_suffixes)) {
    stop("strip_suffixes must be TRUE or FALSE", call. = FALSE)
  }
  base <- if (isTRUE(strip_suffixes)) {
    sql_name_clean(col)
  } else {
    sql_strip_parenthetical(.sql_translit_upper(col))
  }
  sprintf("NULLIF(REGEXP_REPLACE(%s, '[^A-Z]', '', 'g'), '')", base)
}

#' SQL: first initial of a name column (DuckDB/RE2)
#'
#' The database-side twin of [extract_first_initial()], built on the same
#' transliterating base as every other SQL twin: normalizes exactly as
#' [normalize_string()] does (NFC, German digraphs, Latin special letters,
#' accent strip), strips non-letters BEFORE taking the character, so
#' `"(Sandra) Theresa"` yields `'S'`, `"Émile"` yields `'E'` (the same
#' initial the R side produces - a blocking primitive whose two sides
#' disagree puts the same person in two different blocks), and a
#' punctuation-only or empty value yields `NULL` -- never `''`, never a
#' punctuation byte. The 2026-09-19 isochrones survey found candidate
#' queries hand-rolling `SUBSTR(UPPER(TRIM(col)), 1, 1)`, which hands back
#' `'('` or `'-'` for exactly the inputs above and then blocks that person
#' against nobody.
#'
#' Parity with [extract_first_initial()] is proven BY EXECUTION on a
#' Unicode corpus (acute accents, umlauts, tilde, cedilla, Latin special
#' letters, decomposed combining marks, punctuation-led and parenthesised
#' names) in `test-sql-r-parity-contract.R`.
#'
#' @param col character(1): a SQL column expression.
#' @return character(1) SQL expression yielding a single upper-case letter,
#'   `NULL` where no letter survives normalization.
#' @family sql-join-keys
#' @export
sql_first_initial <- function(col) {
  if (!is.character(col) || length(col) != 1L || is.na(col) || !nzchar(col)) {
    stop("sql_first_initial() requires a non-empty single-string column expression",
         call. = FALSE)
  }
  sprintf(
    "NULLIF(SUBSTR(REGEXP_REPLACE(%s, '[^A-Z]', '', 'g'), 1, 1), '')",
    .sql_translit_upper(col))
}

#' SQL: a character value as a DuckDB SQL string literal
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
#' SCOPE: this is a DuckDB SQL literal builder for GENERATED SQL text -
#' deterministic correctness where the query has to be assembled as a
#' string. It is not a database-independent quoting or sanitization
#' abstraction; other engines have other literal rules. Where the caller
#' holds a live connection, prefer DBI parameter binding
#' (`DBI::dbBind()` / parameterised `dbGetQuery()`) over pasting literals
#' at all.
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
