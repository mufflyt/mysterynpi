# UDF-free SQL builders: EXECUTED against DuckDB and compared to the R side.
# A docstring claiming parity is prose; only running both sides is a test.

skip_if_not_installed("DBI")
skip_if_not_installed("duckdb")

with_duck <- function(code) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  code(con)
}

test_that("sql_name_clean strips TRAILING suffixes and only those (executable)", {
  with_duck(function(con) {
    rows <- data.frame(x = c("SMITH JR", "Smith Jr.", "SMITH III", "SMITH JR MD",
                             "JONES MD", "DELLA BADIA JR",
                             # must-NOT-strip set: bare short surnames and lookalikes
                             "DO", "JR", "DOOLEY", "MADDOX"),
                       stringsAsFactors = FALSE)
    duckdb::duckdb_register(con, "t", rows)
    got <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v FROM t", sql_name_clean("x")))$v
    expect_identical(got, c("SMITH", "SMITH", "SMITH", "SMITH",
                            "JONES", "DELLA BADIA",
                            "DO", "JR", "DOOLEY", "MADDOX"))
  })
})

test_that("REGRESSION: the pattern reaches RE2 with SINGLE backslashes", {
  # The inert-regex specimen: '\\b' in the SQL literal is a literal backslash
  # to RE2 and matches nothing, silently. The generated SQL must carry \s and
  # \. as SINGLE backslash escapes.
  sql <- sql_name_clean("x")
  expect_false(grepl("\\\\\\\\", sql))          # no double-backslash anywhere
  expect_true(grepl("\\\\s\\+", sql))           # \s+ present, single-escaped
})

test_that("sql_name_compact agrees with compact_name_key on ASCII inputs (parity)", {
  with_duck(function(con) {
    inputs <- c("Jones-Cox", "JONES COX", "JonesCox", "O'Brien", "O BRIEN",
                "VAN HOUTEN", "VANHOUTEN", "van de Ven", "SMITH JR",
                "  Della  Badia ", "MC CARTHY-DERVIN")
    duckdb::duckdb_register(con, "t2", data.frame(x = inputs, stringsAsFactors = FALSE))
    sql_side <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v FROM t2", sql_name_compact("x")))$v
    # R reference: suffix-strip then compact, the same contract the SQL claims.
    r_side <- compact_name_key(sub("(\\s+(MD|M\\.D\\.|DO|D\\.O\\.|JR|SR|III|II|IV|PH\\.\\s?D\\.)\\.?)+$",
                                   "", toupper(trimws(inputs)), perl = TRUE))
    expect_identical(sql_side, unname(r_side))
  })
})

test_that("sql_middle_initial_guard: absence passes, contradiction fails (executable)", {
  with_duck(function(con) {
    left <- data.frame(aid = 1:3, mi = c("R", NA, "R"), stringsAsFactors = FALSE)
    right <- data.frame(rid = 1:4, middle = c("ROBERT", "XAVIER", NA, ""),
                        stringsAsFactors = FALSE)
    duckdb::duckdb_register(con, "l", left)
    duckdb::duckdb_register(con, "r", right)
    q <- sprintf("SELECT l.aid, r.rid FROM l JOIN r ON %s ORDER BY l.aid, r.rid",
                 sql_middle_initial_guard("l.mi", "r.middle"))
    got <- DBI::dbGetQuery(con, q)
    expect_identical(got$rid[got$aid == 1], c(1L, 3L, 4L))  # agree, NA, ''
    expect_identical(got$rid[got$aid == 2], 1:4)            # no initial: all pass
    # NEGATIVE CONTROL: the live contradiction (R vs XAVIER) never appears
    expect_false(any(got$aid == 1 & got$rid == 2))
  })
})

test_that("sql_first_initial agrees with extract_first_initial on ASCII (parity)", {
  with_duck(function(con) {
    inputs <- c("Mary", "mary ann", "(Sandra) Theresa", " 'Anne", "J",
                "---", "", NA_character_, "  ", "j. robert")
    duckdb::duckdb_register(con, "t3", data.frame(x = inputs, stringsAsFactors = FALSE))
    sql_side <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v FROM t3",
                                             sql_first_initial("x")))$v
    r_side <- extract_first_initial(inputs)
    expect_identical(sql_side, unname(r_side))
    # and the shape contract explicitly: no '', no punctuation byte, ever
    expect_false(any(sql_side %in% c("", "(", "-", "'"), na.rm = TRUE))
    expect_true(all(is.na(sql_side) | grepl("^[A-Z]$", sql_side)))
  })
})

test_that("RETRACTION PIN: accented first letters key the SAME block on both sides", {
  # An earlier revision of this file pinned "Émile" -> R "E" vs SQL "M" as a
  # documented ASCII parity boundary. Retracted by owner review 2026-09-19:
  # a documented disagreement is still a disagreement, and blocking is
  # exactly where R and SQL must agree byte-for-byte. The full Unicode
  # parity contract lives in test-sql-r-parity-contract.R; this pin stays
  # here so the old divergence can never quietly return.
  with_duck(function(con) {
    duckdb::duckdb_register(con, "t4", data.frame(x = "Émile", stringsAsFactors = FALSE))
    sql_side <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v FROM t4",
                                             sql_first_initial("x")))$v
    expect_identical(extract_first_initial("Émile"), "E")
    expect_identical(sql_side, "E")
  })
})

test_that("sql_quote_literal round-trips values through a real database", {
  with_duck(function(con) {
    values <- c("O'Brien", "D'Angelo-Smith", "already ''doubled''",
                "", "with;semicolon -- and comment", "back\\slash",
                "  padded  ")
    for (v in values) {
      got <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v", sql_quote_literal(v)))$v
      expect_identical(got, v, label = sprintf("round-trip of %s", deparse(v)))
    }
    # NA is the SQL keyword NULL, not the string 'NA'
    got_na <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v", sql_quote_literal(NA_character_)))$v
    expect_true(is.na(got_na))
  })
})

test_that("sql_quote_literal is vectorised and refuses non-character input", {
  expect_identical(sql_quote_literal(c("a", NA, "o'b")),
                   c("'a'", "NULL", "'o''b'"))
  expect_identical(sql_quote_literal(character(0)), character(0))
  expect_error(sql_quote_literal(1L), "character vector")
  expect_error(sql_quote_literal(factor("a")), "character vector")
})

test_that("builders refuse malformed column expressions", {
  expect_error(sql_name_clean(""), "non-empty")
  expect_error(sql_name_clean(c("a", "b")), "non-empty")
  expect_error(sql_name_compact(NA_character_), "non-empty")
  expect_error(sql_middle_initial_guard("a", ""), "non-empty")
  expect_error(sql_first_initial(""), "non-empty")
  expect_error(sql_first_initial(c("a", "b")), "non-empty")
})
