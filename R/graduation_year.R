# =============================================================================
# Graduation year against a credentialing year: the first non-name identity axis
# =============================================================================

#' Calibrated bands for [graduation_year_agreement()].
#'
#' PROVISIONAL. The weights are likelihood ratios measured against a SILVER
#' standard -- high-confidence incumbent links treated as matches, every other
#' candidate of the same person treated as a non-match -- not against
#' adjudicated pairs. They are shipped as data, like [NICKNAME_EDGES], so a
#' study with its own calibration supplies its own table: a reviewable data
#' decision rather than a code change. Re-estimate once an adjudicated truth
#' set exists.
#'
#' THE BANDS ARE SIGNED, AND THAT IS THE POINT. `d = graduation - credentialing`.
#' Finishing a programme and then credentialing is the ordinary sequence;
#' credentialing and then graduating is not, and the measurement says so:
#'
#' \preformatted{
#'    d    likelihood ratio
#'    0        43.8
#'   -1        10.2
#'   +1         1.8     <- the same |d|, roughly six times weaker
#' }
#'
#' A symmetric "within 1 year" band averages a strong signal with a weak one.
#' Two independent implementations over the same directory snapshot reached
#' that conclusion; the second also found the middle bands NEGATIVE, so a
#' caller that scores `|d|` of 2 or 3 as evidence FOR a link has the sign
#' wrong (see `log2_lr` below, and the note in [graduation_year_agreement()]).
#'
#' @format data.frame, one row per band, ordered from the strongest evidence
#'   for a link to the strongest against:
#'   \describe{
#'     \item{band}{character label, also what [graduation_year_band()] returns}
#'     \item{lo,hi}{inclusive bounds on `d`, in years; `Inf`/`-Inf` at the ends}
#'     \item{verdict}{what [graduation_year_agreement()] reports for the band}
#'     \item{log2_lr}{log2 likelihood ratio for a caller that scores; 0 where
#'       the band decides nothing}
#'   }
#' @source Measured on 8,681 likely matches and 170,827 likely non-matches,
#'   AMCB certificants against a commercial provider directory (snapshot
#'   2026-06-25). Coverage of the graduation year in that directory is about
#'   half of linked clinicians, and it originates in CMS DAC, so it exists only
#'   for Medicare-enrolled clinicians.
#' @export
GRADUATION_YEAR_BANDS <- data.frame(
  band    = c("same_year", "one_before", "one_after", "two_three_before",
              "two_three_after", "four_ten_before", "four_ten_after", "beyond_ten"),
  lo      = c(0L,  -1L, 1L,  -3L,  2L,  -10L, 4L,  -Inf),
  hi      = c(0L,  -1L, 1L,  -2L,  3L,  -4L,  10L, Inf),
  verdict = c("corroborates", "corroborates", "corroborates", "uninformative",
              "uninformative", "uninformative", "uninformative", "conflicts"),
  log2_lr = c(5.45, 3.35, 0.81, -0.25, -1.37, -1.57, -2.00, -3.16),
  stringsAsFactors = FALSE
)

