# The scoring module is an extraction, so these tests pin BEHAVIOUR AS
# EXTRACTED -- including the quirks the file header documents. A quirk test
# failing means someone repaired the dictionary; that may be right, but it
# changes scores and must be a deliberate, versioned decision, not a tidy-up.

skip_if_not_installed("stringdist")
dict <- create_nickname_dictionary(verbose = FALSE)

test_that("the score tiers are the extracted ones", {
  expect_identical(calculate_enhanced_first_name_similarity("Robert", "Robert", dict), 1.0)
  expect_identical(calculate_enhanced_first_name_similarity("Bob", "Rob", dict), 0.98)
  expect_identical(calculate_enhanced_first_name_similarity("Robert", "Bob", dict), 0.98)
  expect_identical(calculate_enhanced_first_name_similarity(NA, "Bob", dict), 0.5)
  jw <- calculate_enhanced_first_name_similarity("Robert", "Xzqk", dict)
  expect_true(jw >= 0 && jw < 0.94)
})

test_that("umlaut digraphs get the second Jaro-Winkler chance", {
  a <- calculate_enhanced_first_name_similarity("MUELLER", "MULLER", dict)
  b <- 1 - stringdist::stringdist("MUELLER", "MULLER", method = "jw")
  expect_gte(a, b)
})

test_that("no dictionary means plain Jaro-Winkler, and NULL-safety holds", {
  expect_identical(calculate_enhanced_first_name_similarity("A", "A"), 1.0)
  expect_false(are_nickname_equivalents("Bob", "Rob", NULL))
  expect_identical(get_nicknames_for_name("ELIZABETH", NULL), character(0))
  expect_identical(get_canonical_name("Bob", NULL), "Bob")
  expect_identical(get_canonical_name(NA, dict), NA)
})

test_that("lookups resolve through the dictionary", {
  expect_identical(get_canonical_name("Bob", dict), "ROBERT")
  expect_identical(get_canonical_name("ROBERT", dict), "ROBERT")
  expect_identical(get_canonical_name("Xyzzy", dict), "XYZZY")
  expect_true(are_nickname_equivalents("Beth", "Liz", dict))
  expect_false(are_nickname_equivalents("Bob", "Steve", dict))
  expect_identical(get_nicknames_for_name("ELIZABETH", dict),
                   c("LIZ", "LIZZY", "BETH", "BETTY", "BETSY", "ELIZA"))
})

test_that("the extraction quirks are pinned, not repaired", {
  # last write wins in the reverse map: RICHARD wrote RICK, ERIC overwrote it
  expect_identical(get_canonical_name("RICK", dict), "ERIC")
  # DONNIE: DONALD wrote it, DONNA overwrote it
  expect_identical(get_canonical_name("DONNIE", dict), "DONNA")
  # duplicate formal entries survive in names(); the forward lookup takes
  # the first, so the shadowed second definitions change nothing
  expect_gt(sum(names(dict$formal_to_nicknames) == "JUSTIN"), 1L)
  expect_identical(dict$formal_to_nicknames[["JUSTIN"]], "JUST")
  # self-nickname: GARY is recorded as a nickname of GARY
  expect_identical(get_canonical_name("GARY", dict), "GARY")
  # formal shadows nickname: JULIE is a formal entry, so it never resolves
  # to JULIA and the pair scores by Jaro-Winkler, not by the 0.98 tier
  expect_identical(get_canonical_name("JULIE", dict), "JULIE")
  expect_identical(
    calculate_enhanced_first_name_similarity("JULIA", "JULIE", dict),
    1 - stringdist::stringdist("JULIA", "JULIE", method = "jw"))
})

test_that("the cache returns one dictionary, and refresh rebuilds", {
  a <- get_nickname_dictionary()
  b <- get_nickname_dictionary()
  expect_identical(a$created, b$created)
  c <- get_nickname_dictionary(refresh = TRUE)
  expect_identical(a$formal_count, c$formal_count)
})

test_that("the factory binds the dictionary", {
  f <- create_nickname_aware_similarity(dict)
  expect_identical(f("Robert", "Bob"), 0.98)
})

test_that("scores rank and verdicts decide: the fence in one assertion", {
  # the score puts BETH/LIZ at 0.98; the middle-name VERDICT still
  # conflicts on the same pair -- both true at once is the entire design
  expect_identical(calculate_enhanced_first_name_similarity("BETH", "LIZ", dict), 0.98)
  expect_identical(middle_agreement(middle_tokens("BETH"),
                                    middle_tokens("LIZ")), "conflicts")
})
