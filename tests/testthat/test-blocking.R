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

test_that("CANONICALIZATION DELTAS: surname side, full trail per fixture", {
  # classification: intentional KEY-LEVEL canonicalization delta; POTENTIAL
  # candidate-set delta. A changed key creates the potential for the
  # candidate set to change; whether it actually changes depends on what
  # else occupies the canonicalized block, and is measured against frozen
  # data during downstream migration - never inferred here.
  fixtures <- data.frame(
    raw_first = c("Mary", "Laura", "Jose", "Hans", "Ann"),
    raw_last = c("O'Brien", "Van Houten", "Muñoz", "MÜLLER", "Smith (Jones)"),
    legacy_expected = c("O'BRIEN|M", "VAN HOUTEN|L", "MUÑOZ|J",
                        "MÜLLER|H", "SMITH (JONES)|A"),
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
  # and every fixture is a GENUINE key-level delta: the final keys differ
  expect_true(all(canonical != legacy))
  # the specific canonicalizations, stated once for the reader:
  expect_identical(canonical,
                   c("OBRIEN|M",      # punctuation compacts
                     "VANHOUTEN|L",   # spaces compact
                     "MUNOZ|J",       # accents transliterate
                     "MUELLER|H",     # German digraphs romanise
                     "SMITH|A"))      # parenthetical alternates strip
})

test_that("CANONICALIZATION DELTAS: first-name side, via extract_first_initial", {
  # surname_initial also deliberately canonicalizes the GIVEN-name side:
  # extract_first_initial() normalizes and strips non-letters BEFORE taking
  # the initial, where legacy substr() took whatever byte came first.
  # classification: intentional key-level canonicalization delta; potential
  # candidate-set delta.
  fixtures <- data.frame(
    raw_first = c("Émile", "(Sandra) Theresa", "'Anne"),
    raw_last = c("Smith", "Smith", "Smith"),
    legacy_expected = c("SMITH|É", "SMITH|(", "SMITH|'"),
    stringsAsFactors = FALSE
  )
  legacy <- legacy_key_A(fixtures$raw_first, fixtures$raw_last)
  expect_identical(legacy, fixtures$legacy_expected)
  canonical <- blocking_key(fixtures$raw_last, fixtures$raw_first,
                            mode = "surname_initial")
  derived <- paste0(compact_name_key(fixtures$raw_last), "|",
                    extract_first_initial(fixtures$raw_first))
  expect_identical(canonical, derived)
  expect_identical(canonical, c("SMITH|E", "SMITH|S", "SMITH|A"))
  expect_true(all(canonical != legacy))
})

test_that("punctuation-only given name: the legacy filter was BLIND to it", {
  # nzchar("-") is TRUE, so the audited legacy filter
  # (!is.na(first_up), nzchar(first_up)) did NOT remove a punctuation-only
  # given name - legacy emitted "SMITH|-" into candidate generation, where
  # the canonical key is NA. Unlike plain missing values, this one is a
  # potential candidate-set delta at PIPELINE level too; measure it against
  # frozen data during migration.
  expect_true(nzchar("-"))
  expect_identical(legacy_key_A("---", "Smith"), "SMITH|-")
  expect_identical(blocking_key("Smith", "---", "surname_initial"),
                   NA_character_)
})

test_that("MISSINGNESS: API representation changes; audited candidate behavior does not", {
  # The canonical API returns NA when either required component is
  # insufficient. The audited legacy extractors did NOT serialize a
  # combined key at all: they kept surname and initial as SEPARATE columns
  # and filtered missing rows before the join
  # (extract_florida_retirement_signals.R:122,
  #  extract_washington_retirement_signals.R:87:
  #   filter(!is.na(first_up), !is.na(last_up),
  #          nzchar(first_up), nzchar(last_up))),
  # and dplyr's toupper/trimws keep NA as NA:
  expect_true(is.na(toupper(trimws(NA_character_))))
  # So for plain missing values this changes the API representation, not
  # their missing-value candidate behavior. (legacy_key_A() above is this
  # TEST's serialization helper; its paste0() NA-coercion is a harness
  # artifact, not something any audited call site constructed.)
  expect_identical(blocking_key("Smith", NA_character_, "surname_initial"),
                   NA_character_)
  expect_identical(blocking_key(NA_character_, "Mary", "surname_initial"),
                   NA_character_)
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

test_that("the delimiter makes component boundaries explicit", {
  # NOT collision prevention: with a fixed one-character second field,
  # surname + initial is already uniquely separable (ANNAL vs ANNA do not
  # collide). The delimiter is kept for readability, auditability, and
  # future-proofing against modes without a fixed-width field - and this
  # test pins the SERIALIZED CONTRACT so it cannot drift silently.
  k <- blocking_key(c("ANNA", "ANN"), c("L", "AL"), "surname_initial")
  expect_identical(k, c("ANNA|L", "ANN|A"))
  parts <- strsplit(k, "|", fixed = TRUE)
  expect_identical(vapply(parts, `[`, "", 1), c("ANNA", "ANN"))
  expect_identical(vapply(parts, `[`, "", 2), c("L", "A"))
  expect_identical(vapply(parts, length, 0L), c(2L, 2L))
})

test_that("prefix_n requires a single finite whole number >= 1; never pads", {
  expect_error(blocking_key("Smith", mode = "prefix_n"), "explicit n")
  for (bad in list(1.5, Inf, NaN, "3", TRUE, 0L, -2L, c(2L, 3L))) {
    expect_error(blocking_key("Smith", mode = "prefix_n", n = bad),
                 "explicit n", label = paste("n =", deparse(bad)))
  }
  expect_identical(blocking_key(c("Garcia", "Li", "O'Brien"), mode = "prefix_n", n = 4),
                   c("GARC", "LI", "OBRI"))
  expect_identical(blocking_key("Muñoz", mode = "prefix_n", n = 3), "MUN")
  expect_identical(blocking_key(NA_character_, mode = "prefix_n", n = 3), NA_character_)
})

test_that("supplying n outside prefix_n is an error, not silently discarded", {
  expect_error(blocking_key("Smith", "Mary", "surname_initial", n = 3),
               "only meaningful")
  expect_error(blocking_key("Smith", mode = "compact", n = 3),
               "only meaningful")
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


test_that("blocking_spec defines a governed, labelled recipe", {
  s1 <- blocking_spec("surname_initial")
  expect_s3_class(s1, "mysterynpi_blocking_spec")
  expect_identical(s1$mode, "surname_initial")
  expect_null(s1$n)
  expect_identical(s1$label, "surname_initial")

  s2 <- blocking_spec("prefix_n", n = 3)
  expect_identical(s2$mode, "prefix_n")
  expect_identical(s2$n, 3L)
  expect_identical(s2$label, "prefix_3")

  s3 <- blocking_spec("compact", label = "whole_surname")
  expect_identical(s3$label, "whole_surname")

  expect_error(blocking_spec("prefix_n"), "explicit n")
  expect_error(blocking_spec("compact", n = 3), "only meaningful")
  expect_error(blocking_spec("compact", label = ""), "non-empty")
  expect_error(blocking_spec("compact", label = NA_character_), "non-empty")
})


test_that("blocking_key_info is blocking_key plus auditable metadata", {
  got <- blocking_key_info("Smith", "Mary", "surname_initial")

  expect_identical(got$key, blocking_key(
    "Smith", "Mary", "surname_initial"
  ))
  expect_identical(
    names(got),
    c(
      "key", "mode", "components_used", "informative", "reason",
      "surname_key", "first_initial", "prefix_n"
    )
  )
  expect_identical(got$mode, "surname_initial")
  expect_identical(got$components_used, "surname+first_initial")
  expect_true(got$informative)
  expect_identical(got$reason, "complete")
  expect_identical(got$surname_key, "SMITH")
  expect_identical(got$first_initial, "M")
  expect_identical(got$prefix_n, NA_integer_)
})


test_that("blocking_key_info explains every insufficient component", {
  got <- blocking_key_info(
    c("Smith", NA, NA),
    c(NA, "Mary", NA),
    "surname_initial"
  )

  expect_identical(got$key, rep(NA_character_, 3))
  expect_false(any(got$informative))
  expect_identical(
    got$reason,
    c(
      "missing_first_initial",
      "missing_surname",
      "missing_surname_and_first_initial"
    )
  )
})


test_that("blocking_key_info records prefix width without inventing initials", {
  got <- blocking_key_info(
    c("Smith", "---"),
    mode = "prefix_n",
    n = 3
  )

  expect_identical(got$key, c("SMI", NA_character_))
  expect_identical(got$components_used, rep("surname", 2))
  expect_identical(got$first_initial, rep(NA_character_, 2))
  expect_identical(got$prefix_n, rep(3L, 2))
  expect_identical(got$reason, c("complete", "missing_surname"))
  expect_identical(got$informative, c(TRUE, FALSE))
})


test_that("blocking_key_info preserves surname_initial broadcasting", {
  got <- blocking_key_info(
    "Smith",
    c("Mary", "John"),
    "surname_initial"
  )

  expect_identical(got$key, c("SMITH|M", "SMITH|J"))
  expect_identical(got$surname_key, rep("SMITH", 2))
  expect_identical(got$first_initial, c("M", "J"))
  expect_true(all(got$informative))
})


test_that("blocking_keys emits several governed blocks in long form", {
  plan <- list(
    blocking_spec("surname_initial"),
    blocking_spec("prefix_n", n = 2),
    blocking_spec("compact")
  )

  got <- blocking_keys(
    c("Smith", "O'Brien"),
    c("Mary", "John"),
    specs = plan
  )

  expect_identical(nrow(got), 6L)
  expect_identical(got$record_id, rep(1:2, 3))
  expect_identical(got$spec_id, c(1L, 1L, 2L, 2L, 3L, 3L))
  expect_identical(
    got$label,
    c(
      "surname_initial", "surname_initial",
      "prefix_2", "prefix_2",
      "compact", "compact"
    )
  )
  expect_identical(
    got$key,
    c("SMITH|M", "OBRIEN|J", "SM", "OB", "SMITH", "OBRIEN")
  )
})


test_that("each multi-key row is exactly the corresponding governed key", {
  last <- c("Muñoz", "Van Houten", NA)
  first <- c("José", "Laura", "Mary")
  plan <- list(
    blocking_spec("surname_initial", label = "si"),
    blocking_spec("prefix_n", n = 4, label = "p4"),
    blocking_spec("compact", label = "whole")
  )

  got <- blocking_keys(last, first, plan)

  expect_identical(
    got$key[got$label == "si"],
    blocking_key(last, first, "surname_initial")
  )
  expect_identical(
    got$key[got$label == "p4"],
    blocking_key(last, mode = "prefix_n", n = 4)
  )
  expect_identical(
    got$key[got$label == "whole"],
    blocking_key(last, mode = "compact")
  )
  expect_identical(got$informative, !is.na(got$key))
})


test_that("blocking_keys requires governed specs with unique labels", {
  expect_error(
    blocking_keys("Smith", "Mary"),
    "supply one blocking_spec"
  )
  expect_error(
    blocking_keys("Smith", "Mary", specs = list("compact")),
    "must come from blocking_spec"
  )
  expect_error(
    blocking_keys(
      "Smith",
      "Mary",
      specs = list(
        blocking_spec("compact", label = "same"),
        blocking_spec("prefix_n", n = 3, label = "same")
      )
    ),
    "labels must be unique"
  )
})


test_that("a single blocking_spec is accepted directly", {
  got <- blocking_keys(
    c("Smith", "Jones"),
    specs = blocking_spec("compact")
  )
  expect_identical(got$record_id, 1:2)
  expect_identical(got$spec_id, c(1L, 1L))
  expect_identical(got$label, rep("compact", 2))
  expect_identical(got$key, c("SMITH", "JONES"))
})


test_that("multi-key blocking is candidate plumbing, not identity evidence", {
  got <- blocking_keys(
    "Smith",
    "Mary",
    specs = list(
      blocking_spec("surname_initial"),
      blocking_spec("compact")
    )
  )

  expect_false(any(c("verdict", "score", "confidence") %in% names(got)))
  expect_true(all(got$informative))
})


test_that("multi-key plans share one broadcast record universe", {
  got <- blocking_keys(
    "Smith",
    c("Mary", "John"),
    specs = list(
      blocking_spec("surname_initial"),
      blocking_spec("compact")
    )
  )

  expect_identical(nrow(got), 4L)
  expect_identical(got$record_id, c(1L, 2L, 1L, 2L))
  expect_identical(
    got$key,
    c("SMITH|M", "SMITH|J", "SMITH", "SMITH")
  )
  expect_identical(
    table(got$label),
    structure(c(2L, 2L), dim = 2L,
              dimnames = list(c("compact", "surname_initial")))
  )
})


test_that("multi-key plans require first when any spec needs it", {
  expect_error(
    blocking_keys(
      c("Smith", "Jones"),
      specs = list(
        blocking_spec("compact"),
        blocking_spec("surname_initial")
      )
    ),
    "requires `first`"
  )
})
