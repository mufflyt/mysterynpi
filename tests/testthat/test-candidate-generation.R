# Candidate generation is plumbing, not an identity decision.
#
# These tests intentionally precede the implementation. They define the
# public safety contract for deterministic candidate generation without
# changing any existing matching or resolution policy.

candidate_fixture <- function() {
  list(
    source = data.frame(
      source_id = c("s1", "s2", "s3", "s4"),
      first = c("Mary", "John", "Mary", NA),
      last = c("Smith", "Jones", "Smith", "Brown"),
      stringsAsFactors = FALSE
    ),
    registry = data.frame(
      npi = c("100", "200", "300", "400"),
      first = c("Mary", "John", "Marie", "Anne"),
      last = c("Smith", "Jones", "Smith", "Brown"),
      stringsAsFactors = FALSE
    ),
    strategies = list(
      blocking_spec("surname_initial"),
      blocking_spec("compact")
    )
  )
}

generate_fixture <- function(fixture = candidate_fixture(),
                             strategies = fixture$strategies,
                             max_pairs = 100L) {
  generate_candidates(
    source = fixture$source,
    candidates = fixture$registry,
    strategies = strategies,
    source_id = "source_id",
    candidate_id = "npi",
    source_last = "last",
    source_first = "first",
    candidate_last = "last",
    candidate_first = "first",
    max_pairs = max_pairs
  )
}

test_that("candidate generation returns three ordinary auditable tables", {
  got <- generate_fixture()

  expect_type(got, "list")
  expect_named(got, c("pairs", "provenance", "ledger"), ignore.order = TRUE)
  expect_s3_class(got$pairs, "data.frame")
  expect_s3_class(got$provenance, "data.frame")
  expect_s3_class(got$ledger, "data.frame")

  expect_false(inherits(got$pairs, "mysterynpi_candidate_pairs"))
  expect_false(inherits(got$provenance, "mysterynpi_candidate_pairs"))

  expect_true(all(c("source_id", "candidate_npi") %in% names(got$pairs)))
  expect_true(all(
    c("source_id", "candidate_npi", "strategy") %in%
      names(got$provenance)
  ))
})

test_that("one logical pair survives several deterministic routes", {
  got <- generate_fixture()

  logical_key <- paste(got$pairs$source_id, got$pairs$candidate_npi)
  expect_false(anyDuplicated(logical_key))

  routes <- got$provenance[
    got$provenance$source_id == "s1" &
      got$provenance$candidate_npi == "100",
    ,
    drop = FALSE
  ]
  expect_identical(
    sort(routes$strategy),
    sort(c("surname_initial", "compact"))
  )
  expect_identical(nrow(routes), 2L)
})

test_that("generation never emits identity conclusions or similarity scores", {
  got <- generate_fixture()
  forbidden <- c(
    "score", "similarity", "distance", "probability", "confidence",
    "verdict", "accepted", "resolved", "evidence_class"
  )

  expect_identical(intersect(names(got$pairs), forbidden), character(0))
  expect_identical(
    intersect(names(got$provenance), forbidden),
    character(0)
  )
})

test_that("NA and insufficient blocking keys never create candidate pairs", {
  got <- generate_fixture()

  expect_false("s4" %in% got$pairs$source_id)

  fixture <- candidate_fixture()
  fixture$registry$first[4] <- NA_character_
  fixture$registry$last[4] <- NA_character_
  got2 <- generate_fixture(fixture)

  expect_false("400" %in% got2$pairs$candidate_npi)
  expect_true(all(got2$ledger$conserved))
})

test_that("source row order cannot change logical pairs or provenance", {
  fixture <- candidate_fixture()
  reference <- generate_fixture(fixture)

  fixture$source <- fixture$source[c(4, 2, 1, 3), , drop = FALSE]
  shuffled <- generate_fixture(fixture)

  expect_identical(shuffled$pairs, reference$pairs)
  expect_identical(shuffled$provenance, reference$provenance)
  expect_identical(shuffled$ledger, reference$ledger)
})

test_that("candidate row order cannot change logical pairs or provenance", {
  fixture <- candidate_fixture()
  reference <- generate_fixture(fixture)

  fixture$registry <- fixture$registry[c(3, 1, 4, 2), , drop = FALSE]
  shuffled <- generate_fixture(fixture)

  expect_identical(shuffled$pairs, reference$pairs)
  expect_identical(shuffled$provenance, reference$provenance)
  expect_identical(shuffled$ledger, reference$ledger)
})

test_that("strategy order cannot change returned candidate information", {
  fixture <- candidate_fixture()
  reference <- generate_fixture(fixture)

  reversed <- generate_fixture(
    fixture,
    strategies = rev(fixture$strategies)
  )

  expect_identical(reversed$pairs, reference$pairs)
  expect_identical(reversed$provenance, reference$provenance)
  expect_identical(reversed$ledger, reference$ledger)
})

