test_that("normalize_suffix maps recorded spellings and refuses the rest", {
  expect_identical(normalize_suffix(c("Jr.", "JUNIOR", "jnr", " sr ", "Senior")),
                   c("JR", "JR", "JR", "SR", "SR"))
  expect_identical(normalize_suffix(c("II", "2nd", "III", "3rd", "IV", "4th")),
                   c("II", "II", "III", "III", "IV", "IV"))
  # V is an initial far more often than a fifth-of-name
  expect_identical(normalize_suffix(c("V", "MD", "", NA)),
                   rep(NA_character_, 4))
})

test_that("extract_suffix splits the suffix out and keeps both parts", {
  got <- extract_suffix(c("John Smith Jr.", "SMITH, JOHN, JR",
                          "Samuel V Anaya", "Jane Doe", NA))
  expect_identical(got$suffix, c("JR", "JR", NA, NA, NA))
  expect_identical(got$name, c("John Smith", "SMITH JOHN",
                               "Samuel V Anaya", "Jane Doe", NA))
})

test_that("extract_suffix must run BEFORE strip_name_noise, which deletes it", {
  # this pins the ordering constraint the docs assert
  expect_identical(strip_name_noise("John Smith Jr"), "John Smith")
  expect_identical(extract_suffix(strip_name_noise("John Smith Jr"))$suffix,
                   NA_character_)
  expect_identical(extract_suffix("John Smith Jr")$suffix, "JR")
})

test_that("the father/son veto fires on recorded generations", {
  expect_identical(suffix_agreement("JR", "SR"), "conflicts")
  expect_identical(suffix_agreement("II", "III"), "conflicts")
  expect_identical(suffix_agreement("Junior", "Sr."), "conflicts")
})

test_that("JR and II are the same generation written twice", {
  expect_identical(suffix_agreement("JR", "II"), "corroborates")
  expect_identical(suffix_agreement("2nd", "Jr."), "corroborates")
  expect_identical(suffix_agreement("III", "3rd"), "corroborates")
})

test_that("absence is uninformative, never a conflict", {
  expect_identical(suffix_agreement(NA_character_, "JR"), "uninformative")
  expect_identical(suffix_agreement("", "SR"), "uninformative")
  expect_identical(suffix_agreement("V", "IV"), "uninformative")
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(suffix_agreement(c("JR", "JR", ""), c("SR", "II", "JR")),
                   c("conflicts", "corroborates", "uninformative"))
  expect_error(suffix_agreement(c("JR", "SR"), "JR"), "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_suffix_agreement_contract())
  never_veto <- function(a, b) rep("uninformative", length(a))
  expect_error(assert_suffix_agreement_contract(never_veto))
})
