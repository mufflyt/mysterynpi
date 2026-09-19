# Taxonomy identity screen: three-valued, full-string, tie-break rank.

test_that("taxonomy_consistent is three-valued and inspects the FULL string", {
  got <- taxonomy_consistent(
    taxonomy = c("207V00000X|207VX0201X||||",   # OB/GYN: consistent
                 "122300000X||||",              # dentist: wrong person
                 "390200000X|207V00000X|||",    # residency code FIRST, 207V second
                 "||||",                        # no codes on record
                 "207V00000X||||"),             # no expectation defined
    expected = c("207V", "207V", "207V", "207V", NA))
  expect_identical(got, c(TRUE, FALSE, TRUE, NA, NA))
})

test_that("unknown never reads as clean: NA stays NA through the rank", {
  r <- taxonomy_tiebreak_rank(c(TRUE, NA, FALSE))
  expect_identical(r, c(0L, 1L, 2L))
})

test_that("taxonomy_family_pattern returns NA for unknown specialties", {
  expect_identical(taxonomy_family_pattern("Obstetrics & Gynecology"), "207V")
  expect_true(is.na(taxonomy_family_pattern("Underwater Basket Weaving")))
})

test_that("prefix match is startsWith, not substring", {
  # '207V' must not match a code that merely CONTAINS the digits elsewhere.
  expect_false(isTRUE(taxonomy_consistent("X207V0000X||||", "207V")))
  expect_true(taxonomy_consistent("207V0000XX||||", "207V"))
})

test_that("NEGATIVE CONTROL: a screen with no expectation cannot veto", {
  # A dentist code with NO defined expectation must be NA, never FALSE:
  # absence of an expectation is not evidence of a wrong person.
  expect_true(is.na(taxonomy_consistent("122300000X||||", NA_character_)))
})

test_that("rank is for ties only: caller ordering keeps it after stronger axes", {
  # Executable statement of the intended use: sorting by (recency desc,
  # rank asc) never lets a better rank beat better recency.
  d <- data.frame(recency = c(2024L, 2013L), rank = c(2L, 0L), id = c("a", "b"))
  win <- d[order(-d$recency, d$rank), ][1, "id"]
  expect_identical(win, "a")
})