test_that("repeated generation is byte-for-byte deterministic as R objects", {
  first_run <- generate_fixture()
  second_run <- generate_fixture()

  expect_identical(second_run, first_run)
})

test_that("ledger reconciles every strategy and exposes expansion", {
  got <- generate_fixture()

  required <- c(
    "strategy", "source_rows", "candidate_rows",
    "informative_source_keys", "informative_candidate_keys",
    "generated_pairs", "unique_pairs", "duplicate_pairs", "conserved"
  )
  expect_true(all(required %in% names(got$ledger)))
  expect_identical(
    sort(got$ledger$strategy),
    sort(c("surname_initial", "compact"))
  )
  expect_true(all(got$ledger$conserved))
  expect_true(all(got$ledger$generated_pairs >= got$ledger$unique_pairs))
  expect_identical(
    got$ledger$duplicate_pairs,
    got$ledger$generated_pairs - got$ledger$unique_pairs
  )
})

test_that("broad deterministic blocks cannot silently create a Cartesian blowup", {
  source <- data.frame(
    source_id = paste0("s", 1:20),
    first = rep("Mary", 20),
    last = rep("Smith", 20),
    stringsAsFactors = FALSE
  )
  registry <- data.frame(
    npi = sprintf("%03d", 1:20),
    first = rep("Mary", 20),
    last = rep("Smith", 20),
    stringsAsFactors = FALSE
  )

  expect_error(
    generate_candidates(
      source = source,
      candidates = registry,
      strategies = blocking_spec("surname_initial"),
      source_id = "source_id",
      candidate_id = "npi",
      source_last = "last",
      source_first = "first",
      candidate_last = "last",
      candidate_first = "first",
      max_pairs = 100L
    ),
    "max_pairs|expansion|400"
  )
})

test_that("generator preserves ambiguity rather than selecting a winner", {
  fixture <- candidate_fixture()
  got <- generate_fixture(
    fixture,
    strategies = blocking_spec("surname_initial")
  )

  smith <- got$pairs[got$pairs$source_id == "s1", , drop = FALSE]
  expect_identical(sort(smith$candidate_npi), c("100", "300"))
  expect_identical(nrow(smith), 2L)
})

test_that("identical names with different NPIs remain separate candidates", {
  fixture <- candidate_fixture()
  fixture$registry <- rbind(
    fixture$registry,
    data.frame(
      npi = "500",
      first = "Mary",
      last = "Smith",
      stringsAsFactors = FALSE
    )
  )

  got <- generate_fixture(
    fixture,
    strategies = blocking_spec("surname_initial")
  )
  smith <- got$pairs[got$pairs$source_id == "s1", , drop = FALSE]

  expect_identical(sort(smith$candidate_npi), c("100", "300", "500"))
})

test_that("duplicate input identifiers are rejected before generation", {
  fixture <- candidate_fixture()
  fixture$source$source_id[2] <- fixture$source$source_id[1]

  expect_error(generate_fixture(fixture), "source_id.*unique|duplicate")

  fixture <- candidate_fixture()
  fixture$registry$npi[2] <- fixture$registry$npi[1]

  expect_error(generate_fixture(fixture), "npi.*unique|duplicate")
})

test_that("arbitrary comparator callbacks are not a candidate strategy", {
  fixture <- candidate_fixture()
  fuzzy_escape_hatch <- function(x, y) stats::adist(x, y) <= 1

  expect_error(
    generate_fixture(
      fixture,
      strategies = list(fuzzy_escape_hatch)
    ),
    "blocking_spec|strategy"
  )
})

test_that("candidate generation composes with existing categorical resolution", {
  got <- generate_fixture(
    strategies = blocking_spec("surname_initial")
  )

  evidence <- data.frame(
    id = got$pairs$source_id,
    candidate = got$pairs$candidate_npi,
    evidence_class = ifelse(
      got$pairs$candidate_npi %in% c("100", "200"),
      1L,
      2L
    ),
    stringsAsFactors = FALSE
  )

  resolved <- resolve_ordered_classes(evidence)
  expect_identical(
    resolved$resolved$candidate[resolved$resolved$id == "s1"],
    "100"
  )
})

test_that("existing no-fuzzy invariant still covers the new source module", {
  source_file <- file.path("../../R", "candidate_generation.R")
  if (!file.exists(source_file)) {
    skip("candidate-generation implementation intentionally not written yet")
  }

  code <- readLines(source_file, warn = FALSE)
  banned <- c(
    "adist", "agrep", "agrepl", "stringdist", "stringsim",
    "jarowinkler", "soundex", "fuzzyjoin", "reclin", "reclin2"
  )
  for (term in banned) {
    expect_false(
      any(grepl(term, code, fixed = TRUE)),
      info = paste("candidate generation must not reference", term)
    )
  }
})
