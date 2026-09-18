# =============================================================================
# sql_npi_name(): the SQL-side name key must match normalize_string() exactly,
# or the database half of a pipeline silently disagrees with the R half about
# who matched whom.
# =============================================================================

test_that("sql_npi_name() emits the documented SQL expression", {
  expect_identical(
    sql_npi_name("last_name"),
    paste0(
      "strip_accents(UPPER(TRIM(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(",
      "REPLACE(REPLACE(last_name, 'ß', 'ss'), 'ü', 'ue'), ",
      "'Ü', 'ue'), 'ö', 'oe'), 'Ö', 'oe'), 'ä', 'ae'), ",
      "'Ä', 'ae'))))"))
})

test_that("sql_npi_name() rejects bad inputs", {
  expect_error(sql_npi_name(""), "non-empty")
  expect_error(sql_npi_name(NA_character_), "non-empty")
  expect_error(sql_npi_name(c("a", "b")), "non-empty")
  expect_error(sql_npi_name(NULL), "non-empty")
})

test_that("sql_npi_name() and normalize_string() agree, including German digraphs", {
  # THE DEFECT: sql_npi_name() used to be strip_accents(UPPER(TRIM(x))) alone.
  # strip_accents() only drops a diacritic ("Muller"), it does not know that a
  # German umlaut romanises as a digraph, not a bare vowel
  # (normalize_string("Müller") == "MUELLER"). Confirmed against a live DuckDB
  # connection before the fix: sql_npi_name() emitted "MULLER" for "Müller"
  # and "SCHON" for "Schön" while normalize_string() gave "MUELLER" and
  # "SCHOEN" -- a silent R/SQL parity break caught downstream by
  # isochrones' test-sql-npi-name-helper.R, which this test mirrors.
  skip_if_not_installed("duckdb")
  skip_if_not_installed("DBI")

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

  inputs <- c(
    "García", "Martínez", "Hernández", "Muñoz",
    "Jaén", "Garcça", "Lefèvre", "Benoît",
    "Müller", "Schön", "De Lúca", "Smith", "O'Brien")

  df <- data.frame(rowid = seq_along(inputs), name = inputs,
                   stringsAsFactors = FALSE)
  DBI::dbWriteTable(con, "n", df, overwrite = TRUE)
  sql <- sprintf("SELECT %s AS folded FROM n ORDER BY rowid", sql_npi_name("name"))
  sql_out <- DBI::dbGetQuery(con, sql)$folded

  expect_identical(sql_out, normalize_string(inputs))
  # pin the two cases the defect broke, by name, so a regression is legible
  # without re-deriving the whole vector
  expect_identical(sql_out[inputs == "Müller"], "MUELLER")
  expect_identical(sql_out[inputs == "Schön"], "SCHOEN")
})
