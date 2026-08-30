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
