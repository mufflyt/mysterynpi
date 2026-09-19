# =============================================================================
# Deterministic similarity primitives: the ONE governed home for numeric
# person-name similarity
# =============================================================================
#
# PRINCIPLE (owner ruling, 2026-09-19): Jaro-Winkler and Levenshtein are
# deterministic functions. The defect this module exists to end is not fuzzy
# scoring itself but HAND-ROLLED, INCONSISTENT, UNAUDITED fuzzy scoring - the
# 2026-09-19 isochrones survey found ~24 call sites each with its own
# normalisation, its own missing-value behaviour (usually the silent
# missing-becomes-zero bug), and its own thresholds. These primitives are the
# replacement: one normalisation (the package's own keys), one missing
# contract, pinned method parameters, and a contract assert callers can pin.
#
# THE MISSING CONTRACT IS THE POINT. missing + present = NA_real_. missing +
# missing = NA_real_. Only two OBSERVED values may produce a number. A local
# implementation that returns 0 for a missing side has decided that "we do
# not know this person's middle name" is the same evidence as "the middle
# names are utterly different" - the exact conversion of absence into
# disagreement the whole package exists to refuse.
#
# WHAT THESE ARE FOR - and not. Scores RANK and SCORE within the decision
# layer; the categorical *_agreement() verdicts remain similarity-free, and
# test-no-fuzzy.R proves by call-graph reachability that no agreement rule
# can reach anything in this module. Similarity informs a governed weighted
# decision; it never silently flips a verdict.
# =============================================================================

#' Pinned Jaro-Winkler prefix weight
#'
#' Named so no caller ever re-derives it: stringdist's `p` parameter for the
#' Winkler prefix bonus. 0.1 is the classical Winkler setting; 0 degrades to
#' plain Jaro. Changing this changes every score in every consumer - it is a
#' versioned package decision, not a call-site knob left to drift.
#' @family similarity
#' @export
JW_PREFIX_WEIGHT <- 0.1

#' Pinned nickname-equivalence similarity
#'
#' The score assigned when two given names are one-hop nickname equivalents
#' under [NICKNAME_EDGES] - deliberately just under exact (1.0) and far above
#' any plausible Jaro-Winkler for unrelated names, so a recorded BOB/ROBERT
#' edge always outranks a coincidental spelling neighbour. The historical
#' 0.96/0.94 sub-tiers were consolidated to 0.98 in 2026-09 (see NEWS).
#' @family similarity
#' @export
NICKNAME_SIMILARITY <- 0.98

# Shared engine: length discipline, key normalisation, missing contract.
# Length rules follow the house .nm_pair_len law: equal lengths, or scalar
# broadcast, or an error - silent rep_len() recycling would compare person 1
# against person 3 and report the result as though it had been asked for.
.similarity_engine <- function(a, b, method, key_fn, what) {
  la <- length(a); lb <- length(b)
  if (la != lb) {
    if (la == 0L || lb == 0L) {
      stop(sprintf("%s: one input is empty (%d) and the other is not (%d). Refusing to recycle identity vectors.",
                   what, min(la, lb), max(la, lb)), call. = FALSE)
    }
    if (la == 1L) a <- rep(a, lb)
    else if (lb == 1L) b <- rep(b, la)
    else stop(sprintf("%s: inputs must be the same length, or one must be length 1 for broadcasting; got %d and %d.",
                      what, la, lb), call. = FALSE)
  }
  ka <- key_fn(a); kb <- key_fn(b)
  out <- rep(NA_real_, length(ka))
  ok <- !is.na(ka) & nzchar(ka) & !is.na(kb) & nzchar(kb)
  if (any(ok)) {
    out[ok] <- switch(method,
      jw = 1 - stringdist::stringdist(ka[ok], kb[ok], method = "jw",
                                      p = JW_PREFIX_WEIGHT),
      lv = stringdist::stringsim(ka[ok], kb[ok], method = "lv"))
  }
  out
}

#' Numeric surname similarity, missing-aware and vectorized
#'
#' Similarity in `[0, 1]` between surnames compared on their letters-only
#' compact keys ([compact_name_key()]), so hyphenation, apostrophes, spacing
#' and case can never masquerade as distance: `"Jones-Cox"` vs `"JONES COX"`
#' is exactly 1. `NA_real_` unless BOTH sides are observed. Deterministic:
#' same inputs, same version, same numbers.
#'
#' This is a SCORE for the decision layer, not a verdict:
#' [surname_agreement()] stays categorical and similarity-free. A caller who
#' converts this number to accept/reject with a local literal has recreated
#' the private-threshold defect; thresholds belong in a named, versioned
#' decision configuration.
#'
#' @param a,b character vectors of surnames (equal length, or either scalar).
#' @param method `"jw"` (Jaro-Winkler, prefix weight [JW_PREFIX_WEIGHT]) or
#'   `"lv"` (normalised Levenshtein similarity, `1 - dist / max(length)`).
#' @return numeric vector in `[0, 1]`, `NA_real_` where either side is
#'   missing or empty of letters.
#' @family similarity
#' @export
surname_similarity <- function(a, b, method = c("jw", "lv")) {
  method <- match.arg(method)
  .similarity_engine(a, b, method, compact_name_key, "surname_similarity")
}

