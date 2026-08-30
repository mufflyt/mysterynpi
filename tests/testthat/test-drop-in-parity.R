# strip_alternates = FALSE must reproduce a normaliser that does not handle the
# parenthesised-alternate convention, EXACTLY. That is what makes a migration
# provable: swap with FALSE, show nothing changed, then flip as its own diff.

test_that("FALSE leaves brackets alone and TRUE removes them", {
  expect_identical(name_key("Cynthia (Cindi)", strip_alternates = FALSE),
                   "CYNTHIA (CINDI)")
  expect_identical(name_key("Cynthia (Cindi)"), "CYNTHIA")
  expect_identical(name_key("Anna (Katie", strip_alternates = FALSE), "ANNA (KATIE")
  expect_identical(name_key("Anna (Katie"), "ANNA")
  # word-internal brackets are optional LETTERS under TRUE, untouched under FALSE
  expect_identical(name_key("C(arolyn) Diane", strip_alternates = FALSE),
                   "C(AROLYN) DIANE")
  expect_identical(name_key("C(arolyn) Diane"), "CAROLYN DIANE")
})

test_that("the switch changes NOTHING for names without brackets", {
  plain <- c("Álvarez", "Mróz", "Müller", "Weiß", "O'Brien-Smith",
             "  Double  Space ", "MCCARTHY-DERVIN", NA_character_, "")
  expect_identical(name_key(plain, strip_alternates = FALSE), name_key(plain))
})

test_that("the switch propagates to every derived helper", {
  x <- "Cynthia (Cindi) A."
  expect_identical(blank_na(x, strip_alternates = FALSE), "CYNTHIA (CINDI) A.")
  expect_identical(blank_na(x), "CYNTHIA A.")
  expect_identical(first_initial("(Sandra) Theresa", strip_alternates = FALSE), "(")
  expect_identical(first_initial("(Sandra) Theresa"), "T")
  expect_identical(split_given(x, strip_alternates = FALSE)$middle_from_given,
                   "(CINDI) A.")
  expect_identical(split_given(x)$middle_from_given, "A.")
  expect_identical(middle_tokens("(Cindi) A", strip_alternates = FALSE)[[1]],
                   c("CINDI", "A"))
  expect_identical(surname_tokens("Smith (Melson)", strip_alternates = FALSE),
                   c("SMITH", "MELSON"))
  expect_identical(surname_tokens("Smith (Melson)"), "SMITH")
})

test_that("the default is the FIX, not the incumbent", {
  # A bracket reaching the middle slot yields an initial of "(", which equals no
  # recorded initial anywhere -- every affected roster row failed, 9 of 9.
  expect_false(substr(split_given("Cynthia (Cindi)")$middle_from_given, 1, 1) == "(")
  expect_true(substr(split_given("Cynthia (Cindi)",
                                 strip_alternates = FALSE)$middle_from_given, 1, 1) == "(")
})
