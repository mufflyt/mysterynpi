# =============================================================================
# The nickname policy: governed configuration, not ordinary code
# =============================================================================
# On 2026-09-07 a frozen-matcher ablation (matcher fa7216f, dictionary
# 2026-09-06.1) answered the scientific question this package had been
# engineering around: nicknames are valuable as EVIDENCE, not as a broad
# search-expansion mechanism. On 2026-09-09 the policy was superseded only to
# remove single-letter initials from nickname evidence. The 327-person
# benchmark rows stayed frozen.
#
# SUPERSESSION, NEVER IN-PLACE EDITS. A change to any required field of
# NICKNAME_POLICY demands a NEW policy_id, a NEW evidence artifact, new
# matcher/dictionary provenance, and `supersedes` naming the old policy.
# test-nickname-policy.R pins the required fields together with the
# checksum of the ablation fixture, so an edit without supersession fails
# CI by construction.
# =============================================================================

#' The locked nickname policy and its governing evidence
#'
#' The production rules decided from the 2026-09-07 ablation, recorded as
#' machine-readable, versioned configuration:
#'
#' * **Verdict layer** ([nickname_agreement()]): `retain_global`.
#' * **Candidate expansion** ([npi_search()]): `retain_review_only`, and
#'   only for source classes [SOURCE_CLASSES] marks `review_only`.
#' * **Auto-acceptance**: `never_on_nickname_evidence_alone` --
#'   [assert_nickname_policy()] is the fail-closed guard.
#' * **Governed edges**: `ROBERT>BILL` stands exactly as tested -- zero
#'   observed rescues, candidate inflation present, contained by the
#'   review-only rule. A data-governance record, not a heuristic to tweak.
#'
#' Column correspondence for the lineage contract: `nickname_rule` is
#' carried as `alias_edge_id` and `dictionary_version` as
#' `alias_dictionary_version`; `verdict_layer_used` is the downstream
#' consumer's stamp when it applies [nickname_agreement()], whose standing
#' this object records.
#'
#' @format A list. Required governed fields: `policy_id`, `verdict_layer`,
#'   `candidate_expansion`, `auto_accept_rule`, `governing_matcher_sha`,
#'   `dictionary_version`, `governing_evidence`, `effective_date`,
#'   `supersedes`. Supplementary: `source_class_gate`, `governed_edges`,
#'   `acceptance_contribution_levels`.
#' @export
NICKNAME_POLICY <- list(
  policy_id = "nickname-policy-2026-09-09",
  effective_date = "2026-09-09",
  supersedes = "nickname-policy-2026-09-07",
  verdict_layer = "retain_global",
  candidate_expansion = "retain_review_only",
  auto_accept_rule = "never_on_nickname_evidence_alone",
  source_class_gate = "registry_driven_fail_closed",
  governing_matcher_sha = "fe9e6a3a0f4dfb4882f9ab17926157825963ea68",
  dictionary_version = "2026-09-06.1",
  governing_evidence = paste0(
    "ablation appendix ",
    "https://claude.ai/code/artifact/cd8dd9e2-e841-47b6-a639-fd334c20587b",
    "; evidence: initials separation supersession, 2026-09-09; ",
    "327-person benchmark rows unchanged",
    "; pinned counts: tests/testthat/fixtures/ablation/ablation_pins_v2.csv"),
  governed_edges = list(
    "ROBERT>BILL" = list(observed_rescues = 0L,
                         observed_candidate_inflation = "present",
                         policy_containment = "review_only",
                         evidence = "ablation 2026-09-07, per-edge ledger")),
  # Search-time values are computable from lineage; "necessary" and
  # "conflicting" are reserved for an acceptance layer that weighs nickname
  # evidence against the other axes -- reserved HERE so a future layer
  # extends the governed enum instead of inventing its own vocabulary.
  acceptance_contribution_levels = c("none", "supporting", "nickname_only",
                                     "necessary", "conflicting")
)

