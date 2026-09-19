# blocking_key(): parity with the legacy call sites is characterized at the
# level of the RESULTING KEY, never intermediate string operations; genuine
# non-parity is documented as CANONICALIZATION DELTAS, each with the full
# trail: raw input -> legacy expression -> legacy intermediate key -> legacy
# effective behavior -> canonical primitive output -> canonical blocking key
# -> classification. Canonical expectations are DERIVED BY CALLING THE REAL
# PRIMITIVES inside these tests, never hand-coded.

# The two legacy constructions found across the nine state retirement
# extractors (quoted verbatim; representative sources cited):
#   pattern A (7 sites, e.g. scripts/extract_florida_retirement_signals.R:103-105,
#              scripts/extract_washington_retirement_signals.R:69-71):
#     first_up   = sub(" .*", "", toupper(trimws(first)))
#     last_up    = toupper(trimws(last))
#     first_init = substr(first_up, 1, 1)
#   pattern B (2 sites: extract_arkansas_retirement_signals.R:52-54,
#              extract_nh_retirement_signals.R:98-100 - NO token truncation):
#     first_up   = toupper(trimws(first))
#     last_up    = toupper(trimws(last))
#     first_init = substr(first_up, 1, 1)
legacy_key_A <- function(first, last) {
  first_up <- sub(" .*", "", toupper(trimws(first)))
  paste0(toupper(trimws(last)), "|", substr(first_up, 1, 1))
}
legacy_key_B <- function(first, last) {
  paste0(toupper(trimws(last)), "|", substr(toupper(trimws(first)), 1, 1))
}

test_that("PARITY: all legacy implementations produce identical KEYS to each other", {
  # The AR/NH first-token divergence is implementation duplication with zero
  # output delta: a first initial is the first character of the trimmed
  # uppercase string whether or not truncation ran first.
  probes_first <- c("Mary", "Mary Ann", "J", "jose luis", "  Anne  ")
  probes_last <- c("Smith", "Jones", "Lee", "Garcia", "Brown")
  expect_identical(legacy_key_A(probes_first, probes_last),
                   legacy_key_B(probes_first, probes_last))
})

test_that("AGREEMENT DOMAIN: plain ASCII single-token names, canonical == legacy", {
  first <- c("Mary", "John", "Anne")
  last <- c("Smith", "Jones", "Brown")
  expect_identical(blocking_key(last, first, mode = "surname_initial"),
                   legacy_key_A(first, last))
})

test_that("CANONICALIZATION DELTAS: each documented with the full trail", {
  # classification: intentional effective delta - the KEY changes, so the
  # candidate pool changes (blocks merge that legacy kept apart).
  fixtures <- data.frame(
    raw_first = c("Mary", "Laura", "Jose", "Hans"),
    raw_last = c("O'Brien", "Van Houten", "Muñoz", "MÜLLER"),
    legacy_expected = c("O'BRIEN|M", "VAN HOUTEN|L", "MUÑOZ|J",
                        "MÜLLER|H"),
    stringsAsFactors = FALSE
  )
  legacy <- legacy_key_A(fixtures$raw_first, fixtures$raw_last)
  expect_identical(legacy, fixtures$legacy_expected)  # legacy trail pinned
  canonical <- blocking_key(fixtures$raw_last, fixtures$raw_first,
                            mode = "surname_initial")
  # canonical expectations DERIVED from the real primitives, not hand-coded:
  derived <- paste0(compact_name_key(fixtures$raw_last), "|",
                    extract_first_initial(fixtures$raw_first))
  expect_identical(canonical, derived)
  # and every fixture is a GENUINE delta: the final keys differ
  expect_true(all(canonical != legacy))
  # the specific canonicalizations, stated once for the reader:
  expect_identical(canonical,
                   c("OBRIEN|M",      # punctuation compacts
                     "VANHOUTEN|L",   # spaces compact
                     "MUNOZ|J",       # accents transliterate
                     "MUELLER|H"))    # German digraphs romanise
})

