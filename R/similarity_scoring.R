# =============================================================================
# Nickname dictionary utilities + one deprecated scoring shim
# =============================================================================
#
# HISTORY: this file was the package's "fenced exception" while the package
# refused numeric similarity outright. That posture was REVERSED by owner
# ruling on 2026-09-19 - Jaro-Winkler and Levenshtein are deterministic
# functions, and the real defect was hand-rolled, inconsistent, unaudited
# fuzz downstream. First-class similarity primitives now live in
# R/similarity.R with a pinned missing-aware contract. What REMAINS true,
# and is still proven by test-no-fuzzy.R's call-graph reachability guard:
# the categorical *_agreement() verdicts are similarity-free - an
# edit-distance tolerance that silently converts "conflicts" to
# "corroborates" is still a defect, because similarity informs the governed
# decision layer, it never flips a verdict.
#
# What lives here now: the nickname dictionary utilities (deterministic
# table reads over NICKNAME_EDGES) and the deprecated single-pair scoring
# shim retained for signature compatibility.
#
# ONE NICKNAME SYSTEM (2026-09-05, by owner decision). The scoring API was
# first extracted verbatim from mufflyt/isochrones R/nickname_system.R and
# proven byte-identical; it was then CONSOLIDATED onto NICKNAME_EDGES -- the
# same pinned corpus the nickname_agreement() verdict reads -- because two
# nickname tables is how two layers quietly disagree about what a name may
# stand for. Consolidation is a deliberate, versioned score change: the
# hand-rolled dictionary's quirks (RICK resolving to ERIC by last-write,
# shadowed duplicate entries, JULIE-as-formal hiding its nickname role) are
# FIXED here, not preserved, and the old byte-identical behaviour remains
# available only in history. Equivalence now uses the verdict rule's own
# one-hop relation: a recorded edge or a shared formal root, never
# transitive closure, so AL may stand for ALBERT or ALEXANDER without ever
# welding ALBERT to ALEXANDER -- in scores exactly as in verdicts.
#
# stringdist is a Suggests, required at the point of use only, so the
# package's verdict machinery installs and runs without it.
# =============================================================================

.nickname_cache <- new.env(parent = emptyenv())

#' The nickname dictionary, derived from the one corpus
#'
#' Derived entirely from [NICKNAME_EDGES] -- the same pinned corpus
#' [nickname_agreement()] reads -- so verdicts and scores share ONE truth
#' about what a name may stand for. `nickname_to_formal` is multi-valued:
#' a hub nickname like `AL` carries every formal root the corpus records.
#'
#' @param verbose message the build, as the original did.
#' @return list: `formal_to_nicknames`, `nickname_to_formal`, `source`,
#'   `created`, `formal_count`, `nickname_count`.
#' @export
create_nickname_dictionary <- function(verbose = TRUE) {
  if (verbose) {
    message("Deriving nickname dictionary from NICKNAME_EDGES...")
  }
  e <- mysterynpi::NICKNAME_EDGES
  formal_to_nicknames <- split(e$nickname, e$name)
  nickname_to_formal  <- split(e$name, e$nickname)
  dict <- list(
    formal_to_nicknames = formal_to_nicknames,
    nickname_to_formal = nickname_to_formal,
    source = "mysterynpi::NICKNAME_EDGES (carltonnorthern/nicknames, pinned)",
    created = Sys.time(),
    formal_count = length(formal_to_nicknames),
    nickname_count = length(nickname_to_formal)
  )
  if (verbose) {
    message(sprintf("Nickname dictionary derived: %d formal names, %d nicknames",
                    dict$formal_count, dict$nickname_count))
  }
  dict
}

#' Cached access to the nickname dictionary
#' @param refresh rebuild even if cached.
#' @return see [create_nickname_dictionary()].
#' @export
get_nickname_dictionary <- function(refresh = FALSE) {
  if (refresh || is.null(.nickname_cache$dict)) {
    .nickname_cache$dict <- create_nickname_dictionary(verbose = FALSE)
  }
  .nickname_cache$dict
}