#' Which band does a graduation year fall in, relative to a credentialing year?
#'
#' The mechanics behind [graduation_year_agreement()], reported as a band label
#' rather than collapsed to a verdict, so a caller can weight the bands
#' (`GRADUATION_YEAR_BANDS$log2_lr`) instead of taking the three-verdict
#' summary. This is the same split [name_surname_match_type()] makes against
#' [names_have_compatible_surname()].
#'
#' @param credentialing_year,graduation_year integer-ish vectors, the same
#'   length or one of length 1. Order matters: the difference is
#'   `graduation_year - credentialing_year`, so a NEGATIVE band means the
#'   person graduated BEFORE they credentialed.
#' @param bands the band table; defaults to [GRADUATION_YEAR_BANDS].
#' @return character: a `band` value, or `"unknown"` when either year is
#'   absent or unparseable.
#' @examples
#' graduation_year_band(2015, 2014)   # "one_before"
#' graduation_year_band(2015, 2016)   # "one_after"
#' graduation_year_band(2015, NA)     # "unknown"
#' @export
graduation_year_band <- function(credentialing_year, graduation_year,
                                 bands = GRADUATION_YEAR_BANDS) {
  a <- suppressWarnings(as.integer(credentialing_year))
  b <- suppressWarnings(as.integer(graduation_year))
  n <- max(length(a), length(b))
  a <- rep_len(a, n); b <- rep_len(b, n)
  d <- b - a
  out <- rep("unknown", n)
  known <- !is.na(d)
  for (i in seq_len(nrow(bands))) {
    hit <- known & d >= bands$lo[[i]] & d <= bands$hi[[i]] & out == "unknown"
    out[hit] <- bands$band[[i]]
  }
  out
}

#' Does a graduation year agree with a credentialing year?
#'
#' THE GAP THIS CLOSES. Every other rule in this package compares a name. A
#' name is the axis registries agree on precisely because they copy each other:
#' in one measured pair of national sources, the directory's first name matched
#' NPPES for 100% of linked clinicians, surname 99.96%, sex 99.92% and primary
#' taxonomy 99.75%. Evidence drawn from those fields is one source restated,
#' not two sources agreeing. The graduation year is the first field measured
#' that is genuinely independent: it equals the credentialing year for 70.4% of
#' true links but the NPI's own enumeration year for only 39.4%, so it tracks
#' the person's training, not the registry's paperwork.
#'
#' THREE VERDICTS, SAME CONTRACT AS [middle_agreement()].
#'
#' * `"corroborates"` -- the years are the same, or one year apart. Strength is
#'   NOT symmetric; see [GRADUATION_YEAR_BANDS].
#' * `"uninformative"` -- either year is absent, OR the gap falls in the middle
#'   bands (2 to 10 years either way). Absence is about 47% of pairs in the
#'   source measurement, so a caller that reads `"uninformative"` as
#'   disagreement discards half its population. The middle bands are reported
#'   as uninformative rather than as a conflict because their evidence is
#'   weak and NEGATIVE: a caller that scores must take it from `log2_lr`, and
#'   a caller that scores a 2-to-3-year gap as evidence FOR a link has the sign
#'   backwards.
#' * `"conflicts"` -- beyond ten years either way.
#'
#' USE THE CONFLICT AS A FLAG, NOT A VETO, with the discipline
#' [surname_agreement()] documents. Beyond ten years has an innocent reading in
#' both directions: an earlier degree in another discipline, or a doctorate
#' taken later. In the cohort this was measured on, that band is 2.5% of
#' high-confidence links but 47.6% of the tier the pipeline already treats as a
#' sensitivity analysis. Quarantine and review; do not delete.
#'
#' @inheritParams graduation_year_band
#' @return character: `"corroborates"`, `"conflicts"`, or `"uninformative"`.
#' @examples
#' graduation_year_agreement(2015, 2015)   # "corroborates"
#' graduation_year_agreement(2015, 2014)   # "corroborates" (the ordinary order)
#' graduation_year_agreement(2015, 2017)   # "uninformative" (weakly against)
#' graduation_year_agreement(2015, 1980)   # "conflicts" -- a flag, not a veto
#' graduation_year_agreement(2015, NA)     # "uninformative"
#' @seealso [GRADUATION_YEAR_BANDS] for the weights and their provenance,
#'   [graduation_year_band()] for the band a pair falls in.
#' @export
graduation_year_agreement <- function(credentialing_year, graduation_year,
                                      bands = GRADUATION_YEAR_BANDS) {
  band <- graduation_year_band(credentialing_year, graduation_year, bands)
  out <- rep("uninformative", length(band))
  hit <- match(band, bands$band)
  known <- !is.na(hit)
  out[known] <- bands$verdict[hit[known]]
  out
}
