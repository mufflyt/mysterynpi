test_that("a person's own professional corporation matches them", {
  # The pattern behind all 14 name "mismatches" among NPPES-corroborated
  # NPIs in the 2026-09-13 Medicaid exclusion linkage.
  expect_true(org_name_matches_person("NADINE H. YASSA, M.D., INC.",
                                      "Nadine H. Yassa"))
  expect_true(org_name_matches_person("KEVIN PEZESHKI MD INC",
                                      "Kevin Pezeshki"))
  expect_true(org_name_matches_person("CHARLES W. CHIDSEY III, M.D., A PROFESSIONAL CORPORATION",
                                      "Charles Wellington Chidsey III"))
  expect_true(org_name_matches_person("FOSTER UROLOGY CLINIC",
                                      "Lionel Sidney Foster"))
})

test_that("an unrelated organization does not match", {
  expect_false(org_name_matches_person("QUALITY HOME SERVICES MEDICAL CORPORATION",
                                       "Stephen Meis"))
  expect_false(org_name_matches_person("ECHO PARK PHARMACY",
                                       "Tarek Mohammad Ebrahim"))
})

test_that("corporate form and credentials alone are never a match", {
  # a side that reduces entirely to noise has nothing to compare: NA, never
  # TRUE (shared corporate tokens must not corroborate) and never FALSE
  # (absence of identity is not evidence of a different identity)
  expect_identical(org_name_matches_person("MEDICAL GROUP INC", "J. MD"), NA)
  expect_identical(org_name_matches_person("THE CLINIC LLC", "Dr Smith"), NA)
  expect_identical(org_name_matches_person("SMITH MEDICAL GROUP", "Dr Smith"), TRUE)
})

test_that("a surname colliding with a credential token still carries the org's identity", {
  # THE DEFECT: .identity_tokens() used to strip NAME_NOISE with a bare
  # setdiff() on the already-uppercased string, so a practice literally
  # named after the physician's own "DO"-colliding surname (the Vietnamese
  # surname "Do", vs. the Doctor of Osteopathic Medicine credential -- see
  # strip_name_noise()'s DO carve-out) lost its only shared identity token.
  # org_name_matches_person("Do Family Medicine Clinic", "Anh Do") returned
  # FALSE before this fix.
  expect_true(org_name_matches_person("Do Family Medicine Clinic", "Anh Do"))
  expect_true(org_name_matches_person("Do, Anh, M.D., INC.", "Anh Do"))
  # the control case (a non-colliding surname in the identical structure)
  # already worked and must keep working
  expect_true(org_name_matches_person("Nguyen Family Medicine Clinic",
                                      "Anh Nguyen"))
})

test_that("hyphens fold for the org comparison, accents transliterate", {
  expect_true(org_name_matches_person("ABBAS-RODRIGUEZ MEDICAL GROUP",
                                      "Maria Abbas Rodriguez"))
  expect_true(org_name_matches_person("MUNOZ FAMILY PRACTICE", "José Muñoz"))
})

test_that("absence and length are handled", {
  expect_identical(org_name_matches_person(NA_character_, "Jane Doe"), NA)
  expect_identical(org_name_matches_person("", "Jane Doe"), NA)
  expect_identical(
    org_name_matches_person(c("YASSA MD INC", "ECHO PARK PHARMACY"),
                            c("Nadine Yassa", "Tarek Ebrahim")),
    c(TRUE, FALSE)
  )
  expect_error(org_name_matches_person("A B", c("x", "y")), "same length")
})
