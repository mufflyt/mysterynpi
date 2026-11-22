# Saboteurs and contracts for the srr standards implemented in 0.10.0
#
# Each test names the standard it exists for. The point is not coverage: it is
# that a later change which quietly drops one of these options fails here
# rather than in a reviewer's checklist.

test_that("G2.14a: na_action = 'error' refuses to compare missing values", {
  expect_error(
    middle_agreement(middle_tokens(""), middle_tokens("MARIE"),
                     na_action = "error"),
    "refuses to compare")
  expect_error(surname_agreement(NA, "SMITH", na_action = "error"),
               "refuses to compare")
  expect_error(gender_agreement(NA, "F", na_action = "error"),
               "refuses to compare")
  expect_error(graduation_year_agreement(2015, NA, na_action = "error"),
               "refuses to compare")
})

test_that("G2.14b: na_action = 'warn' warns once and still decides nothing", {
  expect_warning(
    out <- middle_agreement(middle_tokens(c("", "A")),
                            middle_tokens(c("MARIE", "A")),
                            na_action = "warn"),
    "absent evidence, not conflicting evidence")
  expect_equal(out, c("uninformative", "corroborates"))
  # ONE warning per call, not one per row: the policy is resolved before the
  # comparison loop, which is why this matters for a 300,000-row vector.
  w <- testthat::capture_warnings(
    middle_agreement(middle_tokens(rep("", 50)),
                     middle_tokens(rep("MARIE", 50)), na_action = "warn"))
  expect_length(w, 1L)
})

test_that("G2.14: the default is byte-identical to the pre-0.10.0 behaviour", {
  # The contract asserters run against the default, so this is the regression
  # that would catch a default change: absence is uninformative, never
  # conflicting, and present evidence is unaffected.
  expect_equal(middle_agreement(middle_tokens(""), middle_tokens("MARIE")),
               "uninformative")
  expect_equal(middle_agreement(middle_tokens("A REINHARD"),
                                middle_tokens("REINHARD")), "corroborates")
  expect_equal(middle_agreement(middle_tokens("JULIA"), middle_tokens("JULIE")),
               "conflicts")
  expect_silent(middle_agreement(middle_tokens(""), middle_tokens("MARIE")))
})

test_that("G2.14: an unknown policy is rejected, naming the permitted set", {
  expect_error(middle_agreement(middle_tokens("A"), middle_tokens("A"),
                                na_action = "impute"),
               "should be one of")
  # And the refusal of imputation is deliberate, documented, and not an
  # oversight: see R/missing_policy.R.
  expect_false("impute" %in% NA_ACTIONS)
})

test_that("G2.16: NaN and infinities are undefined, not missing", {
  expect_equal(is_undefined_number(c(2015, NA, NaN, Inf, -Inf)),
               c(FALSE, FALSE, TRUE, TRUE, TRUE))
  expect_false(any(is_undefined_number(c("2015", NA))))
  expect_equal(finite_or_na(c(2015, NaN, Inf)), c(2015, NA, NA))
  expect_equal(graduation_year_agreement(2015, NaN), "uninformative")
  expect_equal(graduation_year_agreement(2015, Inf), "uninformative")
  expect_error(graduation_year_agreement(2015, Inf, undefined = "error"),
               "refuses to band")
})

test_that("G5.3: returned verdicts carry no NA", {
  # A verdict of NA would be a fourth, undocumented class. Every rule either
  # decides or says "uninformative".
  pairs <- expand.grid(a = c("SMITH", "", NA, "O'BRIEN"),
                       b = c("SMITH", "", NA, "SMYTHE"),
                       stringsAsFactors = FALSE)
  expect_false(any(is.na(surname_agreement(pairs$a, pairs$b))))
  expect_false(any(is.na(gender_agreement(c("F", NA, "x"), c("M", "F", NA)))))
  expect_false(any(is.na(suffix_agreement(c("JR", NA, ""), c("SR", "JR", NA)))))
  expect_false(any(is.na(graduation_year_agreement(c(2015, NA, 2015),
                                                   c(2015, 2015, NaN)))))
})
