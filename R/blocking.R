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
# canonical key DOES change is canonicalization, and each such change is a
# documented, tested delta (see test-blocking.R): punctuation compacts
# (O'BRIEN and OBRIEN share a block), accents transliterate (MUNOZ finds
# its unaccented registry spelling - the exact 30%-vs-10.4% unmatched
# defect name_key() was built for), German digraphs romanise (MULLER /
# MUELLER), and insufficient input is NA_character_, never a partial key.
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
#'     delimiter is part of the contract: legacy sites joined on two
#'     separate columns, and a single-string key only reproduces that
#'     safely with an explicit field boundary - surname `ANNA` with
#'     initial `L` must never collide with surname `ANN` and a first name
#'     starting `A` (`"ANNA|L"` vs `"ANN|A"`).}
#'   \item{`prefix_n`}{the first `n` letters of the compact surname. `n`
#'     is REQUIRED for this mode - the audited call sites used 2, 3 and 4
#'     with materially different candidate pools, so a silent default
#'     would pick a pool width nobody chose. A surname shorter than `n`
#'     keys as its full compact form, never padded.}
#'   \item{`compact`}{the compact surname alone ([compact_name_key()]).}
#' }
#'
#' MISSING IS INSUFFICIENT, NEVER PARTIAL: if any component a mode
#' requires normalises to nothing (missing, whitespace-only,
#' punctuation-only), the key is `NA_character_`. No `"SMITH|"`, no
#' `"|M"`, no empty-string keys - a partial key silently blocks a person
#' against everyone sharing the observed half. (The legacy sites built
#' partial keys and filtered them immediately afterward, so for them this
#' is an API cleanup with no effective matching change; the fixtures in
#' test-blocking.R record that classification explicitly.)
#'
#' Length discipline: `last` and `first` must be equal length or scalar;
#' anything else refuses to recycle.
#'
#' @param last character vector of surnames. Required by every mode.
#' @param first character vector of given names. Required by
#'   `surname_initial`; ignored by the other modes.
#' @param mode `"surname_initial"`, `"prefix_n"`, or `"compact"`.
#' @param n prefix length for `prefix_n` (required for that mode;
#'   forbidden meaning-free elsewhere and therefore ignored).
#' @return character vector of blocking keys, `NA_character_` where the
#'   mode's required components are insufficient.
#' @family blocking
#' @export
blocking_key <- function(last, first = NULL,
                         mode = c("surname_initial", "prefix_n", "compact"),
                         n = NULL) {
  mode <- match.arg(mode)
  surname_key <- compact_name_key(last)

  if (mode == "compact") {
    return(surname_key)
  }

  if (mode == "prefix_n") {
    if (is.null(n) || length(n) != 1L || is.na(n) || n < 1L) {
      stop("blocking_key(mode = \"prefix_n\") requires an explicit n >= 1: ",
           "the audited call sites used 2, 3 and 4 with materially ",
           "different candidate pools, so no default is safe.",
           call. = FALSE)
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