#' The governed source-class registry
#'
#' The ONE place source classes and their expansion permissions are
#' defined. [npi_search()] resolves its gate by lookup here -- never by
#' string-matching source names, and with no fallback: a class this table
#' does not name cannot be passed at all, and `unknown` fails closed.
#'
#' @format data.frame with columns `class` and `expansion`
#'   (`"forbidden"`, `"review_only"`, or `"fail_closed"`).
#' @export
SOURCE_CLASSES <- data.frame(
  class = c("formal_record", "informal_capable", "unknown"),
  expansion = c("forbidden", "review_only", "fail_closed"),
  stringsAsFactors = FALSE)

# Registry lookup, fail-closed: an unregistered class gets "fail_closed",
# never a permission. (match.arg in npi_search already refuses free text;
# this guards refactors that might loosen that.)
source_class_permission <- function(class) {
  i <- match(class, SOURCE_CLASSES$class)
  if (is.na(i)) "fail_closed" else SOURCE_CLASSES$expansion[i]
}

#' Fail closed: no nickname-only candidate may be auto-accepted
#'
#' The acceptance-side guard of [NICKNAME_POLICY]. Give it the frame of
#' candidates an automated step is about to accept; it errors when
#'
#' * any row's `acceptance_contribution` is `"nickname_only"` or its
#'   `review_only` flag is `TRUE` (the same rows, asserted independently
#'   as defense in depth), or
#' * the lineage contract is broken: the policy columns are absent, or a
#'   row that used candidate expansion is missing any required lineage
#'   field (`source_class`, `review_only`, `acceptance_contribution`,
#'   `found_by_queries`, `found_by_edges`, `alias_dictionary_version`).
#'
#' A frame that cannot prove where its rows came from cannot be
#' auto-accepted; that is the point.
#'
#' @param accepted a data.frame produced by [npi_search()] holding the
#'   rows about to be auto-accepted.
#' @return `accepted`, invisibly, when the policy holds.
#' @export
assert_nickname_policy <- function(accepted) {
  if (!is.data.frame(accepted)) {
    stop("assert_nickname_policy() wants the data.frame of rows about to ",
         "be auto-accepted", call. = FALSE)
  }
  need <- c("source_class", "candidate_expansion_used", "review_only",
            "acceptance_contribution", "found_by_queries", "found_by_edges",
            "alias_edge_id", "alias_dictionary_version")
  missing_cols <- setdiff(need, names(accepted))
  if (length(missing_cols)) {
    stop("frame is missing lineage column(s): ",
         paste(missing_cols, collapse = ", "),
         "; auto-acceptance may only run on npi_search() output with its ",
         "lineage intact", call. = FALSE)
  }
  exp_rows <- which(accepted$candidate_expansion_used %in% TRUE)
  if (length(exp_rows)) {
    for (col in c("source_class", "review_only", "acceptance_contribution",
                  "found_by_queries", "found_by_edges",
                  "alias_dictionary_version")) {
      bad <- exp_rows[is.na(accepted[[col]][exp_rows])]
      if (length(bad)) {
        stop("NICKNAME POLICY VIOLATION: lineage field '", col,
             "' is missing on ", length(bad), " expansion-influenced ",
             "row(s); a candidate that cannot prove why it exists cannot ",
             "be auto-accepted.", call. = FALSE)
      }
    }
  }
  bad <- which(accepted$review_only %in% TRUE |
                 accepted$acceptance_contribution %in% "nickname_only")
  if (length(bad)) {
    stop("NICKNAME POLICY VIOLATION: ", length(bad), " candidate(s) ",
         "whose only distinguishing evidence is nickname expansion in an ",
         "auto-accept set (policy ", NICKNAME_POLICY$policy_id,
         ": ", NICKNAME_POLICY$auto_accept_rule, ").\n  NPIs: ",
         paste(utils::head(accepted$npi[bad], 5L), collapse = ", "),
         if (length(bad) > 5L) " ..." else "", "\n  edges: ",
         paste(unique(utils::head(accepted$found_by_edges[bad], 5L)),
               collapse = "; "),
         "\n  Route these to clerical review instead.", call. = FALSE)
  }
  invisible(accepted)
}
