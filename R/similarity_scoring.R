# =============================================================================
# Nickname dictionary utilities (deterministic table reads; no fuzz remains)
# =============================================================================
#
# HISTORY: this file once held the package's "fenced exception" - a
# Jaro-Winkler scoring pair walled off from the verdicts. The fence is gone
# because THE MACHINERY IS GONE (owner ruling, 2026-09-19): mysterynpi must
# not provide fuzzy person-name matching in any form - no option, no
# deprecated export, no dark-by-default capability. Approximate spelling
# similarity is not part of the identity architecture; exact normalisation,
# declared nickname equivalence, initials, documented surname history and
# structured evidence are. test-no-fuzzy.R now asserts there is NOTHING to
# reach: zero fuzzy references anywhere in the package, with no exempt
# module.
#
# ONE NICKNAME SYSTEM (2026-09-05, by owner decision). What remains here is
# the deterministic dictionary derived from NICKNAME_EDGES - the same pinned
# corpus nickname_agreement() reads - so every consumer shares ONE truth
# about what a name may stand for. Equivalence is the verdict rule's own
# one-hop relation: a recorded edge or a shared formal root, never
# transitive closure, so AL may stand for ALBERT or ALEXANDER without ever
# welding ALBERT to ALEXANDER.
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
