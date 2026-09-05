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

test_that("license_anatomy decomposes prefix, digits, suffix, shape", {
  a <- license_anatomy(c("MD.0012345", "12345a", "A12B34", "DOC", "", NA))
  expect_identical(a$prefix,  c("MD", "", "A", "DOC", NA, NA))
  expect_identical(a$digits,  c("0012345", "12345", "12B34", NA, NA, NA))
  expect_identical(a$suffix,  c("", "A", "", "", NA, NA))
  expect_identical(a$shape,   c("MD#######", "#####A", "A##B##", "DOC", NA, NA))
  expect_identical(a$n_digits, c(7L, 5L, 4L, 0L, NA, NA))
})

test_that("conformance learns each state's shape from its own column", {
  lic <- c(rep("10001", 6), "MD10001", "20002A",
           rep("C 3-141", 4), "141")
  st  <- c(rep("CO", 8), rep("CA", 5))
  got <- license_conformance(lic, st, min_share = 0.25)
  # CO: modal is #####; the stray prefix and suffix rows are flagged
  expect_identical(got$state_modal_shape[1], "#####")
  expect_identical(got$flagged[1:8],
                   c(rep(FALSE, 6), TRUE, TRUE))
  # CA: a board whose REAL format carries a prefix is the modal shape,
  # so its prefix is never flagged -- and the bare number is
  expect_identical(got$state_modal_shape[9], "C####")
  expect_identical(got$flagged[9:13], c(FALSE, FALSE, FALSE, FALSE, TRUE))
})

test_that("a state's several common formats all survive", {
  lic <- c(rep("10001", 5), rep("A2345", 5), "XX999")
  got <- license_conformance(lic, rep("TX", 11), min_share = 0.2)
  expect_identical(sum(got$flagged), 1L)
  expect_true(got$flagged[11])
})

test_that("unusable rows are NA and appear in no denominator", {
  got <- license_conformance(c("123", NA, "123", "4567"),
                             c(NA, "CO", "CO", "CO"))
  expect_identical(got$flagged[1:2], c(NA, NA))
  expect_identical(got$shape_share[3], 0.5)   # of the two usable CO rows
  expect_error(license_conformance(c("1", "2"), "CO"), "same length")
})
