# =============================================================================
# Agreement rules: do two records name the same person?
# =============================================================================

#' Compare two middle names as TOKEN SETS, never by position.
#'
#' THE DEFECT THIS EXISTS TO PREVENT. Comparing `substr(middle, 1, 1)` on each
#' side scores a maiden surname held in a different slot as a disagreement:
#'
#' \preformatted{
#'   "Katherine A. Reinhard" / "KATHERINE REINHARD RYE"   A vs R
#'   "Pamela Beth Harvey"    / "PAMELA H. CAPISTA"        B vs H
#'   "Alyssa Diane Bantz"    / "ALYSSA BANTZ HINDMON"     D vs B
#' }
#'
#' Every one of those shares a token outright. In the pipeline this comes from,
#' 82 roster rows had their ONLY exact first-and-last-name candidate deleted
#' this way, 57 of the 88 deleted pairs carrying a matching credential in the
#' registry, and the row was then published as "no candidate" --
#' indistinguishable from a person absent from the registry entirely.
#'
#' THREE VERDICTS, AND THE MIDDLE ONE IS LOAD-BEARING. `"uninformative"` is not
#' a hedge: it is what absence yields, and it means the middle name decides
#' nothing here. Callers must not treat it as agreement.
#'
#' WHAT THIS DELIBERATELY DOES NOT DO:
#'
#' * It does not loosen the conflict. Two full middle names sharing no token
#'   still conflict, and an initial still conflicts with a token it cannot
#'   abbreviate. Only POSITION is stopped from manufacturing disagreement.
#' * **No edit-distance tolerance.** A one-edit rule was added and removed the
#'   same day: measured, it changed 64 of 30,740 candidate pairs and was worth
#'   22 records, while admitting pairs that are genuinely different given names
#'   (`JULIA`/`JULIE`, `LEE`/`LEA`, `ANN`/`ANNE`). It is not symmetric with
#'   fuzzy SURNAME blocking, which generates a candidate that is then ranked
#'   below exact evidence; this would have suppressed a veto with no tier
#'   recording that it happened.
#'
#' @param a_tokens,b_tokens lists of character vectors from [middle_tokens()],
#'   the same length.
#' @return character: `"corroborates"`, `"conflicts"`, or `"uninformative"` --
#'   the last when either side records no middle name, which is absence of
#'   evidence and must never be read as evidence of difference.
#' @export
middle_agreement <- function(a_tokens, b_tokens) {
  if (length(a_tokens) != length(b_tokens)) {
    stop("a_tokens and b_tokens must be the same length", call. = FALSE)
  }
  # Compound-form equivalence is decided by the package's own surname
  # primitive rather than re-derived here; see the note in the cascade below.
  # Computed once for the whole vector, outside the loop: it is vectorised,
  # and calling it per element turned a 300,000-row comparison into a
  # per-row function call.
  compound <- name_surname_match_type(
    vapply(a_tokens, function(z) paste(z, collapse = " "), character(1)),
    vapply(b_tokens, function(z) paste(z, collapse = " "), character(1)))
  vapply(seq_along(a_tokens), function(i) {
    a <- a_tokens[[i]]; b <- b_tokens[[i]]
    if (!length(a) || !length(b)) return("uninformative")
    if (length(intersect(a[nchar(a) >= 2L], b[nchar(b) >= 2L]))) {
      return("corroborates")
    }
    # A HYPHEN IS PUNCTUATION HERE, NOT A NAME BOUNDARY (2026-11-14).
    #
    # middle_tokens() deliberately does not split on a hyphen: 503a37e found
    # that splitting "Mary-Jane" into MARY/JANE let it satisfy
    # person_matches()'s shared-token requirement against an unrelated "Jane".
    # That reasoning is correct THERE and wrong HERE, because the direction of
    # inference is opposite. In person_matches() a shared token is evidence
    # FOR a match, so over-splitting manufactures false positives. In this
    # function a token mismatch is evidence AGAINST -- it VETOES a candidate --
    # so under-splitting manufactures false NEGATIVES, and the veto is silent.
    #
    # The cost, measured: AMCB roster "Debra Marie-Lefever Rhizal" against
    # NPPES NPI 1619274149, which records the same middle name as
    # "MARIE LEFEVER" in eight annual snapshots. One token ("MARIE-LEFEVER")
    # versus two ("MARIE", "LEFEVER") shares nothing, so this returned
    # "conflicts", the only candidate was vetoed, and a correctly identified
    # midwife left the study cohort as "unmatched". Same person, same name,
    # different punctuation.
    #
    # SET EQUALITY, NOT A SHARED TOKEN -- and that distinction is the whole
    # rule. A first attempt folded both sides and corroborated on any shared
    # token; this package's own test caught it, correctly. Two cases that look
    # alike are not:
    #
    #   "MARIE-LEFEVER" vs "MARIE LEFEVER"  -> SAME components, same order,
    #                                          only the separator differs.
    #                                          One name, two spellings.
    #   "ANNE-MARIE"    vs "MARIE"          -> a compound versus ONE HALF of
    #                                          it. Possibly the same person,
    #                                          possibly an unrelated Marie.
    #                                          503a37e refuses this, and it is
    #                                          right to: a veto suppressed on
    #                                          half a compound is a match
    #                                          asserted on half a name.
    #
    # DELEGATED TO name_surname_match_type(), NOT RE-DERIVED. A first attempt
    # here hand-rolled a hyphen fold and corroborated on any shared folded
    # token; this package's own test-tokens.R caught it. A second attempt
    # required folded SET EQUALITY, which was correct but handled only the
    # hyphen-versus-space case -- and surname_agreement() had meanwhile been
    # treating a THIRD spelling correctly all along:
    #
    #   "ERICKSON-OWENS" vs "ERICKSON OWENS"  separator_equivalent
    #   "ERICKSON-OWENS" vs "ERICKSONOWENS"   concatenated_equivalent
    #   "ANNE-MARIE"     vs "MARIE"           component_subset
    #
    # So the compound-form question is answered by the primitive that already
    # owns it, and these three verdicts mean here exactly what they mean for a
    # surname. Two spellings of the same components corroborate; a compound
    # against one HALF of itself does NOT -- component_subset is deliberately
    # absent from the list below, because 503a37e is right that suppressing a
    # veto on half a compound asserts a match on half a name. ("MARIE LEFEVER"
    # against a bare "MARIE" still corroborates, via the shared whole-token
    # branch above, which runs first; this branch does not change that.)
    #
    # STRICTLY ADDITIVE. Reached only after the token comparison above has
    # failed; it can turn "conflicts" into "corroborates" but never the
    # reverse, so it cannot newly veto any candidate, and it does not touch
    # middle_tokens(), given_tokens() or person_matches() -- the false
    # positive 503a37e fixed stays fixed.
    #
    # NOT edit-distance tolerance: "none" falls through to the cascade, so
    # JULIA/JULIE, LEE/LEA and ANN/ANNE still conflict, and an initials-only
    # record ("M L" against "MARIE LEFEVER") is still decided by
    # initials_string_matches() below rather than here.
    if (compound[i] %in% c("exact", "separator_equivalent",
                           "concatenated_equivalent")) {
      return("corroborates")
    }
    if (initials_string_matches(a, b) || initials_string_matches(b, a)) {
      return("corroborates")
    }
    if (any(nchar(a) == 1L) || any(nchar(b) == 1L)) {
      if (length(intersect(substr(a, 1L, 1L), substr(b, 1L, 1L)))) {
        return("corroborates")
      }
    }
    "conflicts"
  }, character(1))
}

