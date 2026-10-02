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
