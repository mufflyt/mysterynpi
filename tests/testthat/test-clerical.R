pc <- data.frame(
  id = sprintf("p%02d", 1:20),
  candidate = sprintf("npi%02d", 1:20),
  evidence_class = rep(c(1L, 2L, 3L), c(4, 10, 6)),
  roster_name = sprintf("name%02d", 1:20),
  stringsAsFactors = FALSE)

test_that("the sample is stratified, capped per class, and reproducible", {
  s <- clerical_sample(pc, n_per_class = 5, seed = 20260905)
  expect_identical(as.integer(table(s$key$evidence_class)), c(4L, 5L, 5L))
  s2 <- clerical_sample(pc, n_per_class = 5, seed = 20260905)
  expect_identical(s, s2)
  s3 <- clerical_sample(pc, n_per_class = 5, seed = 1)
  expect_false(identical(s$key, s3$key))
})

test_that("the draw is a property of data and seed, not row order", {
  perm <- pc[sample(nrow(pc)), , drop = FALSE]
  a <- clerical_sample(pc, n_per_class = 3, seed = 7)
  b <- clerical_sample(perm, n_per_class = 3, seed = 7)
  key <- function(s) {
    k <- s$key[, c("id", "candidate", "evidence_class")]
    k[order(k$id), , drop = FALSE]
  }
  expect_equal(key(a), key(b), ignore_attr = TRUE)
})

test_that("the sheet is blind: no class column, ids assigned after shuffling", {
  s <- clerical_sample(pc, n_per_class = 5, seed = 42)
  expect_false("evidence_class" %in% names(s$sheet))
  expect_true(all(is.na(s$sheet$reviewer_verdict)))
  expect_identical(s$sheet$review_id, sprintf("REV%04d", seq_len(nrow(s$sheet))))
  # review order must not sort by class -- that would leak the stratum
  m <- merge(s$sheet["review_id"], s$key)[order(
    merge(s$sheet["review_id"], s$key)$review_id), ]
  expect_true(is.unsorted(m$evidence_class))
  # asking to see the class is refused silently
  s4 <- clerical_sample(pc, n_per_class = 2, seed = 1,
                        cols = c("roster_name", "evidence_class"))
  expect_false("evidence_class" %in% names(s4$sheet))
})

test_that("the global random state is left untouched", {
  set.seed(99); before <- .Random.seed
  clerical_sample(pc, n_per_class = 3, seed = 5)
  expect_identical(.Random.seed, before)
})

test_that("a seed is required, and bad columns are named", {
  expect_error(clerical_sample(pc, n_per_class = 3), "seed is required")
  expect_error(clerical_sample(pc[, 1:2], n_per_class = 3, seed = 1),
               "missing")
  expect_error(clerical_sample(pc, n_per_class = 3, seed = 1, cols = "nope"),
               "nope")
})

test_that("clerical_precision reports per class, with unreviewed counted", {
  s <- clerical_sample(pc, n_per_class = 5, seed = 20260905)
  v <- data.frame(review_id = s$key$review_id,
                  is_match = rep(TRUE, nrow(s$key)))
  v$is_match[s$key$evidence_class == 3L] <- c(TRUE, TRUE, FALSE, TRUE, NA)
  p <- clerical_precision(s$key, v)
  expect_identical(p$evidence_class, c(1L, 2L, 3L))
  expect_identical(p$n_sampled, c(4L, 5L, 5L))
  expect_identical(p$n_reviewed, c(4L, 5L, 4L))
  expect_identical(p$n_match, c(4L, 5L, 3L))
  expect_equal(p$precision, c(1, 1, 0.75))
  expect_true(all(p$ci_low <= p$precision & p$precision <= p$ci_high))
})

test_that("clerical_precision refuses what it cannot audit", {
  s <- clerical_sample(pc, n_per_class = 2, seed = 1)
  expect_error(clerical_precision(s$key, data.frame(review_id = "REV9999",
                                                    is_match = TRUE)),
               "unknown review ids")
  dup <- data.frame(review_id = rep(s$key$review_id[1], 2),
                    is_match = c(TRUE, FALSE))
  expect_error(clerical_precision(s$key, dup), "more than one row")
  expect_error(clerical_precision(s$key, data.frame(x = 1)),
               "review_id and is_match")
})
