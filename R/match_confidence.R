# =============================================================================
# Post-match confidence grading
# =============================================================================
#
# match_npi() decides whether a candidate may resolve. These helpers answer a
# different question: how much evidence supported the accepted candidate? The
# vocabulary is deliberately small and ordinal (high / medium / low), with
# ambiguous and unmatched as non-ordinal dispositions. It is intended for
# receipts and downstream sensitivity analyses, not for overriding the
# resolver's accept/review decision.
# =============================================================================

#' Confidence labels for an accepted NPI match
#'
#' `NPI_MATCH_CONFIDENCE_LEVELS` is the stable vocabulary returned by
#' [grade_npi_match_confidence()]: `high`, `medium`, `low`, `ambiguous`, and
#' `unmatched`.
#'
#' @format A character vector of five labels in reporting order.
#' @export
NPI_MATCH_CONFIDENCE_LEVELS <- c("high", "medium", "low", "ambiguous", "unmatched")

.text_pair_verdict <- function(a, b, label) {
  if (length(a) != length(b)) {
    stop(label, " inputs must be the same length", call. = FALSE)
  }
  ka <- phrase_key(a)
  kb <- phrase_key(b)
  out <- rep("uninformative", length(ka))
  present <- !is.na(ka) & !is.na(kb)
  out[present & ka == kb] <- "corroborates"
  out[present & ka != kb] <- "conflicts"
  out
}

#' Build canonical evidence fields for post-match grading
#'
#' Compares one roster/candidate pair per row using the package's canonical
#' rules rather than ad-hoc equality: [surname_agreement()] for surnames,
#' [given_name_agreement()] for given names (including its named `initial`
#' rule), and punctuation-insensitive exact phrase keys for state and city.
#' Missing values are `uninformative`, never positive or negative evidence.
#'
#' @param roster_given,roster_surname Character vectors of source names.
#' @param candidate_given,candidate_surname Character vectors of candidate
#'   names, the same length as the roster vectors.
#' @param roster_state,candidate_state,roster_city,candidate_city Optional
#'   character vectors of place fields, the same length as the name vectors.
#' @return A data frame with surname and given verdicts/reasons plus state and
#'   city verdicts.
#' @examples
#' npi_match_evidence("John", "Smith", "J", "Smith",
#'                    roster_state = "CO", candidate_state = "CO")
#' @export
npi_match_evidence <- function(roster_given, roster_surname,
                               candidate_given, candidate_surname,
                               roster_state = NULL, candidate_state = NULL,
                               roster_city = NULL, candidate_city = NULL) {
  n <- length(roster_given)
  lengths <- c(length(roster_surname), length(candidate_given), length(candidate_surname))
  if (any(lengths != n)) {
    stop("name inputs must all be the same length", call. = FALSE)
  }
  for (pair in list(list(roster_state, candidate_state, "state"),
                    list(roster_city, candidate_city, "city"))) {
    if (is.null(pair[[1L]]) && is.null(pair[[2L]])) next
    if (is.null(pair[[1L]]) || is.null(pair[[2L]]) ||
        length(pair[[1L]]) != n || length(pair[[2L]]) != n) {
      stop(pair[[3L]], " inputs must both be NULL or both be the same length as the name inputs",
           call. = FALSE)
    }
  }

  sur <- surname_agreement(roster_surname, candidate_surname, detail = TRUE)
  giv <- given_name_agreement(roster_given, candidate_given)
  out <- data.frame(
    surname_verdict = sur$verdict,
    surname_reason = sur$reason,
    given_verdict = giv$verdict,
    given_reason = giv$reason,
    stringsAsFactors = FALSE
  )
  if (!is.null(roster_state)) {
    out$state_verdict <- .text_pair_verdict(roster_state, candidate_state, "state")
  } else {
    out$state_verdict <- rep("uninformative", n)
  }
  if (!is.null(roster_city)) {
    out$city_verdict <- .text_pair_verdict(roster_city, candidate_city, "city")
  } else {
    out$city_verdict <- rep("uninformative", n)
  }
  out
}

# Recycle a grading input to the evidence-row count, with scalar broadcasting
# only. Length-zero is valid when the evidence table has zero rows.
.grade_recycle <- function(x, n, label) {
  if (length(x) == n) return(x)
  if (length(x) == 1L) return(rep(x, n))
  stop(label, " must be length 1 or the number of evidence rows", call. = FALSE)
}

