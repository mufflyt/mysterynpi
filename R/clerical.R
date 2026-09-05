# =============================================================================
# Clerical review: a blinded, stratified sample, and the precision it buys
# =============================================================================
#
# WHY THIS IS SHARED MACHINERY. Ordered classes make a claim per class --
# "full name plus corroborating middle" is a different assertion from "full
# name alone" -- and the only way to publish those claims as numbers is a
# blinded review of a sample FROM EACH CLASS. That stratification is the
# payoff of ordered classes over a blended score: a score buys one pooled
# precision estimate, a class buys one per rule. The sampling and the
# bookkeeping are mechanism and live here; who reviews, how many, and what
# counts as a match remain the study's.
#
# BLINDING IS STRUCTURAL, NOT PROCEDURAL. The reviewer sheet carries no
# evidence class, no pool statistics, and review ids assigned AFTER shuffling,
# so neither column nor position leaks which stratum a pair came from. A
# reviewer who knows a pair sits in the weakest class knows what the machine
# concluded, and is no longer measuring the machine.
# =============================================================================

#' Draw a blinded, class-stratified sample of candidate pairs for review
#'
#' @param per_candidate data.frame of candidate pairs, e.g. the
#'   `per_candidate` element of [resolve_ordered_classes()].
#' @param n_per_class rows to sample from each evidence class; a class with
#'   fewer rows contributes all of them.
#' @param seed integer, REQUIRED. The draw must be reproducible to be
#'   auditable, and a default seed would smuggle a constant into every study's
#'   methods section; the seed belongs in yours. The global random state is
#'   saved and restored, so calling this does not perturb the caller's
#'   randomness.
#' @param id,candidate,class column names.
#' @param cols columns to show the reviewer. Defaults to everything except
#'   `class` -- which is never shown, whatever `cols` says.
#' @return list of two data.frames. `sheet`: `review_id`, the `cols`, and an
#'   empty `reviewer_verdict` column, shuffled -- give this to the reviewer.
#'   `key`: `review_id`, `id`, `candidate`, `class` -- keep this from the
#'   reviewer, then hand both to [clerical_precision()].
#' @export
clerical_sample <- function(per_candidate, n_per_class, seed,
                            id = "id", candidate = "candidate",
                            class = "evidence_class", cols = NULL) {
  need <- c(id, candidate, class)
  miss <- setdiff(need, names(per_candidate))
  if (length(miss)) {
    stop(sprintf("per_candidate is missing: %s", paste(miss, collapse = ", ")),
         call. = FALSE)
  }
  if (missing(seed)) {
    stop("seed is required: the draw must be reproducible from the methods ",
         "section alone", call. = FALSE)
  }
  if (is.null(cols)) cols <- setdiff(names(per_candidate), class)
  cols <- setdiff(cols, class)              # the class is never shown
  if (length(bad <- setdiff(cols, names(per_candidate)))) {
    stop(sprintf("cols not in per_candidate: %s", paste(bad, collapse = ", ")),
         call. = FALSE)
  }
  old <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv())
  on.exit(if (!is.null(old)) assign(".Random.seed", old, globalenv()))
  set.seed(seed)
  # Sort before sampling so the draw is a property of the data and the seed,
  # not of input row order -- same reasoning as collapse_candidates().
  ord <- do.call(order, c(unname(per_candidate[c(class, id, candidate)]),
                          list(method = "radix")))
  d <- per_candidate[ord, , drop = FALSE]
  take <- unlist(lapply(split(seq_len(nrow(d)), d[[class]]), function(ix) {
    if (length(ix) <= n_per_class) ix else sort(sample(ix, n_per_class))
  }), use.names = FALSE)
  s <- d[take, , drop = FALSE]
  shuffle <- sample(nrow(s))                # ids assigned AFTER the shuffle
  s <- s[shuffle, , drop = FALSE]
  rid <- sprintf("REV%04d", seq_len(nrow(s)))
  sheet <- cbind(data.frame(review_id = rid, stringsAsFactors = FALSE),
                 s[, cols, drop = FALSE],
                 data.frame(reviewer_verdict = NA_character_,
                            stringsAsFactors = FALSE))
  key <- data.frame(review_id = rid, stringsAsFactors = FALSE)
  key[[id]] <- s[[id]]; key[[candidate]] <- s[[candidate]]
  key[[class]] <- s[[class]]
  rownames(sheet) <- NULL; rownames(key) <- NULL
  list(sheet = sheet, key = key)
}

#' Per-class precision from a completed clerical review
#'
#' Joins the reviewer's verdicts back to the blinding key and reports, per
#' evidence class: rows sampled, rows reviewed, matches confirmed, precision,
#' and an exact binomial confidence interval ([stats::binom.test()]).
#' Unreviewed rows are counted and excluded, never imputed; a class reviewed
#' at zero rows gets `NA` precision, not a flattering blank.
#'
#' @param key the `key` frame from [clerical_sample()].
#' @param verdicts data.frame with `review_id` and `is_match` (logical; `NA`
#'   means not reviewed). Unknown review ids error -- a verdict that matches
#'   no sampled row is a transcription failure, not data.
#' @param class column name of the class in `key`.
#' @param conf.level confidence level for the interval.
#' @return one row per class: `n_sampled`, `n_reviewed`, `n_match`,
#'   `precision`, `ci_low`, `ci_high`.
#' @export
clerical_precision <- function(key, verdicts, class = "evidence_class",
                               conf.level = 0.95) {
  for (nm in c("review_id", "is_match")) if (!nm %in% names(verdicts))
    stop("verdicts needs columns review_id and is_match", call. = FALSE)
  if (length(bad <- setdiff(verdicts$review_id, key$review_id))) {
    stop(sprintf("verdicts carry unknown review ids: %s",
                 paste(bad, collapse = ", ")), call. = FALSE)
  }
  if (anyDuplicated(verdicts$review_id)) {
    stop("verdicts holds more than one row for a review id", call. = FALSE)
  }
  m <- merge(key, verdicts, by = "review_id", all.x = TRUE)
  out <- do.call(rbind, lapply(split(m, m[[class]]), function(g) {
    rev <- g$is_match[!is.na(g$is_match)]
    ci <- if (length(rev)) stats::binom.test(sum(rev), length(rev),
                                             conf.level = conf.level)$conf.int
          else c(NA_real_, NA_real_)
    data.frame(class = g[[class]][1], n_sampled = nrow(g),
               n_reviewed = length(rev), n_match = sum(rev),
               precision = if (length(rev)) mean(rev) else NA_real_,
               ci_low = ci[1], ci_high = ci[2], stringsAsFactors = FALSE)
  }))
  names(out)[1] <- class
  out <- out[order(out[[class]]), , drop = FALSE]
  rownames(out) <- NULL
  out
}
