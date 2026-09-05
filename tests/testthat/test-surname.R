test_that("exact key equality corroborates, even below the token floor", {
  expect_identical(surname_agreement("LEE", "LEE"), "corroborates")
  expect_identical(surname_agreement("Smith", "SMITH"), "corroborates")
})

test_that("a shared component spans hyphenation and dropped parts", {
  expect_identical(surname_agreement("MCCARTHY-DERVIN", "MCCARTHY"),
                   "corroborates")
  expect_identical(surname_agreement("HARVEY CAPISTA", "CAPISTA"),
                   "corroborates")
})

test_that("particles are convention, not identity", {
  expect_identical(surname_agreement("DE LA CRUZ", "DE LEON"), "conflicts")
  expect_identical(surname_agreement("VAN DYKE", "VAN BUREN"), "conflicts")
})

test_that("apostrophes are formatting, never a veto", {
  expect_identical(surname_agreement("O'BRIEN", "OBRIEN"), "corroborates")
  expect_identical(surname_agreement("D'ANGELO", "DANGELO"), "corroborates")
})

test_that("the maiden-as-middle rescue needs the middles, and uses them", {
  expect_identical(surname_agreement("RYE", "REINHARD"), "conflicts")
  expect_identical(
    surname_agreement("RYE", "REINHARD", middle_a = "REINHARD", middle_b = "A"),
    "corroborates")
  expect_identical(
    surname_agreement("REINHARD", "RYE", middle_a = "A", middle_b = "REINHARD"),
    "corroborates")
  # a middle that holds no surname component rescues nothing
  expect_identical(
    surname_agreement("RYE", "WORKMAN", middle_a = "REINHARD", middle_b = "B"),
    "conflicts")
})

test_that("two recorded surnames sharing nothing conflict", {
  expect_identical(surname_agreement("LEE", "SMITH"), "conflicts")
  expect_identical(surname_agreement("GARCIA", "MARTINEZ"), "conflicts")
})

test_that("absence is uninformative, never a conflict", {
  expect_identical(surname_agreement("", "SMITH"), "uninformative")
  expect_identical(surname_agreement(NA_character_, "SMITH"), "uninformative")
  expect_identical(surname_agreement("", ""), "uninformative")
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(
    surname_agreement(c("LEE", "LEE", ""), c("LEE", "SMITH", "SMITH")),
    c("corroborates", "conflicts", "uninformative"))
  expect_error(surname_agreement(c("A", "B"), "A"), "same length")
  expect_error(surname_agreement("A", "B", middle_a = c("X", "Y")),
               "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_surname_agreement_contract())
  exact_only <- function(a, b, ...) {
    ifelse(toupper(a) == toupper(b), "corroborates", "conflicts")
  }
  expect_error(assert_surname_agreement_contract(exact_only))
})
