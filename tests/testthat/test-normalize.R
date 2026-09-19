# =============================================================================
# sql_npi_name(): the SQL-side name key must match normalize_string() exactly,
# or the database half of a pipeline silently disagrees with the R half about
# who matched whom.
# =============================================================================

test_that("sql_npi_name() emits the documented SQL shape", {
  # Formerly a byte-exact pin of a 7-REPLACE chain; the chain now carries the
  # full translit map (German digraphs + Latin special letters) plus
  # nfc_normalize(), and the SEMANTIC contract is proven by execution in
  # test-sql-r-parity-contract.R. What this pin still owns is the STRUCTURE:
  # NFC first, every declared mapping present exactly once, accent strip
  # outermost - so a mapping cannot be dropped or duplicated silently.
  sql <- sql_npi_name("last_name")
  expect_match(sql, "^strip_accents\\(UPPER\\(TRIM\\(", perl = TRUE)
  expect_match(sql, "nfc_normalize\\(last_name\\)", fixed = FALSE)
  for (ch in names(mysterynpi:::.sql_translit_map)) {
    hits <- gregexpr(sprintf("'%s', '%s'", ch, mysterynpi:::.sql_translit_map[[ch]]),
                     sql, fixed = TRUE)[[1]]
    expect_identical(length(hits[hits > 0]), 1L,
                     info = sprintf("mapping for %s must appear exactly once", ch))
  }
  # replacement targets run BEFORE UPPER: the map's lowercase forms must be
  # inside the TRIM(...) argument, which starts after the fixed prefix
  expect_identical(length(gregexpr("REPLACE(", sql, fixed = TRUE)[[1]]),
                   length(mysterynpi:::.sql_translit_map))
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
