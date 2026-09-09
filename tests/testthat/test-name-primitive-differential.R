test_that("name primitive differential fixture has no unintended regressions", {
  path <- testthat::test_path("..", "fixtures",
                              "name_primitive_differential.csv")
  diff <- utils::read.csv(path, stringsAsFactors = FALSE)
  allowed <- c("NO_CHANGE", "INTENTIONAL_FIX", "INTENTIONAL_API_DIFFERENCE",
               "UNINTENDED_REGRESSION")

  expect_gt(nrow(diff), 20L)
  expect_true(all(diff$classification %in% allowed))
  expect_identical(sum(diff$classification == "UNINTENDED_REGRESSION"), 0L)
  expect_true(all(nzchar(diff$reason)))
  expect_true(all(diff$same | diff$classification != "NO_CHANGE"))
})

test_that("name primitive differential covers required edge classes", {
  path <- testthat::test_path("..", "fixtures",
                              "name_primitive_differential.csv")
  diff <- utils::read.csv(path, stringsAsFactors = FALSE)

  required_cases <- c(
    "surname_substring_anderson",
    "surname_substring_williams",
    "surname_substring_martin",
    "surname_apostrophe",
    "surname_component_subset",
    "surname_concatenated",
    "surname_blank",
    "surname_na",
    "surname_scalar_broadcast",
    "surname_same_length_vector",
    "surname_illegal_lengths",
    "given_initial_full",
    "given_two_initials",
    "given_positional_nickname",
    "given_positional_prefix_false_positive",
    "given_any_token_middle",
    "given_position_middle",
    "given_tokens_middle_broadcast",
    "given_tokens_illegal_middle",
    "surname_particle",
    "surname_hyphenated",
    "given_leading_initial",
    "given_missing"
  )

  expect_setequal(diff$case_id, required_cases)
})
