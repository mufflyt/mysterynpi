#!/usr/bin/env Rscript
# Freeze-out verification for the reconciled nickname edge audit.
#
# Asserts the invariants the union must hold, and nothing else. Run from the
# package root with the two source audits as arguments:
#
#   Rscript data-raw/verify_nickname_edge_audit_union.R audit_A.csv audit_B.csv
#
# Non-vacuous by observation: before the symmetric rule-1 fix, check 6b failed
# with 4 disagreements (the JEN>JENNIFER reverse-direction rows).

# Freeze-out verification for the reconciled nickname edge audit (commit 116f9e2).
# Reads the COMMITTED artifact, both source audits, and the corpus. Asserts only.

args <- commandArgs(trailingOnly = TRUE)
pa <- if (length(args) >= 1L) args[[1L]] else "/tmp/audit_A.csv"
pb <- if (length(args) >= 2L) args[[2L]] else "/tmp/audit_B.csv"
A <- utils::read.csv(pa, stringsAsFactors = FALSE)
B <- utils::read.csv(pb, stringsAsFactors = FALSE)
R <- utils::read.csv("inst/extdata/external_nickname_edge_audit_reconciled.csv", stringsAsFactors = FALSE)

load("data/NICKNAME_EDGES.rda")
corpus <- get("NICKNAME_EDGES")

fails <- character(0)
ok <- function(label, cond, detail = "") {
  cat(sprintf("[%s] %s%s\n", if (cond) "PASS" else "FAIL", label,
              if (nzchar(detail)) paste0(" -- ", detail) else ""))
  if (!cond) fails <<- c(fails, label)
}

prov_key <- function(d) paste(d$source_repository, d$source_path, d$source_symbol,
                              d$normalized_formal, d$normalized_nickname, sep = "|")
A$key <- prov_key(A); B$key <- prov_key(B); R$key <- prov_key(R)
edge <- function(d) paste(d$normalized_formal, d$normalized_nickname, sep = ">")
A$edge <- edge(A); B$edge <- edge(B); R$edge <- edge(R)

cat("\n---- counts ----\n")
cat(sprintf("audit A rows: %d  (unique prov keys %d)\n", nrow(A), length(unique(A$key))))
cat(sprintf("audit B rows: %d  (unique prov keys %d)\n", nrow(B), length(unique(B$key))))
cat(sprintf("reconciled rows: %d  (unique prov keys %d)\n", nrow(R), length(unique(R$key))))
cat(sprintf("unique edges: %d\n", length(unique(R$edge))))

dual <- intersect(unique(A$edge), unique(B$edge))
cat(sprintf("dual-audit edges: %d\n", length(dual)))

cat("\n---- CHECK 1: no edge carries conflicting final verdicts ----\n")
per_edge <- tapply(R$classification, R$edge, function(x) length(unique(x)))
conflicting <- names(per_edge)[per_edge > 1L]
ok("1. zero edges with conflicting final verdicts", length(conflicting) == 0L,
   if (length(conflicting)) paste(conflicting, collapse = ", ") else "checked all edges")

cat("\n---- CHECK 2: every unique provenance row from BOTH audits survives ----\n")
miss_a <- setdiff(unique(A$key), R$key)
miss_b <- setdiff(unique(B$key), R$key)
ok("2a. all audit A provenance rows preserved", length(miss_a) == 0L,
   sprintf("%d missing", length(miss_a)))
ok("2b. all audit B provenance rows preserved", length(miss_b) == 0L,
   sprintf("%d missing", length(miss_b)))
ok("2c. reconciled introduces no invented provenance rows",
   length(setdiff(R$key, union(A$key, B$key))) == 0L)
ok("2d. reconciled row count equals union of provenance keys",
   nrow(R) == length(union(unique(A$key), unique(B$key))),
   sprintf("%d rows vs %d union keys", nrow(R),
           length(union(unique(A$key), unique(B$key)))))

cat("\n---- CHECK 3: dual-audit edges retain BOTH rationales ----\n")
dual_rows <- R[R$edge %in% dual, , drop = FALSE]
both_reasons <- nzchar(dual_rows$audit_A_reason) & !is.na(dual_rows$audit_A_reason) &
                nzchar(dual_rows$audit_B_reason) & !is.na(dual_rows$audit_B_reason)
ok("3a. every dual-audit row carries a reason from each audit", all(both_reasons),
   sprintf("%d/%d rows", sum(both_reasons), nrow(dual_rows)))
# The union of rationale is preserved COLUMN-WISE with attribution, which keeps
# who-said-what, so the invariant is verbatim preservation against the sources,
# not concatenation into one string.
amap <- stats::setNames(A$reason, A$edge); bmap <- stats::setNames(B$reason, B$edge)
verb_a <- mapply(function(e, r) identical(unname(amap[[e]]), r), dual_rows$edge, dual_rows$audit_A_reason)
verb_b <- mapply(function(e, r) identical(unname(bmap[[e]]), r), dual_rows$edge, dual_rows$audit_B_reason)
ok("3b. audit A rationale preserved verbatim from source", all(verb_a),
   sprintf("%d/%d rows", sum(verb_a), nrow(dual_rows)))
