ag <- function(a, b) middle_agreement(middle_tokens(a), middle_tokens(b))

test_that("position does not manufacture disagreement", {
  expect_identical(ag("A REINHARD", "REINHARD"), "corroborates")
  expect_identical(ag("BETH HARVEY", "H"), "corroborates")
  expect_identical(ag("M", "ANN MARIE"), "corroborates")
  expect_identical(ag("JANE", "J"), "corroborates")
})

test_that("concatenated initials are initials, and order matters", {
  expect_identical(ag("VL", "VELMA LAURITZEN"), "corroborates")
  expect_identical(ag("MJ", "MARY JANE"), "corroborates")
  expect_identical(ag("CJ", "CAROL JEAN"), "corroborates")
  expect_identical(ag("VL", "LAURITZEN VELMA"), "conflicts")
})

test_that("the veto still vetoes", {
  expect_identical(ag("JANE", "DENISE"), "conflicts")
  expect_identical(ag("MARILYN", "F"), "conflicts")
  expect_identical(ag("WORKMAN", "G"), "conflicts")
  expect_identical(ag("JANE", "JOAN"), "conflicts")
})

test_that("there is NO edit-distance tolerance", {
  expect_identical(ag("JULIA", "JULIE"), "conflicts")
  expect_identical(ag("LYN", "LYNN"), "conflicts")
  expect_identical(ag("ELISABETH", "ELIZABETH"), "conflicts")
  expect_identical(ag("KRISTINA", "KRISHNA"), "conflicts")
  expect_false(exists("near_spelling", where = asNamespace("mysterynpi"),
                      inherits = FALSE))
})

test_that("absence is uninformative, never a conflict", {
  expect_identical(ag("", "MARIE"), "uninformative")
  expect_identical(ag("MARIE", ""), "uninformative")
  expect_identical(ag(NA_character_, "MARIE"), "uninformative")
  expect_identical(ag("", ""), "uninformative")
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(ag(c("A REINHARD", "JANE", ""), c("REINHARD", "DENISE", "MARIE")),
                   c("corroborates", "conflicts", "uninformative"))
  expect_error(middle_agreement(list("A"), list("A", "B")), "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_middle_agreement_contract())
  always_agree <- function(a, b) rep("corroborates", length(a))
  expect_error(assert_middle_agreement_contract(always_agree))
})
