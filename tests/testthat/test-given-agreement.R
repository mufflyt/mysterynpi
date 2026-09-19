# given_name_agreement(): categorical, deterministic, three-valued, with the
# named rule in a separate `reason` column so the coarse verdict stays
# stable. Salvaged from the removed similarity module: the missing-is-unknown
# cases, NA/length discipline, and normalization edges - rewritten against
# the categorical verdict, which is the contract that was worth keeping.

v <- function(a, b) given_name_agreement(a, b)$verdict
r <- function(a, b) given_name_agreement(a, b)$reason

test_that("the contract assert passes and is falsifiable", {
  expect_true(assert_given_name_agreement_contract())
  # falsifiability: a stand-in that folds uninformative into conflicts fails
  broken <- function(a, b) {
    out <- given_name_agreement(a, b)
    out$verdict[out$verdict == "uninformative"] <- "conflicts"
    out
  }
  expect_error(assert_given_name_agreement_contract(broken), "uninformative")
})

test_that("the canonical missingness table holds exactly", {
  expect_identical(v("SMITH", "SMITH"), "corroborates")
  expect_identical(v("SMITH", "JONES"), "conflicts")
  expect_identical(v(NA_character_, "SMITH"), "uninformative")
  expect_identical(v(NA_character_, NA_character_), "uninformative")
})

test_that("normalization can never read as difference", {
  expect_identical(v("Anne-Marie", "ANNE MARIE"), "corroborates")
  expect_identical(v("O'Neal", "ONEAL"), "corroborates")
  expect_identical(v(" Robert ", "robert"), "corroborates")
  expect_identical(unique(r(c("Anne-Marie", "O'Neal"), c("ANNE MARIE", "ONEAL"))),
                   "exact")
})

test_that("reasons are named rules; the coarse verdict stays three-valued", {
  got <- given_name_agreement(c("Robert", "Bob", "R", "Robert", NA),
                              c("Robert", "Robert", "Robert", "William", "Robert"))
  expect_identical(got$verdict, c("corroborates", "corroborates",
                                  "corroborates", "conflicts", "uninformative"))
  expect_identical(got$reason, c("exact", "nickname", "initial",
                                 NA_character_, NA_character_))
  expect_true(all(got$verdict %in% c("corroborates", "conflicts", "uninformative")))
  # reason exists ONLY for corroborates
  expect_true(all(is.na(got$reason[got$verdict != "corroborates"])))
})

test_that("declared alias vs spelling: the edge decides, never the distance", {
  # recorded NICKNAME_EDGES relations - verified against the corpus, not
  # assumed from spelling
  expect_identical(r("JULIA", "JULIE"), "nickname")
  expect_identical(r("ANN", "ANNE"), "nickname")
  # one edit apart, NO recorded edge: conflicts, nothing numeric to soften it
  expect_identical(v("LEE", "LEA"), "conflicts")
  expect_identical(v("JANE", "JOAN"), "conflicts")
})

test_that("one hop, never transitive closure", {
  expect_identical(v("Al", "Albert"), "corroborates")
  expect_identical(v("Al", "Alexander"), "corroborates")
  expect_identical(v("ALBERT", "ALEXANDER"), "conflicts")
})

test_that("vectorization keeps rows aligned; scalars broadcast; recycling refuses", {
  got <- given_name_agreement("Robert", c("Bob", "Robert", NA))
  expect_identical(got$verdict, c("corroborates", "corroborates", "uninformative"))
  expect_identical(got$reason, c("nickname", "exact", NA_character_))
  expect_error(given_name_agreement(c("A", "B"), c("A", "B", "C")), "recycle")
  expect_error(given_name_agreement(character(0), "SMITH"), "empty")
})

test_that("bare initials: equal corroborate as exact, different conflict", {
  expect_identical(given_name_agreement("R", "R"),
                   data.frame(verdict = "corroborates", reason = "exact",
                              stringsAsFactors = FALSE))
  expect_identical(v("R", "W"), "conflicts")
})
