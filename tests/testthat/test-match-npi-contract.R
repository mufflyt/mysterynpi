contract_roster <- function() {
  data.frame(record = c("r1", "r2"), first = c("Jane", NA_character_),
             last = c("Doe", "Smith"), state = c("CO", "RI"))
}

contract_nppes <- function() {
  data.frame(provider = c("1234567893", "1245319599"), type = c("1", "2"),
             first = c("Jane", "Jane"), last = c("Doe", "Doe"))
}

contract_match <- function(roster = contract_roster(), nppes = contract_nppes(), ...) {
  args <- list(roster = roster, nppes = nppes, id = "record", given = "first",
               surname = "last", npi = "provider", entity_type = "type",
               nppes_given = "first", nppes_surname = "last")
  do.call(match_npi, utils::modifyList(args, list(...), keep.null = TRUE))
}

test_that("match_npi keeps every source row in explicit result partitions", {
  roster <- contract_roster()
  reference <- contract_nppes()
  result <- contract_match(roster, reference)
  expect_named(result, c("matches", "review", "unmatched", "candidates", "counts",
                         "run_manifest"))
  expect_s3_class(result$matches, "data.frame")
  expect_s3_class(result$review, "data.frame")
  expect_s3_class(result$candidates, "data.frame")
  expect_equal(nrow(result$matches), 0L)
  expect_equal(nrow(result$review), 0L)
  expect_equal(nrow(result$candidates), 0L)
  expect_identical(result$unmatched$record, c("r1", "r2"))
  expect_identical(result$unmatched$state, c("CO", "RI"))
  expect_identical(result$unmatched$reason[2], "missing_required_name")
  expect_type(result$matches$npi, "character")
  expect_type(result$candidates$npi, "character")
  expect_identical(roster, contract_roster())
  expect_identical(reference, contract_nppes())
})

test_that("match_npi validates mapped columns and source IDs", {
  expect_error(contract_match(contract_roster()[, -2]), "first")
  expect_error(contract_match(nppes = contract_nppes()[, -1]), "provider")
  for (ids in list(c("r1", "r1"), c("r1", " "), c("r1", NA_character_))) {
    roster <- contract_roster()
    roster$record <- ids
    expect_error(contract_match(roster), "ID")
  }
  expect_error(contract_match(given = c("first", "last")), "column")
})

test_that("match_npi defaults to Type 1 and rejects an empty filtered universe", {
  result <- contract_match()
  expect_identical(result$run_manifest$entity_filter, "1")
  expect_equal(result$run_manifest$reference_rows, 2L)
  expect_equal(result$run_manifest$reference_rows_filtered, 1L)
  expect_equal(contract_match(entity_filter = "2")$run_manifest$reference_rows_filtered, 1L)
  expect_error(contract_match(nppes = contract_nppes()[2, ]), "entity")
})

test_that("match_npi accepts empty rosters and full-name mappings", {
  result <- contract_match(roster = contract_roster()[FALSE, ])
  expect_equal(nrow(result$unmatched), 0L)
  expect_equal(result$counts$roster_rows, 0L)
  skip_if_not_installed("humaniformat")
  result <- match_npi(data.frame(record = "r1", name = " "), contract_nppes(),
                      id = "record", full_name = "name", npi = "provider",
                      entity_type = "type", nppes_given = "first", nppes_surname = "last")
  expect_identical(result$unmatched$reason, "missing_required_name")
  roster <- data.frame(record = "r1", name = "Jane Doe")
  run_full_name <- function(roster) {
    match_npi(roster, data.frame(provider = "1234567893", type = "1", name = "Jane Doe"),
              id = "record", full_name = "name", npi = "provider", entity_type = "type",
              nppes_full_name = "name")
  }
  expect_identical(run_full_name(roster)$unmatched$reason, "no_candidates")
  expect_equal(nrow(run_full_name(roster[FALSE, ])$unmatched), 0L)
})

test_that("match_npi rejects incompatible backend inputs and missing name mappings", {
  expect_error(contract_match(backend = "duckdb"), "connection")
  expect_error(contract_match(nppes = list()), "data.frame|connection")
  expect_error(match_npi(contract_roster(), contract_nppes(), id = "record",
                        npi = "provider", entity_type = "type",
                        nppes_given = "first", nppes_surname = "last"), "name")
})

test_that("match_npi preserves source columns that share result metadata names", {
  roster <- contract_roster()
  roster$npi <- c("original1", "original2")
  roster$reason <- c("a", "b")
  roster$source_id <- c("legacy1", "legacy2")
  result <- contract_match(roster)
  expect_identical(result$unmatched[names(roster)], roster)
  expect_identical(result$unmatched[[result$run_manifest$result_columns[["reason"]]]],
                   c("no_candidates", "missing_required_name"))
})