test_that("MISSINGNESS: function-level delta, pipeline-level NO effective delta", {
  # function-level: legacy built a partial key; canonical is NA outright.
  # (paste0 coerces the NA component to the STRING "NA" - the partial keys
  # legacy could construct are "SMITH|NA" and "NA|M".)
  expect_identical(legacy_key_A(NA, "Smith"), "SMITH|NA")
  expect_identical(legacy_key_A("Mary", NA), "NA|M")
  expect_identical(blocking_key("Smith", NA_character_, "surname_initial"),
                   NA_character_)
  expect_identical(blocking_key(NA_character_, "Mary", "surname_initial"),
                   NA_character_)
  # pipeline-level: the legacy sites filtered those rows out before any
  # join (e.g. extract_florida_retirement_signals.R:122,
  # extract_washington_retirement_signals.R:87:
  #   filter(!is.na(first_up), !is.na(last_up), nzchar(first_up), nzchar(last_up)))
  # NOTE the quoted filter catches NA and "" but NOT the "SMITH|N" / "NA|M"
  # coercion above - legacy is only safe because upstream readers deliver
  # real NA, and dplyr::mutate() keeps NA as NA through toupper/trimws (the
  # base-R paste0 coercion shown here is the test harness's own artifact).
  # Classification: API cleanup; no effective matching delta on the legacy
  # inputs, and the canonical NA removes the coercion hazard class entirely.
  legacy_na_via_dplyr <- toupper(trimws(NA_character_))   # NA, not "NA"
  expect_true(is.na(legacy_na_via_dplyr))
})

test_that("insufficient input is NA, never a partial key", {
  # whitespace-only and punctuation-only names normalise to nothing
  expect_identical(blocking_key("   ", "Mary", "surname_initial"), NA_character_)
  expect_identical(blocking_key("---", "Mary", "surname_initial"), NA_character_)
  expect_identical(blocking_key("Smith", "   ", "surname_initial"), NA_character_)
  expect_identical(blocking_key("Smith", "---", "surname_initial"), NA_character_)
  # no "|M", no "SMITH|" - assert the SHAPE, not just NA-ness
  keys <- blocking_key(c("Smith", "   ", "Smith"), c("   ", "Mary", "Mary"),
                       "surname_initial")
  expect_false(any(grepl("^\\||\\|$", keys[!is.na(keys)])))
  expect_identical(keys, c(NA, NA, "SMITH|M"))
})

test_that("the delimiter prevents field-boundary collisions", {
  a <- blocking_key("ANNA", "L", "surname_initial")
  b <- blocking_key("ANN", "AL", "surname_initial")
  expect_identical(a, "ANNA|L")
  expect_identical(b, "ANN|A")
  expect_false(a == b)
})

test_that("prefix_n requires an explicit n and never pads", {
  expect_error(blocking_key("Smith", mode = "prefix_n"), "explicit n")
  expect_identical(blocking_key(c("Garcia", "Li", "O'Brien"), mode = "prefix_n", n = 4),
                   c("GARC", "LI", "OBRI"))
  expect_identical(blocking_key("Muñoz", mode = "prefix_n", n = 3), "MUN")
  expect_identical(blocking_key(NA_character_, mode = "prefix_n", n = 3), NA_character_)
})

test_that("compact mode is the compact surname, first ignored", {
  expect_identical(blocking_key(c("Smith-Jones", "van de Ven", NA), mode = "compact"),
                   compact_name_key(c("Smith-Jones", "van de Ven", NA)))
})

test_that("length discipline: broadcast works, recycling refuses", {
  expect_identical(blocking_key("Smith", c("Mary", "John"), "surname_initial"),
                   c("SMITH|M", "SMITH|J"))
  expect_identical(blocking_key(c("Smith", "Jones"), "Mary", "surname_initial"),
                   c("SMITH|M", "JONES|M"))
  expect_error(blocking_key(c("A", "B"), c("X", "Y", "Z"), "surname_initial"),
               "recycle")
  expect_error(blocking_key(character(0), "Mary", "surname_initial"), "empty")
  expect_error(blocking_key("Smith", mode = "surname_initial"), "requires `first`")
})

test_that("multi-token first names key identically to legacy (no delta)", {
  # 'Mary Ann' -> initial M under every legacy pattern AND canonically
  expect_identical(blocking_key("Smith", "Mary Ann", "surname_initial"),
                   legacy_key_A("Mary Ann", "Smith"))
  expect_identical(blocking_key("Smith", "Mary Ann", "surname_initial"),
                   legacy_key_B("Mary Ann", "Smith"))
})
