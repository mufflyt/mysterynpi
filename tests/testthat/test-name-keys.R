test_that("absence is never read as information", {
  expect_false(has_name_information(NA_character_))
  expect_false(has_name_information(""))
  expect_true(has_name_information("A"))
  # the defect: nzchar(NA) is TRUE
  expect_true(nzchar(NA_character_))
})

test_that("accented names transliterate rather than survive", {
  expect_identical(name_key("Álvarez"), "ALVAREZ")
  expect_identical(first_initial("Álvarez"), "A")
  expect_identical(name_key("Mróz"), "MROZ")
  expect_identical(name_key("Müller"), "MUELLER")   # romanised, not "MULLER"
  expect_identical(name_key("Weiß"), "WEISS")
})

test_that("NA in, NA out; blank_na is the only route to empty", {
  expect_true(is.na(name_key(NA_character_)))
  expect_identical(blank_na(NA_character_), "")
  expect_true(is.na(first_initial(NA_character_)))
  expect_true(is.na(first_initial("")))
  expect_identical(name_key(character(0)), character(0))
})

test_that("parenthesised alternate names leave the key", {
  expect_identical(name_key("Cynthia (Cindi)"), "CYNTHIA")
  expect_identical(name_key("Patty (Pepita) B."), "PATTY B.")
  expect_identical(name_key("Anna (Katie"), "ANNA")          # unclosed
  expect_identical(name_key("Renée (Ren)"), "RENEE")         # still transliterates
  # word-internal brackets are optional LETTERS, not a nickname
  expect_identical(name_key("C(arolyn) Diane"), "CAROLYN DIANE")
  expect_identical(split_given("C(arolyn) Diane")$given, "CAROLYN")
})

test_that("a fused given-name field splits without fabricating a middle", {
  s <- split_given("Julie Ann")
  expect_identical(s$given, "JULIE")
  expect_identical(s$middle_from_given, "ANN")
  expect_identical(split_given("Cynthia (Cindi)")$middle_from_given, "")
  expect_false(substr(split_given("Cynthia (Cindi)")$middle_from_given, 1, 1) == "(")
})

test_that("fold_hyphens defaults to FALSE: a hyphen is a literal character", {
  # the safe default. A hyphen must never be folded unless a caller opts in
  # explicitly for a SURNAME comparison -- see the split_given test below for
  # why the opposite default was reverted.
  expect_identical(name_key("Abbas-Rodriguez"), "ABBAS-RODRIGUEZ")
  expect_false(identical(name_key("Abbas-Rodriguez"), name_key("Abbas Rodriguez")))
  expect_identical(blank_na("Smith-Jones"), "SMITH-JONES")
})

test_that("fold_hyphens = TRUE joins a compound surname's space-separated spelling", {
  # the defect this opt-in exists to fix: two different sources record the
  # same compound SURNAME with a hyphen and a space, and without folding
  # these are different keys
  expect_identical(name_key("Abbas-Rodriguez", fold_hyphens = TRUE),
                   name_key("Abbas Rodriguez", fold_hyphens = TRUE))
  expect_identical(name_key("Abbas-Rodriguez", fold_hyphens = TRUE), "ABBAS RODRIGUEZ")
  expect_identical(blank_na("Smith-Jones", fold_hyphens = TRUE),
                   blank_na("Smith Jones", fold_hyphens = TRUE))
  expect_identical(first_initial("Abbas-Rodriguez", fold_hyphens = TRUE), "A")
  # multiple hyphens must not leave double spaces behind
  expect_identical(name_key("Smith--Jones-Lee", fold_hyphens = TRUE), "SMITH JONES LEE")
  expect_identical(name_key("Smith - Jones", fold_hyphens = TRUE), "SMITH JONES")
  # interacts correctly with accent transliteration and alternate-stripping
  expect_identical(name_key("Muñoz-García", fold_hyphens = TRUE), "MUNOZ GARCIA")
  expect_identical(name_key("Smith-Jones (Suzy)", fold_hyphens = TRUE), "SMITH JONES")
})

test_that("split_given never folds a hyphen, even if asked -- REGRESSION", {
  # THE DEFECT THIS GUARDS AGAINST. fold_hyphens briefly defaulted to TRUE
  # for every caller of blank_na(), including split_given() -- so a
  # genuinely compound GIVEN name ("Samantha-Rose") was split into
  # given = "SAMANTHA", middle_from_given = "ROSE", and a downstream
  # middle-name veto that drops "ROSE" then matches on "SAMANTHA" + surname
  # alone. Three cross-state false identity matches (different real people
  # sharing only a shortened given name and surname) were found this way
  # before the default was reverted. This must never regress.
  for (compound in c("Samantha-Rose", "Bonnie-Dee", "Mary-Louise")) {
    # The safe default: the hyphen is a literal character, split_given()
    # splits on WHITESPACE only, so the whole compound name stays given
    # and no middle token is manufactured out of it.
    s_default <- split_given(compound)
    expect_identical(s_default$given, toupper(compound))
    expect_identical(s_default$middle_from_given, "")
    # The unsafe call this test guards against: fold_hyphens = TRUE turns
    # the hyphen into a space BEFORE the whitespace split, so it silently
    # manufactures a middle token out of half a given name. Documented here
    # as a demonstrated failure mode, not a recommendation -- callers must
    # never pass fold_hyphens = TRUE to split_given().
    s_explicit_true <- split_given(compound, fold_hyphens = TRUE)
    expect_identical(s_explicit_true$given, toupper(sub("-.*$", "", compound)))
    expect_identical(s_explicit_true$middle_from_given,
                     toupper(sub("^.*-", "", compound)))
  }
  # The safe, correct behaviour: the whole hyphenated name stays given, with
  # no middle token manufactured out of it.
  expect_identical(split_given("Samantha-Rose")$given, "SAMANTHA-ROSE")
  expect_identical(split_given("Samantha-Rose")$middle_from_given, "")
})
