# =============================================================================
# The one-to-one constraint, and what to do about contested candidates
# =============================================================================

#' Count RIVAL ids: alternative claimants who are a different PERSON
#'
#' THE DEFECT THIS PREVENTS, which cost two false demotions before it was
#' understood. A temporal registry's unit is (candidate x snapshot x name
#' variant), NOT candidate. One person recorded with a middle initial in one
#' snapshot and without it in another supplies BOTH a conflicting and a
#' non-conflicting row -- so a naive `n_distinct(candidate[conflict])` counts a
#' person as evidence AGAINST the match that belongs to them. Two real NPIs
#' were vetoed by themselves this way.
#'
#' Anything that counts "alternative candidates" must exclude the one that won.
#'
#' @param vetoed data.frame with `id` and `vetoed` columns: candidates removed
#'   by some veto, recorded BEFORE the veto was applied.
#' @param won data.frame with `id` and `candidate`: what actually won, one row
#'   per id. `NA` candidate means the person matched nothing, so every vetoed
#'   alternative is a genuine rival.
#' @return data.frame(id, n_rivals).
#' @export
count_rivals <- function(vetoed, won, id = "id") {
  for (nm in c(id, "vetoed")) if (!nm %in% names(vetoed))
    stop("vetoed needs columns ", id, " and vetoed", call. = FALSE)
  if (anyDuplicated(won[[id]]))
    stop("won must hold one row per id; the bijection is upstream", call. = FALSE)
  if (!nrow(vetoed)) {
    out <- data.frame(character(0), integer(0), stringsAsFactors = FALSE)
    names(out) <- c(id, "n_rivals"); return(out)
  }
  v <- unique(vetoed[, c(id, "vetoed")])
  j <- merge(v, won[, c(id, "candidate")], by = id, all.x = TRUE)
  j$is_rival <- is.na(j$candidate) | j$vetoed != j$candidate
  agg <- stats::aggregate(list(n_rivals = j$is_rival), by = j[id], FUN = sum)
  agg$n_rivals <- as.integer(agg$n_rivals)
  agg[order(agg[[id]]), , drop = FALSE]
}

#' Award a contested candidate, or refuse to
#'
#' A **contested** candidate is one that two or more people each resolved to
#' independently. It is not a matching error; it is two people whose evidence
#' points at the same record, and the count is a data-quality signal in itself.
#'
#' Three policies, and the difference between them is not a matter of taste.
#' Measured on one real cohort with 93 contested candidates:
#'
#' \tabular{lrr}{
#'   policy \tab recovered \tab identities decided by SORT ORDER \cr
#'   `quarantine_all` \tab 0 \tab 0 \cr
#'   `strict_dominance` \tab 56 \tab 0 \cr
#'   `greedy` \tab 93 \tab **37** \cr
#' }
#'
#' The 37 tie on every ranking key -- 10 of them at the strongest class, meaning
#' two people whose full names AND middle names both match one record. Handing
#' that to whoever sorts first is not a linkage result. `strict_dominance` takes
#' every record the evidence justifies and none that it does not.
#'
#' `greedy` exists because reproducing a cohort frozen before this distinction
#' was drawn requires it, and a published number nobody can regenerate is worse
#' than one whose weakness is written down. It is not the default.
#'
#' @param contested data.frame of claimants on contested candidates.
#' @param policy "strict_dominance", "quarantine_all", or "greedy".
#' @param id,candidate column names.
#' @param key character: ranking columns in precedence order. Ties on ALL of
#'   them are what "not separable" means. Numeric columns are compared
#'   ascending; wrap in `-x` upstream if larger is better.
#' @return the rows to add back; zero rows if none qualify.
#' @export
award_contested <- function(contested, policy = "strict_dominance",
                            id = "id", candidate = "candidate",
                            key = "rank") {
  if (!policy %in% c("strict_dominance", "quarantine_all", "greedy"))
    stop("policy must be strict_dominance, quarantine_all or greedy", call. = FALSE)
  empty <- contested[0, , drop = FALSE]
  if (policy == "quarantine_all" || is.null(contested) || !nrow(contested))
    return(empty)
  miss <- setdiff(c(id, candidate, key), names(contested))
  if (length(miss)) stop("contested is missing: ", paste(miss, collapse = ", "),
                         call. = FALSE)
  ord <- do.call(order, c(lapply(c(candidate, key, id),
                                 function(k) contested[[k]]),
                          list(method = "radix")))
  cc <- contested[ord, , drop = FALSE]
  sig <- do.call(paste, c(lapply(key, function(k) cc[[k]]), list(sep = "\r")))
  idx <- split(seq_len(nrow(cc)), cc[[candidate]])
  keep <- unlist(lapply(idx, function(ix) {
    if (length(ix) < 2L) return(integer(0))
    if (policy == "greedy" || sig[ix[1]] != sig[ix[2]]) ix[1] else integer(0)
  }), use.names = FALSE)
  if (!length(keep)) return(empty)
  won <- cc[keep, , drop = FALSE]
  won <- won[!duplicated(won[[id]]) & !duplicated(won[[candidate]]), , drop = FALSE]
  rownames(won) <- NULL
  won
}
