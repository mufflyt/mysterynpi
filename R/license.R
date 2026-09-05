# =============================================================================
# License-number agreement: the strongest key after the NPI itself,
# and a rule that deliberately cannot veto
# =============================================================================

#' Normalise a recorded license number for comparison
#'
#' Uppercase; spaces, periods and hyphens removed; blank to `NA`. THAT IS ALL,
#' and the restraint is the point:
#'
#' * **Leading zeros stay.** Some boards number with fixed-width zero padding
#'   and some do not; stripping zeros corroborates `"052"` with `"52"` at the
#'   price of corroborating `"520"`-style truncations too. A caller who has
#'   verified its two sources share a padding convention can strip upstream.
#' * **Alpha prefixes stay.** In states that prefix by profession, `MD12345`
#'   and `PA12345` are two different people's licenses; a prefix strip would
#'   merge them.
#'
#' @param x character vector of recorded license numbers.
#' @return character vector, or `NA_character_` where nothing was recorded.
#' @export
normalize_license <- function(x) {
  out <- toupper(gsub("[ .\\-]", "", as.character(x)))
  out[!is.na(out) & !nzchar(out)] <- NA_character_
  out
}

#' Do two recorded licenses corroborate? (This rule cannot veto.)
#'
#' A license number is only a number WITHIN its issuing state, so the state
#' rides along: `"12345"` in Colorado and `"12345"` in Texas is a numbering
#' coincidence, not evidence.
#'
#' TWO VERDICTS, NOT THREE, AND THE MISSING ONE IS THE DESIGN. Same state and
#' same normalised number is `"corroborates"` -- after the NPI itself, the
#' strongest deterministic evidence a candidate pair can carry. EVERYTHING
#' else is `"uninformative"`; there is no `"conflicts"` and no code path that
#' could produce one:
#'
#' * The registry's license field is PARTIAL (the NBER NPI-license crosswalk
#'   is built from it and is far from fully populated), so absence is
#'   ordinary, not evidence.
#' * Roughly a quarter of NPIs carry MORE THAN ONE license. A roster's
#'   Colorado number against a registry row's Texas number -- or against a
#'   different Colorado number from an earlier licensure -- is two glimpses
#'   of one career, not a disagreement.
#' * A formatting difference [normalize_license()] declines to erase (padding,
#'   a profession prefix) must not become a veto.
#'
#' A rule that can only add evidence can be ranked as high as its agreement
#' deserves without ever deleting a candidate it does not understand. Callers
#' holding several registry licenses per candidate should compare against
#' each and keep the best verdict -- one `"corroborates"` outweighs any
#' number of `"uninformative"`.
#'
#' @param a,b character vectors of recorded license numbers, the same length.
#'   Raw formatting is fine; [normalize_license()] is applied internally.
#' @param state_a,state_b character vectors of issuing-state codes. Compared
#'   after uppercasing and trimming; a missing state makes the pair
#'   uninformative, because a number without its state is not yet a license.
#' @return character: `"corroborates"` or `"uninformative"`.
#' @export
license_agreement <- function(a, state_a, b, state_b) {
  n <- length(a)
  if (length(state_a) != n || length(b) != n || length(state_b) != n) {
    stop("a, state_a, b and state_b must be the same length", call. = FALSE)
  }
  na <- normalize_license(a); nb <- normalize_license(b)
  sa <- toupper(trimws(as.character(state_a)))
  sb <- toupper(trimws(as.character(state_b)))
  sa[!is.na(sa) & !nzchar(sa)] <- NA_character_
  sb[!is.na(sb) & !nzchar(sb)] <- NA_character_
  hit <- !is.na(na) & !is.na(nb) & !is.na(sa) & !is.na(sb) &
    sa == sb & na == nb
  ifelse(hit, "corroborates", "uninformative")
}

