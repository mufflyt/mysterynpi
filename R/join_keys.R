# =============================================================================
# Equality-join surname keys: letters-only, BOTH surname conventions
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR: a database hash join can only test
# equality, and real registries hold the SAME surname under two conventions.
# NPPES stores "Catherine Van Hook" as last name "VAN HOOK" in some records
# and "HOOK" (particle filed under middle name) in others; for Vietnamese
# names "Van" is usually a MIDDLE name, so "Linda Van Le" is surname "LE".
# A matcher that emits ONE key form loses whichever population the other
# convention holds. Measured in the isochrones ABMS-to-NPI matcher
# (2026-09-18): punctuated/particled surnames matched at 80.1% against 97.5%
# for plain names, and a glued-only repair would have TRADED 42 currently
# matched physicians (mostly Vietnamese) for the recovered Dutch/Hispanic
# ones. Emitting BOTH variants recovered 475 of 765 missing physicians while
# losing zero.
#
# [names_have_compatible_surname()] already solves this pairwise in R by
# subset comparison; these keys exist for the join you cannot bring into R --
# millions of registry rows on the database side, where the candidate set is
# built by hash-join equality BEFORE any pairwise rule can run.
# =============================================================================

#' Letters-only compact key for equality joins
#'
#' Collapses a name to its A-Z content after [name_key()] normalisation:
#' `"JONES-COX"`, `"JONES COX"` and `"JonesCox"` all become `"JONESCOX"`;
#' `"O'Brien"` becomes `"OBRIEN"`. This is deliberately MORE destructive than
#' [name_key()]: apostrophes, hyphens and spaces are exactly the bytes two
#' sources disagree about, so a key that keeps them fails the join whenever
#' conventions differ. Measured origin: the isochrones ABMS matcher compared
#' an R side that KEPT punctuation against a SQL side that spaced it out, so
#' `"JONES-COX" = "JONES COX"` could never be true (2026-09-18 QA).
#'
#' Use for building candidate sets by equality. Do NOT use as proof of
#' identity: compaction merges `"ANN E"` and `"ANNE"`, which is what the
#' downstream agreement axes (middle initial, suffix, license, taxonomy) are
#' for.
#'
#' `NA` in, `NA` out; a name with no letters is also `NA`, never `""`, so
#' absence cannot join to absence.
#'
#' @param x character vector of names or name fragments.
#' @param strip_alternates see [name_key()].
#' @return character vector of A-Z-only keys, `NA` where no letters survive.
#' @family join-keys
#' @examples
#' compact_name_key(c("Jones-Cox", "O'Brien", "van de Ven"))
#' # "JONESCOX" "OBRIEN" "VANDEVEN"
#' @export
compact_name_key <- function(x, strip_alternates = TRUE) {
  k <- name_key(x, strip_alternates)
  out <- gsub("[^A-Z]", "", k)
  out[!is.na(out) & !nzchar(out)] <- NA_character_
  out
}

#' Both equality-join key variants of a surname
#'
#' Returns one row per input with two keys:
#' \describe{
#'   \item{key_full}{the compact key of the WHOLE surname, particles glued:
#'     `"Van Houten"` -> `"VANHOUTEN"`, `"de la Cruz"` -> `"DELACRUZ"`.}
#'   \item{key_final}{the compact key of the FINAL token alone:
#'     `"Van Houten"` -> `"HOUTEN"`, `"Van Le"` -> `"LE"`.}
#' }
#' They are equal for single-token surnames. A matcher should accept EITHER
#' against the registry key (one long-format frame row per variant keeps the
#' database join a hash join; an OR predicate degrades it to a nested loop).
#'
#' A TRAILING SINGLE LETTER never enters either key when at least one other
#' token exists: `"Goodyear V"` keys as `"GOODYEAR"`. This is a positional
#' rule about what can be a surname, NOT a claim that the letter is a
#' generational suffix -- the suffix module deliberately refuses to read `V`
#' as a generation ([normalize_suffix()]), and both rules stand: here the V
#' merely must not become the surname key; there it must not veto a match.
#'
#' @param x character vector of surnames (already parsed out of a full name;
#'   see [parse_person()]).
#' @param strip_alternates see [name_key()].
#' @return data.frame with columns `surname` (the input), `key_full`,
#'   `key_final`. `NA` surname gives `NA` keys.
#' @family join-keys
#' @examples
#' surname_key_variants(c("Van Houten", "Van Le", "Jones-Cox", "Goodyear V"))
#' @export
surname_key_variants <- function(x, strip_alternates = TRUE) {
  k <- name_key(x, strip_alternates)
  key_full <- compact_name_key(k, strip_alternates = FALSE)
  key_final <- vapply(k, function(s) {
    if (is.na(s) || !nzchar(s)) return(NA_character_)
    toks <- strsplit(gsub("[^A-Z']+", " ", s), "\\s+")[[1]]
    toks <- toks[nzchar(toks)]
    if (!length(toks)) return(NA_character_)
    # positional trailing-single-letter rule (see docs above)
    if (length(toks) >= 2L && nchar(gsub("[^A-Z]", "", toks[length(toks)])) == 1L) {
      toks <- toks[-length(toks)]
    }
    out <- gsub("[^A-Z]", "", toks[length(toks)])
    if (!nzchar(out)) NA_character_ else out
  }, character(1), USE.NAMES = FALSE)
  # the trailing-letter rule must bind key_full too, or "GOODYEARV" versus
  # "GOODYEAR" quietly disagree about the same person
  drop_trail <- !is.na(k) & vapply(k, function(s) {
    toks <- strsplit(gsub("[^A-Z']+", " ", s), "\\s+")[[1]]
    toks <- toks[nzchar(toks)]
    length(toks) >= 2L && nchar(gsub("[^A-Z]", "", toks[length(toks)])) == 1L
  }, logical(1), USE.NAMES = FALSE)
  key_full[drop_trail] <- vapply(k[drop_trail], function(s) {
    toks <- strsplit(gsub("[^A-Z']+", " ", s), "\\s+")[[1]]
    toks <- toks[nzchar(toks)]
    out <- gsub("[^A-Z]", "", paste(toks[-length(toks)], collapse = ""))
    if (!nzchar(out)) NA_character_ else out
  }, character(1), USE.NAMES = FALSE)
  data.frame(surname = x, key_full = key_full, key_final = key_final,
             stringsAsFactors = FALSE)
}
