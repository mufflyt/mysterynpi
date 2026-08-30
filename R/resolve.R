# =============================================================================
# Ordered-class resolution, and the one-to-one constraint
# =============================================================================
#
# WHAT IS MECHANISM AND WHAT IS POLICY. The framework below -- collapse to one
# row per (person, candidate), take the strongest class, resolve only when that
# class holds exactly ONE candidate, quarantine otherwise -- is generic. Which
# classes exist, what evidence earns each one, and what a study is willing to
# claim from them is NOT, and stays with the caller.
#
# Ordered classes rather than a blended score, deliberately. A numeric
# threshold expresses a continuous question about categorical evidence. In the
# pipeline this comes from, the blended version carried a margin constant whose
# zero-conflict behaviour turned out to be structural -- the candidates it
# compared never coexisted -- rather than evidence the threshold was right.
# =============================================================================

#' Collapse candidates to one row per (id, candidate), keeping the strongest class
#'
#' DETERMINISTIC TIEBREAK. Picking with `which.min()` returns the FIRST minimum,
#' so when one person has two rows for the same candidate tied at the same
#' class, the retained row depends on input order. A permutation suite measured
#' this: the recorded name variant changed in **231 of 300 orderings** while the
#' accepted identity never moved once. Identity was never at risk, but the
#' recorded variant is what a human reads when judging whether a weak match is
#' real, and two reviewers running on different days must not see different
#' evidence for the same person. Sorting first makes the retained row a
#' property of the data rather than of row order.
#'
#' @param candidates data.frame of candidate pairs.
#' @param id,candidate,class column names.
#' @param tiebreak character: additional columns, in order, that make the
#'   retained representative deterministic. Strongly recommended.
#' @return one row per (id, candidate), carrying the minimum class.
#' @export
collapse_candidates <- function(candidates, id = "id", candidate = "candidate",
                                class = "evidence_class",
                                tiebreak = character(0)) {
  need <- c(id, candidate, class, tiebreak)
  miss <- setdiff(need, names(candidates))
  if (length(miss)) {
    stop(sprintf("candidates is missing: %s", paste(miss, collapse = ", ")),
         call. = FALSE)
  }
  ord <- do.call(order, c(lapply(c(id, candidate, class, tiebreak),
                                 function(k) candidates[[k]]),
                          list(method = "radix")))
  d <- candidates[ord, , drop = FALSE]
  key <- paste(d[[id]], d[[candidate]], sep = "\r")
  keep <- !duplicated(key)                       # first row after sorting
  out <- d[keep, , drop = FALSE]
  out[[class]] <- as.integer(stats::ave(d[[class]], key, FUN = min))[keep]
  rownames(out) <- NULL
  out
}

#' Per-person pool statistics
#'
#' `n_at_best` is the number that decides everything downstream: one candidate
#' at the strongest class resolves, more than one is ambiguous.
#'
#' @param per_candidate output of [collapse_candidates()].
#' @param id,class column names.
#' @param facet optional column (e.g. a taxonomy axis) counted per class-best
#'   pool. Counted, never used to break a tie -- see [resolve_best_class()].
#' @return one row per id.
#' @export
pool_stats <- function(per_candidate, id = "id", class = "evidence_class",
                       facet = NULL) {
  k <- per_candidate[[id]]
  best <- stats::ave(per_candidate[[class]], k, FUN = min)
  at_best <- per_candidate[[class]] == best
  agg <- data.frame(
    id = unique(k),
    n_candidates = as.integer(table(k)[as.character(unique(k))]),
    best_class = as.integer(best[!duplicated(k)]),
    n_at_best = as.integer(tapply(at_best, k, sum)[as.character(unique(k))]),
    stringsAsFactors = FALSE)
  names(agg)[1] <- id
  if (!is.null(facet)) {
    for (lv in sort(unique(per_candidate[[facet]]))) {
      agg[[paste0("n_", lv)]] <-
        as.integer(tapply(per_candidate[[facet]] == lv, k, sum)[as.character(agg[[id]])])
    }
  }
  agg
}

#' Resolve people whose strongest class holds exactly one candidate
#'
#' TAXONOMY -- OR ANY OTHER FACET -- MAY NOT BREAK THE TIE. Several candidates
#' at the strongest class means they are indistinguishable on the evidence
#' held. A facet like taxonomy says what a candidate record is *for*, not
#' *which person* the name refers to. Letting it decide is how a resolver
#' becomes a plausible-match machine.
#'
#' @param per_candidate,stats outputs of [collapse_candidates()], [pool_stats()].
#' @param id,class column names.
#' @param confidence optional numeric vector indexed by class, attached as
#'   `confidence`. Reporting only; nothing here ranks on it.
#' @return the resolved rows, one per id.
#' @export
resolve_best_class <- function(per_candidate, stats, id = "id",
                               class = "evidence_class", confidence = NULL) {
  m <- merge(per_candidate, stats[, c(id, "best_class", "n_at_best")],
             by = id, all.x = TRUE)
  out <- m[m[[class]] == m$best_class & m$n_at_best == 1L, , drop = FALSE]
  if (!is.null(confidence)) out$confidence <- confidence[out[[class]]]
  rownames(out) <- NULL
  out
}

#' Ordered-class resolution end to end
#'
#' @inheritParams collapse_candidates
#' @param facet,confidence see [pool_stats()], [resolve_best_class()].
#' @return list(per_candidate, stats, resolved, quarantined).
#' @export
resolve_ordered_classes <- function(candidates, id = "id",
                                    candidate = "candidate",
                                    class = "evidence_class",
                                    tiebreak = character(0),
                                    facet = NULL, confidence = NULL) {
  pc <- collapse_candidates(candidates, id, candidate, class, tiebreak)
  ps <- pool_stats(pc, id, class, facet)
  rs <- resolve_best_class(pc, ps, id, class, confidence)
  list(per_candidate = pc, stats = ps, resolved = rs,
       quarantined = setdiff(unique(candidates[[id]]), unique(rs[[id]])))
}
