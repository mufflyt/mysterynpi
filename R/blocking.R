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

.blocking_validate_n <- function(mode, n) {
  if (mode != "prefix_n") {
    if (!is.null(n)) {
      stop("blocking_key: `n` is only meaningful with mode = ",
           "\"prefix_n\"; an argument that would be silently discarded ",
           "is a caller mistake, not a request.", call. = FALSE)
    }
    return(NULL)
  }

  n_ok <- !is.null(n) && length(n) == 1L && is.numeric(n) &&
    !is.na(n) && is.finite(n) && n >= 1 && n == trunc(n)
  if (!n_ok) {
    stop("blocking_key(mode = \"prefix_n\") requires an explicit n: a ",
         "single finite whole number >= 1. The audited call sites used ",
         "2, 3 and 4 with materially different candidate pools, so no ",
         "default is safe, and 1.5/Inf/NaN/\"3\"/TRUE are caller ",
         "mistakes rejected rather than coerced.", call. = FALSE)
  }
  as.integer(n)
}

.blocking_broadcast_pair <- function(last, first) {
  ll <- length(last)
  lf <- length(first)

  if (ll != lf) {
    if (ll == 0L || lf == 0L) {
      stop("blocking_key: one input is empty (", min(ll, lf),
           ") and the other is not (", max(ll, lf),
           "). Refusing to recycle identity vectors.", call. = FALSE)
    }
    if (ll == 1L) {
      last <- rep(last, lf)
    } else if (lf == 1L) {
      first <- rep(first, ll)
    } else {
      stop("blocking_key: `last` and `first` must be the same length, ",
           "or one must be length 1 for broadcasting; got ", ll, " and ",
           lf, ". Refusing to recycle identity vectors.", call. = FALSE)
    }
  }

  list(last = last, first = first)
}

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
  n <- .blocking_validate_n(mode, n)

  if (mode == "compact") {
    return(compact_name_key(last))
  }

  if (mode == "prefix_n") {
    surname_key <- compact_name_key(last)
    return(substr(surname_key, 1L, n))
  }

  # surname_initial
  if (is.null(first)) {
    stop("blocking_key(mode = \"surname_initial\") requires `first`.",
         call. = FALSE)
  }
  pair <- .blocking_broadcast_pair(last, first)
  surname_key <- compact_name_key(pair$last)
  init <- extract_first_initial(pair$first)
  out <- ifelse(!is.na(surname_key) & !is.na(init),
                paste0(surname_key, "|", init),
                NA_character_)
  as.character(out)
}


#' Define one governed blocking specification
#'
#' A specification records HOW a block is constructed, separately from the
#' records it will be applied to. This makes multi-key candidate generation
#' auditable: a caller can persist the exact blocking plan rather than only
#' the resulting strings.
#'
#' @param mode One blocking mode accepted by [blocking_key()].
#' @param n Prefix width for `prefix_n`; forbidden for other modes.
#' @param label Optional human-readable identifier. Defaults to the mode, or
#'   `prefix_<n>` for `prefix_n`.
#' @return An object of class `mysterynpi_blocking_spec`.
#' @family blocking
#' @export
blocking_spec <- function(mode, n = NULL, label = NULL) {
  if (missing(mode)) {
    stop("blocking_spec: `mode` must be explicit.", call. = FALSE)
  }
  mode <- match.arg(mode, c("surname_initial", "prefix_n", "compact"))
  n <- .blocking_validate_n(mode, n)

  if (is.null(label)) {
    label <- if (mode == "prefix_n") {
      paste0("prefix_", n)
    } else {
      mode
    }
  }
  label_ok <- is.character(label) && length(label) == 1L &&
    !is.na(label) && nzchar(trimws(label))
  if (!label_ok) {
    stop("blocking_spec: `label` must be one non-empty string.",
         call. = FALSE)
  }

  structure(
    list(mode = mode, n = n, label = trimws(label)),
    class = "mysterynpi_blocking_spec"
  )
}


