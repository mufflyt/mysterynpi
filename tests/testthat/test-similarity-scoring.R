# ONE nickname system: the dictionary derives from NICKNAME_EDGES, the same
# corpus the verdict rule reads, and equivalence is the verdict rule's own
# one-hop relation. These tests pin the consolidation - including the
# repairs it deliberately made to the old hand-rolled dictionary's quirks.
# The Jaro-Winkler scoring pair that once shared this file was REMOVED
# 2026-09-19 (owner ruling: no fuzzy person-name matching in any form);
# its salvageable missing-is-unknown cases live on in
# test-given-agreement.R against the categorical verdict.

dict <- create_nickname_dictionary(verbose = FALSE)

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
  expect_true(are_nickname_equivalents("RICK", "RICHARD", dict))
  expect_true(are_nickname_equivalents("RICK", "ERIC", dict))
  # JULIE-as-formal shadowed its nickname role; the corpus records the edge,
  # and the categorical verdict names it - no score involved
  expect_identical(given_name_agreement("JULIA", "JULIE"), "corroborates_nickname")
  expect_identical(nickname_agreement("JULIA", "JULIE"), "corroborates")
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
