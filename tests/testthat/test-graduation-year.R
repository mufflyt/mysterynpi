test_that("absence on either side is uninformative, never disagreement", {
  expect_identical(graduation_year_agreement(2015, NA), "uninformative")
  expect_identical(graduation_year_agreement(NA, 2015), "uninformative")
  expect_identical(graduation_year_agreement(NA, NA), "uninformative")
  expect_identical(graduation_year_agreement(2015, ""), "uninformative")
  expect_identical(graduation_year_band(2015, NA), "unknown")
})

test_that("the sign asymmetry survives: one year BEFORE outranks one year after", {
  before <- GRADUATION_YEAR_BANDS$log2_lr[GRADUATION_YEAR_BANDS$band == "one_before"]
  after  <- GRADUATION_YEAR_BANDS$log2_lr[GRADUATION_YEAR_BANDS$band == "one_after"]
  expect_gt(before, after)
  # Both still corroborate; it is the WEIGHT that differs, not the verdict.
  expect_identical(graduation_year_agreement(2015, 2014), "corroborates")
  expect_identical(graduation_year_agreement(2015, 2016), "corroborates")
  expect_identical(graduation_year_band(2015, 2014), "one_before")
  expect_identical(graduation_year_band(2015, 2016), "one_after")
})

test_that("a two- to three-year gap is NEGATIVE evidence, on both sides", {
  mid <- GRADUATION_YEAR_BANDS[GRADUATION_YEAR_BANDS$band %in%
                                 c("two_three_before", "two_three_after"), ]
  expect_true(all(mid$log2_lr < 0))
  # It must not reach a verdict in either direction.
  expect_identical(graduation_year_agreement(2015, 2017), "uninformative")
  expect_identical(graduation_year_agreement(2015, 2012), "uninformative")
})

test_that("conflicts fires only beyond ten years, in both directions", {
  expect_identical(graduation_year_agreement(2015, 2005), "uninformative")
  expect_identical(graduation_year_agreement(2015, 2025), "uninformative")
  expect_identical(graduation_year_agreement(2015, 2004), "conflicts")
  expect_identical(graduation_year_agreement(2015, 2026), "conflicts")
  inside <- vapply(-10:10, function(d) graduation_year_agreement(2015, 2015 + d), character(1))
  expect_false(any(inside == "conflicts"))
})

test_that("the band table is contiguous and covers the line", {
  b <- GRADUATION_YEAR_BANDS
  expect_true(all(b$lo <= b$hi))
  expect_identical(anyDuplicated(b$band), 0L)
  covered <- vapply(-60:60, function(d) graduation_year_band(2000, 2000 + d), character(1))
  expect_false(any(covered == "unknown"))
  expect_true(all(covered %in% b$band))
  expect_true(all(b$verdict %in% c("corroborates", "conflicts", "uninformative")))
})

test_that("it vectorises and recycles like the other agreement rules", {
  expect_identical(
    graduation_year_agreement(c(2015, 2015, 2015), c(2015, 2017, 1990)),
    c("corroborates", "uninformative", "conflicts"))
  expect_identical(graduation_year_agreement(2015, c(2015, 2014)),
                   c("corroborates", "corroborates"))
  expect_length(graduation_year_agreement(integer(0), integer(0)), 0L)
})

test_that("a caller may supply its own calibration, as with NICKNAME_EDGES", {
  strict <- GRADUATION_YEAR_BANDS
  strict$verdict[strict$band == "one_after"] <- "uninformative"
  expect_identical(graduation_year_agreement(2015, 2016, bands = strict), "uninformative")
  expect_identical(graduation_year_agreement(2015, 2016), "corroborates")
})
