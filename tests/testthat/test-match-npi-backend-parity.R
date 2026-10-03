parity_roster <- function() {
  data.frame(
    record = c("exact", "nick", "fuzzy", "tie", "claim_a", "claim_b", "blank", "none",
               "initial", "variant"),
    first = c("Jane", "Bob", "Xlice", "Mary", "Carol", "Carol", NA, "Zelda",
              "R.", "Anne"),
    middle = c(NA, NA, NA, NA, "Ann", "Ann", NA, NA, NA, NA),
    last = c("Doe", "Smith", "Smith", "Jones", "White", "White", "Lee", "Zzyzx",
             "Brown", "Nelson Becker"),
    state = c("CO", "CO", "RI", "RI", "CO", "RI", "CO", "RI", "CO", "RI"))
}

parity_reference <- function() {
  data.frame(
    provider = c("1234567893", "1245319599", "1004000000", "1012000000", "1020000000",
                 "1038000000", "1046000000", "1053000000", "1234567890", "1234567893"),
    type = c("1", "1", "1", "1", "1", "1", "1", "1", "1", "2"),
    first = c("Jane", "Robert", "Alice", "Mary", "Mary", "Carol", "Robert", "Anne", "Jane",
              "Jane"),
    middle = c(NA, NA, NA, NA, NA, "Ann", NA, NA, NA, NA),
    last = c("Doe", "Smith", "Smith", "Jones", "Jones", "White", "Brown", "Nelson-Becker",
             "Doe", "Doe"))
}

parity_args <- function() {
  list(id = "record", given = "first", middle = "middle", surname = "last",
       npi = "provider", entity_type = "type", nppes_given = "first",
       nppes_middle = "middle", nppes_surname = "last")
}

parity_connection <- function(reference, table = "reference") {
  testthat::skip_if_not_installed("duckdb")
  path <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), path)
  DBI::dbWriteTable(con, table, reference)
  DBI::dbDisconnect(con, shutdown = TRUE)
  con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
  withr::defer({
    DBI::dbDisconnect(con, shutdown = TRUE)
    unlink(path)
  }, envir = parent.frame())
  con
}

parity_inventory <- function(con) {
  DBI::dbGetQuery(con, paste(
    "SELECT database_name, schema_name, table_name FROM duckdb_tables()",
    "WHERE NOT temporary ORDER BY ALL"))
}

test_that("both backends return identical partitions, evidence, counts, and rationale", {
  roster <- parity_roster()
  reference <- parity_reference()
  memory <- do.call(match_npi, c(list(roster, reference), parity_args()))
  con <- parity_connection(reference)
  before <- parity_inventory(con)
  duck <- do.call(match_npi, c(list(roster, con, table = "reference"), parity_args()))
  expect_identical(parity_inventory(con), before)
  expect_identical(roster, parity_roster())
  expect_identical(reference, parity_reference())

  for (part in c("matches", "review", "unmatched", "candidates", "counts")) {
    expect_identical(duck[[part]], memory[[part]], info = part)
  }
  expect_identical(memory$run_manifest$backend, "data.frame")
  expect_identical(duck$run_manifest$backend, "duckdb")
  expect_null(memory$run_manifest$table)
  expect_identical(duck$run_manifest$table, "reference")
  shared <- setdiff(names(memory$run_manifest), c("backend", "table"))
  expect_identical(duck$run_manifest[shared], memory$run_manifest[shared])
  for (result in list(memory, duck)) {
    expect_identical(result$run_manifest$execution_status, "complete")
    expect_identical(result$run_manifest$roster_rows, 10L)
    expect_identical(result$run_manifest$reference_rows, 10L)
    expect_identical(result$run_manifest$reference_rows_filtered, 9L)
    expect_identical(result$run_manifest$reference_excluded_invalid_npi, 1L)
    expect_identical(result$run_manifest$reference_rows_usable, 8L)
    expect_identical(result$run_manifest$package_version,
                     as.character(utils::packageVersion("mysterynpi")))
    expect_identical(result$run_manifest$nickname_policy, NICKNAME_POLICY$policy_id)
    expect_type(result$matches$npi, "character")
    expect_type(result$candidates$npi, "character")
  }
})

test_that("the shared fixture exercises every disposition with a stable reason", {
  roster <- parity_roster()
  result <- do.call(match_npi, c(list(roster, parity_reference()), parity_args()))
  reasons <- stats::setNames(c(result$matches$reason, result$review$reason,
                               result$unmatched$reason),
                             c(result$matches$record, result$review$record,
                               result$unmatched$record))
  expect_identical(reasons[roster$record], c(
    exact = "unique_best_evidence", nick = "nickname_only_evidence",
    fuzzy = "fuzzy_only_evidence", tie = "ambiguous_tied_evidence",
    claim_a = "ambiguous_contested_candidate", claim_b = "ambiguous_contested_candidate",
    blank = "missing_required_name", none = "no_candidate",
    initial = "unique_best_evidence", variant = "unique_best_evidence"))
  expect_identical(result$matches$record, c("exact", "initial", "variant"))
  expect_identical(result$matches$npi, c("1234567893", "1046000000", "1053000000"))
  # Review rows carry no NPI; the candidates component keeps the identities.
  expect_true(all(is.na(result$review$npi)))
  expect_setequal(result$candidates$npi[result$candidates$source_id == "tie"],
                  c("1012000000", "1020000000"))
  expect_identical(result$candidates$block_routes[result$candidates$source_id == "nick"],
                   "nickname_surname")
})

test_that("match_npi guards table usage and the empty filtered universe per backend", {
  roster <- parity_roster()
  reference <- parity_reference()
  args <- parity_args()
  expect_error(do.call(match_npi, c(list(roster, reference, table = "reference"), args)),
               "table")
  con <- parity_connection(reference)
  expect_error(do.call(match_npi, c(list(roster, con), args)), "table")
  expect_error(do.call(match_npi, c(list(roster, con, table = "reference",
                                         entity_filter = "9"), args)), "entity")
  expect_error(do.call(match_npi, c(list(roster, con, table = "missing"), args)),
               "exist")
  expect_error(do.call(match_npi, c(list(roster, con, table = "reference",
                                         backend = "data.frame"), args)), "data.frame")
  empty <- do.call(match_npi, c(list(roster[FALSE, ], con, table = "reference"), args))
  expect_identical(empty$counts$roster_rows, 0L)
  expect_identical(empty$run_manifest$execution_status, "complete")
})
