mk <- function(...) data.frame(..., stringsAsFactors = FALSE)

test_that("a name variant of the winner is not its own rival", {
  vetoed <- mk(id = c("A","A"), vetoed = c("n1","n2"))
  won    <- mk(id = "A", candidate = "n1")
  expect_identical(count_rivals(vetoed, won)$n_rivals, 1L)   # n1 is self
})

test_that("an unmatched person's vetoed candidates are all rivals", {
  expect_identical(
    count_rivals(mk(id = c("A","A"), vetoed = c("n1","n2")),
                 mk(id = "A", candidate = NA_character_))$n_rivals, 2L)
})

test_that("count_rivals refuses a winner table with duplicate ids", {
  expect_error(count_rivals(mk(id = "A", vetoed = "n1"),
                            mk(id = c("A","A"), candidate = c("n1","n2"))),
               "one row per id")
})

test_that("strict_dominance awards the separable and REFUSES the tie", {
  cc <- mk(id = c("A","B","C","D"),
           candidate = c("n1","n1","n2","n2"),
           rank = c(1L, 2L, 3L, 3L))          # n1 separable, n2 an exact tie
  w <- award_contested(cc, "strict_dominance")
  expect_identical(w$id, "A")
  expect_false("n2" %in% w$candidate)
})

test_that("greedy takes the tie too -- the behaviour being priced", {
  cc <- mk(id = c("A","B","C","D"), candidate = c("n1","n1","n2","n2"),
           rank = c(1L, 2L, 3L, 3L))
  expect_equal(nrow(award_contested(cc, "greedy")), 2L)
  expect_equal(nrow(award_contested(cc, "quarantine_all")), 0L)
})

test_that("no person wins two candidates and no candidate goes to two people", {
  cc <- mk(id = c("A","B","A","C"), candidate = c("n1","n1","n2","n2"),
           rank = c(1L, 2L, 1L, 2L))
  w <- award_contested(cc, "strict_dominance")
  expect_false(any(duplicated(w$id)))
  expect_false(any(duplicated(w$candidate)))
})

test_that("an unknown policy errors rather than silently quarantining", {
  expect_error(award_contested(mk(id="A", candidate="n1", rank=1L), "whatever"))
})

# Regression test modeled on reclin2's test_select_greedy.R ("Test empty set
# pairs; regression test"): a contested table can legitimately have zero rows
# (no contested candidates this run), and every policy must hand back a
# zero-row frame with the input's columns, not error.
test_that("award_contested on zero rows returns zero rows, not an error, for every policy", {
  empty <- mk(id = character(0), candidate = character(0), rank = integer(0))
  for (policy in c("strict_dominance", "greedy", "quarantine_all")) {
    w <- award_contested(empty, policy)
    expect_equal(nrow(w), 0L)
    expect_identical(names(w), names(empty))
  }
})

# Modeled on reclin2's test_greedy.R, which tests that NA weights are
# detected rather than silently sorted as if they were real evidence. Here an
# NA rank means "no ranking evidence for this claim", and must never let that
# claimant win over a ranked rival, nor break a tie between two unranked ones.
test_that("a candidate with no rank information never silently wins a contest", {
  ranked_beats_unranked <- mk(id = c("A", "B"), candidate = c("n1", "n1"),
                              rank = c(NA_integer_, 1L))
  w <- award_contested(ranked_beats_unranked, "strict_dominance")
  expect_identical(w$id, "B")

  both_unranked <- mk(id = c("A", "B"), candidate = c("n1", "n1"),
                      rank = c(NA_integer_, NA_integer_))
  expect_equal(nrow(award_contested(both_unranked, "strict_dominance")), 0L)
})

# Modeled on reclin2's test_greedy.R assertion that greedy() sorts internally
# so its result does not depend on input row order. award_contested() makes
# the same claim implicitly (it re-sorts on entry); this pins it as a
# contract for all three policies, then formalizes the vignette's own prose
# claim ("vignette('vetoes-and-quarantine')" / roster-benchmark: "greedy hands
# [ties] to whoever sorts first") as an executable test: on a full tie across
# every `key` column, greedy awards the lowest-sorting id and strict_dominance
# refuses to award anyone.
test_that("award_contested is independent of input row order, for every policy", {
  cc <- mk(id = c("A", "B", "C", "D"), candidate = c("n1", "n1", "n2", "n2"),
           rank = c(1L, 2L, 3L, 3L))
  for (policy in c("strict_dominance", "greedy", "quarantine_all")) {
    base <- award_contested(cc, policy)
    base <- base[order(base$id), , drop = FALSE]
    rownames(base) <- NULL
    for (i in 1:20) {
      perm <- cc[sample(nrow(cc)), , drop = FALSE]
      got <- award_contested(perm, policy)
      got <- got[order(got$id), , drop = FALSE]
      rownames(got) <- NULL
      expect_identical(got, base)
    }
  }
})

test_that("a full tie on every key column: greedy hands it to the lowest id, strict_dominance refuses", {
  cc <- mk(id = c("B", "A"), candidate = c("n1", "n1"), rank = c(5L, 5L))
  expect_equal(nrow(award_contested(cc, "strict_dominance")), 0L)
  w <- award_contested(cc, "greedy")
  expect_identical(w$id, "A")   # "A" sorts before "B"
})

test_that("count_rivals does not propagate NA from an unrecorded veto", {
  # vetoed=NA used to make is_rival NA, and aggregate(sum) returned NA.
  v <- mk(id = c("A", "A", "B"), vetoed = c("n1", NA, "n2"))
  w <- mk(id = c("A", "B"), candidate = c("n1", "n9"))
  r <- count_rivals(v, w)
  expect_identical(r$n_rivals, c(1L, 1L))   # A: only the NA veto counts
})

test_that("award_contested signatures cannot collide across a literal CR", {
  # paste(sep="\\r") fused ("x\\ry","z") and ("x","y\\rz") into one signature,
  # manufacturing the tie strict_dominance exists to refuse.
  cc <- mk(id = c("p", "q"), candidate = c("n1", "n1"),
           r1 = c("x\ry", "x"), r2 = c("z", "y\rz"), rank = 1:2)
  w <- award_contested(cc, "strict_dominance", key = c("r1", "r2"))
  expect_identical(nrow(w), 1L)             # distinct signatures: one wins
  # A REAL tie still refuses, CR-free signatures included.
  cc2 <- mk(id = c("p", "q"), candidate = c("n1", "n1"),
            r1 = c("x", "x"), r2 = c("z", "z"), rank = 1:2)
  expect_identical(nrow(award_contested(cc2, "strict_dominance",
                                      key = c("r1", "r2"))), 0L)
})
