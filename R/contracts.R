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

#' Assert that nickname agreement still behaves as this caller relies on.
#'
#' Pins the one-hop semantics: a recorded edge admits, a shared formal name
#' admits, and a shared NICKNAME does not -- AL must never merge ALBERT with
#' ALEXANDER. A table update that flips any of these is a breaking change.
#'
#' @param fn the function to test; defaults to [nickname_agreement()].
#' @return `TRUE` invisibly, or `stop()` naming the property that failed.
#' @export
assert_nickname_agreement_contract <- function(fn = nickname_agreement) {
  expect <- list(
    # a recorded edge admits, in either direction
    list("BETH", "ELIZABETH",     "corroborates"),
    list("ELIZABETH", "LIZ",      "corroborates"),
    # a shared formal name admits
    list("BOB", "BOBBY",          "corroborates"),
    # a shared nickname does NOT: one hop, no transitive closure
    list("ALBERT", "ALEXANDER",   "conflicts"),
    list("AL", "ALBERT",          "corroborates"),
    # no edit-distance tolerance -- only recorded edges admit
    list("ELISABETH", "ELIZABETH", "conflicts"),
    list("JANE", "JOAN",          "conflicts"),
    # an initial is compatibility, not a nickname (issue #3 residual)
    list("J", "JAMES",            "corroborates"),
    list("J", "ROBERT",           "conflicts"),
    # absence decides nothing
    list("", "MARY",              "uninformative"),
    list(NA_character_, "MARY",   "uninformative"))
  for (e in expect) {
    got <- fn(e[[1]], e[[2]])
    if (!identical(got, e[[3]])) {
      stop(sprintf("nickname_agreement contract: %s vs %s gave '%s', expected '%s'",
                   if (is.na(e[[1]])) "NA" else e[[1]], e[[2]], got, e[[3]]),
           call. = FALSE)
    }
  }
  if (!inherits(try(fn(c("A", "B"), "A"), silent = TRUE), "try-error")) {
    stop("nickname_agreement contract: mismatched lengths must error, not recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that suffix agreement still behaves as this caller relies on.
#'
#' Pins the father/son veto and the generation semantics: SR vs JR conflicts,
#' JR vs II corroborates (both a second-of-name), absence decides nothing.
#'
#' @param fn the function to test; defaults to [suffix_agreement()].
#' @return `TRUE` invisibly, or `stop()` naming the property that failed.
#' @export
assert_suffix_agreement_contract <- function(fn = suffix_agreement) {
  expect <- list(
    list("JR", "SR",              "conflicts"),      # the veto itself
    list("II", "III",             "conflicts"),
    list("JR", "II",              "corroborates"),   # both second-of-name
    list("Jr.", "JUNIOR",         "corroborates"),
    list(NA_character_, "JR",     "uninformative"),
    list("", "SR",                "uninformative"),
    list("V", "IV",               "uninformative"))  # V is an initial, not a suffix
  for (e in expect) {
    got <- fn(e[[1]], e[[2]])
    if (!identical(got, e[[3]])) {
      stop(sprintf("suffix_agreement contract: %s vs %s gave '%s', expected '%s'",
                   if (is.na(e[[1]])) "NA" else e[[1]], e[[2]], got, e[[3]]),
           call. = FALSE)
    }
  }
  if (!inherits(try(fn(c("JR", "SR"), "JR"), silent = TRUE), "try-error")) {
    stop("suffix_agreement contract: mismatched lengths must error, not recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that license agreement still behaves as this caller relies on.
#'
#' Pins the two-verdict design: same state and same normalised number
#' corroborates; everything else -- including a same-state mismatch, which
#' a quarter of multi-licensed NPIs make ordinary -- is uninformative, and
#' no input can produce a conflict.
#'
#' @param fn the function to test; defaults to [license_agreement()].
#' @return `TRUE` invisibly, or `stop()` naming the property that failed.
#' @export
assert_license_agreement_contract <- function(fn = license_agreement) {
  expect <- list(
    list("MD-12345", "CO", "md 12345", "co", "corroborates"),
    list("12345", "CO", "12345", "TX",       "uninformative"),  # states differ
    list("12345", "CO", "99999", "CO",       "uninformative"),  # NOT a conflict
    list("0052", "CO", "52", "CO",           "uninformative"),  # zeros are kept
    list("12345", "CO", NA, "CO",            "uninformative"),
    list("12345", NA, "12345", "CO",         "uninformative"))  # no state, no license
  for (e in expect) {
    got <- fn(e[[1]], e[[2]], e[[3]], e[[4]])
    if (!identical(got, e[[5]])) {
      stop(sprintf("license_agreement contract: (%s,%s) vs (%s,%s) gave '%s', expected '%s'",
                   e[[1]], e[[2]], e[[3]], e[[4]], got, e[[5]]),
           call. = FALSE)
    }
  }
  if (!inherits(try(fn(c("1", "2"), "CO", "1", "CO"), silent = TRUE),
                "try-error")) {
    stop("license_agreement contract: mismatched lengths must error, not recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' Assert that surname agreement still behaves as this caller relies on.
#'
#' Pins the component logic, the sub-floor exact match, the apostrophe fold,
#' the particle refusal, and the maiden-as-middle rescue -- each a measured
#' failure mode of exact-equality surname comparison.
#'
#' @param fn the function to test; defaults to [surname_agreement()].
#' @return `TRUE` invisibly, or `stop()` naming the property that failed.
#' @export
assert_surname_agreement_contract <- function(fn = surname_agreement) {
  expect <- list(
    # a shared component spans hyphenation and dropped parts
    list("MCCARTHY-DERVIN", "MCCARTHY",   "corroborates"),
    # exact equality still counts below the token floor
    list("LEE", "LEE",                    "corroborates"),
    # formatting must not veto
    list("O'BRIEN", "OBRIEN",             "corroborates"),
    # particles are convention, not identity
    list("DE LA CRUZ", "DE LEON",         "conflicts"),
    # recorded difference conflicts
    list("LEE", "SMITH",                  "conflicts"),
    # absence decides nothing
    list("", "SMITH",                     "uninformative"),
    list(NA_character_, "SMITH",          "uninformative"))
  for (e in expect) {
    got <- fn(e[[1]], e[[2]])
    if (!identical(got, e[[3]])) {
      stop(sprintf("surname_agreement contract: %s vs %s gave '%s', expected '%s'",
                   if (is.na(e[[1]])) "NA" else e[[1]], e[[2]], got, e[[3]]),
           call. = FALSE)
    }
  }
  rescued <- fn("RYE", "REINHARD", middle_a = "REINHARD", middle_b = "A")
  if (!identical(rescued, "corroborates")) {
    stop("surname_agreement contract: the maiden-as-middle rescue must ",
         "corroborate RYE vs REINHARD when REINHARD sits in the middle slot",
         call. = FALSE)
  }
  if (!inherits(try(fn(c("A", "B"), "A"), silent = TRUE), "try-error")) {
    stop("surname_agreement contract: mismatched lengths must error, not recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}
