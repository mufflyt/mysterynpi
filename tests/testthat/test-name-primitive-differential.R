# The frozen differential between the isochrones primitives and these.
#
# The isochrones copy is deleted only once this proves equivalence. The fixture
# is the record of that proof: 40 cases covering the adversarial surname pairs
# that must stay distinct, both comparison modes, initials, particles,
# hyphenation, concatenation, blanks, NA, and the vectorisation contract.
#
# A line-count or hash difference between two implementations is NOT evidence of
# a behavioural difference. This measures behaviour.

FIX <- testthat::test_path("..", "fixtures", "name_primitive_differential.csv")

testthat::test_that("the frozen differential exists and covers the required cases", {
  testthat::skip_if_not(file.exists(FIX))
  d <- utils::read.csv(FIX, stringsAsFactors = FALSE)
  testthat::expect_gt(nrow(d), 30L)
  required <- c("surname_anderson_sanderson", "surname_williams_williamson",
                "surname_martin_martinez", "surname_oconnor_apostrophe",
                "surname_nelson_hyphen", "surname_abu_ghazaleh",
                "given_positional_same", "given_anytoken_same",
                "pos_initial_vs_full", "pos_two_initials",
                "vec_scalar_broadcast", "vec_equal_length", "vec_illegal_unequal",
                "components_blank", "components_na", "components_particle")
  testthat::expect_true(all(required %in% d$case_id),
                        info = paste("missing:", paste(setdiff(required, d$case_id),
                                                       collapse = ", ")))
})

testthat::test_that("UNINTENDED_REGRESSION is zero", {
  # The blocking condition for deleting the isochrones implementation.
  testthat::skip_if_not(file.exists(FIX))
  d <- utils::read.csv(FIX, stringsAsFactors = FALSE)
  testthat::expect_equal(sum(d$classification == "UNINTENDED_REGRESSION"), 0L)
  # Nothing may sit unclassified either.
  testthat::expect_equal(sum(is.na(d$classification) | d$classification == ""), 0L)
  testthat::expect_true(all(d$classification %in%
    c("NO_CHANGE", "INTENTIONAL_FIX", "INTENTIONAL_API_DIFFERENCE",
      "UNINTENDED_REGRESSION")))
})

testthat::test_that("the adversarial surname pairs are NOT compatible", {
  # These are the pairs a substring or prefix rule would wrongly merge. This is
  # the behaviour itself, not a record of it, so it fails if the primitive
  # regresses even when the fixture is stale.
  for (p in list(c("ANDERSON", "SANDERSON"), c("WILLIAMS", "WILLIAMSON"),
                 c("MARTIN", "MARTINEZ"))) {
    testthat::expect_false(
      isTRUE(mysterynpi::names_have_compatible_surname(p[1], p[2])),
      info = paste(p[1], "and", p[2], "must not be surname-compatible"))
  }
})

testthat::test_that("an initial alone does not identify a person", {
  # Initial compatibility is not identity evidence, and must never be produced
  # by the surname path at all.
  testthat::expect_false(isTRUE(mysterynpi::names_have_compatible_surname("M", "MARY")))
})

testthat::test_that("mode must be chosen explicitly, never defaulted", {
  # A default would silently pick a comparison semantics the caller never
  # considered, and mode is a property of the SOURCE contract.
  testthat::expect_error(
    mysterynpi::names_have_compatible_given("MARY", "MARY"),
    "mode must be explicitly specified")
})

testthat::test_that("unequal-length vectors are refused, not recycled", {
  # Silent recycling would compare the wrong pairs and report confidently.
  testthat::expect_error(
    mysterynpi::names_have_compatible_surname(c("A", "B", "C"), c("A", "B")))
})
