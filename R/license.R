# =============================================================================
# License-number agreement: the strongest key after the NPI itself,
# and a rule that deliberately cannot veto
# =============================================================================

#' Normalise a recorded license number for comparison
#'
#' Uppercase; spaces, periods and hyphens removed; blank to `NA`. THAT IS ALL,
#' and the restraint is the point:
#'
#' * **Leading zeros stay.** Some boards number with fixed-width zero padding
#'   and some do not; stripping zeros corroborates `"052"` with `"52"` at the
#'   price of corroborating `"520"`-style truncations too. A caller who has
#'   verified its two sources share a padding convention can strip upstream.
#' * **Alpha prefixes stay.** In states that prefix by profession, `MD12345`
#'   and `PA12345` are two different people's licenses; a prefix strip would
#'   merge them.
#'
#' @param x character vector of recorded license numbers.
#' @return character vector, or `NA_character_` where nothing was recorded.
#' @export
normalize_license <- function(x) {
  out <- toupper(gsub("[ .\\-]", "", as.character(x)))
  out[!is.na(out) & !nzchar(out)] <- NA_character_
  out
}

#' Do two recorded licenses corroborate? (This rule cannot veto.)
#'
#' A license number is only a number WITHIN its issuing state, so the state
#' rides along: `"12345"` in Colorado and `"12345"` in Texas is a numbering
#' coincidence, not evidence.
#'
#' TWO VERDICTS, NOT THREE, AND THE MISSING ONE IS THE DESIGN. Same state and
#' same normalised number is `"corroborates"` -- after the NPI itself, the
#' strongest deterministic evidence a candidate pair can carry. EVERYTHING
#' else is `"uninformative"`; there is no `"conflicts"` and no code path that
#' could produce one:
#'
#' * The registry's license field is PARTIAL (the NBER NPI-license crosswalk
#'   is built from it and is far from fully populated), so absence is
#'   ordinary, not evidence.
#' * Roughly a quarter of NPIs carry MORE THAN ONE license. A roster's
#'   Colorado number against a registry row's Texas number -- or against a
#'   different Colorado number from an earlier licensure -- is two glimpses
#'   of one career, not a disagreement.
#' * A formatting difference [normalize_license()] declines to erase (padding,
#'   a profession prefix) must not become a veto.
#'
#' A rule that can only add evidence can be ranked as high as its agreement
#' deserves without ever deleting a candidate it does not understand. Callers
#' holding several registry licenses per candidate should compare against
#' each and keep the best verdict -- one `"corroborates"` outweighs any
#' number of `"uninformative"`.
#'
#' @param a,b character vectors of recorded license numbers, the same length.
#'   Raw formatting is fine; [normalize_license()] is applied internally.
#' @param state_a,state_b character vectors of issuing-state codes. Compared
#'   after uppercasing and trimming; a missing state makes the pair
#'   uninformative, because a number without its state is not yet a license.
#' @return character: `"corroborates"` or `"uninformative"`.
#' @export
license_agreement <- function(a, state_a, b, state_b) {
  n <- length(a)
  if (length(state_a) != n || length(b) != n || length(state_b) != n) {
    stop("a, state_a, b and state_b must be the same length", call. = FALSE)
  }
  na <- normalize_license(a); nb <- normalize_license(b)
  sa <- toupper(trimws(as.character(state_a)))
  sb <- toupper(trimws(as.character(state_b)))
  sa[!is.na(sa) & !nzchar(sa)] <- NA_character_
  sb[!is.na(sb) & !nzchar(sb)] <- NA_character_
  hit <- !is.na(na) & !is.na(nb) & !is.na(sa) & !is.na(sb) &
    sa == sb & na == nb
  ifelse(hit, "corroborates", "uninformative")
}
