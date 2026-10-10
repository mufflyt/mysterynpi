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
  # The merge below is many-to-one BY CONTRACT: pool_stats() emits one row
  # per id. A caller supplying its own stats with a duplicated id would fan
  # the merge out and resolve people against manufactured rows -- the silent
  # row explosion the join ledger exists to catch. Refuse it here.
  if (anyDuplicated(stats[[id]])) {
    stop("stats must hold one row per ", id,
         "; a duplicated id would fan the merge out", call. = FALSE)
  }
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

#' Resolve a ranked candidate table to an unambiguous one-to-one linkage
#'
#' Applies caller-supplied lexicographic ranking independently to each record,
#' then enforces that a candidate is assigned to at most one record. A record
#' is resolved only when exactly one distinct candidate has its best ranking
#' tuple. If several records uniquely select the same candidate, all of those
#' claims are quarantined rather than awarding the candidate to the highest
#' score or first row. This is deliberately not a maximum-weight assignment.
#'
#' Duplicate evidence rows for the same record-candidate pair are collapsed to
#' that pair's best ranking tuple. Equal-ranked duplicate rows are represented
#' deterministically by sorting their remaining scalar columns. Missing ranking
#' values rank below observed values; when all values for a ranking field are
#' missing, that field does not break the tie. Rows without a candidate are
#' returned separately as unmatched and never compete for a shared missing ID.
#'
#' The caller owns candidate generation, evidence interpretation, and the
#' meaning and direction of each ranking field. This function only applies the
#' supplied order and ambiguity policy.
#'
#' @param candidates A data frame with one or more candidate rows per record.
#' @param id Character scalar naming the source-record identifier column.
#' @param candidate Character scalar naming the candidate-identity column.
#' @param rank_by A named character vector mapping ranking column names to
#'   directions: `"asc"` (smaller is better) or `"desc"` (larger is better).
#'   Earlier entries have precedence over later entries.
#' @param eligible `NULL` (default) or one column name holding a logical flag,
#'   constant within each record and never missing. Eligible records are
#'   resolved first; ineligible records are then resolved only on candidates no
#'   eligible record resolved to or contests, so an ineligible record (for
#'   example one already outside a study cohort but kept for linkage) can never
#'   quarantine an eligible record's candidate. Ineligible claims that give way
#'   are returned in `quarantined` with status `"yielded_to_eligible"`.
#' @param output `"list"` (default) returns the list described below.
#'   `"table"` returns the `resolved` data frame with `quarantined`,
#'   `unmatched`, and `counts` attached as attributes of the same names.
#' @return A list with `resolved`, `quarantined`, `unmatched`, and `counts`.
#'   The first three elements are data frames retaining the supplied columns
#'   and adding `resolution_status`; quarantine statuses distinguish a tie
#'   within a record from a candidate claimed by multiple records. With
#'   `output = "table"`, the `resolved` data frame carrying the other three as
#'   attributes.
#' @export
#' @examples
#' candidates <- data.frame(
#'   person = c("A", "A", "B"), npi = c("n1", "n2", "n1"),
#'   source_priority = c(1L, 2L, 1L), agreement = c(90, 100, 85)
#' )
#' result <- resolve_one_to_one(
#'   candidates, id = "person", candidate = "npi",
#'   rank_by = c(source_priority = "asc", agreement = "desc")
#' )
#' result$resolved  # empty: A and B both uniquely claim n1
#' result$quarantined
#'
#' # B is already outside the cohort: it may not block A, A gets n1.
#' candidates$in_cohort <- c(TRUE, TRUE, FALSE)
#' resolve_one_to_one(
#'   candidates, id = "person", candidate = "npi",
#'   rank_by = c(source_priority = "asc", agreement = "desc"),
#'   eligible = "in_cohort", output = "table"
#' )
resolve_one_to_one <- function(candidates, id = "id", candidate = "candidate",
                               rank_by, eligible = NULL,
                               output = c("list", "table")) {
  output <- match.arg(output)
  if (is.null(eligible)) {
    res <- .resolve_pass(candidates, id, candidate, rank_by)
  } else {
    if (!is.data.frame(candidates)) {
      stop("candidates must be a data frame", call. = FALSE)
    }
    if (!is.character(eligible) || length(eligible) != 1L || is.na(eligible) ||
        !eligible %in% names(candidates)) {
      stop("eligible must name one column of candidates", call. = FALSE)
    }
    if (eligible %in% c(id, candidate, names(rank_by))) {
      stop("eligible cannot also be the id, candidate, or a ranking column",
           call. = FALSE)
    }
    flag <- candidates[[eligible]]
    if (!is.logical(flag) || anyNA(flag)) {
      stop("eligible column '", eligible, "' must be logical with no NA",
           call. = FALSE)
    }
    mixed <- tapply(flag, candidates[[id]], function(x) length(unique(x)) > 1L)
    if (any(mixed, na.rm = TRUE)) {
      stop("eligible must be constant within each record", call. = FALSE)
    }
    first <- .resolve_pass(candidates[flag, , drop = FALSE], id, candidate, rank_by)
    held <- c(first$resolved[[candidate]], first$quarantined[[candidate]])
    held <- held[!is.na(held)]
    yields <- !flag & candidates[[candidate]] %in% held
    second <- .resolve_pass(candidates[!flag & !yields, , drop = FALSE],
                            id, candidate, rank_by)
    yielded <- candidates[yields, , drop = FALSE]
    yielded$resolution_status <- rep("yielded_to_eligible", nrow(yielded))
    bind <- function(...) {
      x <- rbind(...)
      if (nrow(x) > 1L) {
        x <- x[order(x[[id]], x[[candidate]], x$resolution_status,
                     na.last = TRUE, method = "radix"), , drop = FALSE]
      }
      rownames(x) <- NULL
      x
    }
    res <- list(
      resolved = bind(first$resolved, second$resolved),
      quarantined = bind(first$quarantined, second$quarantined, yielded),
      unmatched = bind(first$unmatched, second$unmatched)
    )
    res$counts <- c(
      input_rows = as.integer(nrow(candidates)),
      distinct_pairs = as.integer(first$counts[["distinct_pairs"]] +
        second$counts[["distinct_pairs"]] +
        nrow(unique(yielded[c(id, candidate)]))),
      resolved = as.integer(nrow(res$resolved)),
      quarantined = as.integer(nrow(res$quarantined)),
      unmatched = as.integer(nrow(res$unmatched))
    )
  }
  if (output == "list") return(res)
  out <- res$resolved
  attr(out, "quarantined") <- res$quarantined
  attr(out, "unmatched") <- res$unmatched
  attr(out, "counts") <- res$counts
  out
}