#' Does a single 2-4 character token spell out the other side's initials?
#'
#' `"VL"` against `"VELMA LAURITZEN"` is the same person written two ways, but
#' it is two characters, so a naive rule scores it as a full NAME token, finds
#' no match, and -- neither side then holding a single letter -- never runs the
#' initial test at all. Verdict: conflict, and the candidate is deleted.
#'
#' A classification test ("does this look like initials?") was tried first and
#' abandoned: `LYN`, `BRY` and `SKY` are vowel-less and are names, while `CJ`
#' and `MJ` are initials, so no property of the token alone separates them.
#' This asks the only decidable question -- do these characters MAP, in order,
#' onto distinct tokens on the other side. Order-preserving, so `"VL"` matches
#' `VELMA LAURITZEN` and not `LAURITZEN VELMA`.
#'
#' @keywords internal
#' @noRd
initials_string_matches <- function(short, toks) {
  if (length(short) != 1L) return(FALSE)
  ch <- strsplit(short, "")[[1]]
  if (length(ch) < 2L || length(ch) > 4L || length(toks) < length(ch)) return(FALSE)
  j <- 1L
  for (k in seq_along(ch)) {
    hit <- FALSE
    while (j <= length(toks)) {
      if (substr(toks[j], 1L, 1L) == ch[k]) { hit <- TRUE; j <- j + 1L; break }
      j <- j + 1L
    }
    if (!hit) return(FALSE)
  }
  TRUE
}

#' Do two parsed people share a surname AND at least one full given-name token?
#'
#' Comparison is on token SETS, not position. `"Williams, W. Jon"` and
#' `"Jon W Williams"` are the same person and their given-name token sets share
#' `JON`; a positional first-token rule scores them as different. A shared FULL
#' token (>= 2 characters) is required -- initials may corroborate but never
#' identify, since `"W."` matches every W.
#'
#' THIS IS THE EXACT TIER, DELIBERATELY. `BOB` does not match `ROBERT` here,
#' and the logical return collapses "no given name" with "different given
#' name" -- both acceptable only because this rule's job is the strictest
#' pass. The nickname tier, with the three-verdict contract that keeps
#' absence uninformative, is [nickname_agreement()]; a pipeline's weaker
#' blocking passes should rank on its verdicts rather than loosen this one.
#'
#' @param last_a,last_b character vectors of normalised surnames.
#' @param given_a,given_b lists from [given_tokens()].
#' @return logical vector.
#' @export
person_matches <- function(last_a, given_a, last_b, given_b) {
  same_last <- has_name_information(last_a) & has_name_information(last_b) &
    last_a == last_b
  shared <- mapply(function(x, y) length(intersect(x, y)) > 0, given_a, given_b)
  same_last & shared
}