#' Decompose a license number into prefix, digits, and suffix
#'
#' FOR STATE MEDICAL BOARD FILES, where the license number is about to become
#' a blocking variable and its anatomy decides whether it can be one. A board
#' file's numbers arrive as `12345`, `MD12345`, `12345A`, `MD.0012345` --
#' and whether `MD` is a profession code (meaning) or decoration (junk) is
#' not decidable from one row. This function makes the anatomy VISIBLE so
#' [license_conformance()] can decide it from the whole column. (NPPES's
#' license field has known conventions; this machinery is aimed at the board
#' side, where each state is its own convention.)
#'
#' Decomposition runs on [normalize_license()] output (case and punctuation
#' are already formatting): `prefix` is everything before the first digit,
#' `suffix` everything after the last digit, `digits` the span between --
#' which may itself contain letters (`A12B34`), and the `shape` says so.
#' `shape` is the license with every digit replaced by `#`: `MD12345A` has
#' shape `MD#####A`. Two numbers with the same shape are formatted alike;
#' that is the unit [license_conformance()] counts.
#'
#' @param x character vector of recorded license numbers.
#' @return data.frame with `license` (as given), `key` (normalised),
#'   `prefix`, `digits`, `suffix`, `shape`, `n_digits`. All-`NA` rows for
#'   absent input; a key with no digit at all keeps everything in `prefix`.
#' @export
license_anatomy <- function(x) {
  key <- normalize_license(x)
  has <- !is.na(key)
  prefix <- suffix <- digits <- shape <- rep(NA_character_, length(key))
  n_digits <- rep(NA_integer_, length(key))
  prefix[has] <- sub("^([^0-9]*).*$", "\\1", key[has])
  hasd <- has & grepl("[0-9]", key)
  suffix[hasd] <- sub("^.*[0-9]([^0-9]*)$", "\\1", key[hasd])
  suffix[has & !hasd] <- ""
  digits[hasd] <- substr(key[hasd], nchar(prefix[hasd]) + 1L,
                         nchar(key[hasd]) - nchar(suffix[hasd]))
  shape[has] <- gsub("[0-9]", "#", key[has])
  n_digits[has] <- nchar(gsub("[^0-9]", "", key[has]))
  data.frame(license = as.character(x), key = key, prefix = prefix,
             digits = digits, suffix = suffix, shape = shape,
             n_digits = n_digits, stringsAsFactors = FALSE)
}

#' Does each license fit the shape its state's board actually issues?
#'
#' THE FORMAT TABLE IS LEARNED FROM THE COLUMN, NOT VENDORED. A hand-curated
#' fifty-state table of board formats would rot the day a board changed its
#' numbering, and this package would have no way to notice. What a board
#' file itself knows is better evidence: within one state, the overwhelming
#' majority of rows carry the board's real format, and a row shaped like
#' nothing else in its state -- a stray `MD` prefix, a trailing `A`, a
#' pasted-in NPI -- is exactly the row that will corrupt a blocking key.
#'
#' For each row this reports its [license_anatomy()] shape, the share of its
#' state's rows carrying that shape, the state's modal shape, and a flag:
#' `flagged` when the shape is not the modal one AND its share falls below
#' `min_share`. A state can legitimately issue several formats (numbering
#' eras); those survive because their shapes are common, not because anyone
#' listed them. The flag marks rows for REVIEW before blocking -- it never
#' silently rewrites a number, because whether `MD` was meaning or junk is a
#' decision that belongs in reviewed code, not inside a cleaner.
#'
#' Rows with no usable license or state get `NA` throughout and are counted
#' in no denominator.
#'
#' @param license,state character vectors of the same length: the recorded
#'   number and its issuing state.
#' @param min_share shapes rarer than this within their state, other than
#'   the modal shape, are flagged. Default 0.01.
#' @return data.frame: the [license_anatomy()] columns plus `state`,
#'   `shape_share`, `state_modal_shape`, `flagged`.
#' @export
license_conformance <- function(license, state, min_share = 0.01) {
  if (length(license) != length(state)) {
    stop("license and state must be the same length", call. = FALSE)
  }
  st <- toupper(trimws(as.character(state)))
  st[!is.na(st) & !nzchar(st)] <- NA_character_
  out <- license_anatomy(license)
  out$state <- st
  out$shape_share <- NA_real_
  out$state_modal_shape <- NA_character_
  usable <- !is.na(out$key) & !is.na(st)
  for (s in sort(unique(st[usable]))) {
    i <- usable & st == s
    tab <- table(out$shape[i])
    out$shape_share[i] <- as.numeric(tab[out$shape[i]] / sum(tab))
    # deterministic modal shape: ties break to the first after sorting
    out$state_modal_shape[i] <-
      names(tab)[order(-as.numeric(tab), names(tab))][1]
  }
  out$flagged <- ifelse(usable,
                        out$shape != out$state_modal_shape &
                          out$shape_share < min_share,
                        NA)
  out
}
