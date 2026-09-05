# The parser is tested against a stored SYNTHETIC fixture; no test here ever
# touches the network. npi_search() itself is a thin fetch over this parser
# and is exercised only for its argument validation.

read_fixture <- function() {
  paste(readLines(testthat::test_path("fixtures", "npi_api_response.json"),
                  warn = FALSE), collapse = "\n")
}

test_that("a full record parses into the columns a linkage wants", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(nrow(got), 2L)
  r <- got[1, ]
  expect_identical(r$npi, "1234567893")
  expect_identical(r$first, "JANE")
  expect_identical(r$middle, "QUINN")
  expect_identical(r$last, "EXAMPLESON")
  expect_identical(r$honorific, "DR.")
  expect_identical(r$credential, "M.D.")
  expect_identical(r$gender, "F")
  expect_identical(r$gender_code, "F")
  # LOCATION address wins over MAILING, and zip5 is derived from zip9
  expect_identical(r$zip, "80204")
  expect_identical(r$zip_full, "802044597")
  expect_identical(r$state, "CO")
  expect_identical(r$enumeration_date, "2006-07-01")
  expect_identical(r$years_enumerated, 20L)
  expect_identical(r$last_updated, "2025-01-14")
  expect_identical(r$retrieved, "2026-09-05")
})

test_that("NPPES absence -- missing key, empty, or the '--' sentinel -- is NA", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(got$suffix[1], NA_character_)      # "--" sentinel
  expect_identical(got$middle[2], NA_character_)      # key absent entirely
  expect_identical(got$honorific[2], NA_character_)
  # the sentinel must be uninformative downstream, never a fake veto
  expect_identical(suffix_agreement(got$suffix[1], "JR"), "uninformative")
})

test_that("an unmappable sex code carries its raw value but normalises to NA", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(got$gender_code[2], "X")
  expect_identical(got$gender[2], NA_character_)
  expect_identical(gender_agreement(got$gender[2], "F"), "uninformative")
})

test_that("a record without a LOCATION address falls back to what exists", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(got$zip[2], "80011")
  expect_identical(got$zip_full[2], "80011")
})

test_that("an empty result set is zero rows with every column present", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search('{"result_count":0, "results":[]}',
                          retrieved = as.Date("2026-09-05"))
  expect_identical(nrow(got), 0L)
  expect_true(all(c("npi", "first", "middle", "last", "suffix", "honorific",
                    "credential", "gender", "gender_code", "zip", "zip_full",
                    "state", "enumeration_date", "years_enumerated",
                    "last_updated", "retrieved") %in% names(got)))
})

test_that("an API error surfaces as an error, never as an empty success", {
  skip_if_not_installed("jsonlite")
  expect_error(
    parse_npi_search(
      '{"Errors":[{"description":"limit must be <= 200","field":"limit"}]}',
      retrieved = as.Date("2026-09-05")),
    "limit must be")
})

test_that("the parse is reproducible because retrieved is explicit", {
  skip_if_not_installed("jsonlite")
  a <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  b <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(a, b)
  later <- parse_npi_search(read_fixture(), retrieved = as.Date("2027-09-05"))
  expect_identical(later$years_enumerated[1], 21L)
  expect_error(parse_npi_search(read_fixture(), retrieved = c(Sys.Date(),
                                                              Sys.Date())),
               "single date")
})

test_that("npi_search refuses bad arguments before touching the network", {
  expect_error(npi_search(), "at least one search criterion")
  expect_error(npi_search(last_name = "SMITH", limit = 0), "between 1 and 200")
  expect_error(npi_search(last_name = "SMITH", limit = 500), "between 1 and 200")
})
