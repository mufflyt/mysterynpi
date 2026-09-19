# =============================================================================
# THE PACKAGE-LEVEL SQL/R PARITY CONTRACT
#
# If an R function and a SQL helper are called twins, they must have the same
# preprocessing, the same supported input domain, and the same output for
# every supported input. "Parity except for..." means they are not twins
# (owner review 2026-09-19, twice: first retracting the "ASCII parity
# boundary" under which Émile keyed E in R and M in SQL, then retracting a
# single delete-the-group parenthetical regex that collapsed two OPPOSITE
# roster conventions, and a compact "twin" that silently included a suffix
# strip its R counterpart does not perform).
#
# DECLARED SUPPORTED DOMAIN for the transliterating base: ASCII plus
# U+00C0..U+017F (Latin-1 Supplement + Latin Extended-A). Inside it, parity
# is not sampled - it is MEASURED EXHAUSTIVELY by the differential below, so
# the hand-written translit map is mechanically governed: any character the
# map misses fails the build and must be added or the domain narrowed.
# Outside it, the measured failure shape is ABSTENTION (the SQL side's key
# strips to NULL), never a different populated key - also pinned below.
#
# Organization: one section per semantic rule, so a change to any R
# normalization branch demands the matching SQL branch. Every expectation is
# DERIVED BY CALLING THE REAL R PRIMITIVE; every SQL side is EXECUTED on a
# live DuckDB. Fixtures are literal UTF-8 (test files may carry it; package
# code uses \uxxxx).
# =============================================================================

skip_if_not_installed("DBI")
skip_if_not_installed("duckdb")

with_duck <- function(code) {
  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  code(con)
}

sql_side <- function(con, builder, values) {
  df <- data.frame(x = values, stringsAsFactors = FALSE)
  duckdb::duckdb_register(con, "parity_t", df)
  out <- DBI::dbGetQuery(con, sprintf("SELECT %s AS v FROM parity_t", builder("x")))$v
  duckdb::duckdb_unregister(con, "parity_t")
  out
}

expect_twin <- function(con, builder, r_fn, values, label) {
  got <- sql_side(con, builder, values)
  want <- unname(r_fn(values))
  expect_identical(got, want, label = label)
}

# ---------------------------------------------------------------------------
# THE MECHANICAL GOVERNOR: exhaustive differential over the declared domain
# ---------------------------------------------------------------------------

test_that("DOMAIN DIFFERENTIAL: every character in U+00C0..U+017F agrees, exhaustively", {
  # This is what makes .sql_translit_map governed rather than hand-curated:
  # normalize_string() delegates to ICU's Latin-ASCII, the SQL side is
  # strip_accents() plus the map, and every single character of the declared
  # domain is executed on both. A disagreement here has exactly two legal
  # exits: extend the map, or narrow the declared domain - never a silent
  # divergent key.
  cp <- c(0xC0:0xFF, 0x100:0x17F)
  chars <- vapply(cp, intToUtf8, "")
  with_duck(function(con) {
    got <- sql_side(con, function(col) mysterynpi:::.sql_translit_upper(col), chars)
    want <- unname(normalize_string(chars))
    mism <- which(got != want)
    expect_identical(
      got, want,
      info = paste("divergent code points:",
                   paste(sprintf("U+%04X (R=%s SQL=%s)", cp[mism],
                                 want[mism], got[mism]), collapse = ", ")))
  })
  # positive control on the differential itself: the domain genuinely
  # exercises transliteration (a broken normalizer pair that both returned
  # their input unchanged would also "agree")
  expect_gte(sum(normalize_string(chars) != toupper(chars), na.rm = TRUE), 100)
})

test_that("BEYOND THE DOMAIN: disagreement is abstention, never a different populated key", {
  # Latin Extended-B is NOT in the declared domain. Measured 2026-09-19 over
  # all 208 characters: 82 disagreements, every one abstention-shaped (the
  # SQL side's letters-only key strips to nothing -> NULL) and ZERO cases of
  # two different populated keys. That shape is the safety property - an
  # out-of-domain character can cost a candidate, never place a person in a
  # WRONG block - and this pins it exhaustively for the whole range.
  cp <- 0x180:0x24F
  chars <- vapply(cp, intToUtf8, "")
  with_duck(function(con) {
    got <- sql_side(con, function(col) mysterynpi:::.sql_translit_upper(col), chars)
    want <- unname(normalize_string(chars))
    disagree <- which(got != want)
    expect_gt(length(disagree), 0)   # the range must actually exercise the shape
    sql_key <- gsub("[^A-Z]", "", got[disagree])
    expect_true(all(!nzchar(sql_key)),
                info = "an out-of-domain char minted a POPULATED divergent SQL key")
  })
})

