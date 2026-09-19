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

test_that("all-provider-type credentials are stripped -- 2026-09-13 additions", {
  # From the OpenSanctions Medicaid exclusion linkage (8,450 sanctioned
  # individuals of every provider type): DC 314, DDS 248, LPN 130, DPM 114,
  # DMD 101, PA 73. None were in NAME_NOISE, so each sailed through into a
  # parsed name slot.
  expect_identical(strip_name_noise("Jane Doe, D.D.S."), "Jane Doe")
  expect_identical(strip_name_noise("Jane Doe DMD"), "Jane Doe")
  expect_identical(strip_name_noise("John Roe, D.C."), "John Roe")
  expect_identical(strip_name_noise("John Roe DPM"), "John Roe")
  expect_identical(strip_name_noise("Ann Poe, LPN"), "Ann Poe")
  expect_identical(strip_name_noise("Ann Poe, PA-C"), "Ann Poe")
  expect_identical(strip_name_noise("Ann Poe, Pharm.D."), "Ann Poe")
  expect_identical(parse_person("Jane Doe, D.D.S.")$last, "DOE")
  expect_identical(parse_person("John Roe, O.D.")$last, "ROE")
  # token matching still protects real names that contain a credential
  expect_identical(parse_person("Dana Odell")$last, "ODELL")
  expect_identical(parse_person("Paul Paxton")$last, "PAXTON")
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

test_that("the 'Do' surname is protected from the DO credential, given-first", {
  # THE DEFECT: strip_name_noise("Anh Do") returned "Anh" -- the surname was
  # deleted as the DO credential, which then read as unqueryable downstream
  # (has_name_information() on an empty last name is FALSE) and silently
  # dropped the record. Found in an isochrones consumer of this package
  # (resolve_dea_action_to_npi()) whose DEA-action records for practitioners
  # actually named "Do" were vanishing before ever reaching NPI lookup.
  expect_identical(strip_name_noise("Anh Do"), "Anh Do")
  expect_identical(strip_name_noise("Linda Do"), "Linda Do")
  expect_identical(strip_name_noise("Nguyen Van Do"), "Nguyen Van Do")
  expect_identical(parse_person("Anh Do")$last, "DO")
  expect_identical(parse_person("Linda Do")$last, "DO")
  expect_identical(parse_person("Nguyen Van Do")$last, "VAN DO")
  expect_true(has_name_information(parse_person("Anh Do")$last))
})

test_that("the 'Do' surname is protected surname-first, including with a trailing credential", {
  # Segment-scoped, not string-scoped: "Do, Anh, M.D." protects the one-token
  # "Do" segment even though the credential segment "M.D." brings the WHOLE
  # string's token count to three.
  expect_identical(strip_name_noise("Do, Anh"), "Do Anh")
  expect_identical(strip_name_noise("Do, Anh, M.D."), "Do Anh")
  expect_identical(parse_person("Do, Anh")$last, "DO")
  expect_identical(parse_person("Do, Anh, M.D.")$last, "DO")
  # reverses to "Nguyen Van Do"; humaniformat's own multi-token surname
  # grouping (unrelated to this carve-out) reads the last two tokens as one
  # compound surname, same as parsing "Nguyen Van Do" directly would.
  expect_identical(parse_person("Do, Nguyen Van")$last, "VAN DO")
})

test_that("the DO credential is still stripped -- the carve-out narrows NAME_NOISE, it does not widen it", {
  expect_identical(strip_name_noise("John Smith DO"), "John Smith")
  expect_identical(strip_name_noise("John Michael Smith DO"), "John Michael Smith")
  expect_identical(strip_name_noise("John Smith D.O."), "John Smith")
  expect_identical(strip_name_noise("Smith, John, MD"), "Smith John")
  expect_identical(parse_person("John Smith DO")$last, "SMITH")
  expect_identical(parse_person("John Michael Smith DO")$last, "SMITH")
  expect_false(grepl("DO", parse_person("John Smith DO")$last, fixed = TRUE))
})

test_that("the 'Ma' surname is protected from the MA (Master of Arts) credential", {
  # THE DEFECT: strip_name_noise("John Ma") returned "John" -- the same
  # silent-drop failure mode as the pre-fix "Do" case, for a common Chinese
  # surname (Yo-Yo Ma, Jack Ma) that carried none of "Do"'s protection
  # because the earlier fix was scoped to the DO token specifically, not
  # generalised. Found 2026-09-18 during a QA pass on honorific parsing.
  expect_identical(strip_name_noise("John Ma"), "John Ma")
  expect_identical(strip_name_noise("Yo-Yo Ma"), "Yo-Yo Ma")
  expect_identical(strip_name_noise("John Michael Ma"), "John Michael Ma")
  expect_identical(parse_person("John Ma")$last, "MA")
  expect_identical(parse_person("Yo-Yo Ma")$last, "MA")
  # humaniformat's OWN independent suffix heuristic treats a trailing "Ma"
  # as a degree-suffix token once a name has 3+ tokens (unrelated to this
  # carve-out -- see parse_person()'s "reclaimed" comment) and would
  # otherwise silently drop it; reclaimed into a compound last name, same
  # shape as humaniformat's own "Van Do" compound-surname grouping.
  expect_identical(parse_person("John Michael Ma")$last, "MICHAEL MA")
  expect_true(has_name_information(parse_person("John Ma")$last))
})

test_that("the 'Ma' surname is protected surname-first, including with a trailing credential", {
  expect_identical(strip_name_noise("Ma, John"), "Ma John")
  expect_identical(strip_name_noise("Ma, John, M.D."), "Ma John")
  expect_identical(parse_person("Ma, John")$last, "MA")
  expect_identical(parse_person("Ma, John, M.D.")$last, "MA")
})

test_that("the MA credential is still stripped -- the collision list narrows NAME_NOISE, it does not widen it", {
  expect_identical(strip_name_noise("John Smith MA"), "John Smith")
  expect_identical(strip_name_noise("John Michael Smith MA"), "John Michael Smith")
  expect_identical(parse_person("John Smith MA")$last, "SMITH")
  expect_false(grepl("MA", parse_person("John Smith MA")$last, fixed = TRUE))
})

test_that("a trailing 'Ma' is reclaimed from humaniformat's own suffix detection", {
  # THE DEFECT: humaniformat::parse_names() has its OWN internal notion of
  # degree-suffix tokens, entirely independent of NAME_NOISE/
  # SURNAME_CREDENTIAL_COLLISIONS -- humaniformat::suffix("John Michael Ma")
  # returns "Ma", not NA, once a name has 3+ tokens. strip_name_noise()'s
  # carve-out correctly kept "Ma" IN the string handed to humaniformat, but
  # this file never reads humaniformat's own $suffix column (mysterynpi's
  # suffix comes from extract_suffix() in step 1), so the reclaimed token
  # was silently dropped anyway: "John Michael Ma" parsed to last =
  # "Michael" before this fix, losing the surname a second time via a
  # completely different mechanism than the one already fixed.
  expect_identical(parse_person("John Michael Ma")$last, "MICHAEL MA")
  expect_true(has_name_information(parse_person("John Michael Ma")$last))

  # NEGATIVE CONTROL: all-caps "MA" is NOT reclaimed -- matches the case
  # boundary strip_name_noise() already draws (see its "KNOWN LIMITATION"
  # docs): there is no case signal left to read all-caps "MA" as a surname
  # any more than all-caps "DO" is, so reclaiming it would contradict the
  # decision already made on the string side.
  expect_identical(parse_person("JOHN MICHAEL MA")$last, "MICHAEL")

  # NEGATIVE CONTROL: genuine credentials that humaniformat also treats as
  # its own internal suffix (MD, PhD) are NOT reclaimed -- only the curated
  # SURNAME_CREDENTIAL_COLLISIONS tokens are.
  expect_identical(parse_person("John Michael MD")$last, "MICHAEL")
  expect_identical(parse_person("John Michael PhD")$last, "MICHAEL")
})

test_that("other short NAME_NOISE tokens (PA, OD, DC, MS, LM, BA) stay unconditionally stripped", {
  # Deliberately NOT in SURNAME_CREDENTIAL_COLLISIONS: not well-known common
  # surnames the way "Do"/"Ma" are, so protecting them would invent a fake
  # surname for a genuinely credential-only input rather than recover a
  # real one. Pins that the generalisation didn't overreach.
  expect_identical(parse_person("John Smith PA")$last, "SMITH")
  expect_identical(parse_person("John Smith OD")$last, "SMITH")
  expect_identical(parse_person("John Smith DC")$last, "SMITH")
  expect_identical(parse_person("John Smith LM")$last, "SMITH")
})
