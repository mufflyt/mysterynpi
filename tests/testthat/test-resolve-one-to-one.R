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

eligibility_fixture <- function() {
  data.frame(
    id = c("A", "B", "C", "D", "E"),
    candidate = c("n1", "n1", "n2", "n2", "n3"),
    priority = 1L,
    in_cohort = c(TRUE, FALSE, TRUE, TRUE, FALSE),
    stringsAsFactors = FALSE
  )
}

test_that("an ineligible record cannot quarantine an eligible record's candidate", {
  result <- resolve_one_to_one(eligibility_fixture(), rank_by = c(priority = "asc"),
                               eligible = "in_cohort")
  expect_setequal(paste(result$resolved$id, result$resolved$candidate),
                  c("A n1", "E n3"))
  expect_setequal(
    paste(result$quarantined$id, result$quarantined$resolution_status),
    c("B yielded_to_eligible", "C ambiguous_contested_candidate",
      "D ambiguous_contested_candidate")
  )
  expect_identical(result$counts[["resolved"]], 2L)
  expect_identical(result$counts[["quarantined"]], 3L)
})

test_that("negative control: without eligible the namesake quarantines both", {
  result <- resolve_one_to_one(eligibility_fixture(), rank_by = c(priority = "asc"))
  expect_false("A" %in% result$resolved$id)
  expect_true(all(c("A", "B") %in% result$quarantined$id))
})

test_that("all-eligible input gives the same answer as no eligible column", {
  x <- eligibility_fixture()
  x$in_cohort <- TRUE
  with_flag <- resolve_one_to_one(x, rank_by = c(priority = "asc"), eligible = "in_cohort")
  without <- resolve_one_to_one(x, rank_by = c(priority = "asc"))
  expect_identical(with_flag$resolved, without$resolved)
  expect_identical(with_flag$counts, without$counts)
})

test_that("table output is the resolved frame carrying the rest as attributes", {
  args <- list(eligibility_fixture(), rank_by = c(priority = "asc"), eligible = "in_cohort")
  as_list <- do.call(resolve_one_to_one, args)
  as_table <- do.call(resolve_one_to_one, c(args, output = "table"))
  expect_s3_class(as_table, "data.frame")
  expect_identical(as.data.frame(as_table)[, names(as_list$resolved)], as_list$resolved)
  expect_identical(attr(as_table, "quarantined"), as_list$quarantined)
  expect_identical(attr(as_table, "unmatched"), as_list$unmatched)
  expect_identical(attr(as_table, "counts"), as_list$counts)
})

test_that("eligible is validated", {
  x <- eligibility_fixture()
  rk <- c(priority = "asc")
  expect_error(resolve_one_to_one(x, rank_by = rk, eligible = "nope"), "must name one column")
  expect_error(resolve_one_to_one(x, rank_by = rk, eligible = "priority"), "cannot also be")
  x$in_cohort[1] <- NA
  expect_error(resolve_one_to_one(x, rank_by = rk, eligible = "in_cohort"), "no NA")
  y <- rbind(eligibility_fixture(), data.frame(id = "A", candidate = "n9", priority = 2L,
                                               in_cohort = FALSE))
  expect_error(resolve_one_to_one(y, rank_by = rk, eligible = "in_cohort"), "constant within")
  expect_error(resolve_one_to_one(x, rank_by = rk, output = "tibble"))
})
