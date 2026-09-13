test_that("periods are joiners: M.D. is one token, never M, D", {
  # THE DEFECT THIS GUARDS AGAINST: splitting on punctuation turned "M.D."
  # into "M, D" for 1,782 physicians in the 2026-09-13 OpenSanctions
  # Medicaid linkage before periods were stripped ahead of tokenising.
  expect_identical(normalize_credential("M.D."), "MD")
  expect_identical(normalize_credential("D.O."), "DO")
  expect_identical(normalize_credential("M.D., PH.D."), "MD, PHD")
  expect_identical(normalize_credential("R.N., B.S.N."), "RN, BSN")
})

test_that("separators, case, duplicates and hyphens", {
  expect_identical(normalize_credential("md"), "MD")
  expect_identical(normalize_credential("MD/PhD"), "MD, PHD")
  expect_identical(normalize_credential("MD; FACOG"), "MD, FACOG")
  expect_identical(normalize_credential("MD, M.D."), "MD")        # dedupe
  expect_identical(normalize_credential("NP-C"), "NP-C")          # hyphen kept
  expect_identical(normalize_credential("  M.D.  "), "MD")
})

test_that("unknown credentials pass through instead of being dropped", {
  expect_identical(normalize_credential("XYZQ"), "XYZQ")
  expect_identical(normalize_credential("MD, XYZQ"), "MD, XYZQ")
})

test_that("absence is empty string, never NA, and vectorisation holds", {
  expect_identical(normalize_credential(NA_character_), "")
  expect_identical(normalize_credential(""), "")
  expect_identical(normalize_credential("   "), "")
  expect_identical(normalize_credential(c("M.D.", NA, "do")),
                   c("MD", "", "DO"))
  expect_identical(normalize_credential(character(0)), character(0))
})
