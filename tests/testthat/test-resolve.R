mk <- function(...) data.frame(..., stringsAsFactors = FALSE)

test_that("a person resolves only when the strongest class is unique", {
  cand <- mk(id = c("A","A","B","B","C"),
             candidate = c("n1","n2","n3","n4","n5"),
             evidence_class = c(1L, 2L, 2L, 2L, 3L))
  r <- resolve_ordered_classes(cand)
  expect_identical(sort(r$resolved$id), c("A", "C"))     # B ties at class 2
  expect_identical(r$resolved$candidate[r$resolved$id == "A"], "n1")
  expect_identical(r$quarantined, "B")
})

test_that("collapsing keeps the strongest class per (id, candidate)", {
  cand <- mk(id = "A", candidate = c("n1","n1","n1"), evidence_class = c(3L,1L,2L))
  pc <- collapse_candidates(cand)
  expect_equal(nrow(pc), 1L)
  expect_identical(pc$evidence_class, 1L)
})

test_that("the retained representative is a property of the data, not row order", {
  cand <- mk(id = "A", candidate = "n1", evidence_class = c(2L, 2L),
             variant = c("WRIGHT", "WILLIAMS"))
  a <- collapse_candidates(cand, tiebreak = "variant")$variant
  b <- collapse_candidates(cand[c(2, 1), ], tiebreak = "variant")$variant
  expect_identical(a, b)
  expect_identical(a, "WILLIAMS")
})

test_that("a facet is COUNTED and never breaks a tie", {
  cand <- mk(id = "A", candidate = c("n1","n2"), evidence_class = c(2L,2L),
             tax = c("midwife", "nursing"))
  r <- resolve_ordered_classes(cand, facet = "tax")
  expect_equal(nrow(r$resolved), 0L)          # tied, despite one being midwife
  expect_identical(r$stats$n_midwife, 1L)
  expect_identical(r$stats$n_nursing, 1L)
})

test_that("confidence is reporting only and is indexed by class", {
  cand <- mk(id = "A", candidate = "n1", evidence_class = 3L)
  r <- resolve_ordered_classes(cand, confidence = c(1, .9, .7, .5, .35))
  expect_equal(r$resolved$confidence, 0.7)
})

test_that("a missing column is named, not silently tolerated", {
  expect_error(collapse_candidates(mk(id = "A"), ), "missing")
})

# Regression test modeled on reclin2's test_select_greedy.R, which pins that
# select_greedy() on a zero-row pairs table returns logical(0) rather than
# erroring -- an empty candidate frame is a normal pipeline state (e.g. a
# block with no survivors), not an edge case that should need special-casing
# by every caller.
test_that("resolve_ordered_classes on zero rows returns well-formed empty output, not an error", {
  empty <- mk(id = character(0), candidate = character(0), evidence_class = integer(0))
  r <- resolve_ordered_classes(empty)
  expect_equal(nrow(r$per_candidate), 0L)
  expect_equal(nrow(r$stats), 0L)
  expect_equal(nrow(r$resolved), 0L)
  expect_identical(r$quarantined, character(0))
})

test_that("an unclassed (NA) sibling row cannot erase a candidate's real class", {
  # min(c(NA, 2)) is NA: the collapse used to report candidate n1 as unclassed.
  pc <- collapse_candidates(mk(id = c("A", "A"), candidate = c("n1", "n1"),
                               evidence_class = c(NA, 2L)))
  expect_identical(pc$evidence_class, 2L)
  # ...and an all-NA candidate stays NA rather than becoming Inf or a warning.
  pc2 <- collapse_candidates(mk(id = "A", candidate = "n1",
                                evidence_class = NA_integer_))
  expect_true(is.na(pc2$evidence_class))
})

test_that("an unclassed rival cannot blank a pool or fabricate resolved rows", {
  cand <- mk(id = c("A", "A", "B", "B", "C"),
             candidate = c("n1", "n1", "n3", "n4", "n5"),
             evidence_class = c(NA, 2L, 1L, NA, NA))
  r <- resolve_ordered_classes(cand)
  # B's only CLASSED candidate is unique at class 1: it resolves. Before the
  # fix best_class was NA, B was quarantined, and the NA row index injected
  # three all-NA rows into `resolved`.
  expect_false(anyNA(r$resolved$id))
  expect_identical(sort(r$resolved$id), c("A", "B"))
  expect_identical(r$resolved$candidate[r$resolved$id == "B"], "n3")
  st <- r$stats[r$stats$id == "C", ]
  expect_true(is.na(st$best_class))   # nothing earned a class
  expect_identical(st$n_at_best, 0L)  # so nothing is at best: quarantined
  expect_identical(r$quarantined, "C")
})

test_that("resolve_best_class drops NA comparisons instead of injecting rows", {
  pc <- mk(id = c("A", "B"), candidate = c("n1", "n2"),
           evidence_class = c(1L, NA))
  st <- mk(id = c("A", "B"), best_class = c(1L, NA), n_at_best = c(1L, NA))
  out <- resolve_best_class(pc, st)
  expect_identical(out$id, "A")
})
