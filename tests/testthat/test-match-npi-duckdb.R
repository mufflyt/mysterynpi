duck_columns <- function() {
  list(id = "record", given = "first", middle = "middle", surname = "last",
       npi = "provider", entity_type = "type", nppes_given = "first",
       nppes_middle = "middle", nppes_surname = "last")
}

duck_roster <- function(first = "Jane", last = "Doe", middle = NA_character_) {
  data.frame(record = paste0("r", seq_along(first)), first, middle, last)
}

duck_reference <- function(first = "Jane", last = "Doe", middle = NA_character_,
                           provider = "1234567893", type = "1") {
  data.frame(provider, type, first, middle, last)
}

duck_fixture <- function(reference, table = "reference", schema = NULL) {
  testthat::skip_if_not_installed("duckdb")
  path <- tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), path)
  if (!is.null(schema)) {
    DBI::dbExecute(con, paste("CREATE SCHEMA", DBI::dbQuoteIdentifier(con, schema)))
  }
  DBI::dbWriteTable(con, table, reference)
  DBI::dbDisconnect(con, shutdown = TRUE)
  con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
  withr::defer({
    DBI::dbDisconnect(con, shutdown = TRUE)
    unlink(path)
  }, envir = parent.frame())
  con
}

duck_inventory <- function(con) {
  DBI::dbGetQuery(con, paste(
    "SELECT database_name, schema_name, table_name FROM duckdb_tables()",
    "WHERE NOT temporary ORDER BY ALL"))
}

duck_sort_pairs <- function(pairs) {
  pairs <- pairs[do.call(order, c(unname(pairs), list(na.last = TRUE))), , drop = FALSE]
  rownames(pairs) <- NULL
  pairs
}

duck_expect_parity <- function(roster, reference, columns = duck_columns(), type = "1") {
  con <- duck_fixture(reference)
  before <- duck_inventory(con)
  actual <- generate_npi_candidates_duckdb(con, "reference", roster, columns, type)
  expected <- generate_npi_candidates_memory(roster, reference, columns, type)
  expect_named(actual, c("pairs", "reference_counts"))
  expect_identical(duck_sort_pairs(actual$pairs), duck_sort_pairs(expected$pairs))
  expect_identical(actual$reference_counts, expected$reference_counts)
  expect_identical(duck_inventory(con), before)
  expect_equal(DBI::dbGetQuery(con,
    "SELECT count(*) AS n FROM duckdb_tables() WHERE temporary")$n, 0)
  expect_equal(DBI::dbGetQuery(con, paste(
    "SELECT count(*) AS n FROM duckdb_functions()",
    "WHERE function_type = 'macro' AND function_name LIKE 'mysterynpi_%'"))$n, 0)
  actual
}

test_that("DuckDB read-only candidates preserve all seven routes and repeated profiles", {
  roster <- duck_roster(
    c("Jane", "Mary", "Robert James", "Bob", "Alice", "David", "Jane", "Zelda", NA,
      "J.", "Anne", "Sean", "Anne", "Xlice", "David"),
    c("Doe", "Barlow Reed", "Jones", "Muffly", "Smith", "Clark", "Doe", "Zzyzx", "Doe",
      "Doe", "Nelson", "O'Connor", "Abu Ghazaleh", "Smith", "Clrak"))
  reference <- duck_reference(
    c("Jane", "Mary", "James Robert", "Robert", "Alyce", "David", "Jane",
      "Anne", "Sean", "Anne", "Alice", "Janet"),
    c("Doe", "Barlow-Reed", "Jones", "Muffly", "Smith", "Clarke", "Doe",
      "Nelson-Becker", "Oconnor", "Abughazaleh", "Smith", "Doe"))
  result <- duck_expect_parity(roster, reference)
  expect_length(unique(result$pairs$block_route), 7L)
  expect_equal(sum(result$pairs$source_id == "r1" &
                     result$pairs$block_route == "exact_given_surname"), 2)
})

test_that("DuckDB excludes invalid NPIs and missing names sequentially within entity type", {
  reference <- duck_reference(
    first = c("Jane", "Jane", "Jane", "", "Jane", "Jane", "Jane", "Jane"),
    last = c("Doe", "Doe", "Doe", "Doe", NA, "Doe", "Doe", "Doe"),
    provider = c("1234567893", "1245319599", "1234567890", "1234567893",
                 "1234567893", "1234567893", NA, "1234567893; DROP TABLE reference"),
    type = c("1", "2", "1", "1", "1", NA, "1", "1"))
  result <- duck_expect_parity(duck_roster(), reference)
  expect_identical(result$reference_counts,
                   c(input = 8L, entity_type = 6L, invalid_npi = 3L,
                     missing_required_name = 2L, usable = 1L))
  type2 <- duck_expect_parity(duck_roster(), reference, type = "2")
  expect_identical(unique(type2$pairs$npi), "1245319599")
})

test_that("DuckDB name normalization matches accents parentheses particles and token order", {
  reference <- duck_reference(
    c("José", "Jörg", "C(arolyn)", "Cynthia (Cindi)", "Renée", "Sean", "Mary Anne",
      "A.", "Jane", "Jane", "Łukasz", "François", "Zoe\u0308"),
    c("García", "Müller", "de la Cruz", "O’Connor", "Dùpont", "O`Brien", "van van Erven",
      "Li", "X", "---", "Żółć", "Dœ", "Åström"),
    middle = c(rep(NA, 6), "Jane", rep(NA, 6)))
  roster <- duck_roster(
    c("Jose", "Joerg", "Carolyn", "Cynthia", "Renee", "Sean", "Jane", "A", "Jane",
      "Jane", "Lukasz", "Francois", "Zoe"),
    c("Garcia", "Mueller", "Cruz", "Oconnor", "Dupont", "Obrien", "van Erven",
      "Li", "X", "---", "Zolc", "Doe", "Aastroem"))
  duck_expect_parity(roster, reference)
})