# One resolution pass over a candidate table; resolve_one_to_one() calls it
# once, or twice when `eligible` splits the records.
.resolve_pass <- function(candidates, id, candidate, rank_by) {
  if (!is.data.frame(candidates)) {
    stop("candidates must be a data frame", call. = FALSE)
  }
  if (!is.character(id) || length(id) != 1L || is.na(id) || !nzchar(id)) {
    stop("id must be one non-empty column name", call. = FALSE)
  }
  if (!is.character(candidate) || length(candidate) != 1L ||
      is.na(candidate) || !nzchar(candidate)) {
    stop("candidate must be one non-empty column name", call. = FALSE)
  }
  if (!is.character(rank_by) || !length(rank_by) ||
      is.null(names(rank_by)) || anyNA(names(rank_by)) ||
      any(!nzchar(names(rank_by))) || anyDuplicated(names(rank_by))) {
    stop("rank_by must be a non-empty named character vector", call. = FALSE)
  }
  if (any(!rank_by %in% c("asc", "desc"))) {
    stop("rank_by directions must be 'asc' or 'desc'", call. = FALSE)
  }
  if (anyDuplicated(names(candidates))) {
    stop("candidates must have unique column names", call. = FALSE)
  }
  required <- c(id, candidate, names(rank_by))
  missing <- setdiff(required, names(candidates))
  if (length(missing)) {
    stop("candidates is missing required column(s): ",
         paste(missing, collapse = ", "), call. = FALSE)
  }
  if (any(c(id, candidate) %in% names(rank_by))) {
    stop("id and candidate columns cannot also be ranking columns",
         call. = FALSE)
  }
  if ("resolution_status" %in% names(candidates)) {
    stop("candidates already contains reserved column 'resolution_status'",
         call. = FALSE)
  }
  if (anyNA(candidates[[id]]) ||
      (is.character(candidates[[id]]) && any(!nzchar(trimws(candidates[[id]]))))) {
    stop("record identifiers must be present and non-empty", call. = FALSE)
  }
  if (any(vapply(candidates, is.list, logical(1)))) {
    stop("candidates must contain scalar columns, not list columns",
         call. = FALSE)
  }
  for (column in names(rank_by)) {
    x <- candidates[[column]]
    if (!(is.numeric(x) || is.logical(x) || is.character(x) ||
          inherits(x, "Date") || inherits(x, "POSIXt") || is.ordered(x))) {
      stop("ranking column '", column,
           "' must be numeric, logical, character, date, or ordered factor",
           call. = FALSE)
    }
  }

  empty_frame <- function() {
    out <- candidates[FALSE, , drop = FALSE]
    out$resolution_status <- character(0)
    out
  }
  if (!nrow(candidates)) {
    return(list(
      resolved = empty_frame(), quarantined = empty_frame(),
      unmatched = empty_frame(),
      counts = c(input_rows = 0L, distinct_pairs = 0L, resolved = 0L,
                 quarantined = 0L, unmatched = 0L)
    ))
  }

  # Keep every row tied at the best supplied lexicographic tuple.
  best_rank_rows <- function(rows) {
    for (column in names(rank_by)) {
      values <- candidates[[column]][rows]
      observed <- which(!is.na(values))
      if (!length(observed)) next
      ordered <- order(
        values[observed],
        decreasing = identical(unname(rank_by[[column]]), "desc"),
        method = "radix"
      )
      best <- values[observed[ordered[[1L]]]]
      rows <- rows[!is.na(values) & values == best]
    }
    rows
  }

  # The ranking fields may tie across repeated evidence rows for one pair.
  # Choose a deterministic representative without relying on input order.
  stable_representative <- function(rows) {
    if (length(rows) < 2L) return(rows)
    other <- setdiff(names(candidates), names(rank_by))
    if (!length(other)) return(rows[[1L]])
    ordering <- do.call(order, c(
      lapply(candidates[other], `[`, rows),
      list(na.last = TRUE, method = "radix")
    ))
    rows[ordering[[1L]]]
  }

  candidate_values <- candidates[[candidate]]
  candidate_missing <- is.na(candidate_values)
  if (is.character(candidate_values) || is.factor(candidate_values)) {
    candidate_missing <- candidate_missing |
      !nzchar(trimws(as.character(candidate_values)))
  }
  unmatched <- which(candidate_missing)
  valid_rows <- which(!candidate_missing)
  groups <- function(rows, values) {
    if (!length(rows)) return(list())
    split(rows, match(values[rows], unique(values[rows])))
  }

  # First collapse duplicate evidence to one best representative per pair.
  pair_rows <- unlist(lapply(groups(valid_rows, candidates[[id]]), function(ids) {
    unlist(lapply(groups(ids, candidate_values), function(pair) {
      best <- best_rank_rows(pair)
      stable_representative(best)
    }), use.names = FALSE)
  }), use.names = FALSE)
  pair_rows <- as.integer(pair_rows)

  # Then select each record's best distinct candidates. Ties are abstentions.
  by_record <- groups(pair_rows, candidates[[id]])
  best_by_record <- lapply(by_record, best_rank_rows)
  tied <- unlist(best_by_record[lengths(best_by_record) > 1L],
                 use.names = FALSE)
  provisional <- unlist(best_by_record[lengths(best_by_record) == 1L],
                        use.names = FALSE)
  provisional <- as.integer(provisional)

  # A candidate uniquely selected by multiple records is contested; do not
  # let row order or a tiny score difference allocate that identity.
  contested <- integer(0)
  for (claims in groups(provisional, candidate_values)) {
    if (length(unique(candidates[[id]][claims])) > 1L) {
      contested <- c(contested, claims)
    }
  }
  contested <- unique(contested)
  resolved <- setdiff(provisional, contested)

  add_status <- function(rows, status) {
    out <- candidates[rows, , drop = FALSE]
    out$resolution_status <- rep(status, length(rows))
    out
  }
  resolved_df <- add_status(resolved, "resolved")
  tied_df <- add_status(tied, "ambiguous_tied_evidence")
  contested_df <- add_status(contested, "ambiguous_contested_candidate")
  quarantine_df <- rbind(tied_df, contested_df)
  unmatched_df <- add_status(unmatched, "no_candidate")

  stable_output_order <- function(x) {
    if (nrow(x) < 2L) return(x)
    ord <- order(x[[id]], x[[candidate]], x$resolution_status,
                 na.last = TRUE, method = "radix")
    x[ord, , drop = FALSE]
  }
  resolved_df <- stable_output_order(resolved_df)
  quarantine_df <- stable_output_order(quarantine_df)
  unmatched_df <- stable_output_order(unmatched_df)
  rownames(resolved_df) <- rownames(quarantine_df) <- rownames(unmatched_df) <- NULL

  list(
    resolved = resolved_df,
    quarantined = quarantine_df,
    unmatched = unmatched_df,
    counts = c(
      input_rows = as.integer(nrow(candidates)),
      distinct_pairs = as.integer(length(pair_rows)),
      resolved = as.integer(nrow(resolved_df)),
      quarantined = as.integer(nrow(quarantine_df)),
      unmatched = as.integer(nrow(unmatched_df))
    )
  )
}
