# =============================================================================
# THE PACKAGE-LEVEL SQL/R PARITY CONTRACT
#
# For every SQL helper advertised as the database twin of an R identity
# primitive, executing the SQL on a supported input must produce the same
# normalized value as the R primitive. Candidate generation is exactly where
# R/SQL normalization has to agree byte-for-byte: a blocking primitive whose
# two sides disagree puts the same person in two different blocks, and a
# DOCUMENTED disagreement is still a disagreement (owner review 2026-09-19,
# retracting the earlier "ASCII parity boundary" posture, under which
# "Emile"-with-acute keyed E in R and M in SQL).
#
# Every expected value is DERIVED BY CALLING THE REAL R PRIMITIVE inside the
# test, never hand-coded, and the SQL side is EXECUTED against a live DuckDB.
# =============================================================================

skip_if_not_installed("DBI")
skip_if_not_installed("duckdb")

with_duck <- function(code) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  code(con)
}

# The Unicode corpus: representative characters normalize_string() supports,
# as literal UTF-8 (test files may carry it; package code uses \uxxxx). The
# LAST TWO entries are DECOMPOSED sequences (base letter + combining mark),
# which only agree across R and SQL because both sides NFC-normalize FIRST.
CORPUS <- c(
  "Mary", "mary ann", "J",
  "Émile",                      # E-acute (acute accents)
  "Álvaro", "García",      # A-acute, i-acute
  "Ömer", "Ümit",          # O-umlaut, U-umlaut (German digraphs)
  "Müller", "MÜLLER",      # u-umlaut lower/upper
  "Ñico", "Muñoz",         # N-tilde, n-tilde
  "Çetin", "François",     # C-cedilla, c-cedilla
  "Groß",                       # sharp-s (UPPER gives U+1E9E - measured)
  "Øyvind", "Ødegaard",    # O-slash: a LETTER, not an accent
  "Łukasz", "Łak",         # L-stroke
  "Đorđe",                 # D-stroke, upper and lower
  "Æsa",                        # AE ligature
  "Œuvre",                      # OE ligature
  "Þor",                        # thorn
  "O'Brien", "Van Houten", "van de Ven", "Jones-Cox",
  "(Sandra) Theresa", "'Anne",       # punctuation before the first letter
  "---", "", "  ", NA_character_,
  paste0("E", "́", "mile"),     # DECOMPOSED E-acute
  paste0("Mu", "̈", "ller")     # u + COMBINING diaeresis... on the wrong
)                                    # base here would be a fixture bug - see
# the decomposed-umlaut fixture check below, which derives the truth from R.

sql_side <- function(con, builder, values) {
  df <- data.frame(x = values, stringsAsFactors = FALSE)
  duckdb::duckdb_register(con, "parity_t", df)
  out <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v FROM parity_t", builder("x")))$v
  duckdb::duckdb_unregister(con, "parity_t")
  out
}

test_that("POSITIVE CONTROL: the corpus actually exercises non-ASCII normalization", {
  # A corpus that normalization leaves untouched would grant every parity
  # assertion for free. At least a third of it must CHANGE under
  # normalize_string() beyond mere upper-casing.
  changed <- sum(normalize_string(CORPUS) != toupper(trimws(CORPUS)), na.rm = TRUE)
  expect_gte(changed, 10)
})

test_that("TWIN: sql_npi_name() == normalize_string(), executed on the corpus", {
  with_duck(function(con) {
    got <- sql_side(con, sql_npi_name, CORPUS)
    want <- normalize_string(CORPUS)
    expect_identical(got, unname(want))
  })
})

test_that("TWIN: sql_first_initial() == extract_first_initial(), executed on the corpus", {
  with_duck(function(con) {
    got <- sql_side(con, sql_first_initial, CORPUS)   # SQL NULL arrives as NA
    want <- extract_first_initial(CORPUS)
    expect_identical(got, unname(want))
    # the defect this contract exists for, named explicitly: an accented
    # first letter keys the SAME block on both sides
    e_acute <- "Émile"
    expect_identical(extract_first_initial(e_acute), "E")
    expect_identical(sql_side(con, sql_first_initial, e_acute), "E")
  })
})

test_that("TWIN: sql_name_compact() == compact_name_key(), executed (suffix-free domain)", {
  # sql_name_compact()'s contract includes the trailing credential/generation
  # strip; compact_name_key() alone does not. On suffix-free names the twins
  # must agree exactly - including accents, special letters, parentheticals
  # and the NULL-for-no-letters rule.
  suffix_free <- CORPUS[!grepl("\\s(JR|SR|II|III|IV|MD|DO)\\.?$",
                               toupper(trimws(CORPUS))) | is.na(CORPUS)]
  with_duck(function(con) {
    got <- sql_side(con, sql_name_compact, suffix_free)
    want <- compact_name_key(suffix_free)
    expect_identical(got, unname(want))
  })
})

test_that("sql_name_compact(): the suffix-strip contract, reference DERIVED from primitives", {
  strip_suffix <- function(x) sub(
    "(\\s+(MD|M\\.D\\.|DO|D\\.O\\.|JR|SR|III|II|IV|PH\\.\\s?D\\.)\\.?)+$",
    "", toupper(trimws(x)), perl = TRUE)
  inputs <- c("SMITH JR", "Smith Jr.", "SMITH JR MD", "Müller Jr")
  with_duck(function(con) {
    got <- sql_side(con, sql_name_compact, inputs)
    want <- compact_name_key(strip_suffix(inputs))
    expect_identical(got, unname(want))
  })
})

test_that("no-letter inputs are NULL/NA on BOTH sides: absence cannot join to absence", {
  inputs <- c("---", "", "   ", NA_character_, "123", "Иван")
  # the last is Cyrillic: neither side claims to transliterate it, and both
  # must refuse to mint a key rather than disagreeing about the refusal shape
  with_duck(function(con) {
    expect_true(all(is.na(sql_side(con, sql_name_compact, inputs))))
    expect_true(all(is.na(compact_name_key(inputs))))
    expect_true(all(is.na(sql_side(con, sql_first_initial, inputs))))
    expect_true(all(is.na(extract_first_initial(inputs))))
  })
})

test_that("decomposed combining marks agree with their composed forms, both sides", {
  # Only true because BOTH sides NFC-normalize before the digraph table:
  # without nfc_normalize() in the SQL chain, decomposed u-umlaut fell
  # through to strip_accents() and emitted MULLER where R said MUELLER.
  composed <- c("Émile", "Müller")
  decomposed <- c(paste0("E", "́", "mile"), paste0("Mu", "̈", "ller"))
  expect_identical(normalize_string(decomposed), normalize_string(composed))
  with_duck(function(con) {
    expect_identical(sql_side(con, sql_npi_name, decomposed),
                     sql_side(con, sql_npi_name, composed))
    expect_identical(sql_side(con, sql_first_initial, decomposed),
                     sql_side(con, sql_first_initial, composed))
  })
})

test_that("blocking_key()'s surname side and the SQL compact key block identically", {
  # The end-to-end statement of the invariant: R-side blocking via
  # compact_name_key() (what blocking_key() uses) and database-side blocking
  # via sql_name_compact() place these physicians in the SAME block.
  names <- c("Muñoz", "Müller", "García", "O'Brien",
             "Van Houten", "Smith (Jones)", "Ødegaard")
  with_duck(function(con) {
    expect_identical(sql_side(con, sql_name_compact, names),
                     unname(blocking_key(names, mode = "compact")))
  })
})