ok("3c. audit B rationale preserved verbatim from source", all(verb_b),
   sprintf("%d/%d rows", sum(verb_b), nrow(dual_rows)))
ok("3d. the two rationales are distinct, not one copied over the other",
   sum(dual_rows$audit_A_reason == dual_rows$audit_B_reason) < nrow(dual_rows))
ok("3e. every disagreement records its resolution basis",
   all(nzchar(R$resolution_basis[!is.na(R$audit_A_classification) &
                                 !is.na(R$audit_B_classification) &
                                 R$audit_A_classification != R$audit_B_classification])))
cat(sprintf("   rows carrying both audits' reasons, whole file: %d/%d\n",
            sum(nzchar(R$audit_A_reason) & nzchar(R$audit_B_reason), na.rm = TRUE), nrow(R)))

cat("\n---- CHECK 4: MEGAN>MEGGIE adjudicated evidence preserved and conservative ----\n")
mm <- R[R$edge == "MEGAN>MEGGIE", , drop = FALSE]
ok("4a. MEGAN>MEGGIE present in reconciled audit", nrow(mm) > 0L,
   sprintf("%d provenance rows", nrow(mm)))
ok("4b. MEGAN>MEGGIE has one consistent verdict", length(unique(mm$classification)) == 1L,
   paste(unique(mm$classification), collapse = " / "))
ok("4c. MEGAN>MEGGIE verdict is the conservative one",
   all(mm$classification != "SUPPORTED_NEW_EDGE"), unique(mm$classification)[1])
ok("4d. the dissenting SUPPORTED_NEW_EDGE verdict is still recorded, not erased",
   any(mm$audit_A_classification == "SUPPORTED_NEW_EDGE", na.rm = TRUE) ||
   any(mm$audit_B_classification == "SUPPORTED_NEW_EDGE", na.rm = TRUE))
ok("4e. adjudication evidence text survives",
   any(nzchar(mm$reason)) && all(nzchar(mm$reason)))
ok("4f. MEGAN>MEGGIE was NOT admitted to the corpus",
   !any(toupper(corpus$name) == "MEGAN" & toupper(corpus$nickname) == "MEGGIE"))

cat("\n---- CHECK 5: already-governed pairs unaltered ----\n")
governed <- list(c("ELIZABETH","LISA"), c("ALEXANDRA","SANDRA"), c("CATHERINE","KATE"),
                 c("CATHERINE","KATIE"), c("CAROLYN","CAROL"), c("CHRISTINA","CHRIS"))
for (g in governed) {
  e <- paste(g[1], g[2], sep = ">")
  in_corpus <- any(toupper(corpus$name) == g[1] & toupper(corpus$nickname) == g[2])
  rows <- R[R$edge == e, , drop = FALSE]
  cls <- unique(rows$classification)
  ok(sprintf("5. %s governed in corpus AND classified ALREADY_PRESENT", e),
     in_corpus && (nrow(rows) == 0L || identical(cls, "ALREADY_PRESENT")),
     sprintf("corpus=%s, audit rows=%d, verdict=%s", in_corpus, nrow(rows),
             if (length(cls)) paste(cls, collapse = "/") else "not audited"))
}

cat("\n---- CHECK 6: nothing admitted, classification totals ----\n")
ok("6a. every row is classified", !any(is.na(R$classification) | R$classification == ""))
present <- R$classification == "ALREADY_PRESENT"
in_corpus_flag <- mapply(function(f, n)
  any(toupper(corpus$name) == f & toupper(corpus$nickname) == n),
  R$normalized_formal, R$normalized_nickname)
ok("6b. ALREADY_PRESENT is a corpus FACT, not an assertion",
   all(present == in_corpus_flag),
   sprintf("%d disagreements", sum(present != in_corpus_flag)))
ok("6c. nothing outside ALREADY_PRESENT was admitted to the corpus",
   !any(in_corpus_flag & !present))
ok("6d. rule 1 symmetric: no ALREADY_PRESENT row is absent from the corpus",
   !any(present & !in_corpus_flag), sprintf("%d violations", sum(present & !in_corpus_flag)))
ok("6e. reverse-direction legacy edges are surfaced, not hidden",
   all(R$classification[R$edge == "JEN>JENNIFER"] == "NEEDS_ADJUDICATION"),
   paste(unique(R$classification[R$edge == "JEN>JENNIFER"]), collapse = "/"))

cat("\n---- classification totals ----\n")
print(sort(table(R$classification), decreasing = TRUE))
cat("\n---- NEEDS_ADJUDICATION edges ----\n")
print(sort(unique(R$edge[R$classification == "NEEDS_ADJUDICATION"])))

cat("\n================ RESULT ================\n")
if (length(fails)) {
  cat("FAILED CHECKS:\n"); cat(paste0("  - ", fails, collapse = "\n"), "\n")
  quit(status = 1L)
}
cat("ALL CHECKS PASSED\n")
cat(sprintf("\nrows before merge (A|B) | rows after merge | unique edges | dual-audit edges | conflicting verdicts | unresolved adjudications\n%d|%d | %d | %d | %d | %d | %d\n",
            nrow(A), nrow(B), nrow(R), length(unique(R$edge)), length(dual), length(conflicting),
            length(unique(R$edge[R$classification == "NEEDS_ADJUDICATION"]))))
