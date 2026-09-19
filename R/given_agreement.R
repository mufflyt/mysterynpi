# =============================================================================
# Given-name agreement: the categorical three-valued verdict
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR: downstream pipelines compared given
# names with hand-rolled numeric similarity (the 2026-09-19 isochrones
# survey found ~24 such sites), and every one of them converted "we do not
# know" into a number - usually zero, sometimes a neutral 0.5 - so absence
# scored like disagreement and a missing first name silently killed or
# manufactured matches. The replacement is not a governed number; it is NO
# number (owner ruling, 2026-09-19: approximate spelling similarity is not
# part of the identity architecture). A spelling difference that no named
# deterministic rule explains IS a conflict, and stays one.
#
# The package's existing given-name comparison, names_have_compatible_given(),
# answers a logical and therefore collapses "nothing to compare" into its
# answer. This verdict keeps the three legs separate, in the house
# vocabulary: corroborates / conflicts / uninformative. Detail travels in a
# separate `reason` column so the coarse verdict stays stable and nobody is
# tempted to grow an ever-longer verdict-string taxonomy.
# =============================================================================

#' Categorical given-name agreement: verdict plus named reason
#'
#' Deterministic rules only - no edit distance, no thresholds, no number of
#' any kind. Returns one row per pair with two columns:
#'
#' \describe{
#'   \item{`verdict`}{`"corroborates"` / `"conflicts"` / `"uninformative"` -
#'     the same three-valued vocabulary as every other `*_agreement()` rule.
#'     `uninformative` means either side is missing or empty of letters;
#'     absence is never evidence of difference.}
#'   \item{`reason`}{the NAMED deterministic rule behind a `corroborates`:
#'     \itemize{
#'       \item `"exact"` - compact keys equal after [name_key()]
#'         normalisation, so case, punctuation, spacing and accents can
#'         never read as difference;
#'       \item `"nickname"` - a RECORDED one-hop [NICKNAME_EDGES] relation
#'         (a recorded edge or a shared formal root, the same relation
#'         [nickname_agreement()] corroborates on, never transitive
#'         closure). Declared equivalence, not spelling similarity:
#'         JULIA/JULIE corroborates because the corpus records the edge,
#'         while LEE/LEA - one edit apart, no edge - conflicts;
#'       \item `"initial"` - exactly one side is a single letter and it
#'         equals the other side's first letter. An explicit rule about
#'         initials, and deliberately WEAK evidence (an initial matches
#'         many people): callers must treat it as countable, never
#'         rankable, which is why the reason travels with the verdict.
#'     }
#'     `NA_character_` for `conflicts` and `uninformative`.}
#' }
#'
#' Length discipline: equal lengths or scalar broadcast; anything else
#' refuses to recycle (comparing person 1 against person 3 and reporting
#' the result as though it had been asked for is how identity vectors get
#' silently mispaired).
#'
#' @param a,b character vectors of given names.
#' @return data.frame with columns `verdict` and `reason`, one row per pair.
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
  verdict <- rep("uninformative", n)
  reason <- rep(NA_character_, n)
  ok <- !is.na(ka) & !is.na(kb)

  if (any(ok)) {
    exact <- ok & ka == kb
    verdict[exact] <- "corroborates"
    reason[exact] <- "exact"

    # initials rule: exactly one bare initial, matching the other's first
    # letter; a bare initial against a DIFFERENT first letter is a conflict
    ia <- nchar(ka) == 1L
    ib <- nchar(kb) == 1L
    one_initial <- ok & !exact & xor(ia, ib)
    init_match <- one_initial & substr(ka, 1L, 1L) == substr(kb, 1L, 1L)
    verdict[init_match] <- "corroborates"
    reason[init_match] <- "initial"
    verdict[one_initial & !init_match] <- "conflicts"

    # nickname rule: one-hop relation under the one pinned corpus - declared
    # equivalence, never inferred from spelling
    todo <- which(ok & !exact & !one_initial)
    if (length(todo)) {
      dict <- get_nickname_dictionary()
      nick <- vapply(todo, function(i) {
        isTRUE(are_nickname_equivalents(a[i], b[i], dict))
      }, logical(1))
      verdict[todo[nick]] <- "corroborates"
      reason[todo[nick]] <- "nickname"
      verdict[todo[!nick]] <- "conflicts"
    }
  }
  data.frame(verdict = verdict, reason = reason, stringsAsFactors = FALSE)
}

