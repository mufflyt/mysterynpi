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

test_that("a hyphenated compound surname joins its space-separated spelling", {
  # the defect: two different sources record the same compound surname with
  # a hyphen and a space, and until fold_hyphens these were different keys
  expect_identical(name_key("Abbas-Rodriguez"), name_key("Abbas Rodriguez"))
  expect_identical(name_key("Abbas-Rodriguez"), "ABBAS RODRIGUEZ")
  expect_identical(blank_na("Smith-Jones"), blank_na("Smith Jones"))
  expect_identical(first_initial("Abbas-Rodriguez"), "A")
  # multiple hyphens must not leave double spaces behind
  expect_identical(name_key("Smith--Jones-Lee"), "SMITH JONES LEE")
  expect_identical(name_key("Smith - Jones"), "SMITH JONES")
  # fold_hyphens = FALSE reproduces the pre-fix, hyphen-as-literal behaviour
  expect_identical(name_key("Abbas-Rodriguez", fold_hyphens = FALSE), "ABBAS-RODRIGUEZ")
  expect_false(identical(name_key("Abbas-Rodriguez", fold_hyphens = FALSE),
                        name_key("Abbas Rodriguez", fold_hyphens = FALSE)))
  # interacts correctly with accent transliteration and alternate-stripping
  expect_identical(name_key("Muñoz-García"), "MUNOZ GARCIA")
  expect_identical(name_key("Smith-Jones (Suzy)"), "SMITH JONES")
})
