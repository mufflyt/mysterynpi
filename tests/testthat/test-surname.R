test_that("exact key equality corroborates, even below the token floor", {
  expect_identical(surname_agreement("LEE", "LEE"), "corroborates")
  expect_identical(surname_agreement("Smith", "SMITH"), "corroborates")
})

test_that("a shared component spans hyphenation and dropped parts", {
  expect_identical(surname_agreement("MCCARTHY-DERVIN", "MCCARTHY"),
                   "corroborates")
  expect_identical(surname_agreement("HARVEY CAPISTA", "CAPISTA"),
                   "corroborates")
})

test_that("particles are convention, not identity", {
  expect_identical(surname_agreement("DE LA CRUZ", "DE LEON"), "conflicts")
  expect_identical(surname_agreement("VAN DYKE", "VAN BUREN"), "conflicts")
})

test_that("surname_agreement uses the same engine as name_surname_match_type", {
  # surname_agreement() used to run its own component/particle logic
  # (surname_tokens(), a 4-character floor) instead of delegating to
  # name_surname_match_type(). The two disagreed on real compound-name
  # patterns: ABU was a stripped particle in the old logic (dropping the
  # only shared component) but a real, retained component in the new one.
  expect_identical(surname_agreement("Abu-Ghazaleh", "Abughazaleh"),
                   "corroborates")
  # a compound surname against the SHORT bare form of one of its parts: the
  # old engine's 4-character component floor dropped "LEE" (3 characters)
  # entirely, so this conflicted even though the surnames plainly share a
  # component. name_surname_match_type()'s 2-character floor does not.
  expect_identical(surname_agreement("Lee-Chen", "Lee"), "corroborates")
})

test_that("apostrophes are formatting, never a veto", {
  expect_identical(surname_agreement("O'BRIEN", "OBRIEN"), "corroborates")
  expect_identical(surname_agreement("D'ANGELO", "DANGELO"), "corroborates")
})

test_that("the maiden-as-middle rescue needs the middles, and uses them", {
  expect_identical(surname_agreement("RYE", "REINHARD"), "conflicts")
  expect_identical(
    surname_agreement("RYE", "REINHARD", middle_a = "REINHARD", middle_b = "A"),
    "corroborates")
  expect_identical(
    surname_agreement("REINHARD", "RYE", middle_a = "A", middle_b = "REINHARD"),
    "corroborates")
  # a middle that holds no surname component rescues nothing
  expect_identical(
    surname_agreement("RYE", "WORKMAN", middle_a = "REINHARD", middle_b = "B"),
    "conflicts")
})

test_that("two recorded surnames sharing nothing conflict", {
  expect_identical(surname_agreement("LEE", "SMITH"), "conflicts")
  expect_identical(surname_agreement("GARCIA", "MARTINEZ"), "conflicts")
})

