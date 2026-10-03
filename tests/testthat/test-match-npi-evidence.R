evidence_pair <- function(source_id = "a", npi = "1234567893",
                          roster_first = "Jane", roster_middle = NA_character_,
                          roster_last = "Smith", nppes_first = "Jane",
                          nppes_middle = NA_character_, nppes_last = "Smith",
                          block_route = "exact") {
  data.frame(source_id, npi, roster_first, roster_middle, roster_last,
             nppes_first, nppes_middle, nppes_last, block_route)
}

test_that("exact evidence collapses route duplicates without inventing middle agreement", {
  pairs <- rbind(evidence_pair(block_route = "surname"),
                 evidence_pair(block_route = "exact"), evidence_pair())
  out <- build_npi_candidate_evidence(pairs)
  expect_equal(nrow(out), 1L)
  expect_identical(out$npi, "1234567893")
  expect_identical(out$block_routes, "exact;surname")
  expect_identical(out$middle_evidence, "uninformative")
  expect_identical(as.character(out$evidence_class), "exact_name")
  expect_true(is.ordered(out$evidence_class))
  expect_identical(out$disposition, "eligible")
  expect_identical(out$reason, "exact_name_evidence")
})

test_that("nickname and fuzzy blocking alone cannot resolve an identity", {
  pairs <- rbind(evidence_pair("nick", roster_first = "Bob", nppes_first = "Robert",
                              block_route = "nickname"),
                 evidence_pair("fuzzy", nppes_last = "Smyth", block_route = "fuzzy"))
  out <- build_npi_candidate_evidence(pairs)
  expect_identical(out$disposition, c("review", "review"))
  expect_identical(out$reason, c("fuzzy_only_evidence", "nickname_only_evidence"))
  parts <- partition_npi_matches(data.frame(source_id = c("nick", "fuzzy")), out)
  expect_equal(nrow(parts$matches), 0L)
  expect_setequal(parts$review$reason, c("nickname_only_evidence", "fuzzy_only_evidence"))
})

test_that("positional expansion is eligible but two initials and middle-only matches are weak", {
  out <- build_npi_candidate_evidence(rbind(
    evidence_pair("initial", roster_first = "J.", nppes_first = "Jane"),
    evidence_pair("two", roster_first = "J.", nppes_first = "J"),
    evidence_pair("middle", roster_first = "Ann", nppes_first = "Sue",
                  roster_middle = "Jane", nppes_middle = "Jane")))
  expect_identical(out$disposition, c("eligible", "review", "review"))
  expect_identical(as.character(out$evidence_class),
                   c("positional_name", "weak_name", "weak_name"))
  expect_identical(out$given_position[2], "neither_leading")
})

test_that("middle conflict and invalid NPIs veto otherwise exact evidence", {
  out <- build_npi_candidate_evidence(rbind(
    evidence_pair("conflict", roster_middle = "Alice", nppes_middle = "Beth"),
    evidence_pair("invalid", npi = "1234567890")))
  expect_identical(out$disposition, c("review", "review"))
  expect_identical(out$reason, c("middle_name_conflict", "invalid_npi"))
  parts <- partition_npi_matches(data.frame(source_id = c("conflict", "invalid")), out)
  expect_equal(nrow(parts$matches), 0L)
  expect_equal(nrow(parts$review), 2L)
})

test_that("a unique evidence-supported best candidate wins over weaker alternatives", {
  candidates <- build_npi_candidate_evidence(rbind(
    evidence_pair(npi = "1234567893"),
    evidence_pair(npi = "1999999984", roster_first = "J", nppes_first = "Jane")))
  parts <- partition_npi_matches(data.frame(source_id = "a", payload = 42), candidates)
  expect_identical(parts$matches$npi, "1234567893")
  expect_identical(parts$matches$reason, "unique_best_evidence")
  expect_equal(parts$matches$payload, 42)
  expect_equal(nrow(parts$candidates), 2L)
})

