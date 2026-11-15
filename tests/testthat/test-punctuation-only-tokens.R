# A token must carry a letter. Punctuation is not a name, and a field holding
# only punctuation is ABSENT information -- never evidence of difference.
#
# Found by a full-corpus differential audit of a downstream AMCB-NPPES linkage
# (22,357 roster rows x 527,756 registry name variants). 12 candidate pairs
# changed verdict from "uninformative" to "conflicts" between 0.3.1.9000 and
# 0.9.0, and every one of them was dirty registry data rather than a name:
# 11 rows record a PHONE NUMBER in the middle-name field and 3 a bare "-".
# A "conflicts" verdict VETOES a candidate, so junk in a registry field was
# silently deleting matches.

test_that("a punctuation-only middle-name field is uninformative, not a conflict", {
  # Digits are separators in the token class, so a phone number collapses to a
  # run of hyphens. Before the fix this yielded the token "-".
  expect_length(middle_tokens("646-704-2003")[[1]], 0L)
  expect_length(middle_tokens("-")[[1]], 0L)
  expect_length(middle_tokens("--")[[1]], 0L)
  expect_length(middle_tokens("'")[[1]], 0L)
  expect_length(middle_tokens("- -")[[1]], 0L)

  # The contract middle_agreement() documents: absence yields "uninformative",
  # which must never be read as evidence of difference.
  for (junk in c("646-704-2003", "-", "--", "'", "- -")) {
    expect_identical(
      middle_agreement(middle_tokens("MARIE"), middle_tokens(junk)),
      "uninformative",
      info = junk)
    # Symmetric: the junk may be on either side.
    expect_identical(
      middle_agreement(middle_tokens(junk), middle_tokens("MARIE")),
      "uninformative",
      info = junk)
  }
})

test_that("given_tokens() drops a punctuation-only token", {
  # The >= 2 character filter already dropped a bare "-", but not these, and a
  # punctuation-only token would satisfy person_matches()'s shared-token
  # requirement -- asserting a match on no name at all.
  expect_length(given_tokens("--")[[1]], 0L)
  expect_length(given_tokens("''")[[1]], 0L)
  expect_false(person_matches("SMITH", given_tokens("--"),
                              "SMITH", given_tokens("--")))
})

test_that("name_leading_given() does not return punctuation as a name", {
  expect_true(is.na(name_leading_given("-")))
  expect_true(is.na(name_leading_given("--")))
  expect_identical(name_leading_given("Mary-Jane Smith"), "MARY-JANE")
})

test_that("the 0.9.0 corrections are unchanged by this fix", {
  # Separator-only difference still corroborates (the CNM04881 case).
  expect_identical(
    middle_agreement(middle_tokens("MARIE-LEFEVER"), middle_tokens("MARIE LEFEVER")),
    "corroborates")
  expect_identical(
    middle_agreement(middle_tokens("ERICKSON-OWENS"), middle_tokens("ERICKSONOWENS")),
    "corroborates")
  # A compound against one HALF of itself still conflicts (503a37e preserved).
  expect_identical(
    middle_agreement(middle_tokens("ANNE-MARIE"), middle_tokens("MARIE")),
    "conflicts")
  expect_identical(
    middle_agreement(middle_tokens("GAIL-ROSANNE"), middle_tokens("GAIL")),
    "conflicts")
  # Genuinely different given names still conflict: not edit-distance tolerance.
  expect_identical(middle_agreement(middle_tokens("JULIA"), middle_tokens("JULIE")),
                   "conflicts")
  # A real hyphenated name is still ONE token, so the tokenizer is unchanged
  # for every input that carries a letter.
  expect_identical(middle_tokens("MARIE-LEFEVER")[[1]], "MARIE-LEFEVER")
  expect_identical(given_tokens("Mary-Jane")[[1]], "MARY-JANE")
})