#' Resolve a name, possibly a nickname, to a canonical formal form
#'
#' A DISPLAY LABEL, arbitrary-but-stable, and documented as such: the
#' corpus records SUBSTITUTABILITY, not hierarchy -- it contains cycles
#' (`BOB` and `ROBERT` each list the other) and hub nicknames with dozens
#' of roots -- so no true canonical exists. This returns the
#' lexicographically first recorded root when the name has any, else the
#' normalised name itself. Nothing ranks or decides on it;
#' [are_nickname_equivalents()] carries the meaning, over ALL roots.
#' @param name a name.
#' @param nickname_dict from [create_nickname_dictionary()]; NULL returns
#'   the input.
#' @return one stable label; the normalised input when the corpus records
#'   no root for it.
#' @export
get_canonical_name <- function(name, nickname_dict) {
  if (is.null(name) || is.null(nickname_dict) ||
      (length(name) == 1 && is.na(name))) {
    return(name)
  }
  name_clean <- normalize_string(name)
  roots <- nickname_dict$nickname_to_formal[[name_clean]]
  if (!is.null(roots) && length(roots)) {
    return(sort(roots)[1])
  }
  name_clean
}

#' Are two names one-hop equivalent under the corpus?
#'
#' THE SAME RELATION [nickname_agreement()] corroborates on: equal after
#' normalisation, a recorded edge in either direction, or a shared formal
#' root. One hop, never transitive closure -- a shared NICKNAME does not
#' equate two formal names, so `AL` pairs with `ALBERT` and with
#' `ALEXANDER` while `ALBERT` and `ALEXANDER` stay distinct.
#' @param name1,name2 names to compare.
#' @param nickname_dict from [create_nickname_dictionary()]; NULL is FALSE.
#' @return logical.
#' @export
are_nickname_equivalents <- function(name1, name2, nickname_dict) {
  if (is.null(nickname_dict) || is.null(name1) || is.null(name2) ||
      (length(name1) == 1 && is.na(name1)) ||
      (length(name2) == 1 && is.na(name2))) {
    return(FALSE)
  }
  x <- normalize_string(name1); y <- normalize_string(name2)
  if (x == y) return(TRUE)
  cx <- c(x, nickname_dict$nickname_to_formal[[x]])
  cy <- c(y, nickname_dict$nickname_to_formal[[y]])
  length(intersect(cx, cy)) > 0
}

#' All recorded nicknames for a formal name
#' @param formal_name the formal name.
#' @param nickname_dict from [create_nickname_dictionary()].
#' @return character vector; empty when unknown or inputs NULL.
#' @export
get_nicknames_for_name <- function(formal_name, nickname_dict) {
  if (is.null(nickname_dict) || is.null(formal_name)) {
    return(character(0))
  }
  formal_clean <- normalize_string(formal_name)
  if (formal_clean %in% names(nickname_dict$formal_to_nicknames)) {
    return(nickname_dict$formal_to_nicknames[[formal_clean]])
  }
  character(0)
}

#' Deprecated: use [given_name_similarity()]
#'
#' Superseded 2026-09-19 when similarity became a first-class governed
#' primitive (owner ruling: the defect was hand-rolled fuzz, not fuzz). The
#' replacement differs in exactly one semantic: MISSING input returns
#' `NA_real_`, never this function's `0.5` neutral scalar - a neutral
#' constant for absence is the absence-into-evidence conversion the package
#' forbids everywhere else. This wrapper preserves the old single-pair
#' contract (including the 0.5) so a deprecation period cannot silently
#' change scores; migrate to [given_name_similarity()] and handle `NA`.
#' The `options(mysterynpi.enable_similarity_scoring)` opt-in fence is
#' retired with the same ruling.
#'
#' @param name1,name2 names to compare.
#' @param nickname_dict ignored (the consolidated corpus is always used);
#'   accepted for signature compatibility.
#' @return numeric in `[0, 1]`; `0.5` for missing input (old contract).
#' @keywords internal
#' @export
calculate_enhanced_first_name_similarity <- function(name1, name2,
                                                     nickname_dict = NULL) {
  .Deprecated("given_name_similarity", package = "mysterynpi",
              msg = paste0(
    "calculate_enhanced_first_name_similarity() is deprecated: use ",
    "given_name_similarity(), which is vectorized and returns NA (not 0.5) ",
    "for missing input."))
  if (is.null(name1) || is.null(name2) || is.na(name1) || is.na(name2)) {
    return(0.5)
  }
  # old contract: a NULL dictionary meant plain Jaro-Winkler, no nickname step
  out <- given_name_similarity(as.character(name1)[1], as.character(name2)[1],
                               nickname_aware = !is.null(nickname_dict))
  if (is.na(out)) 0.5 else out
}
