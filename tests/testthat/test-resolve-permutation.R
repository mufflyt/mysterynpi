# A permutation test over data with no ties proves nothing, so this fixture
# is deliberately hostile: an exact tie at the best class, a tie broken only
# at a weaker class, one candidate contested by two people, and duplicate
# rows for one pair differing only in the recorded name variant. Identity
# and the retained representative must both be properties of the data, never
# of row order -- the upstream permutation suite measured the variant moving
# in 231 of 300 orderings while identity never moved once.

hostile <- data.frame(
  id = c("p1", "p1", "p1",          # tied at class 1 -> must quarantine
         "p2", "p2", "p2",          # duplicate rows for one pair + a rival
         "p3", "p3",                # resolves at class 2 over a class-3 rival
         "p4", "p5"),               # both resolve to the same candidate
  candidate = c("A", "B", "A",
                "C", "C", "D",
                "E", "F",
                "G", "G"),
  evidence_class = c(1L, 1L, 2L,
                     1L, 1L, 2L,
                     2L, 3L,
                     1L, 1L),
  variant = c("v1", "v1", "v2",
              "JOHN Q", "JOHNNY Q", "v1",
              "v1", "v1",
              "v1", "v1"),
  stringsAsFactors = FALSE)

canon <- function(d) {
  d <- d[do.call(order, unname(d)), , drop = FALSE]
  rownames(d) <- NULL
  d
}

test_that("identity, ambiguity, and the retained variant survive permutation", {
  base <- resolve_ordered_classes(hostile, tiebreak = "variant")
  for (i in 1:40) {
    perm <- hostile[sample(nrow(hostile)), , drop = FALSE]
    got <- resolve_ordered_classes(perm, tiebreak = "variant")
    expect_identical(canon(got$resolved), canon(base$resolved))
    expect_identical(canon(got$per_candidate), canon(base$per_candidate))
    expect_identical(sort(got$quarantined), sort(base$quarantined))
  }
})

test_that("the hostile fixture is actually hostile", {
  r <- resolve_ordered_classes(hostile, tiebreak = "variant")
  expect_true("p1" %in% r$quarantined)          # the tie at best class
  expect_true(all(c("p2", "p3", "p4", "p5") %in% r$resolved$id))
  # the duplicate (p2, C) rows collapsed to the tiebreak-first variant
  pc <- r$per_candidate
  expect_identical(pc$variant[pc$id == "p2" & pc$candidate == "C"], "JOHN Q")
  # without a tiebreak the retained variant is order-dependent; the contract
  # is that identity still is not
  a <- resolve_ordered_classes(hostile)
  expect_identical(canon(a$resolved[c("id", "candidate")]),
                   canon(r$resolved[c("id", "candidate")]))
})
