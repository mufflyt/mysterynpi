test_that("one-to-one resolver chooses the unique best candidate per record", {
  candidates <- data.frame(
    id = c("A", "A", "B"),
    candidate = c("n1", "n2", "n3"),
    priority = c(1L, 2L, 1L),
    score = c(80, 100, 75),
    stringsAsFactors = FALSE
  )

  result <- resolve_one_to_one(
    candidates,
    rank_by = c(priority = "asc", score = "desc")
  )

  expect_identical(result$resolved$id, c("A", "B"))
  expect_identical(result$resolved$candidate, c("n1", "n3"))
  expect_equal(nrow(result$quarantined), 0L)
})

test_that("ties and cross-record candidate claims are quarantined", {
  candidates <- data.frame(
    id = c("A", "A", "B", "D", "C", "C"),
    candidate = c("n1", "n2", "n1", "n1", "n4", "n5"),
    priority = c(1L, 1L, 1L, 1L, 1L, 2L),
    stringsAsFactors = FALSE
  )

  result <- resolve_one_to_one(
    candidates,
    rank_by = c(priority = "asc")
  )

  expect_identical(result$resolved$id, "C")
  expect_identical(result$resolved$candidate, "n4")
  expect_setequal(
    paste(result$quarantined$id, result$quarantined$resolution_status),
    c("A ambiguous_tied_evidence", "A ambiguous_tied_evidence",
      "B ambiguous_contested_candidate", "D ambiguous_contested_candidate")
  )
})

test_that("duplicate evidence rows for one pair do not create a false tie", {
  candidates <- data.frame(
    id = c("A", "A", "A"),
    candidate = c("n1", "n1", "n2"),
    priority = c(1L, 1L, 2L),
    score = c(90, 90, 100),
    evidence = c("z_registry", "a_registry", "secondary"),
    stringsAsFactors = FALSE
  )

  result <- resolve_one_to_one(
    candidates,
    rank_by = c(priority = "asc", score = "desc")
  )

  expect_identical(result$resolved$candidate, "n1")
  expect_equal(nrow(result$resolved), 1L)
  expect_identical(result$resolved$evidence, "a_registry")
})

test_that("resolution is invariant to candidate row order", {
  candidates <- data.frame(
    id = c("A", "A", "B", "C"),
    candidate = c("n1", "n2", "n1", "n4"),
    priority = c(1L, 2L, 1L, 1L),
    score = c(80, 100, 75, 70),
    stringsAsFactors = FALSE
  )

  forward <- resolve_one_to_one(
    candidates,
    rank_by = c(priority = "asc", score = "desc")
  )
  reverse <- resolve_one_to_one(
    candidates[nrow(candidates):1, ],
    rank_by = c(priority = "asc", score = "desc")
  )

  expect_identical(forward$resolved$id, reverse$resolved$id)
  expect_identical(forward$resolved$candidate, reverse$resolved$candidate)
  expect_identical(
    forward$quarantined[, c("id", "candidate", "resolution_status")],
    reverse$quarantined[, c("id", "candidate", "resolution_status")]
  )
})

test_that("resolver rejects missing columns and invalid ranking directions", {
  candidates <- data.frame(id = "A", candidate = "n1", priority = 1L)

  expect_error(
    resolve_one_to_one(candidates, id = "missing", rank_by = c(priority = "asc")),
    "missing"
  )
  expect_error(
    resolve_one_to_one(candidates, rank_by = c(priority = "sideways")),
    "asc.*desc"
  )
  expect_error(
    resolve_one_to_one(
      transform(candidates, id = NA_character_),
      rank_by = c(priority = "asc")
    ),
    "identifiers must be present"
  )
})

test_that("missing candidate IDs are unmatched, not contested identities", {
  candidates <- data.frame(
    id = c("A", "B"), candidate = NA_character_, priority = c(1L, 1L),
    stringsAsFactors = FALSE
  )

  result <- resolve_one_to_one(candidates, rank_by = c(priority = "asc"))

  expect_equal(nrow(result$resolved), 0L)
  expect_equal(nrow(result$quarantined), 0L)
  expect_identical(result$unmatched$id, c("A", "B"))
  expect_true(all(result$unmatched$resolution_status == "no_candidate"))
})
