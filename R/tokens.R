# =============================================================================
# Tokenisation: surnames, given names, middle names
# =============================================================================

#' Surname particles that are naming convention, not identity.
#'
#' A token match on `"DE"`, `"VAN"` or `"ST"` is evidence of a naming
#' convention, not of identity; admitting them joins every `DE LA CRUZ` to
#' every `DE LEON` sharing a given name.
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
#' @return character vector of components; `character(0)` when nothing survives.
#' @export
surname_tokens <- function(x) {
  k <- name_key(x)
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
#' @param x character vector.
#' @return list of character vectors, one per input.
#' @export
middle_tokens <- function(x) {
  k <- blank_na(x)
  lapply(strsplit(k, "[^A-Z']+"), function(t) unique(t[nzchar(t)]))
}

#' Given-name tokens of length >= 2, initials EXCLUDED.
#'
#' Initials are dropped for matching because `"W."` is compatible with every
#' W; they remain available in the parsed columns for reporting.
#'
#' @param given,middle character vectors.
#' @return list of character vectors.
#' @export
given_tokens <- function(given, middle = NULL) {
  b <- if (is.null(middle)) blank_na(given) else
    trimws(paste(blank_na(given), blank_na(middle)))
  lapply(strsplit(b, "[^A-Z']+"), function(t) {
    t <- t[nchar(t) >= 2L]
    unique(t[nzchar(t)])
  })
}
