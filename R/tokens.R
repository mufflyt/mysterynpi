# =============================================================================
# Tokenisation: surnames, given names, middle names
# =============================================================================

#' Surname particles that are naming convention, not identity.
#'
#' A token match on `"DE"`, `"VAN"` or `"ST"` is evidence of a naming
#' convention, not of identity; admitting them joins every `DE LA CRUZ` to
#' every `DE LEON` sharing a given name.
#'
#' KNOWN LIMITATION: `"DO"` IS BOTH A PARTICLE AND A STANDALONE SURNAME.
#' `"do"` is a genuine Portuguese/Lusophone particle ("of the", as in
#' surnames built like `"do Carmo"`), which is why it is listed here -- but
#' it is ALSO, unrelatedly, a common standalone Vietnamese surname (the
#' same collision [strip_name_noise()]'s DO carve-out and
#' [SURNAME_CREDENTIAL_COLLISIONS] exist for, in a different function).
#' [parse_person()]'s `format = "surname_first"` particle walk cannot tell
#' these apart: `parse_person("Do Nguyen Van", format = "surname_first")`
#' reads leading `"Do"` as a particle and walks one token further to
#' capture what it assumes is the surname root, corrupting a real
#' Vietnamese surname ("Do") into a false compound ("Do Nguyen") while
#' losing the real given name ("Van") -- yet removing `"DO"` from this list
#' would equally break the genuine Portuguese case (`"Do Carmo Silva
#' Maria"` would then read as surname `"Do"` alone, losing `"Carmo"`).
#' Both are real populations in a US provider directory and this package
#' has no evidence either is rarer than the other, so -- matching the
#' precedent already set for the identical shape elsewhere in this
#' package -- this is documented rather than resolved with an unproven
#' directional guess. Found 2026-09-18. A caller who knows their source
#' data's naming convention should resolve the ambiguity before calling
#' in (e.g. skip `format = "surname_first"` for a source known to be
#' Vietnamese-surname-first with no particles).
#' @export
SURNAME_PARTICLES <- c(
  "DE", "DEL", "DELA", "DELAS", "DELOS", "LA", "LAS", "LE", "LOS", "DA", "DAS",
  "DI", "DO", "DOS", "VAN", "VANDER", "VON", "DER", "DEN", "TER", "TEN",
  "ST", "STE", "MC", "MAC", "EL", "AL", "BIN", "IBN", "BEN", "ABU", "Y", "I")

#' Minimum surname token length.
#'
#' A real threshold, not a formatting detail: at 2 characters, particles and
#' initials become blocking keys and unrelated people collide. Pinned by value
#' in the tests so lowering it fails loudly rather than quietly widening every
#' candidate pool.
#' @export
MIN_SURNAME_TOKEN <- 4L

#' Split a normalised surname into its components.
#'
#' Sources disagree about how a compound surname is recorded: one holds
#' `"MCCARTHY-DERVIN"` where another holds `"MCCARTHY"`, or one splits
#' `"HARVEY CAPISTA"` across its middle and last fields where the other keeps
#' it whole. No exact or edit-distance strategy can span a DROPPED component --
#' an edit distance of 2 cannot cross seven missing characters -- so these fail
#' silently as "no candidate". Measured in one crosswalk: hyphenated surnames
#' ran 27.1% unmatched against 9.8% for unhyphenated, a 2.8x gap.
#'
#' @param x a single surname string.
#' @param strip_alternates see [name_key()].
#' @return character vector of components; `character(0)` when nothing survives.
#' @export
surname_tokens <- function(x, strip_alternates = TRUE) {
  k <- name_key(x, strip_alternates)
  if (length(k) != 1L) stop("surname_tokens() takes one name", call. = FALSE)
  if (is.na(k) || !nzchar(k)) return(character(0))
  toks <- strsplit(gsub("[^A-Z']+", " ", k), "\\s+")[[1]]
  toks <- toks[nzchar(toks)]
  toks <- toks[!toks %in% SURNAME_PARTICLES]
  unique(toks[nchar(toks) >= MIN_SURNAME_TOKEN])
}

#' Middle-name tokens, initials INCLUDED.
#'
#' Unlike [given_tokens()], single-letter tokens are kept. A recorded middle
#' initial is the only middle-name evidence most registry rows carry; dropping
#' it would make every initial-only row uninformative rather than comparable,
#' and comparability is the whole point of the middle-name axis.
#'
#' A HYPHEN NEVER SPLITS A TOKEN HERE, for the same reason [name_key()]'s
#' `fold_hyphens` must default `FALSE` and must never apply before
#' [split_given()]: "Anne-Marie" is ONE compound name, not "Anne" plus an
#' incidental, droppable "Marie". Splitting it produced a real false
#' corroboration -- `middle_agreement(middle_tokens("Anne-Marie"),
#' middle_tokens("Marie"))` returned `"corroborates"` against a middle name
#' that is a DIFFERENT, unrelated person's, sharing only the second half of
#' the compound. This is the identical defect class [name_key()]'s
#' `fold_hyphens` documentation describes for given names (three cross-state
#' false identity matches), just not yet applied to this tokeniser when that
#' policy was set.
#'
#' @param x character vector.
#' @param strip_alternates see [name_key()].
#' @return list of character vectors, one per input.
#' @export
middle_tokens <- function(x, strip_alternates = TRUE) {
  k <- blank_na(x, strip_alternates)
  lapply(strsplit(k, "[^A-Z'-]+"), function(t) unique(t[nzchar(t)]))
}

#' Given-name tokens of length >= 2, initials EXCLUDED.
#'
#' Initials are dropped for matching because `"W."` is compatible with every
#' W; they remain available in the parsed columns for reporting.
#'
#' A HYPHEN NEVER SPLITS A TOKEN HERE. "Mary-Jane" is ONE given name; splitting
#' it into `"MARY"`/`"JANE"` let it satisfy [person_matches()]'s shared-token
#' requirement against an unrelated "Jane" who shares nothing but the second
#' half of the compound -- `person_matches("SMITH", given_tokens("Mary-Jane"),
#' "SMITH", given_tokens("Jane"))` returned `TRUE` before this fix. Consistent
#' with [split_given()], which already never folds a given-name hyphen for
#' exactly this reason.
#'
#' @param given,middle character vectors.
#' @param strip_alternates see [name_key()].
#' @return list of character vectors.
#' @export
given_tokens <- function(given, middle = NULL, strip_alternates = TRUE) {
  b <- if (is.null(middle)) blank_na(given, strip_alternates) else
    trimws(paste(blank_na(given, strip_alternates), blank_na(middle, strip_alternates)))
  lapply(strsplit(b, "[^A-Z'-]+"), function(t) {
    t <- t[nchar(t) >= 2L]
    unique(t[nzchar(t)])
  })
}

#' Surname components as a long (id, token) data frame
#'
#' Returned long rather than as a list column because every caller joins on the
#' token; a list column would have to be unnested at each call site.
#'
#' @param x character vector of surnames.
#' @param id vector of identifiers, the same length as `x`.
#' @param strip_alternates see [name_key()].
#' @return data.frame(id, token), zero rows where a surname yields no component.
#' @export
surname_token_table <- function(x, id, strip_alternates = TRUE) {
  stopifnot(length(x) == length(id))
  lst <- lapply(x, surname_tokens, strip_alternates = strip_alternates)
  n <- lengths(lst)
  data.frame(id = rep(id, n), token = unlist(lst, use.names = FALSE),
             stringsAsFactors = FALSE)
}