#' Numeric middle-name similarity, missing-aware and vectorized
#'
#' Same engine and contract as [surname_similarity()], on compact keys.
#' NOTE ON INITIALS: an initial against a full name (`"R"` vs `"ROBERT"`)
#' produces a mechanically low score that MEANS NOTHING about the person -
#' most registry rows record only an initial. That comparison belongs to
#' [middle_agreement()], whose initial rules are categorical; use this only
#' when both sides carry full middle names, or feed the decision layer,
#' which is missing-aware and initial-aware by configuration.
#'
#' @inheritParams surname_similarity
#' @return numeric vector in `[0, 1]`, `NA_real_` where either side is
#'   missing or empty of letters.
#' @family similarity
#' @export
middle_name_similarity <- function(a, b, method = c("jw", "lv")) {
  method <- match.arg(method)
  .similarity_engine(a, b, method, compact_name_key, "middle_name_similarity")
}

#' Numeric given-name similarity: nickname-aware, missing-aware, vectorized
#'
#' The canonical replacement for
#' [calculate_enhanced_first_name_similarity()] (deprecated) and for every
#' hand-rolled first-name Jaro-Winkler in downstream pipelines. Per pair:
#' \enumerate{
#'   \item exact after compact-key normalisation: `1`
#'   \item one-hop nickname equivalents under [NICKNAME_EDGES] (the same
#'     relation [nickname_agreement()] corroborates on - a recorded edge or
#'     a shared formal root, never transitive closure): [NICKNAME_SIMILARITY]
#'   \item both observed, otherwise: Jaro-Winkler on compact keys, taking
#'     the LARGER of the raw score and the umlaut-digraph-simplified score
#'     (`AE/OE/UE -> A/O/U`), so `MUELLER` and `MULLER` score as the same
#'     romanisation family rather than as strangers
#'   \item either side missing: `NA_real_` - never `0`, never a neutral
#'     constant. (The deprecated function returned `0.5` for missing; that
#'     neutral scalar is exactly the absence-into-evidence conversion this
#'     contract forbids.)
#' }
#'
#' @param a,b character vectors of given names (equal length, or either
#'   scalar).
#' @param nickname_aware apply step 2. `TRUE` is the default and the reason
#'   this function exists; `FALSE` gives plain governed Jaro-Winkler.
#' @return numeric vector in `[0, 1]`, `NA_real_` where either side is
#'   missing.
#' @family similarity
#' @export
given_name_similarity <- function(a, b, nickname_aware = TRUE) {
  base <- .similarity_engine(a, b, "jw", compact_name_key,
                             "given_name_similarity")
  # broadcast to common length the same way the engine did
  n <- length(base)
  if (length(a) == 1L) a <- rep(a, n)
  if (length(b) == 1L) b <- rep(b, n)
  ka <- compact_name_key(a); kb <- compact_name_key(b)
  ok <- !is.na(base)
  if (!any(ok)) return(base)

  # step 3 refinement: umlaut-digraph family score, take the larger
  simplify <- function(x) {
    x <- gsub("AE", "A", x, fixed = TRUE)
    x <- gsub("OE", "O", x, fixed = TRUE)
    gsub("UE", "U", x, fixed = TRUE)
  }
  digraph <- rep(NA_real_, n)
  digraph[ok] <- 1 - stringdist::stringdist(simplify(ka[ok]), simplify(kb[ok]),
                                            method = "jw",
                                            p = JW_PREFIX_WEIGHT)
  out <- pmax(base, digraph)

  if (isTRUE(nickname_aware)) {
    out[.nickname_mask(a, b, ok, out)] <- NICKNAME_SIMILARITY
  }
  # exact compact-key equality is 1 regardless of anything above
  out[ok & compact_equal(ka, kb)] <- 1
  out
}

# Which observed, non-exact pairs are one-hop nickname equivalents?
.nickname_mask <- function(a, b, ok, out) {
  dict <- get_nickname_dictionary()
  idx <- which(ok & out < 1)
  if (!length(idx)) return(logical(length(out)))
  hit <- vapply(idx, function(i) {
    isTRUE(are_nickname_equivalents(a[i], b[i], dict))
  }, logical(1))
  mask <- logical(length(out))
  mask[idx[hit]] <- TRUE
  mask
}

# Exact-key equality where both observed (helper for the step-1 override).
compact_equal <- function(ka, kb) {
  !is.na(ka) & !is.na(kb) & ka == kb
}

#' Assert the similarity contract on a similarity function
#'
#' Executable pin for the properties every consumer builds on: missing +
#' present is `NA` (never 0, never a neutral constant), missing + missing is
#' `NA`, self-similarity of an observed name is 1, symmetry, scalar
#' broadcasting works, and unequal non-scalar lengths REFUSE to recycle.
#' Downstream test suites call this against the installed package so a
#' semantic drift fails their build, not just this package's.
#'
#' @param fn a similarity function taking `(a, b)`.
#' @return invisible TRUE, or an error naming the violated property.
#' @family similarity
#' @export
assert_similarity_contract <- function(fn = surname_similarity) {
  chk <- function(cond, msg) if (!isTRUE(cond)) {
    stop("similarity contract violated: ", msg, call. = FALSE)
  }
  chk(is.na(fn("SMITH", NA_character_)), "missing + present must be NA")
  chk(is.na(fn(NA_character_, "SMITH")), "present + missing must be NA")
  chk(is.na(fn(NA_character_, NA_character_)), "missing + missing must be NA")
  chk(identical(fn("Smith", "SMITH"), 1), "self-similarity must be exactly 1")
  chk(identical(fn("Jones", "Smith"), fn("Smith", "Jones")),
      "similarity must be symmetric")
  v <- fn("Smith", c("Smith", "Jones", NA))
  chk(length(v) == 3L && v[1] == 1 && !is.na(v[2]) && is.na(v[3]),
      "scalar broadcasting must pair the scalar with every element")
  refused <- tryCatch({ fn(c("A", "B"), c("A", "B", "C")); FALSE },
                      error = function(e) TRUE)
  chk(refused, "unequal non-scalar lengths must refuse to recycle")
  invisible(TRUE)
}
