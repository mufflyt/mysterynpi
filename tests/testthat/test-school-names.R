# strip_med_suffix(): each expectation below is a string that came out wrong
# in a real pipeline (midwifery's CMS DAC and Trilliant directory school
# fields, 2026-09-13) before the rule that fixes it existed.

test_that("a trailing medical unit is removed and the university kept", {
  expect_identical(strip_med_suffix("GEORGETOWN UNIVERSITY SCHOOL OF MEDICINE"),
                   "GEORGETOWN UNIVERSITY")
  expect_identical(strip_med_suffix("UNIVERSITY OF MICHIGAN MEDICAL SCHOOL"),
                   "UNIVERSITY OF MICHIGAN")
  expect_identical(strip_med_suffix("STATE UNIVERSITY OF NEW YORK AT STONY BROOK, SCHOOL OF MEDICINE"),
                   "STATE UNIVERSITY OF NEW YORK AT STONY BROOK")
  expect_identical(strip_med_suffix("UNIVERSITY OF ILLINOIS COLLEGE OF MED (CHI/PEOR/ROCK/CHM-URB)"),
                   "UNIVERSITY OF ILLINOIS")
})

test_that("the longest phrase wins, so no fragment of a longer one is left", {
  expect_identical(strip_med_suffix("UNIVERSITY OF FLORIDA COLLEGE OF MEDICINE"),
                   "UNIVERSITY OF FLORIDA")
  expect_identical(strip_med_suffix("UNIVERSITY OF ROCHESTER SCHOOL OF MEDICINE AND DENTISTRY"),
                   "UNIVERSITY OF ROCHESTER")
})

test_that("a named school of a university gives the university, not the school's name", {
  expect_identical(strip_med_suffix("BRODY SCHOOL OF MEDICINE AT EAST CAROLINA UNIVERSITY"),
                   "EAST CAROLINA UNIVERSITY")
  expect_identical(strip_med_suffix("PERELMAN SCHOOL OF MED AT THE UNIVERSITY OF PENNSYLVANIA"),
                   "UNIVERSITY OF PENNSYLVANIA")
  expect_identical(strip_med_suffix("JEFFERSON MEDICAL COLLEGE OF THOMAS JEFFERSON UNIVERSITY"),
                   "THOMAS JEFFERSON UNIVERSITY")
  expect_identical(strip_med_suffix("SANFORD SCHOOL OF MEDICINE OF UNIVERSITY OF SOUTH DAKOTA"),
                   "UNIVERSITY OF SOUTH DAKOTA")
  expect_identical(strip_med_suffix("JC EDWARDS SCHOOL OF MEDICINE, MARSHALL UNIVERSITY"),
                   "MARSHALL UNIVERSITY")
})

test_that("a strip that would leave no institution is refused", {
  # Each of these is an institution whose name IS the medical phrase. The
  # version this was extracted from returned BAYLOR, OHIO and PHILADELPHIA.
  for (s in c("BAYLOR COLLEGE OF MEDICINE", "OHIO MEDICAL UNIVERSITY",
              "PHILADELPHIA COLLEGE OF OSTEOPATHIC MEDICINE",
              "ATLANTA SCHOOL OF MEDICINE"))
    expect_identical(strip_med_suffix(s), s)
  # ...but one refused step does not refuse the others.
  expect_identical(strip_med_suffix("MEHARRY MEDICAL COLLEGE SCHOOL OF MEDICINE"),
                   "MEHARRY MEDICAL COLLEGE")
})

test_that("a phrase that opens the name is never taken for a suffix", {
  expect_identical(strip_med_suffix("MEDICAL UNIVERSITY OF SOUTH CAROLINA COLLEGE OF MEDICINE"),
                   "MEDICAL UNIVERSITY OF SOUTH CAROLINA")
  expect_identical(strip_med_suffix("SCHOOL OF MEDICINE"), "SCHOOL OF MEDICINE")
})

test_that("matching ignores case and the result keeps the input's case", {
  expect_identical(strip_med_suffix("Georgetown University School of Medicine"),
                   "Georgetown University")
  expect_identical(strip_med_suffix("Brody School of Medicine at East Carolina University"),
                   "East Carolina University")
})

test_that("NA stays NA, names with no unit are untouched, and length is kept", {
  expect_identical(strip_med_suffix(c(NA, "FRONTIER NURSING UNIVERSITY", "")),
                   c(NA, "FRONTIER NURSING UNIVERSITY", ""))
  expect_identical(strip_med_suffix(NA), NA_character_)
  expect_identical(strip_med_suffix(character(0)), character(0))
  expect_identical(strip_med_suffix(factor("YALE UNIVERSITY SCHOOL OF MEDICINE")),
                   "YALE UNIVERSITY")
  expect_error(strip_med_suffix(42), "character")
})

test_that("the CMS corpus: every distinct school string, pinned", {
  # 88 distinct strings: the CMS Doctors and Clinicians medical-school field
  # for nurse-midwives, plus the same field as a commercial directory carries
  # it. Public institution names, no person data.
  fix <- read.csv(testthat::test_path("fixtures", "cms_medical_school_names.csv"),
                  comment.char = "#", colClasses = "character")
  expect_identical(strip_med_suffix(fix$raw), fix$institution)
})

test_that("stripping is idempotent", {
  fix <- read.csv(testthat::test_path("fixtures", "cms_medical_school_names.csv"),
                  comment.char = "#", colClasses = "character")
  once <- strip_med_suffix(fix$raw)
  expect_identical(strip_med_suffix(once), once)
})

test_that("the unit list is longest-first", {
  # A phrase that begins another, longer phrase must come after it, or the
  # shorter one matches first and leaves a fragment ("COLLEGE OF MED" + "INE").
  p <- MEDICAL_UNIT_PATTERNS
  for (i in seq_along(p)) for (j in seq_along(p)) if (i < j)
    expect_false(startsWith(p[j], p[i]) && nchar(p[j]) > nchar(p[i]),
                 label = sprintf("'%s' listed before the longer '%s'", p[i], p[j]))
})
