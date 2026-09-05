test_that("same state, same normalised number corroborates", {
  expect_identical(license_agreement("MD-12345", "CO", "md 12345", "co"),
                   "corroborates")
  expect_identical(license_agreement("A.1.2", "TX", "A12", "TX"),
                   "corroborates")
})

test_that("normalisation stops at case and punctuation, deliberately", {
  expect_identical(normalize_license(c("md 12345", "A.1-2", "", NA)),
                   c("MD12345", "A12", NA, NA))
  # leading zeros and profession prefixes are meaning, not formatting
  expect_identical(license_agreement("0052", "CO", "52", "CO"),
                   "uninformative")
  expect_identical(license_agreement("MD12345", "CO", "12345", "CO"),
                   "uninformative")
})

test_that("there is no conflicts verdict, by design", {
  # same-state mismatch: a quarter of NPIs carry multiple licenses
  expect_identical(license_agreement("12345", "CO", "99999", "CO"),
                   "uninformative")
  # cross-state same number: a numbering coincidence
  expect_identical(license_agreement("12345", "CO", "12345", "TX"),
                   "uninformative")
  grid <- expand.grid(a = c("1", "2", NA), s1 = c("CO", "TX", NA),
                      b = c("1", "2", NA), s2 = c("CO", "TX", NA),
                      stringsAsFactors = FALSE)
  got <- license_agreement(grid$a, grid$s1, grid$b, grid$s2)
  expect_true(all(got %in% c("corroborates", "uninformative")))
})

test_that("absence of any part is uninformative", {
  expect_identical(license_agreement(NA, "CO", "12345", "CO"), "uninformative")
  expect_identical(license_agreement("12345", NA, "12345", "CO"), "uninformative")
  expect_identical(license_agreement("12345", "", "12345", "CO"), "uninformative")
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(
    license_agreement(c("1", "1", NA), c("CO", "CO", "CO"),
                      c("1", "2", "1"), c("CO", "CO", "CO")),
    c("corroborates", "uninformative", "uninformative"))
  expect_error(license_agreement(c("1", "2"), "CO", "1", "CO"), "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_license_agreement_contract())
  eager <- function(a, sa, b, sb) rep("corroborates", length(a))
  expect_error(assert_license_agreement_contract(eager))
})