#' Grade the confidence of an accepted NPI candidate
#'
#' Grades evidence after the resolver has chosen a candidate; it does not
#' decide whether the candidate is acceptable. `high` requires the strongest
#' query tier, corroborating state, corroborating surname, and exact or
#' recorded-initial given-name agreement. `medium` requires exact given-name
#' agreement or corroborating geography. A candidate without a corroborating
#' surname is `unmatched`; tied or contested candidates are `ambiguous` when
#' the caller marks them so (for example, from `match_npi()`'s review reason).
#'
#' Given-name handling is canonical: a bare recorded initial corroborates with
#' reason `initial`; two different full names that merely share a first letter
#' conflict and do not receive initial credit.
#'
#' @param evidence Data frame from [npi_match_evidence()].
#' @param query_tier Integer or numeric vector describing the query tier that
#'   produced the candidate (`1` strongest). `NA` means no tiered query.
#' @param ambiguous Logical vector: `TRUE` when candidate selection ended in a
#'   tie or otherwise ambiguous disposition.
#' @param matched Logical vector: `FALSE` when no candidate was accepted.
#' @return Character vector of labels from [NPI_MATCH_CONFIDENCE_LEVELS].
#' @examples
#' ev <- npi_match_evidence("John", "Smith", "John", "Smith",
#'                          roster_state = "CO", candidate_state = "CO")
#' grade_npi_match_confidence(ev, query_tier = 1)
#' @export
grade_npi_match_confidence <- function(evidence, query_tier = NA_integer_,
                                       ambiguous = FALSE, matched = TRUE) {
  needed <- c("surname_verdict", "surname_reason", "given_verdict",
              "given_reason", "state_verdict", "city_verdict")
  if (!is.data.frame(evidence) || !all(needed %in% names(evidence))) {
    stop("evidence must be a data frame from npi_match_evidence()", call. = FALSE)
  }
  n <- nrow(evidence)
  query_tier <- .grade_recycle(query_tier, n, "query_tier")
  ambiguous <- .grade_recycle(ambiguous, n, "ambiguous")
  matched <- .grade_recycle(matched, n, "matched")
  if (!is.logical(ambiguous) || anyNA(ambiguous)) {
    stop("ambiguous must be non-missing logical", call. = FALSE)
  }
  if (!is.logical(matched) || anyNA(matched)) {
    stop("matched must be non-missing logical", call. = FALSE)
  }

  surname_ok <- evidence$surname_verdict == "corroborates"
  given_exact <- evidence$given_verdict == "corroborates" &
    evidence$given_reason == "exact"
  given_initial <- evidence$given_verdict == "corroborates" &
    evidence$given_reason == "initial"
  state_ok <- evidence$state_verdict == "corroborates"
  city_ok <- evidence$city_verdict == "corroborates"

  out <- rep("low", n)
  unmatched <- !matched | !surname_ok
  out[unmatched] <- "unmatched"
  active <- !unmatched
  out[active & ambiguous] <- "ambiguous"
  active <- active & !ambiguous

  tier1 <- !is.na(query_tier) & query_tier == 1
  high <- active & tier1 & state_ok & (given_exact | given_initial)
  medium <- active & !high & (given_exact | state_ok | city_ok)
  out[high] <- "high"
  out[medium] <- "medium"
  out
}

#' Test taxonomy codes against a specialty allowlist
#'
#' Convenience wrapper over [taxonomy_consistent()] for the common case where a
#' caller has a vector of exact NUCC codes or profession-family prefixes. The
#' full pipe-concatenated taxonomy string is inspected, so a residency or
#' student code ahead of the specialty code cannot hide the specialty code.
#'
#' @param taxonomy Character vector of pipe-concatenated NUCC codes.
#' @param allowlist Character vector of exact codes or prefixes. Elements are
#'   treated as alternatives.
#' @return Logical vector: `TRUE` when any code starts with any allowlist
#'   element, `FALSE` when codes exist but none do, and `NA` when either side
#'   is missing.
#' @examples
#' taxonomy_allowlist_consistent("390200000X|208800000X", c("208800000X", "2088F0040X"))
#' @export
taxonomy_allowlist_consistent <- function(taxonomy, allowlist) {
  if (!is.character(allowlist) || !length(allowlist) || anyNA(allowlist) ||
      any(!nzchar(trimws(allowlist)))) {
    stop("allowlist must be a non-empty character vector without missing or blank codes",
         call. = FALSE)
  }
  taxonomy_consistent(taxonomy, paste(allowlist, collapse = "|"))
}
