test_that("WINKLER_CENSUS is what the build script promises", {
  expect_identical(nrow(WINKLER_CENSUS), 841L)
  expect_identical(as.integer(table(WINKLER_CENSUS$relation)[c("A", "B")]),
                   c(449L, 392L))
  expect_identical(
    length(with(WINKLER_CENSUS,
                intersect(id[relation == "A"], id[relation == "B"]))), 327L)
  # the within-relation duplicates are kept, and are the duplicate demo
  expect_identical(
    sum(duplicated(paste(WINKLER_CENSUS$relation, WINKLER_CENSUS$id))), 11L)
  expect_true(all(nzchar(WINKLER_CENSUS$surname)))
})

test_that("the Winkler matches carry the pathology they exist for", {
  a <- WINKLER_CENSUS[WINKLER_CENSUS$relation == "A", ]
  b <- WINKLER_CENSUS[WINKLER_CENSUS$relation == "B", ]
  m <- merge(a, b, by = "id", suffixes = c("_a", "_b"))
  # a real share of true matches disagree on the raw surname string --
  # that is why exact equality alone cannot link this corpus
  expect_gt(mean(m$surname_a != m$surname_b), 0.2)
})

test_that("SURNAME_FREQUENCIES is the Census top thousand", {
  expect_identical(nrow(SURNAME_FREQUENCIES), 1000L)
  expect_identical(SURNAME_FREQUENCIES$surname[1:3],
                   c("SMITH", "JOHNSON", "WILLIAMS"))
  # Census assigns TIED ranks to tied counts (SAUNDERS and FRANCO share
  # rank 476), so ranks are sorted with a few repeats, never renumbered here
  expect_false(is.unsorted(SURNAME_FREQUENCIES$rank))
  expect_lte(max(SURNAME_FREQUENCIES$rank), 1000L)
  ties <- SURNAME_FREQUENCIES$rank[duplicated(SURNAME_FREQUENCIES$rank)]
  for (t in ties) {
    expect_identical(length(unique(
      SURNAME_FREQUENCIES$count[SURNAME_FREQUENCIES$rank == t])), 1L)
  }
  expect_false(anyNA(SURNAME_FREQUENCIES))
})

test_that("ROSTER_BENCHMARK holds what its documentation claims", {
  expect_identical(nrow(ROSTER_BENCHMARK), 190L)
  expect_identical(anyDuplicated(ROSTER_BENCHMARK$pair_id), 0L)
  expect_setequal(unique(ROSTER_BENCHMARK$truth), c("match", "nonmatch"))
  expect_identical(sum(ROSTER_BENCHMARK$truth == "match"), 132L)
  # the trap families exist and are all nonmatches; the rescue families
  # exist and are all matches
  with_truth <- function(f) unique(ROSTER_BENCHMARK$truth[
    ROSTER_BENCHMARK$family == f])
  expect_identical(with_truth("spelling-trap"), "nonmatch")
  expect_identical(with_truth("cross-gender-derivative"), "nonmatch")
  expect_identical(with_truth("hub-nickname"), "nonmatch")
  expect_identical(with_truth("maiden-as-middle"), "match")
  expect_identical(with_truth("stale-gender"), "match")
  expect_setequal(with_truth("suffix-generations"), c("match", "nonmatch"))
  expect_setequal(with_truth("license-anchor"), c("match", "nonmatch"))
})

test_that("the shipped CSV is the same benchmark", {
  csv <- read.csv(system.file("extdata", "roster_benchmark.csv",
                              package = "mysterynpi"),
                  comment.char = "#", colClasses = "character")
  expect_identical(nrow(csv), nrow(ROSTER_BENCHMARK))
  expect_identical(csv$pair_id, ROSTER_BENCHMARK$pair_id)
  expect_identical(csv$truth, ROSTER_BENCHMARK$truth)
})
