# srr: the result class, the reference comparison, and behaviour as the data
# changes. The standards each test serves are named in its description.

mk_inputs <- function() {
  list(roster = data.frame(id = c("r1", "r2"),
                           given = c("MARY", "ZZZZZ"),
                           surname = c("JOHNSON", "QQQQQ"),
                           stringsAsFactors = FALSE),
       ref = data.frame(npi = "1234567893", entity_type = "1",
                        given = "MARY", middle = NA_character_,
                        surname = "JOHNSON", stringsAsFactors = FALSE))
}
run_match <- function() {
  i <- mk_inputs()
  match_npi(roster = i$roster, nppes = i$ref, id = "id", given = "given",
            surname = "surname", npi = "npi", entity_type = "entity_type",
            nppes_given = "given", nppes_middle = "middle",
            nppes_surname = "surname")
}

test_that("EA4.2: the result has a class and prints as a summary, not a dump", {
  res <- run_match()
  expect_s3_class(res, "npi_match_result")
  # Still a list with the same names: every existing caller keeps working.
  expect_true(all(c("matches", "review", "unmatched", "counts") %in% names(res)))
  expect_s3_class(res$matches, "data.frame")
  out <- capture.output(print(res))
  expect_true(any(grepl("npi_match_result", out)))
  expect_true(any(grepl("matched", out)))
  # The printed form is six lines, not one line per matched row.
  expect_lt(length(out), 10L)
})

test_that("EA4.1, EA5.2: printed proportions honour an explicit precision", {
  res <- run_match()
  expect_match(paste(format(res, digits = 3), collapse = " "), "%")
  s1 <- summary(res, digits = 1)
  s3 <- summary(res, digits = 3)
  v1 <- s1$statistics$value[s1$statistics$statistic == "matched_share"]
  v3 <- s3$statistics$value[s3$statistics$statistic == "matched_share"]
  expect_equal(v1, round(v3, 1))
  expect_error(summary(res, digits = c(1, 2)), "single value")
})

test_that("EA3.0, EA5.3: summary reports named statistics and column storage", {
  s <- summary(run_match())
  expect_s3_class(s, "summary.npi_match_result")
  expect_true(all(c("roster_rows", "matched", "matched_share") %in%
                    s$statistics$statistic))
  # Every rate states its denominator rather than implying it.
  expect_equal(s$statistics$denominator[s$statistics$statistic == "matched_share"],
               "roster_rows")
  expect_true(all(c("column", "class", "storage_mode", "n_missing") %in%
                    names(s$columns)))
  expect_true(all(s$columns$storage_mode %in%
                    c("character", "integer", "double", "logical", "list")))
  expect_output(print(s), "storage_mode")
})

test_that("RE4.5: nobs() reports the rows submitted", {
  res <- run_match()
  expect_equal(nobs(res), 2L)
  expect_equal(nobs(res), nrow(mk_inputs()$roster))
})

test_that("EA3.1, RE4.11: the benchmark comparison reproduces its claims", {
  b <- benchmark_comparison()
  expect_true(attr(b, "all_pass"))
  expect_true(all(b$properties$pass))
  expect_equal(sum(b$properties$violations), 0L)
  # Precision among accepts is the goodness-of-decision statistic RE4.11 asks
  # for, and on this corpus it is exactly 1.
  expect_equal(b$rates$value[b$rates$statistic == "precision_among_accepts"], 1)
  expect_equal(b$rates$value[b$rates$statistic == "pairs"],
               nrow(ROSTER_BENCHMARK))
  expect_error(benchmark_comparison(data.frame(a = 1)), "truth column")
})

test_that("G5.7: the claims hold as the corpus is restricted by family", {
  # Behaviour as properties of the data change: each defect family on its own
  # must satisfy the same three properties the whole corpus does. A rule that
  # only works when the families are mixed is a rule that works by accident.
  fams <- unique(ROSTER_BENCHMARK$family)
  expect_gt(length(fams), 3L)
  for (f in fams) {
    sub <- ROSTER_BENCHMARK[ROSTER_BENCHMARK$family == f, , drop = FALSE]
    b <- benchmark_comparison(sub)
    expect_true(attr(b, "all_pass"),
                info = paste("family", f, "violates a benchmark property"))
  }
})

test_that("G5.9: trivial noise does not change a verdict; seeds control draws", {
  # Noise susceptibility, in the form this domain has: whitespace, case and
  # punctuation are noise, and the keys exist to absorb them.
  expect_equal(surname_agreement("  smith  ", "SMITH"), "corroborates")
  expect_equal(middle_agreement(middle_tokens("a. reinhard"),
                                middle_tokens("A REINHARD")),
               middle_agreement(middle_tokens("A REINHARD"),
                                middle_tokens("A REINHARD")))
  # And the one stochastic routine is reproducible from its seed, different
  # across seeds, and refuses to run without one.
  per <- data.frame(id = sprintf("r%02d", 1:20),
                    candidate = sprintf("c%02d", 1:20),
                    evidence_class = rep(1:2, each = 10),
                    stringsAsFactors = FALSE)
  a <- clerical_sample(per, n_per_class = 3, seed = 1)
  b <- clerical_sample(per, n_per_class = 3, seed = 1)
  c3 <- clerical_sample(per, n_per_class = 3, seed = 2)
  expect_identical(a, b)
  # The draw lives in the blinding key, not at the top level: an earlier
  # version of this test compared a$candidate, which is NULL on both sides,
  # and therefore passed while asserting nothing about the seed.
  expect_true(is.data.frame(a$key) && "candidate" %in% names(a$key))
  expect_false(identical(a$key$candidate, c3$key$candidate))
  expect_error(clerical_sample(per, n_per_class = 3), "seed is required")
})
