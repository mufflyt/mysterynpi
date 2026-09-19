# given_name_agreement(): categorical, deterministic, three-valued.
# Salvaged here from the retired similarity module: the missing-is-unknown
# cases, NA/length discipline, and normalization edges - rewritten against
# the categorical verdict, which is the contract that was worth keeping.

test_that("the contract assert passes and is falsifiable", {
  expect_true(assert_given_name_agreement_contract())
  # falsifiability: a stand-in that folds uninformative into conflicts fails
  broken <- function(a, b) {
    out <- given_name_agreement(a, b)
    out[out == "uninformative"] <- "conflicts"
    out
  }
  expect_error(assert_given_name_agreement_contract(broken), "uninformative")
})

test_that("the canonical missingness table holds exactly", {
  expect_identical(given_name_agreement("SMITH", "SMITH"), "corroborates")
  expect_identical(given_name_agreement("SMITH", "JONES"), "conflicts")
  expect_identical(given_name_agreement(NA_character_, "SMITH"), "uninformative")
  expect_identical(given_name_agreement(NA_character_, NA_character_), "uninformative")
})

test_that("normalization can never read as difference", {
  expect_identical(given_name_agreement("Anne-Marie", "ANNE MARIE"), "corroborates")
  expect_identical(given_name_agreement("O'Neal", "ONEAL"), "corroborates")
  expect_identical(given_name_agreement(" Robert ", "robert"), "corroborates")
})

test_that("named detail states correspond to named rules", {
  expect_identical(given_name_agreement("Bob", "Robert"), "corroborates_nickname")
  expect_identical(given_name_agreement("Al", "Alexander"), "corroborates_nickname")
  # JULIA/JULIE and ANN/ANNE are RECORDED corpus edges: declared
  # equivalence, allowed by the architecture - verified empirically against
  # NICKNAME_EDGES, not assumed from the pair's spelling distance
  expect_identical(given_name_agreement("JULIA", "JULIE"), "corroborates_nickname")
  expect_identical(given_name_agreement("ANN", "ANNE"), "corroborates_nickname")
  expect_identical(given_name_agreement("R", "Robert"), "corroborates_initial")
  expect_identical(given_name_agreement("Robert", "R"), "corroborates_initial")
  expect_identical(given_name_agreement("R", "William"), "conflicts")
})

test_that("no edit-distance tolerance exists, deliberately", {
  # one edit apart, NO recorded edge: these conflict, and nothing numeric
  # exists to soften them
  expect_identical(given_name_agreement("LEE", "LEA"), "conflicts")
  expect_identical(given_name_agreement("JANE", "JOAN"), "conflicts")
})

test_that("one hop, never transitive closure", {
  expect_identical(given_name_agreement("ALBERT", "ALEXANDER"), "conflicts")
})

test_that("vectorization keeps rows aligned; scalars broadcast; recycling refuses", {
  got <- given_name_agreement(c("Bob", NA, "Anna", "R"),
                              c("Robert", "Robert", "Anna", "Rachel"))
  expect_identical(got, c("corroborates_nickname", "uninformative",
                          "corroborates", "corroborates_initial"))
  expect_identical(given_name_agreement("Robert", c("Bob", "Robert", NA)),
                   c("corroborates_nickname", "corroborates", "uninformative"))
  expect_error(given_name_agreement(c("A", "B"), c("A", "B", "C")), "recycle")
  expect_error(given_name_agreement(character(0), "SMITH"), "empty")
})

test_that("two different bare initials conflict; equal ones corroborate", {
  expect_identical(given_name_agreement("R", "W"), "conflicts")
  expect_identical(given_name_agreement("R", "R"), "corroborates")
})
