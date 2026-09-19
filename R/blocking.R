# =============================================================================
# Blocking keys: named, governed modes instead of caller-side regexes
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR: the 2026-09-19 isochrones survey found
# ~18 call sites independently constructing blocking keys, nine of them
# (state retirement extractors) each re-deriving surname + first-initial
# with their own `sub(" .*", "", toupper(trimws(x)))` / `substr(., 1, 1)`
# lines. Measured at the level that matters - the RESULTING KEY - all nine
# legacy implementations agree with each other in every case (the
# first-token truncation two sites skip cannot change a first initial), so
# the duplication was pure drift surface with no behavioral spread. What a
# canonical key DOES change is canonicalization - on BOTH sides of the
# key, each change a documented, tested fixture (see test-blocking.R):
# surname punctuation/spaces compact, accents transliterate (the exact
# 30%-vs-10.4% unmatched defect name_key() was built for), German
# digraphs romanise, parenthetical alternates strip; the GIVEN-name side
# canonicalizes through extract_first_initial(), so a legacy "É"/"("/"'"
# initial becomes the first normalized LETTER; and insufficient input is
# NA_character_, never a partial key. Classification discipline: these
# are intentional KEY-LEVEL canonicalization deltas and POTENTIAL
# candidate-set deltas - whether a candidate set actually changes is
# measured against frozen data at migration, never inferred from a
# changed key. SCOPE: the nine state-extractor surname_initial sites are
# behaviorally characterized here; prefix_n and compact are canonical
# APIs whose call-site parity is characterized when those sites migrate.
#
# EACH MODE IS BUILT FROM THE PRIMITIVE WHOSE SEMANTICS MATCH IT:
# compact_name_key() for the surname component (blocking must be
# punctuation-insensitive) and extract_first_initial() for the initial
# (its own documentation names "a coarse block" as the use case, and it
# refuses to emit a non-letter - first_initial() would hand back "-" for a
# punctuation-only name, because ITS contract is agreement with the join
# key, not blocking).
# =============================================================================

#' Canonical blocking key, by named mode
#'
#' One governed construction for the keys candidate generation joins on.
#' Modes:
#' \describe{
#'   \item{`surname_initial`}{`<compact surname>|<first initial>` via
#'     [compact_name_key()] and [extract_first_initial()]. The `|`
#'     delimiter makes the component boundary EXPLICIT. It is not needed
#'     to prevent collisions - with a fixed one-character second field,
#'     `surname + initial` is already uniquely separable - it is kept for
#'     readability, auditability (a human reading a ledger sees the two
#'     components), and future-proofing against any mode whose second
#'     field is not fixed-width. The serialized contract is pinned by
#'     test, so the delimiter cannot drift silently.}
#'   \item{`prefix_n`}{the first `n` letters of the compact surname. `n`
#'     is REQUIRED for this mode - the audited call sites used 2, 3 and 4
#'     with materially different candidate pools, so a silent default
#'     would pick a pool width nobody chose - and must be a single
#'     finite whole number >= 1 (1.5, Inf, NaN, "3" and TRUE are caller
#'     mistakes, rejected loudly rather than coerced). A surname shorter
#'     than `n` keys as its full compact form, never padded.}
#'   \item{`compact`}{the compact surname alone ([compact_name_key()]).}
#' }
#'
#' Supplying `n` with any mode other than `prefix_n` is an error: an
#' argument that would be silently discarded is a caller mistake the API
#' should catch, not swallow.
#'
#' MISSING IS INSUFFICIENT, NEVER PARTIAL: if any component a mode
#' requires normalises to nothing (missing, whitespace-only,
#' punctuation-only), the key is `NA_character_`. No `"SMITH|"`, no
#' `"|M"`, no empty-string keys - a partial key silently blocks a person
#' against everyone sharing the observed half. The audited legacy
#' extractors kept the components as SEPARATE columns and filtered
#' missing rows before any join, so for plain missing values this changes
#' the API representation, not their missing-value candidate behavior.
#' The exception is a PUNCTUATION-ONLY given name: `nzchar("-")` is TRUE,
#' so the legacy filter was blind to it and a `-` initial reached
#' candidate generation, where the canonical key is `NA` - a potential
#' candidate-set delta, characterized in test-blocking.R.
#'
#' Length discipline: `last` and `first` must be equal length or scalar;
#' anything else refuses to recycle.
#'
#' @param last character vector of surnames. Required by every mode.
#' @param first character vector of given names. Required by
#'   `surname_initial`; ignored by the other modes.
#' @param mode `"surname_initial"`, `"prefix_n"`, or `"compact"`.
#' @param n prefix length: required for `prefix_n` (single finite whole
#'   number >= 1); an ERROR with any other mode.
#' @return character vector of blocking keys, `NA_character_` where the
#'   mode's required components are insufficient.
#' @family blocking
#' @export
blocking_key <- function(last, first = NULL,
                         mode = c("surname_initial", "prefix_n", "compact"),
                         n = NULL) {
  mode <- match.arg(mode)
  if (mode != "prefix_n" && !is.null(n)) {
    stop("blocking_key: `n` is only meaningful with mode = \"prefix_n\"; ",
         "an argument that would be silently discarded is a caller ",
         "mistake, not a request.", call. = FALSE)
  }
  surname_key <- compact_name_key(last)

  if (mode == "compact") {
    return(surname_key)
  }

  if (mode == "prefix_n") {
    n_ok <- !is.null(n) && length(n) == 1L && is.numeric(n) && !is.na(n) &&
      is.finite(n) && n >= 1 && n == trunc(n)
    if (!n_ok) {
      stop("blocking_key(mode = \"prefix_n\") requires an explicit n: a ",
           "single finite whole number >= 1. The audited call sites used ",
           "2, 3 and 4 with materially different candidate pools, so no ",
           "default is safe, and 1.5/Inf/NaN/\"3\"/TRUE are caller ",
           "mistakes rejected rather than coerced.", call. = FALSE)
    }
    return(substr(surname_key, 1L, as.integer(n)))
  }

  # surname_initial
  if (is.null(first)) {
    stop("blocking_key(mode = \"surname_initial\") requires `first`.",
         call. = FALSE)
  }
  ll <- length(last); lf <- length(first)
  if (ll != lf) {
    if (ll == 0L || lf == 0L) {
      stop("blocking_key: one input is empty (", min(ll, lf),
           ") and the other is not (", max(ll, lf),
           "). Refusing to recycle identity vectors.", call. = FALSE)
    }
    if (ll == 1L) surname_key <- rep(surname_key, lf)
    else if (lf == 1L) first <- rep(first, ll)
    else stop("blocking_key: `last` and `first` must be the same length, ",
              "or one must be length 1 for broadcasting; got ", ll, " and ",
              lf, ". Refusing to recycle identity vectors.", call. = FALSE)
  }
  init <- extract_first_initial(first)
  out <- ifelse(!is.na(surname_key) & !is.na(init),
                paste0(surname_key, "|", init),
                NA_character_)
  as.character(out)
}
