# ONE nickname system, ONE answer: the dictionary derives from
# NICKNAME_EDGES, the same corpus nickname_agreement() reads, and
# equivalence is the verdict rule's own one-hop relation. These tests pin
# the consolidation - including the repairs it deliberately made to the old
# hand-rolled dictionary's quirks - and the CORPUS INVARIANT: the
# equivalence relation and the categorical verdicts can never give opposite
# answers to the same deterministic question.

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

test_that("CORPUS INVARIANT: every recorded edge is equivalent AND corroborates, everywhere", {
  # Full-corpus sweep, both APIs, so are_nickname_equivalents() and the
  # categorical verdicts can never give opposite answers to the same
  # deterministic question (the drift this file exists to prevent).
  e <- NICKNAME_EDGES
  equiv <- vapply(seq_len(nrow(e)), function(i) {
    isTRUE(are_nickname_equivalents(e$name[i], e$nickname[i], dict))
  }, logical(1))
  expect_true(all(equiv),
              info = paste("edges NOT equivalent:", sum(!equiv)))
  na <- nickname_agreement(e$name, e$nickname)
  expect_true(all(na == "corroborates"),
              info = paste("edges not corroborated by nickname_agreement:",
                           sum(na != "corroborates")))
  ga <- given_name_agreement(e$name, e$nickname)
  expect_true(all(ga$verdict == "corroborates"),
              info = paste("edges not corroborated by given_name_agreement:",
                           sum(ga$verdict != "corroborates")))
  # exact-after-normalisation edges legitimately carry reason "exact", and a
  # single-letter nickname recorded in the corpus is claimed by the initials
  # rule first ("initial"); every other edge must carry reason "nickname" -
  # never NA, never fabricated
  expect_true(all(ga$reason %in% c("exact", "nickname", "initial")))
})

test_that("CONVERSE: verdicts never fabricate a relationship absent from the corpus", {
  non_edges <- list(c("LEE", "LEA"), c("JANE", "JOAN"),
                    c("ALBERT", "ALEXANDER"), c("MARTIN", "MARVIN"))
  for (p in non_edges) {
    expect_false(are_nickname_equivalents(p[1], p[2], dict),
                 label = paste(p, collapse = "/"))
    expect_identical(nickname_agreement(p[1], p[2]), "conflicts")
    expect_identical(given_name_agreement(p[1], p[2])$verdict, "conflicts")
  }
})

test_that("the consolidation repaired the old dictionary's quirks", {
  expect_true(are_nickname_equivalents("RICK", "RICHARD", dict))
  expect_true(are_nickname_equivalents("RICK", "ERIC", dict))
  # JULIE-as-formal shadowed its nickname role; the corpus records the edge,
  # and BOTH categorical APIs honour it consistently
  expect_identical(nickname_agreement("JULIA", "JULIE"), "corroborates")
  expect_identical(given_name_agreement("JULIA", "JULIE")$reason, "nickname")
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
