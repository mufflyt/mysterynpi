# =============================================================================
# One missing-data policy, selectable, with the old behaviour as the default
# =============================================================================
# WHY THIS EXISTS. Every agreement rule in this package already had a missing
# data policy and it was the right one: an absent name decides nothing, so it
# returns "uninformative" and never "conflicts". That policy was hard-coded in
# eight functions, which made it invisible to a caller and impossible to
# tighten. A pipeline that would rather fail loudly than carry an
# uninformative row had no way to ask for that.
#
# So the policy is now a parameter with the previous behaviour as its default.
# Existing callers are unaffected by construction: `na_action = "uninformative"`
# reproduces the old code path exactly, and the contract asserters
# (assert_middle_agreement_contract() and friends) run against the default.
#
# WHAT IS DELIBERATELY NOT OFFERED, and this is the interesting half.
# srr standard G2.14 asks for three options: error on missing (G2.14a), ignore
# with a warning (G2.14b), and replace missing values with imputed ones
# (G2.14c). The first two are implemented here. The third is refused, for a
# reason that is specific to this domain rather than a shortcut:
#
#   An imputed name is a fabricated identity claim. Filling an absent middle
#   name with a modal token, or an absent surname with anything at all, would
#   manufacture exactly the evidence this package exists to withhold --
#   `has_name_information()` and the "uninformative" verdict are both here
#   because absence of evidence was once read as evidence of difference. The
#   symmetric error, reading absence as evidence of sameness, is worse: it
#   resolves a match on a name nobody recorded.
#
# Imputation IS offered where it is defined: `graduation_year_agreement()`
# takes numeric years, where "replace undefined values with the band in which
# they cannot discriminate" is a real operation on a real scale. See the
# na_action documentation there.
# =============================================================================

#' Missing-data policies accepted across the agreement rules
#'
#' @description
#' The vocabulary every `na_action` argument in this package accepts.
#'
#' \describe{
#'   \item{`"uninformative"`}{The default, and the behaviour every release
#'     before 0.10.0 had. A missing value on either side yields
#'     `"uninformative"`: the field decides nothing, and in particular does not
#'     conflict.}
#'   \item{`"warn"`}{As `"uninformative"`, and additionally issues one warning
#'     per call naming the number of missing values seen. For a caller who
#'     expects complete name fields and wants to hear about it without
#'     stopping.}
#'   \item{`"error"`}{Refuses to compare at all when any value is missing. For
#'     a pipeline whose upstream contract already guarantees completeness, so
#'     that a violation surfaces here rather than as a quietly uninformative
#'     row thousands of rows later.}
#' }
#'
#' @details
#' `"impute"` is not a member of this vocabulary. See the note at the top of
#' `R/missing_policy.R`: an imputed name is a fabricated identity claim.
#' Imputation is available only on the numeric year scale, where it is
#' defined; see [graduation_year_agreement()].
#'
#' @seealso [middle_agreement()], [surname_agreement()],
#'   [given_name_agreement()], [gender_agreement()], [suffix_agreement()],
#'   [nickname_agreement()], [license_agreement()]
#' @export
NA_ACTIONS <- c("uninformative", "warn", "error")

