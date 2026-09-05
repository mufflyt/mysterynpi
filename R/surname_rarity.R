# =============================================================================
# Surname rarity: agreement on SMITH is not agreement on MUFFLY
# =============================================================================

#' How common is this surname? Census facts, for ordered-class refinement
#'
#' Exact agreement on a surname shared by 2.4 million people is weaker
#' identity evidence than exact agreement on one shared by a few thousand,
#' and an ordered-class policy may rank the two differently -- the
#' deterministic analogue of the term-frequency adjustment probabilistic
#' linkers apply (splink's TF weights), kept OUTSIDE the score: the
#' frequency refines which CLASS a pair earns, in reviewable policy code,
#' and never suppresses a veto.
#'
#' Facts only, deliberately: the return is the Census row -- rank and
#' carriers per 100,000 -- and where the caller draws the rare/common line
#' is the caller's claim. A surname absent from the top 1,000 gets `NA`
#' rank, which means "rarer than rank 1,000 OR spelled differently than
#' Census records it"; treat `NA` as *probably rare, possibly misspelled*,
#' and never as a value. Compound surnames should be looked up per
#' component ([surname_tokens()]); the table holds single tokens.
#'
#' @param x character vector of surnames; [name_key()] normalisation is
#'   applied, so `"smith"` and `SMITH` meet the same row.
#' @param frequencies the frequency table; defaults to
#'   [SURNAME_FREQUENCIES] (Census 2010 top 1,000, public domain).
#' @return data.frame, one row per input: `surname` (as given), `key`,
#'   `rank`, `per_100k` -- the latter two `NA` when the key is absent from
#'   the table.
#' @export
surname_rarity <- function(x, frequencies = mysterynpi::SURNAME_FREQUENCIES) {
  for (nm in c("surname", "rank", "per_100k")) if (!nm %in% names(frequencies))
    stop("frequencies needs columns surname, rank and per_100k", call. = FALSE)
  key <- name_key(x)
  i <- match(key, frequencies$surname)
  data.frame(surname = as.character(x), key = key,
             rank = frequencies$rank[i],
             per_100k = frequencies$per_100k[i],
             stringsAsFactors = FALSE)
}
