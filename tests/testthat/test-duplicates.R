reg <- data.frame(
  npi = c("1", "1", "2", "2", "2", "3", "4", NA, NA),
  name = c("JOHN Q", "JOHNNY Q", "ANA RUIZ", "ANA RUIZ", "ANA M RUIZ",
           "SAM COLE", "LEE PARK", "GHOST A", "GHOST B"),
  suffix = c("JR", NA, NA, NA, NA, NA, NA, NA, NA),
  zip = c("80204", "80204", "80011", "80012", "80011", "80014", "80015",
          "80016", "80017"),
  row_id = as.character(1:9),
  stringsAsFactors = FALSE)

test_that("differing columns are reported with their recorded values", {
  d <- duplicate_differences(reg, key = "npi", ignore = "row_id")
  expect_identical(d$column[d$npi == "1"], c("name", "suffix"))
  expect_identical(d$values[d$npi == "1" & d$column == "name"],
                   "JOHN Q | JOHNNY Q")
  expect_identical(sort(d$column[d$npi == "2"]), c("name", "zip"))
  expect_identical(d$n_rows[d$npi == "2"][1], 3L)
})

test_that("absence-only differences are distinguished from value differences", {
  d <- duplicate_differences(reg, key = "npi", ignore = "row_id")
  sfx <- d[d$npi == "1" & d$column == "suffix", ]
  # (JR, NA) is one person incompletely transcribed, not two people
  expect_true(sfx$absence_only)
  expect_true(sfx$has_absence)
  expect_identical(sfx$values, "JR")
  nm <- d[d$npi == "1" & d$column == "name", ]
  expect_false(nm$absence_only)
})

test_that("identical duplicate rows still appear, never silently vanish", {
  pure <- data.frame(id = c("A", "A"), x = c("1", "1"), y = c("2", "2"),
                     stringsAsFactors = FALSE)
  d <- duplicate_differences(pure, key = "id")
  expect_identical(d$column, "<identical>")
  expect_identical(d$n_rows, 2L)
})

test_that("absent keys group nothing, and unique keys report nothing", {
  d <- duplicate_differences(reg, key = "npi", ignore = "row_id")
  expect_false(any(is.na(d$npi)))
  expect_false(any(d$npi %in% c("3", "4")))
  none <- duplicate_differences(reg[6:7, ], key = "npi")
  expect_identical(nrow(none), 0L)
  expect_true(all(c("npi", "column", "values", "absence_only") %in%
                    names(none)))
})

test_that("composite keys work, and missing columns are named", {
  lic <- data.frame(state = c("CO", "CO", "TX"),
                    license = c("123", "123", "123"),
                    name = c("A B", "A C", "D E"),
                    stringsAsFactors = FALSE)
  d <- duplicate_differences(lic, key = c("state", "license"))
  expect_identical(nrow(d), 1L)
  expect_identical(d$state, "CO")
  expect_identical(d$values, "A B | A C")
  expect_error(duplicate_differences(lic, key = "npi"), "missing: npi")
})

test_that("it reads the Winkler household duplicates", {
  d <- duplicate_differences(WINKLER_CENSUS, key = c("relation", "id"))
  expect_gt(nrow(d), 0)
  expect_true(all(d$column %in%
                    c("surname", "given", "middle", "house", "street",
                      "<identical>")))
})