#' Resolve and apply a missing-data policy
#'
#' @description
#' Validates an `na_action` argument and acts on the missingness it is given.
#' Called at the top of every agreement rule, before any comparison, so that
#' `"error"` fails before work is done and `"warn"` reports once per call
#' rather than once per row.
#'
#' @param na_action [character(1)] one of [NA_ACTIONS]. Matched with
#'   [match.arg()], so partial matching works and an unknown value is an error
#'   naming the permitted set (srr G2.3a).
#' @param n_missing [integer(1)] how many missing values the caller found.
#' @param what [character(1)] what was missing, for the message.
#' @return [character(1)] the resolved action, invisibly for `"uninformative"`.
#' @examples
#' resolve_na_action("uninformative", 0L, "middle name")
#' resolve_na_action("warn", 0L, "middle name")   # silent: nothing was missing
#' @export
resolve_na_action <- function(na_action = NA_ACTIONS, n_missing = 0L,
                             what = "value") {
  na_action <- match.arg(na_action, NA_ACTIONS)
  if (length(n_missing) != 1L || is.na(n_missing)) {
    stop("n_missing must be a single non-missing count", call. = FALSE)
  }
  if (n_missing > 0L) {
    if (na_action == "error") {
      stop(sprintf(paste0("%d missing %s value(s); na_action = \"error\" ",
                          "refuses to compare. Pass na_action = ",
                          "\"uninformative\" to score them as deciding ",
                          "nothing, or \"warn\" to do that loudly."),
                   n_missing, what),
           call. = FALSE)
    }
    if (na_action == "warn") {
      warning(sprintf(paste0("%d missing %s value(s) scored as ",
                             "\"uninformative\": absent evidence, not ",
                             "conflicting evidence."),
                      n_missing, what),
              call. = FALSE)
    }
  }
  na_action
}

#' Count the missing values in a character or list input
#'
#' @description
#' One definition of "missing" for the agreement rules, so that the policy is
#' applied to the same thing everywhere. A character value is missing when it
#' is `NA` or empty after trimming -- which is what [has_name_information()]
#' decides, reused here rather than re-derived. A token list element is
#' missing when it holds no tokens.
#'
#' @param x [character] or [list] as passed to an agreement rule.
#' @return [integer(1)] the number of missing elements.
#' @examples
#' count_missing_values(c("SMITH", NA, ""))
#' count_missing_values(list(c("A"), character(0)))
#' @export
count_missing_values <- function(x) {
  if (is.list(x)) return(sum(!vapply(x, function(z) length(z) > 0L, logical(1))))
  sum(!has_name_information(as.character(x)))
}

#' Is this value undefined rather than merely missing?
#'
#' @description
#' `NaN`, `Inf` and `-Inf` are not missing values: they are the result of an
#' arithmetic that went wrong upstream, and a year of `Inf` is a different
#' problem from a year nobody recorded. The agreement rules that take numbers
#' separate the two so a caller can refuse one and tolerate the other (srr
#' G2.16).
#'
#' @param x [numeric] or anything coercible with [as.numeric()]. Non-numeric
#'   input is never undefined, so character and factor input returns `FALSE`.
#' @return [logical] the same length as `x`.
#' @examples
#' is_undefined_number(c(2015, NA, NaN, Inf, -Inf))
#' @export
is_undefined_number <- function(x) {
  if (!is.numeric(x)) return(rep(FALSE, length(x)))
  is.nan(x) | is.infinite(x)
}

#' Replace undefined numbers with NA
#'
#' @description
#' The conversion step that lets a numeric agreement rule treat `NaN` and
#' infinities as "no information" rather than as years: they become `NA`, and
#' the missing-data policy then applies to them like any other absence.
#'
#' @param x [numeric] input.
#' @return [numeric] with `NaN`, `Inf` and `-Inf` replaced by `NA_real_`.
#' @examples
#' finite_or_na(c(2015, NaN, Inf))
#' @export
finite_or_na <- function(x) {
  if (!is.numeric(x)) return(x)
  replace(x, is_undefined_number(x), NA_real_)
}

#' Missing-data and undefined-value policy
#'
#' @description
#' The srr standards this file implements, tagged so `srr::srr_stats_pre_submit()`
#' can count them. The implementations and their reasoning are in the functions
#' below; this block only records which standard each one serves.
#'
#' @srrstats {G2.14} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {G2.14a} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {G2.14b} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {G2.16} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {RE2.1} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {TS2.1} implemented in this file; see the function documentation and the file header for the defect it prevents.

#' @name srr-missing-policy
#' @keywords internal
NULL

