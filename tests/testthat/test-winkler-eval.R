# The Winkler numbers are PINNED, not merely reported: 4 of 327 typo-heavy
# true pairs accepted, zero of 582 same-household negatives. A change that
# moves either number is a change to what the rules recover on a foreign
# corpus, and it must be deliberate -- the recall going UP is how an
# edit-distance tolerance would announce itself.

winkler_decisions <- function(d) {
  ax <- data.frame(
    surname = surname_agreement(d$surname_a, d$surname_b),
    given   = nickname_agreement(d$given_a, d$given_b),
    middle  = middle_agreement(middle_tokens(d$middle_a),
                               middle_tokens(d$middle_b)))
  conflict <- ax$surname == "conflicts" | ax$given == "conflicts" |
    ax$middle == "conflicts"
  name_ok <- ax$surname == "corroborates" & ax$given == "corroborates"
  ifelse(conflict, "reject", ifelse(name_ok, "accept", "review"))
}

test_that("the Winkler trade holds: almost no typo recall, zero false accepts", {
  w <- WINKLER_CENSUS
  a <- w[w$relation == "A", ]; a <- a[!duplicated(a$id), ]
  b <- w[w$relation == "B", ]; b <- b[!duplicated(b$id), ]
  m <- merge(a, b, by = "id", suffixes = c("_a", "_b"))
  expect_identical(nrow(m), 327L)
  dec <- winkler_decisions(m)
  expect_identical(sum(dec == "accept"), 4L)
  expect_identical(sum(dec == "reject"), 323L)

  hn <- merge(a, b, by = c("house", "street"), suffixes = c("_a", "_b"))
  hn <- hn[hn$id_a != hn$id_b, ]
  expect_identical(nrow(hn), 582L)
  expect_identical(sum(winkler_decisions(hn) == "accept"), 0L)
})

test_that("the nickname corpus did its part; the typos did the rejecting", {
  # TRICIA/PATRICIA is a recorded edge and corroborates -- that true pair
  # fell to its SCCHWARTZ surname typo, which no nickname table may rescue
  expect_identical(nickname_agreement("TRICIA", "PATRICIA"), "corroborates")
  expect_identical(surname_agreement("SCCHWARTZ", "SCHWARTZ"), "conflicts")
})
