# =============================================================================
# Similarity SCORING -- candidate-ranking machinery, walled off from verdicts
# =============================================================================
#
# THIS FILE IS THE PACKAGE'S ONE FENCED EXCEPTION to its no-fuzzy rule, and
# the fence is load-bearing. The rule's target was always fuzz in the
# IDENTITY VERDICT path -- an edit-distance tolerance that silently converts
# "conflicts" to "corroborates" -- and that refusal stands in full: the
# no-fuzzy guard now asserts, by call-graph reachability over the installed
# namespace, that NO agreement rule can reach anything in this file, and a
# mutation in the campaign proves the guard fires on exactly that smuggling.
# What lives here is different machinery for a different stage: SCORING for
# candidate generation and ranking, where a fuzzy pass GENERATES a candidate
# that exact evidence then outranks -- the asymmetry the README has always
# called legitimate. Same evolution as the nickname table: the machinery is
# shared, the decision to use it -- and at which pipeline stage -- stays
# policy.
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

#' Nickname-aware first-name similarity SCORE (never a verdict)
#'
#' A number for RANKING candidates, extracted verbatim from isochrones:
#' 1.0 exact after normalisation; 0.98 one-hop nickname equivalent under
#' the consolidated corpus (the same relation the verdict rule
#' corroborates on); 0.5 neutral for missing; otherwise Jaro-Winkler
#' similarity (the larger of raw and umlaut-digraph-simplified). The old
#' extraction's 0.96/0.94 sub-tiers were artifacts of the retired two-table
#' shape and are consolidated into 0.98. Scores rank; only agreement rules
#' decide, and the no-fuzzy guard proves they cannot reach this function.
#'
#' OFF BY DEFAULT: calling this without
#' `options(mysterynpi.enable_similarity_scoring = TRUE)` stops with
#' instructions. The opt-in line belongs in the pipeline script it governs,
#' where a reviewer reads it -- approximate scoring must be a decision,
#' never a default.
#'
#' @param name1,name2 names to compare.
#' @param nickname_dict from [create_nickname_dictionary()]; NULL falls back
#'   to plain Jaro-Winkler.
#' @return numeric in `[0, 1]`.
#' @export
calculate_enhanced_first_name_similarity <- function(name1, name2,
                                                     nickname_dict = NULL) {
  # DARK BY DEFAULT. Approximate scoring never runs by accident: the caller
  # opts in with one visible line, and that line is the reviewable record
  # that a pipeline chose to rank with fuzz. The dictionary lookups above
  # need no gate -- they are deterministic table reads.
  if (!isTRUE(getOption("mysterynpi.enable_similarity_scoring", FALSE))) {
    stop(paste0(
      "Similarity scoring is OFF by default. Opting in is a policy ",
      "decision that belongs in reviewable pipeline code:\n",
      "  options(mysterynpi.enable_similarity_scoring = TRUE)\n",
      "Scores rank candidates; they never decide identity -- the agreement ",
      "rules do, and they cannot reach this function."), call. = FALSE)
  }
  if (!requireNamespace("stringdist", quietly = TRUE)) {
    stop("calculate_enhanced_first_name_similarity() requires stringdist.\n",
         "  install.packages(\"stringdist\")", call. = FALSE)
  }
  if (is.null(name1) || is.null(name2) || is.na(name1) || is.na(name2)) {
    return(0.5)
  }
  name1_clean <- normalize_string(name1)
  name2_clean <- normalize_string(name2)
  normalize_for_similarity <- function(value) {
    value <- normalize_string(value)
    if (requireNamespace("stringi", quietly = TRUE)) {
      value <- stringi::stri_trans_general(value, "Latin-ASCII")
    }
    value
  }
  simplify_umlaut_digraphs <- function(value) {
    value <- gsub("AE", "A", value, perl = TRUE)
    value <- gsub("OE", "O", value, perl = TRUE)
    value <- gsub("UE", "U", value, perl = TRUE)
    value
  }
  name1_norm <- normalize_for_similarity(name1_clean)
  name2_norm <- normalize_for_similarity(name2_clean)
  if (name1_norm == name2_norm) {
    return(1.0)
  }
  if (is.null(nickname_dict)) {
    return(1 - stringdist::stringdist(name1_norm, name2_norm, method = "jw"))
  }
  if (are_nickname_equivalents(name1_clean, name2_clean, nickname_dict)) {
    return(0.98)
  }
  jw_similarity <- 1 - stringdist::stringdist(name1_norm, name2_norm,
                                              method = "jw")
  jw_simplified <- 1 - stringdist::stringdist(
    simplify_umlaut_digraphs(name1_norm),
    simplify_umlaut_digraphs(name2_norm),
    method = "jw"
  )
  max(jw_similarity, jw_simplified)
}

#' Factory: similarity closure with a bound dictionary
#' @param nickname_dict from [create_nickname_dictionary()].
#' @return `function(name1, name2)` returning the similarity score.
#' @export
create_nickname_aware_similarity <- function(nickname_dict) {
  function(name1, name2) {
    calculate_enhanced_first_name_similarity(name1, name2, nickname_dict)
  }
}
