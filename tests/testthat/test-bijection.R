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
