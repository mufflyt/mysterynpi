# srr testing standards, tagged where they are satisfied
#
# srr asks that standards be documented in the code that satisfies them, and
# that they not all sit in one directory. The testing standards therefore live
# here rather than in R/: each tag names the test file or the test that
# satisfies it.
#
#' @srrstats {G5.0} `WINKLER_CENSUS` is a published reference surname frequency
#'   table and `ROSTER_BENCHMARK` is a fixed 190-pair corpus with truth by
#'   construction; both are used by the tests.
#' @srrstats {G5.1} All four datasets are exported with `LazyData`, so a user
#'   can re-run any assertion in this suite themselves.
#' @srrstats {G5.2} 30 of the test files assert on error, warning or message
#'   text rather than merely on failure.
#' @srrstats {G5.2a} Every `stop()` and `warning()` in the package carries a
#'   message naming the offending argument and what to do instead.
#' @srrstats {G5.2b} test-srr-missing-policy.R and test-srr-input-structures.R
#'   assert the message text of each condition they trigger.
#' @srrstats {G5.3} test-srr-missing-policy.R asserts that no verdict is ever
#'   `NA` across the missing/empty/undefined grid.
#' @srrstats {G5.4} 1,654 expectations against fixed inputs, plus the
#'   `assert_*_contract()` functions a consumer runs in their own suite.
#' @srrstats {G5.5} `clerical_sample()` refuses to run without a seed; the
#'   tests fix seeds explicitly and assert both stability and sensitivity.
#' @srrstats {G5.7} test-srr-result-and-benchmark.R runs the benchmark
#'   properties per defect family, so a rule that holds only on the mixed
#'   corpus fails.
#' @srrstats {G5.8} Edge conditions are the suite's subject: empty strings,
#'   `NA`, punctuation-only tokens, single-character given names, concatenated
#'   initials.
#' @srrstats {G5.8a} Zero-length input is tested on the token and key
#'   functions.
#' @srrstats {G5.8b} Unsupported types are rejected and tested: list columns,
#'   non-tabular input, multi-valued scalars.
#' @srrstats {G5.8c} `NA` and empty-string fields are tested on every
#'   agreement rule.
#' @srrstats {G5.8d} Inputs outside the expected scale are tested: years far
#'   outside any band, and `NaN`/`Inf` through the `undefined` parameter.
#' @srrstats {G5.9} test-srr-result-and-benchmark.R tests trivial-noise
#'   invariance (whitespace, case, punctuation) and seed sensitivity.
#' @srrstats {G5.9a} Trivial noise does not change a verdict.
#' @srrstats {G5.9b} Different seeds produce different clerical draws; the same
#'   seed reproduces one exactly.
#' @srrstats {G5.10} test-srr-extended.R runs under testthat like every other
#'   file but is gated on `MYSTERYNPI_EXTENDED_TESTS`.
#' @srrstats {G5.11} The NPPES extract is fetched, never committed;
#'   `MYSTERYNPI_NPPES_CSV` points at a local copy instead.
#' @srrstats {G5.11a} The download is skipped, with a reason, when the asset is
#'   unavailable or the machine is offline.
#' @srrstats {G5.12} The conditions block at the top of test-srr-extended.R
#'   states flag, platform, memory, runtime, network, asset and artefacts.
#'
#' @srrstats {EA6.0} Return values are tested for class, column names,
#'   dimensions and content.
#' @srrstats {EA6.0a} Classes and types of returned objects are asserted.
#' @srrstats {EA6.0b} Dimensions of returned tabular objects are asserted.
#' @srrstats {EA6.0c} Column names of returned tabular objects are asserted.
#' @srrstats {EA6.0d} Classes and types of returned columns are asserted via
#'   `summary()$columns`.
#' @srrstats {EA6.0e} Every reported statistic is asserted against a known
#'   value on the benchmark corpus.
#'
#' @srrstats {RE7.0} Exact, noiseless relationships are the suite's subject:
#'   identical names must corroborate.
#' @srrstats {RE7.1} The response analogue, the agreement verdict, is asserted
#'   against exact inputs including the three documented defect cases.
#' @srrstats {RE7.2} test-match-npi files assert that roster columns and
#'   identifiers survive onto the output frame.
#'
#' @name srr-stats-testing
#' @keywords internal
NULL

test_that("the srr testing-standard tags name tests that exist", {
  # A tag is a claim. This checks the cheapest half of it: that each file named
  # above is really in the suite, so a renamed or deleted test file cannot
  # leave a tag pointing at nothing.
  here <- function(f) testthat::test_path(f)
  for (f in c("test-srr-missing-policy.R", "test-srr-input-structures.R",
              "test-srr-result-and-benchmark.R", "test-srr-extended.R")) {
    expect_true(file.exists(here(f)), info = f)
  }
  expect_true(file.exists(here("../../R/srr-stats-standards.R")))
})
