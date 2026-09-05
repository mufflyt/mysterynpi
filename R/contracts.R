# =============================================================================
# Contracts a CALLER can assert against this package
# =============================================================================
#
# WHY THESE SHIP WITH THE PACKAGE. The pipelines this code was extracted from
# already shared functions by source()-ing across repositories, and that
# sharing is exactly what broke: a consolidation upstream moved a resolver's
# default identifier column, and a caller relying on the default died fifteen
# minutes into a run. The loud failure was the lucky one -- a caller whose data
# happened to carry a column named by the NEW default would have enforced its
# one-to-one constraint over the wrong identifier and produced a clean-looking,
# wrong cohort.
#
# Co-locating code does not fix that. Versioning plus an assertable contract
# does. A caller pins the BEHAVIOUR it relies on, runs this in its own test
# suite, and a breaking change in mysterynpi fails in the caller's CI rather than
# in its published numbers.
# =============================================================================

#' Assert that middle-name agreement still behaves as this caller relies on.
#'
#' Call from your own test suite. Each assertion below is a defect that has
#' shipped; a change to this package that flips any of them is a breaking
#' change and must be a major version bump.
#'
#' @param fn the function to test; defaults to [middle_agreement()] so a caller
#'   can also run it against a stand-in to prove the assertion can fail.
#' @param tokens tokeniser to pair with `fn`.
#' @return `TRUE` invisibly, or `stop()` naming the property that failed.
#' @export
assert_middle_agreement_contract <- function(fn = middle_agreement,
                                             tokens = middle_tokens) {
  say <- function(a, b) fn(tokens(a), tokens(b))
  expect <- list(
    # position must not manufacture disagreement
    list("A REINHARD", "REINHARD",        "corroborates"),
    list("BETH HARVEY", "H",              "corroborates"),
    list("M", "ANN MARIE",                "corroborates"),
    # concatenated initials are initials
    list("VL", "VELMA LAURITZEN",         "corroborates"),
    list("MJ", "MARY JANE",               "corroborates"),
    list("VL", "LAURITZEN VELMA",         "conflicts"),
    # the veto must keep working
    list("JANE", "DENISE",                "conflicts"),
    list("MARILYN", "F",                  "conflicts"),
    list("JANE", "JOAN",                  "conflicts"),
    # no edit-distance tolerance
    list("JULIA", "JULIE",                "conflicts"),
    list("ELISABETH", "ELIZABETH",        "conflicts"),
    # absence is never evidence of difference
    list("", "MARIE",                     "uninformative"),
    list(NA_character_, "MARIE",          "uninformative"),
    list("", "",                          "uninformative"))
  for (e in expect) {
    got <- say(e[[1]], e[[2]])
    if (!identical(got, e[[3]])) {
      stop(sprintf("middle_agreement contract: %s vs %s gave '%s', expected '%s'",
                   if (is.na(e[[1]])) "NA" else e[[1]], e[[2]], got, e[[3]]),
           call. = FALSE)
    }
  }
  if (!inherits(try(fn(list("A"), list("A", "B")), silent = TRUE), "try-error")) {
    stop("middle_agreement contract: mismatched lengths must error, not recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that gender blocking still behaves as this caller relies on.
#'
#' Call from your own test suite. The properties pinned here are the ones a
#' blocking caller silently depends on: encoding differences must not
#' manufacture a veto, absence must never be read as a conflict, and numeric
#' codes must not be guessed at.
#'
#' @param fn the function to test; defaults to [gender_agreement()] so a
#'   caller can also run it against a stand-in to prove the assertion can fail.
#' @return `TRUE` invisibly, or `stop()` naming the property that failed.
#' @export
assert_gender_agreement_contract <- function(fn = gender_agreement) {
  expect <- list(
    # encoding differences must not manufacture a veto
    list("Female", "F",          "corroborates"),
    list(" male ", "M",          "corroborates"),
    # the veto must keep working
    list("M", "F",               "conflicts"),
    list("FEMALE", "MALE",       "conflicts"),
    # absence -- or a code this rule cannot map -- decides nothing
    list("U", "F",               "uninformative"),
    list("", "M",                "uninformative"),
    list(NA_character_, "F",     "uninformative"),
    # numeric conventions are not guessed at
    list("1", "M",               "uninformative"),
    list("2", "F",               "uninformative"))
  for (e in expect) {
    got <- fn(e[[1]], e[[2]])
    if (!identical(got, e[[3]])) {
      stop(sprintf("gender_agreement contract: %s vs %s gave '%s', expected '%s'",
                   if (is.na(e[[1]])) "NA" else e[[1]], e[[2]], got, e[[3]]),
           call. = FALSE)
    }
  }
  if (!inherits(try(fn(c("M", "F"), "M"), silent = TRUE), "try-error")) {
    stop("gender_agreement contract: mismatched lengths must error, not recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}
