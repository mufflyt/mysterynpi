# Every row of the golden corpus is its own test case, and the expected
# verdict must reproduce EXACTLY -- no aggregate score, no tolerance. Pattern
# from datamade/probablepeople (MIT), tests/test_tagging.py, whose comment
# carries the contract this file adopts: every newly discovered hard case is
# appended to the corpus in the same PR that fixes it.

read_golden <- function() {
  read.csv(testthat::test_path("fixtures", "golden", "verdicts.csv"),
           comment.char = "#", colClasses = "character")
}

dispatch <- function(row) {
  switch(row$rule,
    middle   = middle_agreement(middle_tokens(row$a), middle_tokens(row$b)),
    gender   = gender_agreement(row$a, row$b),
    nickname = nickname_agreement(row$a, row$b),
    suffix   = suffix_agreement(row$a, row$b),
    license  = license_agreement(row$a, row$state_a, row$b, row$state_b),
    surname  = surname_agreement(row$a, row$b),
    stop("golden corpus names an unknown rule: ", row$rule))
}

test_that("every golden row reproduces its adjudicated verdict exactly", {
  g <- read_golden()
  expect_gt(nrow(g), 50)
  for (i in seq_len(nrow(g))) {
    row <- as.list(g[i, ])
    expect_identical(
      dispatch(row), row$expected,
      label = sprintf("%s(%s | %s): %s", row$rule, row$a, row$b, row$note))
  }
})

test_that("the corpus covers every three-verdict rule and every verdict", {
  g <- read_golden()
  expect_setequal(unique(g$rule),
                  c("middle", "gender", "nickname", "suffix", "license",
                    "surname"))
  expect_setequal(unique(g$expected),
                  c("corroborates", "conflicts", "uninformative"))
  # each rule must exercise absence -- the verdict that is easiest to lose
  for (r in unique(g$rule)) {
    expect_true("uninformative" %in% g$expected[g$rule == r],
                label = sprintf("rule %s pins an absence case", r))
  }
})
