# =============================================================================
# The nickname policy: locked by ablation, enforced by code
# =============================================================================
# On 2026-09-07 a frozen-matcher ablation (matcher fa7216f, dictionary
# 2026-09-06.1) answered the scientific question this package had been
# engineering around: nicknames are valuable as EVIDENCE, not as a broad
# search-expansion mechanism. Verdict-layer admission rescued 33 adjudicated
# true matches at zero measured false-positive cost -- and its conflicts
# verdict keeps 23 known nonmatches off the review queue. Candidate-layer
# expansion, measured against 221 human-adjudicated links, rescued one true
# match per 77 false candidates (incremental PPV 1.3%). The policy below is
# the decision, not a tuning knob.
# =============================================================================

#' The locked nickname policy and its governing evidence
#'
#' The production rules decided from the 2026-09-07 ablation study, recorded
#' as data so every consumer can cite WHY the machinery behaves as it does:
#'
#' * **Verdict layer** ([nickname_agreement()]): retained globally.
#' * **Candidate expansion** ([npi_search()] `name_expansion =
#'   "curated_one_hop"`): retained REVIEW-ONLY, and only for source classes
#'   that plausibly record informal go-by names. A formal legal-name roster
#'   (an AMCB-style certification roster) cannot invoke expansion at all.
#' * **Auto-acceptance**: a candidate reachable only through a nickname edge
#'   must never be auto-accepted; [assert_nickname_policy()] is the
#'   fail-closed guard an acceptance step calls.
#' * **Dictionary governance**: the versioned dictionary stands as tested,
#'   including `ROBERT>BILL` -- zero measured rescues anywhere, downside
#'   bounded by the review-only rule, retained as a governed, versioned
#'   data decision rather than silently edited.
#'
#' Column correspondence for the lineage contract: `nickname_rule` is
#' carried as `alias_edge_id`, `dictionary_version` as
#' `alias_dictionary_version`; `source_class`, `candidate_expansion_used`,
#' `review_only` and `acceptance_contribution` are stamped by
#' [npi_search()]; `verdict_layer_used` is the downstream consumer's stamp
#' when it applies [nickname_agreement()], and this policy object records
#' the layer's standing (`retain_global`).
#'
#' @format A list with elements `policy_id`, `decided`, `verdict_layer`,
#'   `candidate_expansion`, `auto_accept`, `source_class_gate`,
#'   `governing_matcher_sha`, `governing_dictionary_version`,
#'   `governing_evidence`.
#' @export
NICKNAME_POLICY <- list(
  policy_id = "nickname-policy-2026-09-07",
  decided = "2026-09-07",
  verdict_layer = "retain_global",
  candidate_expansion = "retain_review_only",
  auto_accept = "never_on_nickname_evidence_alone",
  source_class_gate = "informal_capable_only",
  governing_matcher_sha = "fa7216f8966214cf8e1cc4e265b1b5efe56e2c88",
  governing_dictionary_version = "2026-09-06.1",
  governing_evidence = paste0(
    "ablation appendix ",
    "https://claude.ai/code/artifact/cd8dd9e2-e841-47b6-a639-fd334c20587b",
    "; evidence: ~/Dropbox (Personal)/mysterynpi-nickname-ablation-2026-09-07/")
)

#' Fail closed: no nickname-only candidate may be auto-accepted
#'
#' The acceptance-side guard of [NICKNAME_POLICY]. Give it the frame of
#' candidates an automated step is about to accept; it errors -- naming the
#' offending NPIs and the edges that produced them -- if any row is
#' `review_only`, i.e. reachable ONLY through nickname expansion. Rows a
#' human reviewer has since verified belong in a separate, adjudicated
#' acceptance path, not in the automated one this guard protects.
#'
#' @param accepted a data.frame produced by [npi_search()] (it must carry
#'   the `review_only` lineage column) holding the rows about to be
#'   auto-accepted.
#' @return `accepted`, invisibly, when the policy holds.
#' @export
assert_nickname_policy <- function(accepted) {
  if (!is.data.frame(accepted)) {
    stop("assert_nickname_policy() wants the data.frame of rows about to ",
         "be auto-accepted", call. = FALSE)
  }
  if (!"review_only" %in% names(accepted)) {
    stop("frame carries no review_only column; auto-acceptance may only ",
         "run on npi_search() output with its lineage intact",
         call. = FALSE)
  }
  bad <- which(accepted$review_only %in% TRUE)
  if (length(bad)) {
    stop("NICKNAME POLICY VIOLATION: ", length(bad), " candidate(s) ",
         "reachable only through nickname expansion in an auto-accept set ",
         "(policy ", NICKNAME_POLICY$policy_id, ": review-only).\n  NPIs: ",
         paste(utils::head(accepted$npi[bad], 5L), collapse = ", "),
         if (length(bad) > 5L) " ..." else "", "\n  edges: ",
         paste(unique(utils::head(accepted$found_by_edges[bad], 5L)),
               collapse = "; "),
         "\n  Route these to clerical review instead.", call. = FALSE)
  }
  invisible(accepted)
}
