test_that("surname components drop particles and short tokens", {
  expect_identical(surname_tokens("Schrader-Patterson"), c("SCHRADER", "PATTERSON"))
  expect_identical(surname_tokens("De La Cruz"), "CRUZ")
  expect_identical(surname_tokens("De Leon"), "LEON")
  expect_identical(surname_tokens("Van Der Berg"), "BERG")
  expect_length(surname_tokens("De La"), 0)      # all particles
  expect_length(surname_tokens(NA_character_), 0)
  expect_identical(MIN_SURNAME_TOKEN, 4L)        # pinned by value
})

test_that("middle tokens keep initials; given tokens drop them", {
  expect_identical(middle_tokens("BETH HARVEY")[[1]], c("BETH", "HARVEY"))
  expect_identical(middle_tokens("H")[[1]], "H")
  expect_identical(given_tokens("W. Jon")[[1]], "JON")
})

test_that("person matching needs a surname AND a shared full given token", {
  g <- function(...) given_tokens(c(...))
  expect_true(person_matches("SMITH", g("MARY ANNE"), "SMITH", g("ANNE ELIZABETH")))
  expect_false(person_matches("SMITH", g("MARY"), "SMITH", g("JANE")))
  expect_false(person_matches("SMITH", g("MARY"), "JONES", g("MARY")))
  expect_false(person_matches("", g("MARY"), "", g("MARY")))
})

test_that("a hyphen never splits a given- or middle-name token", {
  # THE DEFECT: given_tokens()/middle_tokens() split on "-" like any other
  # delimiter, so a genuinely compound name ("Mary-Jane", "Anne-Marie") -- ONE
  # name, exactly like split_given() already treats it -- broke into two
  # separate tokens. Because person_matches()/middle_agreement() corroborate
  # on ANY shared token, that let a compound name satisfy a match against an
  # unrelated person sharing only the SECOND half of the compound:
  # person_matches("SMITH", given_tokens("Mary-Jane"), "SMITH",
  # given_tokens("Jane")) returned TRUE, and middle_agreement() on
  # "Anne-Marie" vs the unrelated "Marie" returned "corroborates".
  expect_identical(given_tokens("Mary-Jane")[[1]], "MARY-JANE")
  expect_identical(middle_tokens("Anne-Marie")[[1]], "ANNE-MARIE")

  expect_false(person_matches("SMITH", given_tokens("Mary-Jane"),
                              "SMITH", given_tokens("Jane")))
  expect_identical(
    middle_agreement(middle_tokens("Anne-Marie"), middle_tokens("Marie")),
    "conflicts")

  # the same compound name on both sides still matches
  expect_true(person_matches("SMITH", given_tokens("Mary-Jane"),
                             "SMITH", given_tokens("Mary-Jane")))
  # a genuinely space-separated given+middle combination still splits
  expect_identical(given_tokens("Julie Ann")[[1]], c("JULIE", "ANN"))
})
