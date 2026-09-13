skip_if_not_installed("humaniformat")

test_that("a parenthesised alternate never lands in a name slot", {
  # humaniformat alone returns last = "(Pollack)" and middle = "(NMN)".
  p <- parse_person(c("Ann M. Barbaccia (Pollack), M.D.",
                      "Samuel (NMN) Anaya, M.D.",
                      "Thomas (Tuan-Tong) Lee, M.D."))
  expect_identical(p$first,  c("ANN", "SAMUEL", "THOMAS"))
  expect_identical(p$last,   c("BARBACCIA", "ANAYA", "LEE"))
  expect_identical(p$middle, c("M", "", ""))
})

test_that("a credential comma is not read as a Last, First reversal", {
  # THE DEFECT: testing the RAW string for a comma turned this into
  # first "M", middle "BARBACCIA", surname "ANN".
  p <- parse_person("Ann M. Barbaccia, M.D.")
  expect_identical(p$first, "ANN")
  expect_identical(p$last,  "BARBACCIA")
})

test_that("a genuine Last, First IS reversed", {
  p <- parse_person(c("Mróz, Jan", "Smith, Mary Anne"))
  expect_identical(p$first, c("JAN", "MARY"))
  expect_identical(p$last,  c("MROZ", "SMITH"))
})

test_that("credential stripping cannot truncate an accented surname", {
  # \\bMr\\b matched INSIDE "Mróz" and returned a surname of "OZ".
  expect_identical(strip_name_noise("Mróz"), "Mróz")
  expect_identical(parse_person("Jan Mróz")$last, "MROZ")
  expect_identical(parse_person("Álvarez, María")$last, "ALVAREZ")
})

test_that("credentials and titles are removed, names that look like them are not", {
  expect_identical(strip_name_noise("Jane Doe, CNM, MSN"), "Jane Doe")
  expect_identical(strip_name_noise("Dr. Jane Doe"), "Jane Doe")
  expect_identical(parse_person("Jane Doe, CNM")$last, "DOE")
  # "Ms" is noise; "Mason" is not -- token matching, never substring
  expect_identical(parse_person("Ms Erin Mason")$last, "MASON")
})

test_that("absent parts are empty strings, never NA", {
  p <- parse_person(c("Cher", NA_character_, ""))
  expect_false(any(is.na(unlist(p))))
  expect_false(has_name_information(p$last[1]))
})

test_that("it errors clearly when humaniformat is unavailable", {
  expect_true(is.function(parse_person))   # contract documented in ?parse_person
})

test_that("format = 'surname_first' handles comma-less reversed rosters", {
  # New York's Medicaid exclusion list publishes "FINCH SHANNON" -- surname
  # first, no comma. Nothing in the string can reveal that; the caller
  # declares it.
  p <- parse_person(c("FINCH SHANNON", "MULLINGS CLAUDETTE"),
                    format = "surname_first")
  expect_identical(p$last, c("FINCH", "MULLINGS"))
  expect_identical(p$first, c("SHANNON", "CLAUDETTE"))
  # LAST FIRST MIDDLE: the tail parses as given + middle
  p3 <- parse_person("FINCH SHANNON MARIE", format = "surname_first")
  expect_identical(p3$last, "FINCH")
  expect_identical(p3$first, "SHANNON")
  expect_identical(p3$middle, "MARIE")
})

test_that("surname_first consumes leading particles into the surname", {
  p <- parse_person("DE LA CRUZ JUAN", format = "surname_first")
  expect_identical(p$last, "DE LA CRUZ")
  expect_identical(p$first, "JUAN")
})

test_that("surname_first composes with credentials, commas, and absence", {
  # credentials are stripped by the same pipeline
  expect_identical(parse_person("FINCH SHANNON RN",
                                format = "surname_first")$last, "FINCH")
  # a string that already carries a comma is left to the comma logic
  expect_identical(parse_person("FINCH, SHANNON",
                                format = "surname_first")$first, "SHANNON")
  # single tokens and absence behave exactly as the default format
  p <- parse_person(c("Cher", NA_character_, ""), format = "surname_first")
  expect_false(any(is.na(unlist(p))))
  expect_identical(p$first[1], "CHER")
})

test_that("the default format is unchanged", {
  expect_identical(parse_person("FINCH SHANNON")$last, "SHANNON")
  expect_identical(parse_person("Jan Mróz")$last, "MROZ")
})
