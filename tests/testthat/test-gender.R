test_that("normalize_gender maps the encodings that occur, and only those", {
  expect_identical(normalize_gender(c("M", "male", " Female ", "f")),
                   c("M", "M", "F", "F"))
  expect_identical(normalize_gender(c("U", "UNKNOWN", "X", "", NA)),
                   rep(NA_character_, 5))
})

test_that("numeric conventions are refused, not guessed", {
  # ISO/IEC 5218 says 1=male; other systems ship the opposite. Mapping either
  # way flips gender wholesale for sources on the other convention.
  expect_identical(normalize_gender(c("1", "2", "0", "9")),
                   rep(NA_character_, 4))
})

test_that("encoding differences do not manufacture a veto", {
  expect_identical(gender_agreement("Female", "F"), "corroborates")
  expect_identical(gender_agreement(" male ", "M"), "corroborates")
})

test_that("the veto vetoes when both sides committed to a code", {
  expect_identical(gender_agreement("M", "F"), "conflicts")
  expect_identical(gender_agreement("FEMALE", "MALE"), "conflicts")
})

test_that("absence is uninformative, never a conflict", {
  expect_identical(gender_agreement("U", "F"), "uninformative")
  expect_identical(gender_agreement("", "M"), "uninformative")
  expect_identical(gender_agreement(NA_character_, "F"), "uninformative")
  expect_identical(gender_agreement(NA_character_, NA_character_),
                   "uninformative")
})

test_that("there is NO name-based gender inference", {
  expect_false(exists("infer_gender", where = asNamespace("mysterynpi"),
                      inherits = FALSE))
  expect_false(exists("guess_gender", where = asNamespace("mysterynpi"),
                      inherits = FALSE))
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(gender_agreement(c("M", "F", "U"), c("M", "M", "M")),
                   c("corroborates", "conflicts", "uninformative"))
  expect_error(gender_agreement(c("M", "F"), "M"), "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_gender_agreement_contract())
  always_block <- function(a, b) rep("conflicts", length(a))
  expect_error(assert_gender_agreement_contract(always_block))
})
