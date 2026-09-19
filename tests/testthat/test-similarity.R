# First-class similarity primitives: the missing contract IS the feature.

test_that("the contract assert passes for all three primitives", {
  expect_true(assert_similarity_contract(surname_similarity))
  expect_true(assert_similarity_contract(middle_name_similarity))
  expect_true(assert_similarity_contract(given_name_similarity))
})

test_that("missing is NA, never zero and never a neutral constant", {
  expect_identical(surname_similarity(c("SMITH", NA, NA), c(NA, "JONES", NA)),
                   c(NA_real_, NA_real_, NA_real_))
  expect_identical(given_name_similarity(NA_character_, "ROBERT"), NA_real_)
})

test_that("punctuation and case never masquerade as distance", {
  expect_identical(surname_similarity("Jones-Cox", "JONES COX"), 1)
  expect_identical(surname_similarity("O'Brien", "OBRIEN"), 1)
  expect_identical(surname_similarity("van de Ven", "VANDEVEN"), 1)
})

test_that("jw and lv are both available, pinned, and ordered sensibly", {
  jw <- surname_similarity("MARTINEZ", "MARTINES", method = "jw")
  lv <- surname_similarity("MARTINEZ", "MARTINES", method = "lv")
  expect_true(jw > 0.9 && jw < 1)
  expect_identical(lv, 1 - 1 / 8)  # one edit over eight letters
  # different surnames score below near-identical ones under both methods
  expect_true(surname_similarity("SMITH", "JONES", "jw") < jw)
  expect_true(surname_similarity("SMITH", "JONES", "lv") < lv)
})

test_that("given_name_similarity: exact = 1, nickname edge = pinned 0.98", {
  expect_identical(given_name_similarity("Robert", "ROBERT"), 1)
  expect_identical(given_name_similarity("Bob", "Robert"), NICKNAME_SIMILARITY)
  expect_identical(given_name_similarity("Bob", "Robert", nickname_aware = FALSE) <
                     NICKNAME_SIMILARITY, TRUE)
})

test_that("nickname equivalence is one-hop, never transitive closure", {
  # AL pairs with ALBERT and ALEXANDER; ALBERT and ALEXANDER stay strangers
  expect_identical(given_name_similarity("Al", "Albert"), NICKNAME_SIMILARITY)
  expect_identical(given_name_similarity("Al", "Alexander"), NICKNAME_SIMILARITY)
  expect_true(given_name_similarity("Albert", "Alexander") < NICKNAME_SIMILARITY)
})

test_that("umlaut digraph families score as romanisation variants", {
  plain <- given_name_similarity("Muller", "Mueller", nickname_aware = FALSE)
  expect_true(plain > 0.95)  # digraph simplification closed the gap
})

test_that("NEGATIVE CONTROL: recycling of unequal non-scalar lengths refuses", {
  expect_error(surname_similarity(c("A", "B"), c("A", "B", "C")), "recycle|length")
  expect_error(middle_name_similarity(character(0), "SMITH"), "empty")
})

test_that("vectorization: mixed observed/missing stay aligned", {
  got <- given_name_similarity(c("Bob", NA, "Anna", "Katherine"),
                               c("Robert", "Robert", "Anna", "Kathy"))
  expect_identical(got[1], NICKNAME_SIMILARITY)
  expect_identical(got[2], NA_real_)
  expect_identical(got[3], 1)
  expect_true(got[4] >= NICKNAME_SIMILARITY - 1e-9)  # KATHY is a recorded edge
})

test_that("deprecated shim: warns, preserves the old 0.5-missing contract", {
  expect_warning(v <- calculate_enhanced_first_name_similarity(NA, "ROBERT"),
                 "deprecated")
  expect_identical(v, 0.5)
  expect_warning(v2 <- calculate_enhanced_first_name_similarity("Robert", "Robert"),
                 "deprecated")
  expect_identical(v2, 1)
})

test_that("pinned constants hold their documented values", {
  expect_identical(JW_PREFIX_WEIGHT, 0.1)
  expect_identical(NICKNAME_SIMILARITY, 0.98)
})
