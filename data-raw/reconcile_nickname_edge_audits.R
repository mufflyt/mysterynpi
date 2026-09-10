#!/usr/bin/env Rscript
# Union of the two independently produced external nickname edge audits.
#
# Two sessions audited the same problem and produced different answers: a
# 61-row audit with richer adjudication rationale, and a 108-row audit with
# broader source coverage. Neither is dropped wholesale. The union preserves
# BOTH, and deduplicates on the SOURCE EDGE PROVENANCE KEY:
#
#   source_repository + source_path + source_symbol
#     + normalized_formal + normalized_nickname
#
# Keying on the edge alone would collapse the same relationship appearing in
# four different legacy maps into one row, which destroys exactly the evidence
# that says how widely a bad edge had spread. One edge in four maps is four
# findings about four files, not one finding.
#
# RESOLUTION RULES, unchanged:
#   1. Presence in NICKNAME_EDGES is a FACT, decided by querying the corpus,
#      never by either audit assertion.
#   2. Conservatism wins a genuine judgement disagreement: admitting a bad edge
#      welds two real people together, while deferring a good one costs a little
#      recall. The errors are not symmetric so the tie-break is not either.
#   3. Both rationales survive with attribution. A reconciliation that discards
#      the losing reason destroys the evidence that produced it.
#
# ALREADY-GOVERNED POLICY IS NOT REOPENED. ELIZABETH>LISA, ALEXANDRA>SANDRA,
# CATHERINE>KATE, CATHERINE>KATIE, CAROLYN>CAROL and CHRISTINA>CHRIS remain
# governed and classify ALREADY_PRESENT by rule 1. Formal-weld policy is not
# revisited here.
#
# NOTHING IS ADMITTED. This writes a CSV and never touches NICKNAME_EDGES.

suppressMessages(pkgload::load_all(".", quiet = TRUE))

SEVERITY <- c("SUPPORTED_NEW_EDGE", "NEEDS_ADJUDICATION",
              "REJECT_DIRECTIONAL_AMBIGUITY", "REJECT_NOT_NICKNAME",
              "REJECT_LOOSE_ASSOCIATION", "REJECT_FORMAL_WELD")

args <- commandArgs(trailingOnly = TRUE)
pa <- if (length(args) >= 1L) args[[1L]] else "/tmp/audit_A.csv"
pb <- if (length(args) >= 2L) args[[2L]] else "/tmp/audit_B.csv"

A <- utils::read.csv(pa, stringsAsFactors = FALSE)
B <- utils::read.csv(pb, stringsAsFactors = FALSE)

prov_key <- function(d) {
  paste(d$source_repository, d$source_path, d$source_symbol,
        d$normalized_formal, d$normalized_nickname, sep = "|")
}
A$key <- prov_key(A)
B$key <- prov_key(B)

# The two audits harvested from LARGELY DIFFERENT FILES, which is why neither
# may be dropped: A alone found obgyns/R/centralized_npi_matching.R (30 edges)
# and a test-fixture map (12), plus the adjudicated midwifery false-merge case;
# B alone found both isochrones maps (72 edges). Because their source_path
# values differ, a provenance key alone would never pair their rationales.
#
# So identity is PROVENANCE (preserving coverage), while rationale is joined at
# the EDGE level (preserving both audits reasoning). A row therefore keeps its
# own file evidence and still carries what the other audit concluded about the
# same relationship.
A$edge <- paste(A$normalized_formal, A$normalized_nickname, sep = ">")
B$edge <- paste(B$normalized_formal, B$normalized_nickname, sep = ">")
edge_reason <- function(d, e) {
  hit <- d[d$edge == e, , drop = FALSE]
  if (nrow(hit) == 0L) return(NA_character_)
  unique(hit$reason)[[1L]]
}
edge_class <- function(d, e) {
  hit <- d[d$edge == e, , drop = FALSE]
  if (nrow(hit) == 0L) return(NA_character_)
  unique(hit$classification)[[1L]]
}

edges <- mysterynpi::NICKNAME_EDGES
governed <- paste(edges$name, edges$nickname, sep = ">")

pick <- function(x, y) {
  i <- suppressWarnings(max(match(c(x, y), SEVERITY), na.rm = TRUE))
  if (!is.finite(i)) NA_character_ else SEVERITY[i]
}

