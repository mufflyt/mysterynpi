# =============================================================================
# Given-name agreement: the categorical three-valued verdict
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR: downstream pipelines compared given
# names with hand-rolled numeric similarity (the 2026-09-19 isochrones
# survey found ~24 such sites), and every one of them converted "we do not
# know" into a number - usually zero, sometimes a neutral 0.5 - so absence
# scored like disagreement and a missing first name silently killed or
# manufactured matches. The replacement is not a governed score; it is NO
# score (owner ruling, 2026-09-19: approximate spelling similarity is not
# part of the identity architecture). A spelling difference that no named
# deterministic rule explains IS a conflict, and stays one.
#
# The package's existing given-name comparison, names_have_compatible_given(),
# answers a logical and therefore collapses "nothing to compare" into its
# answer. This verdict keeps the three legs separate, in the house
# vocabulary: corroborates / conflicts / uninformative.
# =============================================================================

#' Categorical given-name agreement, three-valued with named detail states
#'
#' Deterministic verdicts only - no edit distance, no thresholds:
#' \describe{
#'   \item{`corroborates`}{compact keys equal after [name_key()]
#'     normalisation: case, punctuation, spacing and accents can never
#'     read as difference.}
#'   \item{`corroborates_nickname`}{one-hop equivalents under
#'     [NICKNAME_EDGES] - a recorded edge or a shared formal root, the same
#'     relation [nickname_agreement()] corroborates on, never transitive
#'     closure.}
#'   \item{`corroborates_initial`}{exactly one side is a single letter and
#'     it equals the other side's first letter - an explicit rule about
#'     initials, not a similarity band. An initial matches many people;
#'     callers must treat this as WEAK corroboration (countable, never
#'     rankable), which is why it is a distinct state and not folded into
#'     `corroborates`.}
#'   \item{`conflicts`}{both sides observed and no named rule above
#'     explains the difference. JULIA/JULIE conflicts, deliberately: no
#'     edit-distance tolerance exists to convert it.}
#'   \item{`uninformative`}{either side missing or empty of letters.
#'     Absence is never evidence of difference: NA vs SMITH is
#'     uninformative, never a conflict, never a zero.}
#' }
#'
#' Callers needing the coarse three values may collapse every
#' `corroborates_*` to `corroborates`; the detail states exist so policy
#' can weigh a nickname edge or a bare initial differently from an exact
#' match WITHOUT anyone reintroducing a number to do it.
#'
#' Length discipline: equal lengths or scalar broadcast; anything else
#' refuses to recycle (comparing person 1 against person 3 and reporting
#' the result as though it had been asked for is how identity vectors get
#' silently mispaired).
#'
#' @param a,b character vectors of given names.
#' @return character vector over
#'   `c("corroborates", "corroborates_nickname", "corroborates_initial",
#'      "conflicts", "uninformative")`.
#' @family agreement rules
#' @export
given_name_agreement <- function(a, b) {
  la <- length(a); lb <- length(b)
  if (la != lb) {
    if (la == 0L || lb == 0L) {
      stop("given_name_agreement: one input is empty (", min(la, lb),
           ") and the other is not (", max(la, lb),
           "). Refusing to recycle identity vectors.", call. = FALSE)
    }
    if (la == 1L) a <- rep(a, lb)
    else if (lb == 1L) b <- rep(b, la)
    else stop("given_name_agreement: inputs must be the same length, or one ",
              "must be length 1 for broadcasting; got ", la, " and ", lb,
              ". Refusing to recycle identity vectors.", call. = FALSE)
  }
  ka <- compact_name_key(a)
  kb <- compact_name_key(b)
  n <- length(ka)
  out <- rep("uninformative", n)
  ok <- !is.na(ka) & !is.na(kb)
  if (!any(ok)) return(out)

  exact <- ok & ka == kb
  out[exact] <- "corroborates"

  # initials rule: exactly one bare initial, matching the other's first letter
  ia <- nchar(ka) == 1L
  ib <- nchar(kb) == 1L
  one_initial <- ok & !exact & xor(ia, ib)
  init_match <- one_initial &
    substr(ka, 1L, 1L) == substr(kb, 1L, 1L)
  out[init_match] <- "corroborates_initial"
  out[one_initial & !init_match] <- "conflicts"

  # nickname rule: one-hop relation under the one corpus
  todo <- which(ok & !exact & !one_initial)
  if (length(todo)) {
    dict <- get_nickname_dictionary()
    nick <- vapply(todo, function(i) {
      isTRUE(are_nickname_equivalents(a[i], b[i], dict))
    }, logical(1))
    out[todo[nick]] <- "corroborates_nickname"
    out[todo[!nick]] <- "conflicts"
  }
  # two bare initials against each other: equal was caught by `exact`;
  # different single letters are a conflict, already assigned above via the
  # nickname branch (single letters are never corpus members).
  out
}

#' Assert the given-name agreement contract
#'
#' Executable pin, runnable in downstream suites so a semantic drift fails
#' their CI: the user's canonical missingness table (SMITH/SMITH
#' corroborates, SMITH/JONES conflicts, NA/SMITH uninformative, NA/NA
#' uninformative), the named detail states, the no-edit-distance rule
#' (JULIA/JULIE conflicts), and the refusal to recycle.
#'
#' @param fn implementation to check; defaults to [given_name_agreement()].
#'   Accepting a stand-in keeps the assertion falsifiable - an assertion
#'   only the real implementation can pass is indistinguishable from one
#'   that always passes.
#' @return invisible TRUE, or an error naming the violated property.
#' @family agreement rules
#' @export
assert_given_name_agreement_contract <- function(fn = given_name_agreement) {
  chk <- function(got, want, msg) {
    if (!identical(got, want)) {
      stop("given-name agreement contract violated: ", msg,
           " (got ", paste(got, collapse = ", "), ")", call. = FALSE)
    }
  }
  chk(fn("SMITH", "SMITH"), "corroborates", "exact must corroborate")
  chk(fn("Smith", " SMITH "), "corroborates", "case/space must not differ")
  chk(fn("SMITH", "JONES"), "conflicts", "observed difference must conflict")
  chk(fn(NA_character_, "SMITH"), "uninformative", "NA vs value must be uninformative")
  chk(fn(NA_character_, NA_character_), "uninformative", "NA vs NA must be uninformative")
  chk(fn("", "SMITH"), "uninformative", "empty vs value must be uninformative")
  chk(fn("BOB", "ROBERT"), "corroborates_nickname", "recorded edge must be named")
  chk(fn("R", "ROBERT"), "corroborates_initial", "matching initial must be named")
  chk(fn("R", "WILLIAM"), "conflicts", "non-matching initial must conflict")
  chk(fn("JULIA", "JULIE"), "corroborates_nickname",
      "a RECORDED corpus edge is declared equivalence, not fuzz")
  chk(fn("LEE", "LEA"), "conflicts",
      "no edit-distance tolerance: LEE/LEA has no recorded edge and conflicts")
  chk(fn("ALBERT", "ALEXANDER"), "conflicts",
      "shared nickname must not weld two formal names (one hop only)")
  refused <- tryCatch({ fn(c("A", "B"), c("A", "B", "C")); FALSE },
                      error = function(e) TRUE)
  if (!isTRUE(refused)) {
    stop("given-name agreement contract violated: unequal non-scalar lengths must refuse to recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}