#' Canonical blocking key with auditable metadata
#'
#' The `key` column is byte-identical to [blocking_key()] on the same
#' inputs. The remaining columns explain how that key was built and why a row
#' is or is not informative. Metadata never upgrades a blocking key into
#' identity evidence: blocking chooses candidates to compare; agreement rules
#' decide what those candidates mean.
#'
#' `components_used` names the governed recipe, not the observed evidence.
#' For example, `surname+first_initial` remains the recipe when the first
#' initial is missing and the key is therefore `NA`.
#'
#' @inheritParams blocking_key
#' @return A data frame with columns `key`, `mode`, `components_used`,
#'   `informative`, `reason`, `surname_key`, `first_initial`, and
#'   `prefix_n`.
#' @family blocking
#' @export
blocking_key_info <- function(
    last,
    first = NULL,
    mode = c("surname_initial", "prefix_n", "compact"),
    n = NULL) {
  mode <- match.arg(mode)
  key <- blocking_key(last = last, first = first, mode = mode, n = n)
  n <- .blocking_validate_n(mode, n)

  if (mode == "surname_initial") {
    pair <- .blocking_broadcast_pair(last, first)
    surname_key <- compact_name_key(pair$last)
    first_initial <- extract_first_initial(pair$first)
    missing_surname <- is.na(surname_key)
    missing_initial <- is.na(first_initial)

    reason <- rep("complete", length(key))
    reason[missing_surname & !missing_initial] <- "missing_surname"
    reason[!missing_surname & missing_initial] <- "missing_first_initial"
    reason[missing_surname & missing_initial] <-
      "missing_surname_and_first_initial"
    components <- rep("surname+first_initial", length(key))
  } else {
    surname_key <- compact_name_key(last)
    first_initial <- rep(NA_character_, length(key))
    reason <- ifelse(is.na(surname_key), "missing_surname", "complete")
    components <- rep("surname", length(key))
  }

  data.frame(
    key = as.character(key),
    mode = rep(mode, length(key)),
    components_used = components,
    informative = !is.na(key),
    reason = as.character(reason),
    surname_key = as.character(surname_key),
    first_initial = as.character(first_initial),
    prefix_n = rep(
      if (mode == "prefix_n") n else NA_integer_,
      length(key)
    ),
    stringsAsFactors = FALSE
  )
}


#' Generate several governed blocking keys per record
#'
#' Produces long-form candidate-generation plumbing: one row per input record
#' per blocking specification. This is intentionally NOT an identity verdict
#' and does not count repeated blocks as repeated evidence. Multiple blocks
#' only widen or partition the candidate set that downstream agreement rules
#' will evaluate.
#'
#' Output order is specification-major: specifications keep their supplied
#' order, and records keep their input order within each specification.
#'
#' @param last Character vector of surnames.
#' @param first Character vector of given names. Required if any specification
#'   uses `surname_initial`.
#' @param specs One [blocking_spec()] or a non-empty list of them. Labels must
#'   be unique so persisted ledgers can identify which rule emitted each key.
#' @return Long-form data frame. It adds `record_id`, `spec_id`, and
#'   `label` to the columns returned by [blocking_key_info()].
#' @family blocking
#' @export
blocking_keys <- function(last, first = NULL, specs) {
  if (missing(specs) || is.null(specs)) {
    stop("blocking_keys: supply one blocking_spec() or a list of specs.",
         call. = FALSE)
  }
  if (inherits(specs, "mysterynpi_blocking_spec")) {
    specs <- list(specs)
  }
  valid_list <- is.list(specs) && length(specs) > 0L &&
    all(vapply(
      specs,
      inherits,
      logical(1),
      what = "mysterynpi_blocking_spec"
    ))
  if (!valid_list) {
    stop("blocking_keys: every entry in `specs` must come from ",
         "blocking_spec().", call. = FALSE)
  }

  labels <- vapply(specs, function(x) x$label, character(1))
  if (anyDuplicated(labels)) {
    stop("blocking_keys: specification labels must be unique; duplicates: ",
         paste(unique(labels[duplicated(labels)]), collapse = ", "),
         ".", call. = FALSE)
  }

  uses_first <- any(vapply(
    specs,
    function(x) identical(x$mode, "surname_initial"),
    logical(1)
  ))
  last_for_plan <- last
  first_for_plan <- first
  if (uses_first) {
    if (is.null(first)) {
      stop("blocking_keys: a surname_initial spec requires `first`.",
           call. = FALSE)
    }
    pair <- .blocking_broadcast_pair(last, first)
    last_for_plan <- pair$last
    first_for_plan <- pair$first
  }

  pieces <- lapply(seq_along(specs), function(i) {
    spec <- specs[[i]]
    info <- blocking_key_info(
      last = last_for_plan,
      first = first_for_plan,
      mode = spec$mode,
      n = spec$n
    )
    data.frame(
      record_id = seq_len(nrow(info)),
      spec_id = rep.int(i, nrow(info)),
      label = rep(spec$label, nrow(info)),
      info,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  })

  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  out
}