test_that("equal best evidence and shared NPI claims remain review items", {
  tied <- build_npi_candidate_evidence(rbind(
    evidence_pair(npi = "1234567893"), evidence_pair(npi = "1999999984")))
  parts <- partition_npi_matches(data.frame(source_id = "a"), tied)
  expect_equal(nrow(parts$matches), 0L)
  expect_identical(parts$review$reason, "ambiguous_tied_evidence")
  expect_true(is.na(parts$review$npi))
  shared <- build_npi_candidate_evidence(rbind(evidence_pair("a"), evidence_pair("b")))
  parts <- partition_npi_matches(data.frame(source_id = c("a", "b")), shared)
  expect_equal(nrow(parts$matches), 0L)
  expect_identical(parts$review$reason, rep("ambiguous_contested_candidate", 2L))
})

test_that("middle corroboration separates same-class candidates conservatively", {
  candidates <- build_npi_candidate_evidence(rbind(
    evidence_pair(npi = "1234567893", roster_middle = "Anne", nppes_middle = "A"),
    evidence_pair(npi = "1999999984", roster_middle = "Anne")))
  parts <- partition_npi_matches(data.frame(source_id = "a"), candidates)
  expect_identical(parts$matches$npi, "1234567893")
})

test_that("contradictory duplicate reference profiles remain review even with an exact row", {
  pairs <- rbind(evidence_pair(), evidence_pair(nppes_first = "John", block_route = "fuzzy"))
  out <- build_npi_candidate_evidence(pairs)
  expect_equal(nrow(out), 1L)
  expect_identical(out$reason, "conflicting_candidate_names")
  expect_identical(out$disposition, "review")
})

test_that("unmatched rows and collision-safe columns preserve the original roster", {
  roster <- data.frame(source_id = c("a", "b"), npi = c("original", "value"),
                       reason = c("source", "reason"))
  map <- c(source_id = "source_id", npi = "npi.1", reason = "reason.1")
  empty <- build_npi_candidate_evidence(evidence_pair()[FALSE, ])
  parts <- partition_npi_matches(roster, empty, result_columns = map)
  expect_identical(parts$unmatched$npi, roster$npi)
  expect_identical(parts$unmatched$reason, roster$reason)
  expect_identical(parts$unmatched$reason.1, rep("no_candidate", 2L))
  expect_identical(parts$unmatched$npi.1, rep(NA_character_, 2L))
  expect_equal(nrow(parts$matches), 0L)
  expect_equal(nrow(parts$review), 0L)
})

test_that("candidate evaluation rejects malformed pairs and unknown source IDs", {
  expect_error(build_npi_candidate_evidence(data.frame(source_id = "a")), "missing")
  candidates <- build_npi_candidate_evidence(evidence_pair("unknown"))
  expect_error(partition_npi_matches(data.frame(source_id = "a"), candidates), "source")
})

test_that("result maps cannot overwrite original roster data", {
  roster <- data.frame(source_id = "a", npi = "original", reason = "original")
  candidates <- build_npi_candidate_evidence(evidence_pair())
  expect_error(partition_npi_matches(roster, candidates,
    result_columns = c(source_id = "source_id", npi = "npi", reason = "reason")),
    "collision-safe")
})

test_that("normalization preserves supported names and numeric NPI becomes character", {
  out <- build_npi_candidate_evidence(evidence_pair(
    npi = 1234567893, roster_first = " Jan\u00e9 ", roster_last = "Sm\u00edth"))
  expect_identical(out$npi, "1234567893")
  expect_identical(out$reason, "exact_name_evidence")
})

test_that("blocked weak evidence is not promoted by an exact route label", {
  out <- build_npi_candidate_evidence(evidence_pair(
    roster_first = "Bob", nppes_first = "Robert", block_route = "exact"))
  expect_identical(out$reason, "nickname_only_evidence")
  expect_identical(out$disposition, "review")
})