rows <- list()
for (k in union(A$key, B$key)) {
  ra <- A[A$key == k, , drop = FALSE]
  rb <- B[B$key == k, , drop = FALSE]
  have_a <- nrow(ra) > 0L
  have_b <- nrow(rb) > 0L
  src <- if (have_b) rb[1, , drop = FALSE] else ra[1, , drop = FALSE]

  edge <- paste(src$normalized_formal[[1L]], src$normalized_nickname[[1L]], sep = ">")
  # Classification and rationale are looked up at the EDGE level, so a row
  # harvested from one audit still carries the other audit verdict and reason
  # for the same relationship even though they came from different files.
  cls_a <- if (have_a) ra$classification[[1L]] else edge_class(A, edge)
  cls_b <- if (have_b) rb$classification[[1L]] else edge_class(B, edge)
  rsn_a <- if (have_a) ra$reason[[1L]] else edge_reason(A, edge)
  rsn_b <- if (have_b) rb$reason[[1L]] else edge_reason(B, edge)

  if (edge %in% governed) {
    final <- "ALREADY_PRESENT"
    basis <- "GROUND_TRUTH_CORPUS_QUERY"
    why <- "edge is present in NICKNAME_EDGES; presence is a fact, not a judgement"
  } else if (!is.na(cls_a) && !is.na(cls_b) && !identical(cls_a, cls_b)) {
    # Applied whenever BOTH verdicts are known, whether they came from the same
    # provenance row or from the edge-level lookup. Restricting it to shared
    # provenance gave one edge TWO different verdicts across its rows
    # (MEGAN>MEGGIE was SUPPORTED in three rows and REJECTED in a fourth),
    # because rows harvested from only one audit skipped the tie-break. An audit
    # that contradicts itself about one relationship is not usable: the
    # provenance may differ per row, the verdict may not.
    final <- pick(cls_a, cls_b)
    basis <- "DISAGREEMENT_RESOLVED_BY_CONSERVATISM"
    why <- sprintf("audits disagreed (A=%s, B=%s); took the more conservative because a bad edge welds people while a deferred edge costs recall",
                   cls_a, cls_b)
  } else {
    final <- if (have_b) cls_b else cls_a
    basis <- if (!is.na(cls_a) && !is.na(cls_b)) "AGREED" else if (!is.na(cls_a)) "AUDIT_A_ONLY_richer_rationale" else "AUDIT_B_ONLY_broader_coverage"
    why <- if (have_a) ra$reason[[1L]] else rb$reason[[1L]]
  }
  if (is.na(final) || !nzchar(final)) {
    final <- "NEEDS_ADJUDICATION"
    basis <- "UNRESOLVED"
    why <- "neither audit produced a usable classification for this source edge"
  }

  rows[[length(rows) + 1L]] <- data.frame(
    source_repository = src$source_repository[[1L]],
    source_sha = src$source_sha[[1L]],
    source_path = src$source_path[[1L]],
    source_symbol = src$source_symbol[[1L]],
    source_formal = src$source_formal[[1L]],
    source_nickname = src$source_nickname[[1L]],
    normalized_formal = src$normalized_formal[[1L]],
    normalized_nickname = src$normalized_nickname[[1L]],
    current_dictionary_version = mysterynpi::nickname_dictionary_version(),
    classification = final,
    resolution_basis = basis,
    audit_A_classification = cls_a,
    audit_B_classification = cls_b,
    audit_A_reason = rsn_a,
    audit_B_reason = rsn_b,
    reason = why, stringsAsFactors = FALSE)
}
out <- do.call(rbind, rows)
out <- out[order(out$source_repository, out$source_path,
                 out$normalized_formal, out$normalized_nickname), ]
utils::write.csv(out, "inst/extdata/external_nickname_edge_audit_reconciled.csv",
                 row.names = FALSE, na = "")

cat("source-edge rows:", nrow(out), "\n")
cat("distinct edges:", length(unique(paste(out$normalized_formal, out$normalized_nickname))), "\n")
print(table(out$classification))
cat("\nresolution basis:\n")
print(table(out$resolution_basis))
cat("\nunclassified:", sum(is.na(out$classification) | out$classification == ""), "\n")
cat("rows carrying BOTH audit reasons:", sum(!is.na(out$audit_A_reason) & !is.na(out$audit_B_reason)), "\n")
cat("admitted into NICKNAME_EDGES: 0 (by construction)\n")