# ---------------------------------------------------------------------------
# NFC: composed and decomposed forms are one input
# ---------------------------------------------------------------------------

test_that("BRANCH nfc: decomposed combining marks agree with composed, both sides", {
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

# ---------------------------------------------------------------------------
# German digraphs, generic accents, special Latin letters
# ---------------------------------------------------------------------------

test_that("BRANCH digraphs: umlauts and sharp-s romanise as digraphs, both sides", {
  v <- c("Müller", "MÜLLER", "Schön", "Ömer", "Ümit", "Groß", "Läßig")
  with_duck(function(con) {
    expect_twin(con, sql_npi_name, normalize_string, v, "digraphs/npi_name")
    expect_twin(con, sql_first_initial, extract_first_initial, v, "digraphs/initial")
    expect_twin(con, sql_name_compact, compact_name_key, v, "digraphs/compact")
  })
})

test_that("BRANCH accents: acute/grave/tilde/cedilla strip identically", {
  v <- c("Émile", "Álvaro", "García", "Muñoz", "Ñico", "Çetin", "François", "Àgnes")
  with_duck(function(con) {
    expect_twin(con, sql_npi_name, normalize_string, v, "accents/npi_name")
    expect_twin(con, sql_first_initial, extract_first_initial, v, "accents/initial")
    expect_twin(con, sql_name_compact, compact_name_key, v, "accents/compact")
    # the founding defect of this contract, named: Émile keys E on BOTH sides
    expect_identical(extract_first_initial("Émile"), "E")
    expect_identical(sql_side(con, sql_first_initial, "Émile"), "E")
  })
})

test_that("BRANCH special letters: strip_accents() keeps them whole; the map must not", {
  v <- c("Øyvind", "Ødegaard", "Łukasz", "Łak", "Đorđe", "Æsa", "Œuvre", "Þor")
  with_duck(function(con) {
    expect_twin(con, sql_npi_name, normalize_string, v, "specials/npi_name")
    expect_twin(con, sql_first_initial, extract_first_initial, v, "specials/initial")
    expect_twin(con, sql_name_compact, compact_name_key, v, "specials/compact")
  })
})

# ---------------------------------------------------------------------------
# Parentheticals: three R branches, three SQL branches
# ---------------------------------------------------------------------------

test_that("BRANCH paren/standalone: a separate-token alternate drops", {
  v <- c("Cynthia (Cindi) A", "Smith (Jones)", "(Sandra) Theresa",
         "(Bob) (Rob) Robert")                     # multiple groups
  with_duck(function(con) {
    expect_twin(con, sql_strip_parenthetical, strip_parenthetical, v,
                "paren/standalone raw twin")
    expect_twin(con, sql_name_compact, compact_name_key, v,
                "paren/standalone compact")
  })
})

test_that("BRANCH paren/word-internal: optional letters UNWRAP, never delete", {
  # The two conventions mean opposite things, and the single
  # delete-the-group regex this replaces collapsed them: C(arolyn) must
  # become CAROLYN - "C" is not a name, it is a blocking key that joins to
  # every bare initial.
  v <- c("C(arolyn) Diane", "A(B)C", "Jo(seph)ine (Jo)")   # mixed forms
  expect_identical(strip_parenthetical("C(arolyn) Diane"), "Carolyn Diane")
  with_duck(function(con) {
    expect_twin(con, sql_strip_parenthetical, strip_parenthetical, v,
                "paren/word-internal raw twin")
    expect_twin(con, sql_name_compact, compact_name_key, v,
                "paren/word-internal compact")
    expect_identical(sql_side(con, sql_name_compact, "C(arolyn) Diane"),
                     unname(compact_name_key("C(arolyn) Diane")))
    expect_identical(unname(compact_name_key("C(arolyn) Diane")), "CAROLYNDIANE")
  })
})

test_that("BRANCH paren/unclosed: an unterminated group runs to end-of-string", {
  v <- c("Smith (Jones", "Smith (", "C(arolyn Diane")
  with_duck(function(con) {
    expect_twin(con, sql_strip_parenthetical, strip_parenthetical, v,
                "paren/unclosed raw twin")
    expect_twin(con, sql_name_compact, compact_name_key, v,
                "paren/unclosed compact")
  })
})

test_that("BRANCH paren/residual: stray brackets become spaces, both sides", {
  v <- c("Smith) Jones", "Smith ] Jones", "[Smith", "Smith ()")
  with_duck(function(con) {
    expect_twin(con, sql_strip_parenthetical, strip_parenthetical, v,
                "paren/residual raw twin")
  })
})

# ---------------------------------------------------------------------------
# Punctuation compaction, missingness, suffixes, first initial
# ---------------------------------------------------------------------------

test_that("BRANCH punctuation: apostrophes/hyphens/spaces compact identically", {
  v <- c("O'Brien", "Jones-Cox", "JONES COX", "Van Houten", "van de Ven",
         "  Della  Badia ", "MC CARTHY-DERVIN")
  with_duck(function(con) {
    expect_twin(con, sql_name_compact, compact_name_key, v, "punct/compact")
    expect_twin(con, sql_first_initial, extract_first_initial, v, "punct/initial")
  })
})

test_that("BRANCH missing: no-letter inputs are NULL/NA on BOTH sides", {
  v <- c("---", "", "   ", NA_character_, "123", "Иван")
  # the last is Cyrillic: out of scope for BOTH sides, and both must refuse
  # to mint a key rather than disagreeing about the refusal shape
  with_duck(function(con) {
    expect_true(all(is.na(sql_side(con, sql_name_compact, v))))
    expect_true(all(is.na(compact_name_key(v))))
    expect_true(all(is.na(sql_side(con, sql_first_initial, v))))
    expect_true(all(is.na(extract_first_initial(v))))
  })
})

test_that("BRANCH suffixes: compact twins hold UNCONDITIONALLY in both modes", {
  # sql_name_compact() and compact_name_key() carry the SAME strip_suffixes
  # argument reading the SAME shared pattern; there is no "suffix-free
  # domain" carve-out left to remember.
  v <- c("SMITH JR", "Smith Jr.", "SMITH JR MD", "Müller Jr", "JONES PH.D.",
         "DO", "JR", "DOOLEY", "MADDOX", "Muñoz")   # must-not-strip lookalikes
  with_duck(function(con) {
    expect_twin(con, function(col) sql_name_compact(col, strip_suffixes = FALSE),
                function(x) compact_name_key(x, strip_suffixes = FALSE),
                v, "suffix/mode-off")
    expect_twin(con, function(col) sql_name_compact(col, strip_suffixes = TRUE),
                function(x) compact_name_key(x, strip_suffixes = TRUE),
                v, "suffix/mode-on")
    # and the modes genuinely differ where a suffix exists
    expect_identical(unname(compact_name_key("SMITH JR", strip_suffixes = TRUE)),
                     "SMITH")
    expect_identical(unname(compact_name_key("SMITH JR")), "SMITHJR")
  })
})

test_that("BRANCH first-initial: extraction parity across every fixture class", {
  v <- c("Mary", "mary ann", "J", "j. robert", "(Sandra) Theresa", "'Anne",
         "C(arolyn) Diane", "Émile", "Ömer", "Øyvind", "Groß",
         "---", "", "  ", NA_character_)
  with_duck(function(con) {
    expect_twin(con, sql_first_initial, extract_first_initial, v, "initial/all")
  })
})

# ---------------------------------------------------------------------------
# End to end: blocking places the same person in the same block
# ---------------------------------------------------------------------------

test_that("END-TO-END: blocking_key(compact) and sql_name_compact() block identically", {
  names <- c("Muñoz", "Müller", "García", "O'Brien", "Van Houten",
             "Smith (Jones)", "C(arolyn)", "Ødegaard", "SMITH JR")
  with_duck(function(con) {
    expect_identical(sql_side(con, sql_name_compact, names),
                     unname(blocking_key(names, mode = "compact")))
  })
})
