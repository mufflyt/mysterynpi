#!/usr/bin/env Rscript
# Reconcile two independently produced external nickname edge audits.
#
# Two sessions audited the same problem and disagreed on 9 of 33 shared edges.
# Rather than pick a winner, this reconciles by RULE, so the outcome does not
# depend on which audit anyone happens to trust:
#
#   1. ALREADY_PRESENT is a FACT, not an opinion. It is decided by querying
#      NICKNAME_EDGES, never by either audit's assertion. This settled 5 of the
#      9 disagreements: MICHAEL>MICKEY, MICHAEL>MICK, THOMAS>THOM,
#      ELIZABETH>ELIZA and PATRICIA>TRISH are all in the governed corpus, so one
#      audit's NEEDS_ADJUDICATION and SUPPORTED_NEW_EDGE were simply wrong.
#
#   2. Where both audits made a JUDGEMENT and disagreed, the MORE CONSERVATIVE
#      classification wins. Admitting a bad edge welds two real people together;
#      deferring a good edge costs a little recall. The errors are not
#      symmetric, so the tie-break is not symmetric either.
#
#   3. Both reasons are retained with attribution. A reconciliation that
#      discards the losing rationale destroys the evidence that produced it, and
#      one of those rationales cites an adjudicated false merge in the midwifery
#      cohort, which is the strongest single piece of evidence in either audit.
#
# Output: inst/extdata/external_nickname_edge_audit_reconciled.csv

suppressMessages(pkgload::load_all(".", quiet = TRUE))

# Conservatism order: later beats earlier when two judgements collide.
SEVERITY <- c("SUPPORTED_NEW_EDGE", "NEEDS_ADJUDICATION",
              "REJECT_DIRECTIONAL_AMBIGUITY", "REJECT_NOT_NICKNAME",
              "REJECT_LOOSE_ASSOCIATION", "REJECT_FORMAL_WELD")

args <- commandArgs(trailingOnly = TRUE)
mine_path <- if (length(args) >= 1L) args[[1L]] else "inst/extdata/external_nickname_edge_audit.csv"
theirs_path <- if (length(args) >= 2L) args[[2L]] else "/tmp/theirs.csv"

mine <- utils::read.csv(mine_path, stringsAsFactors = FALSE)
theirs <- utils::read.csv(theirs_path, stringsAsFactors = FALSE)
mine$origin <- "audit_B_inventory_branch"
theirs$origin <- "audit_A_preserved_wip"

keyof <- function(d) paste(d$normalized_formal, d$normalized_nickname, sep = ">")
mine$key <- keyof(mine); theirs$key <- keyof(theirs)

edges <- mysterynpi::NICKNAME_EDGES
governed <- paste(edges$name, edges$nickname, sep = ">")

pick <- function(a, b) SEVERITY[max(match(c(a, b), SEVERITY), na.rm = TRUE)]

rows <- list()
for (k in union(mine$key, theirs$key)) {
  m <- mine[mine$key == k, , drop = FALSE][1, , drop = FALSE]
  t <- theirs[theirs$key == k, , drop = FALSE][1, , drop = FALSE]
  have_m <- !is.na(m$key[[1L]]); have_t <- !is.na(t$key[[1L]])
  src <- if (have_m) m else t

  cls_m <- if (have_m) m$classification[[1L]] else NA_character_
  cls_t <- if (have_t) t$classification[[1L]] else NA_character_

  # Rule 1: the corpus decides presence.
  if (k %in% governed) {
    final <- "ALREADY_PRESENT"
    basis <- "GROUND_TRUTH_CORPUS_QUERY"
    why <- "edge is present in NICKNAME_EDGES; presence is a fact, not a judgement"
  } else if (have_m && have_t && !identical(cls_m, cls_t)) {
    # Rule 2: conservatism wins a genuine disagreement.
    final <- pick(cls_m, cls_t)
    basis <- "DISAGREEMENT_RESOLVED_BY_CONSERVATISM"
    why <- sprintf("audits disagreed (A=%s, B=%s); took the more conservative because a bad edge welds people while a deferred edge costs recall",
                   cls_t, cls_m)
  } else {
    final <- if (have_m) cls_m else cls_t
    basis <- if (have_m && have_t) "AGREED" else "SINGLE_AUDIT_ONLY"
    why <- if (have_m) m$reason[[1L]] else t$reason[[1L]]
  }

  rows[[length(rows) + 1L]] <- data.frame(
    normalized_formal = src$normalized_formal[[1L]],
    normalized_nickname = src$normalized_nickname[[1L]],
    source_repository = src$source_repository[[1L]],
    source_sha = src$source_sha[[1L]],
    source_path = src$source_path[[1L]],
    source_symbol = src$source_symbol[[1L]],
    current_dictionary_version = mysterynpi::nickname_dictionary_version(),
    classification = final,
    resolution_basis = basis,
    audit_A_classification = cls_t,
    audit_B_classification = cls_m,
    audit_A_reason = if (have_t) t$reason[[1L]] else NA_character_,
    audit_B_reason = if (have_m) m$reason[[1L]] else NA_character_,
    reason = why, stringsAsFactors = FALSE)
}
out <- do.call(rbind, rows)
out <- out[order(out$classification, out$normalized_formal), ]
utils::write.csv(out, "inst/extdata/external_nickname_edge_audit_reconciled.csv",
                 row.names = FALSE, na = "")

cat("reconciled edges:", nrow(out), "\n\n")
print(table(out$classification))
cat("\nresolution basis:\n"); print(table(out$resolution_basis))
cat("\nunclassified:", sum(is.na(out$classification) | out$classification == ""), "\n")
cat("admitted into NICKNAME_EDGES by this script: 0 (by construction)\n")
