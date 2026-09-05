# =============================================================================
# License-status levels: what a board's word for "gone" is allowed to mean
# =============================================================================
#
# THE 4x INFLATION THIS EXISTS TO PREVENT. State boards do not share a
# vocabulary for not-practicing, and a retirement study that reads their
# words naively counts every kind of gone as retired. The landmines are
# concrete: Florida and Illinois publish "Deceased" as a license status --
# death, not retirement; New York's OPMC feed is entirely disciplinary, so
# every one of its exits is a surrender or revocation -- exit, not
# retirement; Colorado, Delaware and Wisconsin are dominated by Expired and
# Revoked. Counting those strata as "retired" multiplies a retirement signal
# roughly fourfold, and nothing in the raw strings warns you.
#
# THE DESIGN IS THE GENDER RULE'S: map the encodings that occur to a small
# closed set of classes, and let everything unmapped be NA -- an encoding
# this table cannot read must degrade to "decides nothing", never into an
# exit class, least of all "retired". Which classes a study counts, and what
# it does with the ambiguous ones, is policy and stays with the caller; the
# quarantine discipline of vignette("vetoes-and-quarantine") applies to
# "lapsed" verbatim.
# =============================================================================

#' The status vocabulary: recorded board spellings and their classes
#'
#' One row per recorded spelling. The classes, and the claim each supports:
#'
#' * `active` -- licensed and unrestricted. Not an exit.
#' * `restricted` -- licensed under discipline (probation, restriction,
#'   suspension). Still practicing for workforce purposes; never an exit.
#' * `retired` -- the board SAYS retired (including emeritus). The only
#'   class a retirement study may count as retirement.
#' * `deceased` -- death. Never retirement: a death certificate read as a
#'   retirement both inflates the signal and misdates the exit.
#' * `disciplinary` -- revoked, surrendered, relinquished. Exit, not
#'   retirement: an exit under discipline says why the person left, and it
#'   is not "chose to stop".
#' * `lapsed` -- expired, delinquent, cancelled, inactive, not renewed. An
#'   exit of UNKNOWN cause: moved states, changed careers, or retired
#'   without saying so. A study may quarantine these for review or model
#'   them separately; it may not silently read them as retired.
#'
#' Spellings match after uppercasing, trimming, and collapsing punctuation
#' to single spaces, so `"Null & Void"` and `NULL AND VOID` meet the same
#' row. A caller whose board uses a spelling this table lacks supplies its
#' own rows via the `levels` argument of [normalize_license_status()] --
#' a reviewable data decision, not a code change.
#'
#' @format data.frame with columns `status`, `class`.
#' @export
LICENSE_STATUS_LEVELS <- local({
  m <- list(
    active = c("ACTIVE", "ACTIVE IN RENEWAL", "CURRENT", "CLEAR",
               "CLEAR ACTIVE", "LICENSED", "REGISTERED", "FULL",
               "ACTIVE MILITARY", "GOOD STANDING", "IN GOOD STANDING"),
    restricted = c("PROBATION", "PROBATIONARY", "RESTRICTED", "SUSPENDED",
                   "SUSPENSION", "STAYED SUSPENSION", "LIMITED",
                   "CONDITIONAL"),
    retired = c("RETIRED", "VOLUNTARILY RETIRED", "VOLUNTARY RETIRED",
                "RETIRED VOLUNTARY", "EMERITUS", "RETIRED EMERITUS",
                "EMERITUS RETIRED", "INACTIVE RETIRED", "RETIRED INACTIVE"),
    deceased = c("DECEASED", "DEATH", "EXPIRED DECEASED",
                 "DECEASED EXPIRED"),
    disciplinary = c("REVOKED", "REVOCATION", "SURRENDERED", "SURRENDER",
                     "VOLUNTARY SURRENDER", "VOLUNTARILY SURRENDERED",
                     "RELINQUISHED", "LICENSE SURRENDER",
                     "SURRENDERED IN LIEU OF DISCIPLINE", "ANNULLED"),
    lapsed = c("EXPIRED", "LAPSED", "DELINQUENT", "INACTIVE", "CANCELLED",
               "CANCELED", "NOT RENEWED", "NONRENEWED", "NULL AND VOID",
               "NULL VOID", "WITHDRAWN", "DISCONTINUED"))
  data.frame(status = unlist(m, use.names = FALSE),
             class = rep(names(m), lengths(m)),
             stringsAsFactors = FALSE)
})

#' Normalise recorded board license statuses to their exit classes
#'
#' Case, surrounding whitespace and punctuation are formatting; the WORDS
#' are the evidence. Everything the table cannot read maps to `NA` -- and
#' that direction is the point, exactly as in [normalize_gender()]: an
#' unmapped status must decide nothing, because a default into any exit
#' class -- least of all `"retired"` -- is how a board's whole vocabulary
#' quietly becomes a retirement signal. Florida's `Deceased` is death.
#' OPMC's `Surrendered` is discipline. Colorado's `Expired` is a lapse of
#' unknown cause. None of them is retirement, and after this function none
#' of them can be counted as one by accident.
#'
#' @param x character vector of recorded license statuses.
#' @param levels the vocabulary; defaults to [LICENSE_STATUS_LEVELS]. A
#'   board-specific supplement is rbind()ed by the caller and reviewed like
#'   data, because it is data.
#' @return character vector of `"active"`, `"restricted"`, `"retired"`,
#'   `"deceased"`, `"disciplinary"`, `"lapsed"`, or `NA_character_`.
#' @export
normalize_license_status <- function(x, levels = LICENSE_STATUS_LEVELS) {
  for (nm in c("status", "class")) if (!nm %in% names(levels))
    stop("levels needs columns status and class", call. = FALSE)
  u <- toupper(trimws(gsub("[[:space:][:punct:]]+", " ", as.character(x))))
  key <- toupper(trimws(gsub("[[:space:][:punct:]]+", " ", levels$status)))
  unname(stats::setNames(levels$class, key)[u])
}
