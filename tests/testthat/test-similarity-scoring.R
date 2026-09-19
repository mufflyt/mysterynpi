# ONE nickname system: the scoring dictionary derives from NICKNAME_EDGES,
# the same corpus the verdict rule reads, and equivalence is the verdict
# rule's own one-hop relation. These tests pin the consolidation -- including
# the repairs it deliberately made to the old hand-rolled dictionary's
# quirks. The dark-by-default fence and the closure factory retired
# 2026-09-19 when similarity became a first-class governed primitive
# (R/similarity.R); the deprecated shim's compatibility contract is pinned
# here and in test-similarity.R.

dict <- create_nickname_dictionary(verbose = FALSE)

test_that("deterministic dictionary lookups never needed a gate, and still work", {
  expect_true(are_nickname_equivalents("Bob", "Robert", dict))
  expect_true(are_nickname_equivalents("Beth", "Liz", dict))
})

test_that("the dictionary IS the corpus, both directions", {
  expect_identical(dict$source,
                   "mysterynpi::NICKNAME_EDGES (carltonnorthern/nicknames, pinned)")
  expect_identical(sort(unique(names(dict$formal_to_nicknames))),
                   unique(NICKNAME_EDGES$name))
  expect_identical(get_nicknames_for_name("AARON", dict),
                   NICKNAME_EDGES$nickname[NICKNAME_EDGES$name == "AARON"])
  expect_true(all(c("BETH", "LIZ") %in%
                    get_nicknames_for_name("ELIZABETH", dict)))
})

test_that("the consolidation repaired the old dictionary's quirks", {
  # RICK belonged ONLY to ERIC by last-write-wins; multi-root equivalence
  # now honours both recorded roots
  expect_true(are_nickname_equivalents("RICK", "RICHARD", dict))
  expect_true(are_nickname_equivalents("RICK", "ERIC", dict))
  # JULIE-as-formal shadowed its nickname role; the corpus records the edge
  expect_identical(given_name_similarity("JULIA", "JULIE"), NICKNAME_SIMILARITY)
})

test_that("canonical is a display label; the corpus has no hierarchy", {
  expect_true("ROBERT" %in% dict$nickname_to_formal[["BOB"]])
  expect_true("BOB" %in% dict$nickname_to_formal[["ROBERT"]])
  expect_identical(get_canonical_name("Bob", dict),
                   sort(dict$nickname_to_formal[["BOB"]])[1])
  expect_identical(get_canonical_name("Xyzzy", dict), "XYZZY")
})

test_that("hub nicknames carry all their roots; display picks one stably", {
  roots <- dict$nickname_to_formal[["AL"]]
  expect_true(all(c("ALBERT", "ALEXANDER", "ALAN") %in% roots))
  expect_identical(get_canonical_name("AL", dict), sort(roots)[1])
  expect_true(are_nickname_equivalents("AL", "ALBERT", dict))
  expect_true(are_nickname_equivalents("AL", "ALEXANDER", dict))
  expect_false(are_nickname_equivalents("ALBERT", "ALEXANDER", dict))
})

test_that("equivalence is the verdict rule's relation, by construction", {
  pairs <- NICKNAME_EDGES[seq(1, nrow(NICKNAME_EDGES), by = 97), ]
  for (i in seq_len(nrow(pairs))) {
    expect_true(are_nickname_equivalents(pairs$name[i], pairs$nickname[i],
                                         dict))
    expect_identical(nickname_agreement(pairs$name[i], pairs$nickname[i]),
                     "corroborates")
  }
  expect_false(are_nickname_equivalents("JANE", "JOAN", dict))
  expect_identical(nickname_agreement("JANE", "JOAN"), "conflicts")
})

test_that("the primitive's tiers are exact, one-hop, NA, or pinned Jaro-Winkler", {
  expect_identical(given_name_similarity("Robert", "Robert"), 1)
  expect_identical(given_name_similarity("Bob", "Rob"), NICKNAME_SIMILARITY)
  expect_identical(given_name_similarity("Robert", "Bob"), NICKNAME_SIMILARITY)
  expect_identical(given_name_similarity(NA_character_, "Bob"), NA_real_)
  # the engine pins the WINKLER prefix (p = JW_PREFIX_WEIGHT); the retired
  # call sites used stringdist's default p = 0 (plain Jaro) - a documented,
  # versioned score change, pinned here so it can never drift silently
  expect_identical(
    given_name_similarity("ELISABETH", "ELIZABETH", nickname_aware = FALSE),
    1 - stringdist::stringdist("ELISABETH", "ELIZABETH", method = "jw",
                               p = JW_PREFIX_WEIGHT))
  jw <- given_name_similarity("Robert", "Xzqk")
  expect_true(jw >= 0 && jw < 0.94)
})

test_that("umlaut digraphs get the second Jaro-Winkler chance", {
  a <- given_name_similarity("MUELLER", "MULLER", nickname_aware = FALSE)
  b <- 1 - stringdist::stringdist("MUELLER", "MULLER", method = "jw",
                                  p = JW_PREFIX_WEIGHT)
  expect_gte(a, b)
})

test_that("NULL-safety holds across the dictionary utilities", {
  expect_false(are_nickname_equivalents("Bob", "Rob", NULL))
  expect_identical(get_nicknames_for_name("ELIZABETH", NULL), character(0))
  expect_identical(get_canonical_name("Bob", NULL), "Bob")
  expect_identical(get_canonical_name(NA, dict), NA)
  expect_false(are_nickname_equivalents(NA, "Bob", dict))
})

test_that("the cache returns one dictionary, and refresh rebuilds", {
  a <- get_nickname_dictionary()
  b <- get_nickname_dictionary()
  expect_identical(a$created, b$created)
  c <- get_nickname_dictionary(refresh = TRUE)
  expect_identical(a$formal_count, c$formal_count)
})

test_that("scores inform and verdicts decide: the separation in one assertion", {
  # the score puts BETH/LIZ at 0.98; the middle-name VERDICT still
  # conflicts on the same pair -- both true at once is the entire design
  expect_identical(given_name_similarity("BETH", "LIZ"), NICKNAME_SIMILARITY)
  expect_identical(middle_agreement(middle_tokens("BETH"),
                                    middle_tokens("LIZ")), "conflicts")
})