#' Assert the given-name agreement contract
#'
#' Executable pin, runnable in downstream suites so a semantic drift fails
#' their CI: the canonical missingness table (SMITH/SMITH corroborates,
#' SMITH/JONES conflicts, NA/SMITH uninformative, NA/NA uninformative), the
#' named reasons, the declared-alias-versus-spelling distinction
#' (JULIA/JULIE corroborates via the recorded edge; LEE/LEA conflicts with
#' nothing to soften it), one-hop-only nickname semantics, and the refusal
#' to recycle.
#'
#' @param fn implementation to check; defaults to [given_name_agreement()].
#'   Accepting a stand-in keeps the assertion falsifiable - an assertion
#'   only the real implementation can pass is indistinguishable from one
#'   that always passes.
#' @return invisible TRUE, or an error naming the violated property.
#' @family agreement rules
#' @export
assert_given_name_agreement_contract <- function(fn = given_name_agreement) {
  one <- function(a, b) {
    r <- fn(a, b)
    if (!is.data.frame(r) || !all(c("verdict", "reason") %in% names(r)) ||
        nrow(r) != 1L) {
      stop("given-name agreement contract violated: result must be a ",
           "one-row data.frame with columns verdict and reason", call. = FALSE)
    }
    r
  }
  chk <- function(got, want_v, want_r, msg) {
    if (!identical(got$verdict, want_v) ||
        !identical(got$reason, want_r)) {
      stop("given-name agreement contract violated: ", msg,
           " (got verdict=", got$verdict, ", reason=", got$reason, ")",
           call. = FALSE)
    }
  }
  chk(one("SMITH", "SMITH"), "corroborates", "exact", "exact must corroborate")
  chk(one("Smith", " SMITH "), "corroborates", "exact", "case/space must not differ")
  chk(one("SMITH", "JONES"), "conflicts", NA_character_, "observed difference must conflict")
  chk(one(NA_character_, "SMITH"), "uninformative", NA_character_, "NA vs value must be uninformative")
  chk(one(NA_character_, NA_character_), "uninformative", NA_character_, "NA vs NA must be uninformative")
  chk(one("", "SMITH"), "uninformative", NA_character_, "empty vs value must be uninformative")
  chk(one("BOB", "ROBERT"), "corroborates", "nickname", "recorded edge must carry reason nickname")
  chk(one("JULIA", "JULIE"), "corroborates", "nickname",
      "a RECORDED corpus edge is declared equivalence, not fuzz")
  chk(one("LEE", "LEA"), "conflicts", NA_character_,
      "no edit-distance tolerance: LEE/LEA has no recorded edge and conflicts")
  chk(one("R", "ROBERT"), "corroborates", "initial", "matching initial must carry reason initial")
  chk(one("R", "WILLIAM"), "conflicts", NA_character_, "non-matching initial must conflict")
  chk(one("ALBERT", "ALEXANDER"), "conflicts", NA_character_,
      "shared nickname must not weld two formal names (one hop only)")
  refused <- tryCatch({ fn(c("A", "B"), c("A", "B", "C")); FALSE },
                      error = function(e) TRUE)
  if (!isTRUE(refused)) {
    stop("given-name agreement contract violated: unequal non-scalar lengths must refuse to recycle",
         call. = FALSE)
  }
  invisible(TRUE)
}