test_that("DuckDB never truncates matching blocks and produces typed empty results", {
  result <- duck_expect_parity(duck_roster(), duck_reference(rep("Jane", 240)))
  expect_equal(sum(result$pairs$block_route == "exact_given_surname"), 240)
  for (roster in list(duck_roster("Zelda", "Zzyzx"), duck_roster()[FALSE, ],
                     duck_roster(NA_character_))) {
    result <- duck_expect_parity(roster, duck_reference())
    expect_equal(nrow(result$pairs), 0L)
    expect_true(all(vapply(result$pairs, is.character, logical(1))))
  }
  duck_expect_parity(duck_roster(), duck_reference(provider = "invalid"))
})

test_that("DuckDB reference joins remain selective in the shared scaling fixture", {
  codes <- apply(expand.grid(LETTERS, LETTERS, LETTERS), 1, function(x) {
    paste0(rep(x, each = 2L), collapse = "")
  })
  reference <- duck_reference(rep("Jane", 2000), paste0("FAMILY", codes[1:2000]))
  result <- duck_expect_parity(duck_roster(rep("Jane", 100), reference$last[1:100]),
                               reference)
  expect_equal(nrow(result$pairs), 400L)
})

test_that("DuckDB supports missing middle mappings and shared-formal nicknames", {
  columns <- duck_columns()
  columns[c("middle", "nppes_middle")] <- NULL
  duck_expect_parity(duck_roster(c("Bob", "Bobby", "Rob", "Robert"), rep("Smith", 4)),
                     duck_reference(c("Bob", "Bobby", "Rob", "Robert"), rep("Smith", 4)),
                     columns)
})

test_that("DuckDB validates identifiers filters mappings and connections without writes", {
  con <- duck_fixture(duck_reference())
  before <- duck_inventory(con)
  expect_error(generate_npi_candidates_duckdb(con, "missing", duck_roster(), duck_columns()),
               "table.*exist|missing.*table")
  columns <- duck_columns()
  columns$nppes_given <- "absent"
  expect_error(generate_npi_candidates_duckdb(con, "reference", duck_roster(), columns),
               "missing mapped column")
  expect_error(generate_npi_candidates_duckdb(con, "reference", duck_roster(),
                                             duck_columns(), "2"), "entity filtering")
  expect_error(generate_npi_candidates_duckdb(con, "reference", duck_roster(),
                                             duck_columns(), "1' OR TRUE --"), "entity filtering")
  expect_error(generate_npi_candidates_duckdb(NULL, "reference", duck_roster(),
                                             duck_columns()), "DuckDB")
  expect_identical(duck_inventory(con), before)
  expect_equal(DBI::dbGetQuery(con,
    "SELECT count(*) AS n FROM duckdb_tables() WHERE temporary")$n, 0)
  expect_equal(DBI::dbGetQuery(con, paste(
    "SELECT count(*) AS n FROM duckdb_functions()",
    "WHERE function_type = 'macro' AND function_name LIKE 'mysterynpi_%'"))$n, 0)
  expect_error(generate_npi_candidates_duckdb(con, DBI::SQL("reference"), duck_roster(),
                                             duck_columns()), "raw identifiers")
  columns <- duck_columns()
  columns$nppes_given <- DBI::SQL("first")
  expect_error(generate_npi_candidates_duckdb(con, "reference", duck_roster(), columns),
               "raw.*column|column.*raw")
})

test_that("DuckDB rejects a real unsupported SQLite connection", {
  skip_if_not_installed("RSQLite")
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(DBI::dbDisconnect(con))
  expect_error(generate_npi_candidates_duckdb(con, "reference", duck_roster(),
                                             duck_columns()), "DuckDB")
})

test_that("DuckDB quotes schema table and column identifiers containing SQL punctuation", {
  reference <- duck_reference()
  original <- reference
  names(reference) <- paste0(names(reference), "\"; odd ' --")
  columns <- duck_columns()
  fields <- c("npi", "entity_type", "nppes_given", "nppes_middle", "nppes_surname")
  columns[fields] <- lapply(columns[fields], paste0, "\"; odd ' --")
  table <- DBI::Id(schema = "odd\"schema", table = "reference\"; DROP TABLE x --")
  con <- duck_fixture(reference, table, "odd\"schema")
  before <- duck_inventory(con)
  result <- generate_npi_candidates_duckdb(con, table, duck_roster(), columns)
  expected <- generate_npi_candidates_memory(duck_roster(), original, duck_columns())
  expect_identical(duck_sort_pairs(result$pairs), duck_sort_pairs(expected$pairs))
  expect_identical(duck_inventory(con), before)
})

test_that("DuckDB accepts parsed roster names and rejects unparsed reference full names", {
  skip_if_not_installed("humaniformat")
  columns <- duck_columns()
  columns[c("given", "middle", "surname")] <- NULL
  columns$full_name <- "name"
  duck_expect_parity(data.frame(record = "r1", name = "Jane Doe"),
                     duck_reference(), columns)
  columns[c("nppes_given", "nppes_middle", "nppes_surname")] <- NULL
  columns$nppes_full_name <- "name"
  con <- duck_fixture(data.frame(provider = "1234567893", type = "1", name = "Jane Doe"))
  expect_error(generate_npi_candidates_duckdb(con, "reference",
    data.frame(record = "r1", name = "Jane Doe"), columns),
    "structured.*reference|reference.*structured")
})
