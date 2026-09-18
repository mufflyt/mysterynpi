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
  expect_identical(got$name, c("John Smith", "SMITH, JOHN",
                               "Samuel V Anaya", "Jane Doe", NA))
})

test_that("commas survive extraction, because the reversal needs them", {
  # the roster benchmark caught the earlier comma-eating version: parse
  # order is extract_suffix() THEN parse_person(), and the reversal must
  # still see "Thomas, William" as Last-comma-First
  got <- extract_suffix(c("Thomas, William", "Powell, Henry, Jr."))
  expect_identical(got$name, c("Thomas, William", "Powell, Henry"))
  expect_identical(got$suffix, c(NA, "JR"))
  p <- parse_person(extract_suffix("Thomas, William")$name)
  expect_identical(p$first, "WILLIAM")
  expect_identical(p$last, "THOMAS")
})

test_that("extract_suffix must run BEFORE strip_name_noise, which deletes it", {
  # this pins the ordering constraint the docs assert
  expect_identical(strip_name_noise("John Smith Jr"), "John Smith")
  expect_identical(extract_suffix(strip_name_noise("John Smith Jr"))$suffix,
                   NA_character_)
  expect_identical(extract_suffix("John Smith Jr")$suffix, "JR")
})

test_that("parse_person() gets the ordering right even if a caller wouldn't", {
  # A pipeline that treats "strip titles" and "suffix handling" as two
  # independently composable stages loses the suffix the moment titles are
  # stripped first, because NAME_NOISE also lists JR/SR/II/III/IV (see the
  # test above). parse_person() extracts the suffix BEFORE its own internal
  # title-stripping runs, so this hazard cannot be triggered by composing
  # stages in the wrong order -- the suffix is always safe by construction.
  p <- parse_person("John Smith Jr, MD")
  expect_identical(p$last, "SMITH")
  expect_identical(p$suffix, "JR")

  p2 <- parse_person(c("Powell, Henry, Jr.", "Jane Doe", NA_character_))
  expect_identical(p2$first,  c("HENRY", "JANE", ""))
  expect_identical(p2$last,   c("POWELL", "DOE", ""))
  expect_identical(p2$suffix, c("JR", "", ""))
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

test_that("a leading 'Sr.' is the religious title Sister, never a generation", {
  # THE DEFECT: extract_suffix() scanned every token for suffix vocabulary,
  # with no positional check. "Sr." is also the standard abbreviation for
  # "Sister" (a nun) when it LEADS a name -- e.g. clinician records for
  # women religious who are also NPs/CNMs/RNs -- and no US name suffix ever
  # leads a name (suffixes trail, per SUFFIX_SPELLINGS' own docs). Before
  # this fix, extract_suffix("Sr. Mary Josephine, CNM") read the leading
  # "Sr." as a generational suffix, deleted it from the name, and reported
  # suffix = "SR" -- feeding a false generation into suffix_agreement()'s
  # father/son veto for someone who was never a "Senior" at all.
  got <- extract_suffix("Sr. Mary Josephine, CNM")
  expect_identical(got$suffix, NA_character_)
  expect_identical(got$name, "Sr. Mary Josephine, CNM")

  # the unabbreviated form was never affected -- this pins that it still isn't
  expect_identical(extract_suffix("Sister Mary Josephine, CNM")$suffix,
                    NA_character_)

  # a genuine trailing suffix is still caught -- the fix is positional
  # (first token only), not a vocabulary change
  expect_identical(extract_suffix("Mary Josephine Smith Jr")$suffix, "JR")

  # strip_name_noise() still removes "Sr." as a title once suffix
  # extraction is out of the way -- only the suffix *field* changes
  p <- parse_person("Sr. Mary Josephine Smith, CNM")
  expect_identical(p$suffix, "")
  expect_identical(p$last, "SMITH")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_suffix_agreement_contract())
  never_veto <- function(a, b) rep("uninformative", length(a))
  expect_error(assert_suffix_agreement_contract(never_veto))
})
