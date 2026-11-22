# =============================================================================
# Gender as a BLOCKING signal: it may veto a candidate, never identify one
# =============================================================================
#
# WHERE GENDER SITS IN A LINKAGE. Half the registry shares any given gender
# code, so agreement is nearly worthless as evidence FOR a match. What gender
# is good for is the veto: a roster row recorded "F" should not resolve to a
# registry candidate recorded "M" on the strength of a shared surname and a
# shared given-name token. That asymmetry -- cheap to agree, expensive to
# disagree -- is the definition of a blocking variable, and it is the only role
# this file gives gender. Nothing here contributes to ranking or scoring.
#
# WHAT THIS FILE REFUSES TO DO: infer gender from a given name. A name-based
# guess ("KELLY", "JORDAN", "KIRAN", "LESLIE") converts absence of evidence
# into fabricated evidence and then lets the fabrication veto real candidates.
# It is the same trade as edit-distance tolerance in middle_agreement(), and it
# is refused for the same reason: a rule that quietly deletes true matches is
# worse than one that decides nothing. Both inputs must be RECORDED codes.
# =============================================================================

#' Normalise recorded gender codes to `"M"`, `"F"`, or `NA`
#'
#' Accepts the encodings that actually occur in rosters and in NPPES
#' (`Provider Sex Code` is `M`/`F`): case-insensitive `M`/`MALE` and
#' `F`/`FEMALE`, with surrounding whitespace ignored. EVERYTHING ELSE MAPS TO
#' `NA`, and that direction is the point of the function:
#'
#' * An unmapped encoding must degrade to "decides nothing", never to a
#'   spurious veto. Passed through raw, `"FEMALE"` vs `"F"` fails `==` and a
#'   naive comparison deletes a candidate over a formatting difference.
#' * `U`, `UNKNOWN`, `X`, blank and `NA` all mean the source did not commit to
#'   a code this rule can compare against a registry that records only
#'   `M`/`F`. They are absence, and absence is handled by
#'   [gender_agreement()] returning `"uninformative"`.
#' * **Numeric codes are deliberately not mapped.** ISO/IEC 5218 says 1=male,
#'   2=female; other systems ship the opposite. Guessing the convention flips
#'   gender wholesale across a source, and a wholesale flip turns the veto
#'   into a true-match shredder. Recode numerics upstream, where you know
#'   which convention the source uses.
#'
#' @param x character vector of recorded gender codes.
#' @return character vector of `"M"`, `"F"`, or `NA_character_`.
#' @export
normalize_gender <- function(x) {
  u <- toupper(trimws(as.character(x)))
  out <- rep(NA_character_, length(u))
  out[u %in% c("M", "MALE")] <- "M"
  out[u %in% c("F", "FEMALE")] <- "F"
  out
}

#' Do two recorded genders agree, disagree, or decide nothing?
#'
#' The blocking rule for name-to-name matching. Both inputs are passed through
#' [normalize_gender()], so `"Female"` vs `"F"` corroborates rather than
#' conflicting over an encoding difference.
#'
#' THREE VERDICTS, SAME CONTRACT AS [middle_agreement()]:
#'
#' * `"corroborates"` -- both sides recorded and equal. This is WEAK evidence:
#'   half the registry corroborates. It exists so a caller can count it, not
#'   so a caller can rank on it.
#' * `"conflicts"` -- both sides recorded and different. This is the verdict a
#'   blocking caller acts on.
#' * `"uninformative"` -- either side unrecorded or unmapped. Absence of a
#'   gender code is not evidence the people differ, and a caller must never
#'   fold this verdict in with `"conflicts"`.
#'
#' USE THE VETO WITH THE SAME DISCIPLINE AS ANY OTHER VETO. Recorded gender
#' can be stale or simply wrong -- data entry, a transition the registry has
#' not caught up with, a source that coded the practice owner rather than the
#' provider. A caller that drops `"conflicts"` pairs should record what it
#' dropped (the [count_rivals()] pattern) rather than silently deleting, so a
#' row published as "no candidate" can be distinguished from a row whose only
#' candidate was vetoed on one field.
#'
#' @param a,b character vectors of recorded gender codes, the same length.
#'   Raw encodings are fine; normalisation is applied internally.
#' @param na_action [character(1)] how to treat a missing value on either
#'   side: one of [NA_ACTIONS]. The default `"uninformative"` is the
#'   behaviour of every release before 0.10.0 -- absence decides nothing.
#'   `"warn"` does the same and says so once per call; `"error"` refuses
#'   to compare. Imputation is deliberately absent: an imputed name is a
#'   fabricated identity claim (srr G2.14a, G2.14b; G2.14c refused with
#'   reason in `R/missing_policy.R`).
#' @return character: `"corroborates"`, `"conflicts"`, or `"uninformative"`.
#' @export
gender_agreement <- function(a, b, na_action = NA_ACTIONS) {
  # The policy this function always had, now selectable. The default
  # reproduces every previous release exactly; see R/missing_policy.R for
  # why imputation is not on the menu.
  na_action <- resolve_na_action(
    na_action,
    count_missing_values(a) + count_missing_values(b),
    "gender")
  if (length(a) != length(b)) {
    stop("a and b must be the same length", call. = FALSE)
  }
  ga <- normalize_gender(a)
  gb <- normalize_gender(b)
  out <- rep("uninformative", length(ga))
  known <- !is.na(ga) & !is.na(gb)
  out[known] <- ifelse(ga[known] == gb[known], "corroborates", "conflicts")
  out
}
