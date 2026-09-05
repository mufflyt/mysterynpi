# Declarative registry of the agreement rules, iterated by the generic
# contract battery in test-rule-contracts.R. Pattern from howardjp/phonics
# (BSD-2-Clause), tests/testthat/helper-encoders.R: a rule added to this list
# inherits the whole battery -- closed verdict set, absence handling, symmetry,
# determinism, vectorisation, recycling refusal -- without writing new tests.
#
# `fn` takes two character vectors of equal length and returns verdicts.
# `verdicts` is the CLOSED set the rule may emit; license has two by design.

rule_specs <- list(
  middle = list(
    fn = function(a, b) middle_agreement(middle_tokens(a), middle_tokens(b)),
    verdicts = c("corroborates", "conflicts", "uninformative")),
  gender = list(
    fn = gender_agreement,
    verdicts = c("corroborates", "conflicts", "uninformative")),
  nickname = list(
    fn = nickname_agreement,
    verdicts = c("corroborates", "conflicts", "uninformative")),
  suffix = list(
    fn = suffix_agreement,
    verdicts = c("corroborates", "conflicts", "uninformative")),
  surname = list(
    fn = function(a, b) surname_agreement(a, b),
    verdicts = c("corroborates", "conflicts", "uninformative")),
  license = list(
    fn = function(a, b) {
      license_agreement(a, rep("CO", length(a)), b, rep("CO", length(b)))
    },
    verdicts = c("corroborates", "uninformative")))

# Deterministic name-shaped inputs for the property block: tokens, dotted
# initials, hyphens, blanks and NAs -- the shapes rosters actually hold.
random_name_pool <- function(n, seed) {
  old <- if (exists(".Random.seed", globalenv())) get(".Random.seed", globalenv())
  on.exit(if (!is.null(old)) assign(".Random.seed", old, globalenv()))
  set.seed(seed)
  mk <- function() paste(sample(LETTERS, sample(1:9, 1), TRUE), collapse = "")
  pool <- replicate(n, mk())
  pool[seq(1, n, by = 11)] <- paste0(substr(pool[seq(1, n, by = 11)], 1, 1), ".")
  pool[seq(2, n, by = 13)] <- paste0(pool[seq(2, n, by = 13)], "-",
                                     rev(pool)[seq(2, n, by = 13)])
  pool[seq(3, n, by = 17)] <- ""
  pool[seq(4, n, by = 19)] <- NA_character_
  pool
}
