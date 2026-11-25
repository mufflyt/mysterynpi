test_that("npi_match_evidence uses canonical surname and given-name rules", {
  ev <- npi_match_evidence("R", "Smith", "Robert", "Smith",
                           roster_state = "co", candidate_state = "CO",
                           roster_city = "St. Mary", candidate_city = "St Mary")
  expect_identical(ev$surname_verdict, "corroborates")
  expect_identical(ev$given_verdict, "corroborates")
  expect_identical(ev$given_reason, "initial")
  expect_identical(ev$state_verdict, "corroborates")
  expect_identical(ev$city_verdict, "corroborates")
})

test_that("npi_match_evidence keeps absence uninformative", {
  ev <- npi_match_evidence(NA_character_, "Smith", "John", "Smith")
  expect_identical(ev$given_verdict, "uninformative")
  expect_identical(ev$state_verdict, "uninformative")
  expect_identical(ev$city_verdict, "uninformative")
})

test_that("npi_match_evidence refuses mispaired identity vectors", {
  expect_error(
    npi_match_evidence(c("A", "B"), "Smith", "A", "Smith"),
    "same length"
  )
  expect_error(
    npi_match_evidence("A", "Smith", "A", "Smith", roster_state = "CO"),
    "both be NULL|same length"
  )
})

test_that("grade high requires tier 1, state, surname, and exact-or-initial given evidence", {
  exact <- npi_match_evidence("John", "Smith", "John", "Smith",
                              roster_state = "CO", candidate_state = "CO")
  expect_identical(as.character(grade_npi_match_confidence(exact, query_tier = 1)), "high")

  initial <- npi_match_evidence("J", "Smith", "John", "Smith",
                                roster_state = "CO", candidate_state = "CO")
  expect_identical(as.character(grade_npi_match_confidence(initial, query_tier = 1)), "high")

  tier2 <- grade_npi_match_confidence(exact, query_tier = 2)
  expect_identical(as.character(tier2), "medium")
})

test_that("full names sharing only a first letter do not receive initial credit", {
  ev <- npi_match_evidence("John", "Smith", "James", "Smith",
                           roster_state = "CO", candidate_state = "CO")
  expect_identical(ev$given_verdict, "conflicts")
  # State corroboration is still medium, but there is no high-grade initial path.
  expect_identical(as.character(grade_npi_match_confidence(ev, query_tier = 1)), "medium")
})

test_that("grade medium uses exact given or geography; surname-only is low", {
  exact_given <- npi_match_evidence("John", "Smith", "John", "Smith")
  expect_identical(as.character(grade_npi_match_confidence(exact_given, query_tier = 2)), "medium")

  geography <- npi_match_evidence("John", "Smith", "James", "Smith",
                                  roster_city = "Denver", candidate_city = "Denver")
  expect_identical(as.character(grade_npi_match_confidence(geography, query_tier = 2)), "medium")

  surname_only <- npi_match_evidence("John", "Smith", "James", "Smith")
  expect_identical(as.character(grade_npi_match_confidence(surname_only, query_tier = 2)), "low")
})

test_that("ambiguous and unmatched are dispositions, not evidence strengths", {
  ev <- npi_match_evidence("John", "Smith", "John", "Smith",
                           roster_state = "CO", candidate_state = "CO")
  expect_identical(as.character(grade_npi_match_confidence(ev, query_tier = 1, ambiguous = TRUE)), "ambiguous")
  expect_identical(as.character(grade_npi_match_confidence(ev, query_tier = 1, matched = FALSE)), "unmatched")

  no_surname <- npi_match_evidence("John", "Smith", "John", "Jones")
  expect_identical(as.character(grade_npi_match_confidence(no_surname, query_tier = 1)), "unmatched")
})

test_that("grade is vectorized and scalar-safe but rejects bad lengths", {
  ev <- npi_match_evidence(c("John", "John"), c("Smith", "Smith"),
                           c("John", "James"), c("Smith", "Smith"))
  out <- grade_npi_match_confidence(ev, query_tier = c(2, 2))
  expect_length(out, 2L)
  expect_identical(as.character(out), c("medium", "low"))
  expect_error(grade_npi_match_confidence(ev, query_tier = c(1, 2, 3)), "length 1|number of evidence rows")
})

test_that("taxonomy allowlist sees codes anywhere in the pipe-concatenated string", {
  expect_true(taxonomy_allowlist_consistent(
    "390200000X|208800000X", c("208800000X", "2088F0040X")
  ))
  expect_false(taxonomy_allowlist_consistent("207Q00000X", c("208800000X")))
  expect_true(is.na(taxonomy_allowlist_consistent(NA_character_, c("208800000X"))))
  expect_error(taxonomy_allowlist_consistent("208800000X", character(0)), "non-empty")
})
