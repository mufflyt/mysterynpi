# parse_person() stands on humaniformat, and humaniformat is dormant
# (Ironholds/humaniformat, last pushed 2022) -- upstream will not announce a
# behaviour change, so this file does. It pins the RAW parse_names() outputs
# the wrapper depends on, including the comma behaviour parse_person() works
# around: if upstream ever starts reversing "Last, First" itself, the
# workaround would double-apply, and the "Williams," row here is the tripwire.

test_that("the humaniformat boundary has not moved", {
  skip_if_not_installed("humaniformat")
  fix <- read.csv(testthat::test_path("fixtures", "humaniformat_boundary.csv"),
                  comment.char = "#", colClasses = "character")
  got <- humaniformat::parse_names(fix$full_name)
  blank <- function(v) { v[is.na(v)] <- ""; v }
  for (col in c("first_name", "middle_name", "last_name")) {
    expect_identical(blank(got[[col]]), fix[[col]],
                     label = sprintf("parse_names()$%s", col))
  }
})

# The loudness rule (pattern from derek73/python-nameparser's ja-extra job): a
# suggested package whose absence silently skips the boundary test would leave
# the boundary unguarded on the day it matters. In every environment this
# package's own CI controls, humaniformat must be PRESENT, so the skip above
# can only ever fire on a user's machine, never silently in CI.
test_that("CI cannot green-skip the vendor boundary", {
  if (!nzchar(Sys.getenv("CI"))) skip("loudness check is for CI environments")
  expect_true(requireNamespace("humaniformat", quietly = TRUE),
              label = "humaniformat installed in CI")
})
