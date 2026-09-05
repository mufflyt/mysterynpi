# =============================================================================
# Generational suffixes: parse them out, and the father/son veto
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR is the canonical false match in provider
# linkage: father and son, same name, same specialty, frequently the same
# practice address, distinguished by nothing in the record except JR against
# SR. A pipeline that strips suffixes as noise -- which parsing must do, since
# no name parser knows JR is not a surname -- and never looks at them again
# has deleted the only field that separates two real people.
#
# So the suffix is PARSED OUT, not thrown away: [extract_suffix()] runs on the
# raw string BEFORE [strip_name_noise()]/[parse_person()] (both of which
# delete suffix tokens), keeps the suffix in its own slot, and hands the rest
# of the name on.
# =============================================================================

# Recognised spellings -> canonical label. "V" is deliberately absent: it is
# an initial far more often than a fifth-of-name, and a rule that reads the V
# in "SAMUEL V ANAYA" as a suffix invents a generation from a middle initial.
SUFFIX_SPELLINGS <- c(
  JR = "JR", JNR = "JR", JUNIOR = "JR",
  SR = "SR", SNR = "SR", SENIOR = "SR",
  II = "II", "2ND" = "II",
  III = "III", "3RD" = "III",
  IV = "IV", "4TH" = "IV")

# Canonical label -> generation ordinal. JR and II are BOTH a second-of-name:
# the same man is styled "Jr" by one source and "II" by another, so comparing
# labels would manufacture a conflict out of house style. SR vs JR, and II vs
# III, are different people; JR vs II is the same generation written twice.
SUFFIX_GENERATION <- c(SR = 1L, JR = 2L, II = 2L, III = 3L, IV = 4L)

#' Normalise a recorded generational suffix to `JR`/`SR`/`II`/`III`/`IV`, or `NA`
#'
#' Case-insensitive, periods and surrounding whitespace ignored (`"Jr."` ->
#' `"JR"`). Everything unrecognised maps to `NA` -- an encoding this rule
#' cannot read must degrade to "decides nothing", never to a spurious veto.
#'
#' @param x character vector of recorded suffixes.
#' @return character vector of canonical labels, or `NA_character_`.
#' @export
normalize_suffix <- function(x) {
  u <- gsub("[.]", "", toupper(trimws(as.character(x))))
  out <- unname(SUFFIX_SPELLINGS[u])
  out[is.na(out)] <- NA_character_
  out
}

#' Pull the generational suffix out of a raw name string, keeping both parts
#'
#' Run this BEFORE [parse_person()] or [strip_name_noise()]: both treat
#' suffix tokens as noise and delete them, which is correct for parsing and
#' fatal for the father/son veto. Token-based like [strip_name_noise()], for
#' the same reason -- a regex alternation can match inside an accented name.
#'
#' When a string carries more than one recognised suffix token the LAST one
#' wins (suffixes trail), and all of them are removed from the name.
#'
#' @param x character vector of raw name strings.
#' @return data.frame with `name` (the string with suffix tokens removed,
#'   whitespace normalised) and `suffix` (canonical label or `NA`).
#' @export
extract_suffix <- function(x) {
  x <- as.character(x)
  res <- lapply(x, function(s) {
    if (is.na(s)) return(list(name = NA_character_, suffix = NA_character_))
    parts <- strsplit(s, "[[:space:],]+")[[1]]
    parts <- parts[nzchar(parts)]
    canon <- normalize_suffix(parts)
    hit <- !is.na(canon)
    list(name = gsub("[[:space:]]+", " ",
                     trimws(paste(parts[!hit], collapse = " "))),
         suffix = if (any(hit)) canon[max(which(hit))] else NA_character_)
  })
  data.frame(name = vapply(res, `[[`, character(1), "name"),
             suffix = vapply(res, `[[`, character(1), "suffix"),
             stringsAsFactors = FALSE)
}

#' Do two recorded generational suffixes agree, disagree, or decide nothing?
#'
#' THE VETO COMPARES GENERATIONS, NOT SPELLINGS. `JR` and `II` are both a
#' second-of-name and corroborate; `SR` vs `JR` and `II` vs `III` are
#' different people and conflict. Absence is `"uninformative"`, never a
#' conflict: most people carry no suffix, and a roster that omits `JR` has
#' not disagreed with a registry that records it.
#'
#' Note the asymmetry that makes this rule worth its keep: agreement is weak
#' (almost everyone agrees on "no suffix" -- which this rule reports as
#' uninformative, not agreement), but a conflict between two RECORDED
#' generations is close to the strongest single-field veto a name offers,
#' because the population it fires on -- same surname, same given name, one
#' generation apart -- is exactly the population every other name field
#' cannot separate.
#'
#' @param a,b character vectors of recorded suffixes, the same length. Raw
#'   spellings are fine; [normalize_suffix()] is applied internally.
#' @return character: `"corroborates"`, `"conflicts"`, or `"uninformative"`.
#' @export
suffix_agreement <- function(a, b) {
  if (length(a) != length(b)) {
    stop("a and b must be the same length", call. = FALSE)
  }
  ga <- unname(SUFFIX_GENERATION[normalize_suffix(a)])
  gb <- unname(SUFFIX_GENERATION[normalize_suffix(b)])
  out <- rep("uninformative", length(ga))
  known <- !is.na(ga) & !is.na(gb)
  out[known] <- ifelse(ga[known] == gb[known], "corroborates", "conflicts")
  out
}
