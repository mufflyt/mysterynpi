# Semantic invariants on the TABLE itself, not the functions over it --
# pattern from carltonnorthern/nicknames (Apache-2.0), python/test_package.py,
# which asserts its lookups reconstruct each other and its data stays
# canonical. The CI drift gate (data-integrity.yaml) covers regeneration;
# these cover meaning.
test_that("the table's semantics hold: no self-edges, canonical form", {
  expect_identical(sum(NICKNAME_EDGES$name == NICKNAME_EDGES$nickname), 0L)
  norm <- function(x) gsub("[.]", "", toupper(trimws(x)))
  expect_identical(NICKNAME_EDGES$name, norm(NICKNAME_EDGES$name))
  expect_identical(NICKNAME_EDGES$nickname, norm(NICKNAME_EDGES$nickname))
  expect_false(is.unsorted(order(NICKNAME_EDGES$name,
                                 NICKNAME_EDGES$nickname)))
  # the forward and inverted lookups must reconstruct the same relation
  fwd <- split(NICKNAME_EDGES$nickname, NICKNAME_EDGES$name)
  inv <- split(NICKNAME_EDGES$name, NICKNAME_EDGES$nickname)
  rebuilt <- data.frame(
    name = rep(unlist(inv, use.names = FALSE),
               times = 1),
    nickname = rep(names(inv), lengths(inv)),
    stringsAsFactors = FALSE)
  rebuilt <- rebuilt[order(rebuilt$name, rebuilt$nickname), ]
  rownames(rebuilt) <- NULL
  expect_identical(rebuilt, NICKNAME_EDGES)
  expect_identical(sort(unique(names(fwd))), unique(NICKNAME_EDGES$name))
})

test_that("the vendored table is what the build script promises", {
  expect_identical(names(NICKNAME_EDGES), c("name", "nickname"))
  expect_gt(nrow(NICKNAME_EDGES), 2500)
  expect_false(anyNA(NICKNAME_EDGES))
  expect_true(all(grepl("^[A-Z]+$", NICKNAME_EDGES$name)))
  expect_true(all(grepl("^[A-Z]+$", NICKNAME_EDGES$nickname)))
  expect_false(anyDuplicated(NICKNAME_EDGES) > 0)
})

test_that("a recorded edge admits, in either direction", {
  expect_identical(nickname_agreement("BETH", "ELIZABETH"), "corroborates")
  expect_identical(nickname_agreement("ELIZABETH", "BETH"), "corroborates")
  expect_identical(nickname_agreement("RON", "AARON"), "corroborates")
})

test_that("a shared formal name admits; a shared nickname does not", {
  # BOB and BOBBY both stand for ROBERT
  expect_identical(nickname_agreement("BOB", "BOBBY"), "corroborates")
  # AL stands for ALBERT and for ALEXANDER -- each pairing admits...
  expect_identical(nickname_agreement("AL", "ALBERT"), "corroborates")
  expect_identical(nickname_agreement("AL", "ALEXANDER"), "corroborates")
  # ...but the hub must not weld the two formal names together
  expect_identical(nickname_agreement("ALBERT", "ALEXANDER"), "conflicts")
})

test_that("only recorded edges admit -- no spelling tolerance", {
  expect_identical(nickname_agreement("ELISABETH", "ELIZABETH"), "conflicts")
  expect_identical(nickname_agreement("JANE", "JOAN"), "conflicts")
  # and the corpus records some spelling-adjacent USAGE; that is the table
  # speaking, not an edit-distance rule
  expect_identical(nickname_agreement("JULIA", "JULIE"), "corroborates")
})

test_that("inputs are normalised like the table: case, accents, periods", {
  expect_identical(nickname_agreement("beth", "Elizabeth"), "corroborates")
  expect_identical(nickname_agreement("k.c.", "CASEY"), "corroborates")
})

test_that("an initial is compatibility evidence, not a nickname", {
  expect_identical(nickname_agreement("J", "JAMES"), "corroborates")
  expect_identical(nickname_agreement("J.", "JULIE"), "corroborates")
  expect_identical(nickname_agreement("J", "ROBERT"), "conflicts")
  expect_identical(nickname_agreement("JAMES", "R"), "conflicts")
})

test_that("absence is uninformative, never a conflict", {
  expect_identical(nickname_agreement("", "MARY"), "uninformative")
  expect_identical(nickname_agreement(NA_character_, "MARY"), "uninformative")
  expect_identical(nickname_agreement(NA_character_, NA_character_),
                   "uninformative")
})

test_that("a caller-supplied table drives the same rule", {
  edges <- data.frame(name = "XAVIERA", nickname = "XA",
                      stringsAsFactors = FALSE)
  expect_identical(nickname_agreement("XA", "XAVIERA", edges = edges),
                   "corroborates")
  expect_identical(nickname_agreement("BETH", "ELIZABETH", edges = edges),
                   "conflicts")
  expect_error(nickname_agreement("A", "B", edges = data.frame(x = 1)),
               "name and nickname")
})

test_that("it vectorises elementwise and refuses recycling", {
  expect_identical(nickname_agreement(c("BETH", "JANE", ""),
                                      c("ELIZABETH", "JOAN", "MARY")),
                   c("corroborates", "conflicts", "uninformative"))
  expect_error(nickname_agreement(c("A", "B"), "A"), "same length")
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_nickname_agreement_contract())
  always_agree <- function(a, b) rep("corroborates", length(a))
  expect_error(assert_nickname_agreement_contract(always_agree))
})