test_that("absence is uninformative, never a conflict", {
  expect_identical(surname_agreement("", "SMITH"), "uninformative")
  expect_identical(surname_agreement(NA_character_, "SMITH"), "uninformative")
  expect_identical(surname_agreement("", ""), "uninformative")
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(
    surname_agreement(c("LEE", "LEE", ""), c("LEE", "SMITH", "SMITH")),
    c("corroborates", "conflicts", "uninformative"))
  expect_error(surname_agreement(c("A", "B"), "A"), "same length")
  expect_error(surname_agreement("A", "B", middle_a = c("X", "Y")),
               "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_surname_agreement_contract())
  exact_only <- function(a, b, ...) {
    ifelse(toupper(a) == toupper(b), "corroborates", "conflicts")
  }
  expect_error(assert_surname_agreement_contract(exact_only))
})

test_that("a recorded alternate surname rescues a legal name change", {
  # NPPES publishes "Provider Other Last Name" for exactly this: a
  # 2026-09-13 sanction record for Sarah Lynn Martin resolved to NPPES
  # legal name BRASSARD -- same person, surname moved wholesale.
  expect_identical(
    surname_agreement("Brassard", "Martin", alternates_a = "Martin"),
    "corroborates"
  )
  expect_identical(
    surname_agreement("Brassard", "Martin", alternates_b = "Brassard"),
    "corroborates"
  )
  # no alternates supplied: same comparison stays a conflict, never a guess
  expect_identical(surname_agreement("Brassard", "Martin"), "conflicts")
})

test_that("alternates match by component and survive normalisation", {
  # a hyphenated alternate meets the bare component
  expect_identical(
    surname_agreement("Nguyen", "Smith", alternates_a = "Smith-Jones"),
    "corroborates"
  )
  # apostrophes and accents normalise like the surnames themselves
  expect_identical(
    surname_agreement("Miller", "OBrien", alternates_a = "O'Brien"),
    "corroborates"
  )
  # an unrelated alternate does not rescue
  expect_identical(
    surname_agreement("Nguyen", "Smith", alternates_a = "Kowalski"),
    "conflicts"
  )
})

test_that("alternates accept a list of several per record, NA means none", {
  expect_identical(
    surname_agreement(c("Brassard", "Lee"), c("Martin", "Park"),
                      alternates_a = list(c("Old", "Martin"), NA_character_)),
    c("corroborates", "conflicts")
  )
  expect_identical(
    surname_agreement("Brassard", "Martin", alternates_a = NA_character_),
    "conflicts"
  )
  expect_error(
    surname_agreement("A", "B", alternates_a = c("x", "y")),
    "same length"
  )
})

test_that("detail = TRUE names the rule; coarse mode is byte-identical", {
  # Reasons are the MEASURED vocabulary name_surname_match_type() reports
  # plus this rule's two rescues - derived by running the primitives, then
  # pinned (expectations below were observed, not hand-assumed).
  a <- c("MCCARTHY-DERVIN", "LEE", "O'BRIEN", "ABU-GHAZALEH", "BARLOW-REED",
         "DE LA CRUZ", "LEE", "", NA)
  b <- c("MCCARTHY", "LEE", "OBRIEN", "ABUGHAZALEH", "BARLOW REED",
         "DE LEON", "SMITH", "SMITH", "SMITH")
  d <- surname_agreement(a, b, detail = TRUE)
  expect_s3_class(d, "data.frame")
  expect_identical(names(d), c("verdict", "reason"))
  expect_identical(d$verdict, surname_agreement(a, b))   # one decision, two views
  expect_identical(d$reason,
                   c("component_subset", "exact", "exact",
                     "concatenated_equivalent", "separator_equivalent",
                     NA, NA, NA, NA))
  # reason exists ONLY for corroborates
  expect_identical(is.na(d$reason), d$verdict != "corroborates")
})

test_that("the two rescues carry their own reasons", {
  expect_identical(
    surname_agreement("RYE", "REINHARD", middle_a = "REINHARD",
                      middle_b = "A", detail = TRUE),
    data.frame(verdict = "corroborates", reason = "maiden_as_middle",
               stringsAsFactors = FALSE))
  expect_identical(
    surname_agreement("MARTIN", "BRASSARD", alternates_b = "MARTIN",
                      detail = TRUE),
    data.frame(verdict = "corroborates", reason = "alternate_recorded",
               stringsAsFactors = FALSE))
})

test_that("detail is a strict scalar flag; the extended contract holds and can fail", {
  expect_error(surname_agreement("A", "B", detail = NA), "TRUE or FALSE")
  expect_error(surname_agreement("A", "B", detail = c(TRUE, TRUE)), "TRUE or FALSE")
  expect_true(assert_surname_agreement_contract())
  # falsifiability: a stand-in whose detail projection disagrees must be caught
  broken <- function(a, b, ..., detail = FALSE) {
    out <- surname_agreement(a, b, ..., detail = detail)
    if (isTRUE(detail)) out$verdict[1] <- "conflicts"
    out
  }
  expect_error(assert_surname_agreement_contract(broken), "diverge")
  # and a reason outside the declared vocabulary must be caught
  novel <- function(a, b, ..., detail = FALSE) {
    out <- surname_agreement(a, b, ..., detail = detail)
    if (isTRUE(detail)) out$reason[out$verdict == "corroborates"][1] <- "vibes"
    out
  }
  expect_error(assert_surname_agreement_contract(novel), "undeclared reason")
})
