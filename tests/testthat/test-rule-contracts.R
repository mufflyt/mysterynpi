# The generic contract battery: run against every rule in rule_specs (see
# helper-rules.R; registry pattern from howardjp/phonics, BSD-2-Clause). The
# invariant style -- enumerated conservation laws over a seeded random pool
# rather than a property-testing framework -- follows opensanctions/rigour
# (MIT), tests/names/test_compare.py, e.g. test_every_input_appears_exactly_once.

pool_a <- random_name_pool(250, seed = 20260905)
pool_b <- random_name_pool(250, seed = 5090602)

for (rule in names(rule_specs)) {
  spec <- rule_specs[[rule]]

  test_that(sprintf("%s: verdicts stay inside the closed set", rule), {
    got <- spec$fn(pool_a, pool_b)
    expect_true(all(got %in% spec$verdicts))
    expect_length(got, length(pool_a))
  })

  test_that(sprintf("%s: absence on either side is uninformative", rule), {
    x <- c("MARY", "J", "SMITH-JONES")
    expect_identical(spec$fn(rep("", 3), x), rep("uninformative", 3))
    expect_identical(spec$fn(x, rep(NA_character_, 3)),
                     rep("uninformative", 3))
  })

  test_that(sprintf("%s: agreement is symmetric", rule), {
    expect_identical(spec$fn(pool_a, pool_b), spec$fn(pool_b, pool_a))
  })

  test_that(sprintf("%s: deterministic on repeated calls", rule), {
    expect_identical(spec$fn(pool_a, pool_b), spec$fn(pool_a, pool_b))
  })

  test_that(sprintf("%s: vector call agrees with scalar calls", rule), {
    idx <- seq(1, 250, by = 25)
    vec <- spec$fn(pool_a[idx], pool_b[idx])
    for (k in seq_along(idx)) {
      expect_identical(spec$fn(pool_a[idx[k]], pool_b[idx[k]]), vec[k])
    }
  })

  test_that(sprintf("%s: identical recorded inputs never conflict", rule), {
    got <- spec$fn(pool_a, pool_a)
    expect_false(any(got == "conflicts"))
  })

  test_that(sprintf("%s: recycling is refused, not performed", rule), {
    expect_error(spec$fn(c("A", "B"), "A"), "same length")
  })
}