test_that("review-only and eligible records claiming one NPI do not create false contention", {
  candidates <- build_npi_candidate_evidence(rbind(evidence_pair("exact"),
    evidence_pair("nick", roster_first = "Bob", nppes_first = "Robert"),
    evidence_pair("fuzzy", nppes_last = "Smyth", block_route = "fuzzy")))
  parts <- partition_npi_matches(data.frame(source_id = c("nick", "exact", "fuzzy")),
                                 candidates)
  expect_identical(parts$matches$source_id, "exact")
  expect_identical(parts$review$source_id, c("nick", "fuzzy"))
})

test_that("missing reference names and incompatible given names remain review", {
  out <- build_npi_candidate_evidence(rbind(
    evidence_pair("absent", nppes_last = NA_character_),
    evidence_pair("given", nppes_first = "Michael")))
  expect_identical(out$reason, c("missing_required_name", "given_name_conflict"))
  expect_identical(out$disposition, rep("review", 2L))
})

test_that("identifier delimiters do not merge unrelated pairs", {
  out <- build_npi_candidate_evidence(rbind(evidence_pair("a;b"), evidence_pair("a")))
  expect_identical(out$source_id, c("a", "a;b"))
  expect_equal(nrow(out), 2L)
})

test_that("missing-name sources are distinct from complete-name no-hit sources", {
  empty <- build_npi_candidate_evidence(evidence_pair()[FALSE, ])
  parts <- partition_npi_matches(data.frame(source_id = c("absent", "complete")), empty,
                                missing_name = c(TRUE, FALSE))
  expect_identical(parts$unmatched$reason, c("missing_required_name", "no_candidate"))
  expect_error(partition_npi_matches(data.frame(source_id = "a"), empty,
                                     missing_name = NA), "missing_name")
  expect_error(partition_npi_matches(data.frame(source_id = "a"), empty,
                                     missing_name = "TRUE"), "missing_name")
  expect_error(partition_npi_matches(data.frame(source_id = "a"), empty,
                                     missing_name = logical()), "missing_name")
  expect_error(partition_npi_matches(data.frame(source_id = "a"),
    build_npi_candidate_evidence(evidence_pair()), missing_name = TRUE), "missing-name")
})

test_that("duplicate route evidence is independent of backend row order", {
  pairs <- rbind(evidence_pair(nppes_first = "Jnae", block_route = "exact"),
                 evidence_pair(nppes_first = "Jnae", block_route = "fuzzy"))
  forward <- build_npi_candidate_evidence(pairs)
  backward <- build_npi_candidate_evidence(pairs[2:1, ])
  expect_identical(forward, backward)
})

test_that("a tied strongest eligible claim contests a second source's unique claim", {
  pairs <- rbind(evidence_pair("a", npi = "1234567893"),
                 evidence_pair("a", npi = "1999999984"),
                 evidence_pair("b", npi = "1234567893"))
  roster <- data.frame(source_id = c("a", "b"))
  forward <- partition_npi_matches(roster, build_npi_candidate_evidence(pairs))
  backward <- partition_npi_matches(roster,
    build_npi_candidate_evidence(pairs[3:1, ]))
  expect_identical(forward, backward)
  expect_equal(nrow(forward$matches), 0L)
  expect_identical(forward$review$source_id, c("a", "b"))
  expect_identical(forward$review$reason,
    c("ambiguous_tied_evidence", "ambiguous_contested_candidate"))
  expect_identical(forward$review$npi, rep(NA_character_, 2L))
})

test_that("eligible alternatives below a source's strongest pool do not contest another match", {
  pairs <- rbind(evidence_pair("a", npi = "1234567893"),
    evidence_pair("a", npi = "1999999984", nppes_first = "J"),
    evidence_pair("b", npi = "1999999984"))
  parts <- partition_npi_matches(data.frame(source_id = c("a", "b")),
                                 build_npi_candidate_evidence(pairs))
  expect_identical(parts$matches$source_id, c("a", "b"))
  expect_identical(parts$matches$npi, c("1234567893", "1999999984"))
  expect_equal(nrow(parts$review), 0L)
})
