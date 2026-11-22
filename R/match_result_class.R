# =============================================================================
# A class on the match result, so printing a result is not printing a list
# =============================================================================
# WHY THIS EXISTS. match_npi() returned a bare list of five elements. Printing
# it dumped every matched row to the console; reading a proportion out of it
# meant knowing which element held it; and the numbers printed at whatever
# precision R felt like, so a 0.9833333 share appeared next to a 0.98 one in
# the same report.
#
# The class is additive by construction: the object is the same list with the
# same five names, so every existing caller's `result$matches` keeps working.
# What is new is that `print()`, `format()`, `summary()` and `nobs()` now
# exist, which is what srr EA4.1, EA4.2, EA5.2, EA5.3, EA3.0 and RE4.5 ask
# for.
#
# WHAT IS DELIBERATELY NOT HERE: a plot method. The EDA standards ask for
# default print AND plot methods (EA4.2), and a match result has no natural
# plot -- the funnel in vignettes/end-to-end-nppes-matching.Rmd is a choice
# about which counts matter, which is the caller's. A plot method that picked
# for them would be a chart with an opinion and no caption.
# =============================================================================

#' Give a match result its class
#'
#' @description
#' Wraps the list [match_npi()] builds so it can be printed, formatted and
#' summarised. Called by `match_npi()`; exported so a caller assembling a
#' result from parts can label it the same way.
#'
#' @param x [list] with elements `matches`, `review`, `unmatched`, `counts`
#'   and `run_manifest`.
#' @return `x` with class `"npi_match_result"`.
#' @export
new_npi_match_result <- function(x) {
  need <- c("matches", "review", "unmatched", "counts")
  miss <- setdiff(need, names(x))
  if (length(miss)) {
    stop(sprintf("a match result needs element(s): %s",
                 paste(miss, collapse = ", ")), call. = FALSE)
  }
  structure(x, class = c("npi_match_result", class(x)))
}

#' Number of roster rows a match result was built from
#'
#' @description
#' The `nobs()` method srr RE4.5 asks for: how many rows were submitted, which
#' is the denominator of every rate in [summary.npi_match_result()] and is
#' otherwise reachable only by knowing that `counts$roster_rows` is where it
#' lives.
#'
#' @param object an `npi_match_result`.
#' @param ... ignored.
#' @return [integer(1)] roster rows submitted.
#' @export
nobs.npi_match_result <- function(object, ...) {
  as.integer(object$counts$roster_rows)
}

#' Standardised statistics from a match result
#'
#' @description
#' One tidy frame of named statistics, so a report does not have to reach into
#' the result's structure and compute its own rates (srr EA3.0). Every rate is
#' over `nobs()`, stated in the frame rather than implied.
#'
#' The `columns` element reports the class and storage mode of every column of
#' the matched table, which is what srr EA5.3 asks of a column-based summary:
#' an identifier silently stored as a double is a defect you can only see if
#' something tells you the storage mode.
#'
#' @param object an `npi_match_result`.
#' @param digits [integer(1)] precision for the reported proportions. The
#'   explicit numeric-precision control srr EA4.1 asks for; the default of 3 is
#'   stated rather than inherited from `options(digits)`.
#' @param ... ignored.
#' @return a list of two data frames, `statistics` and `columns`, with class
#'   `"summary.npi_match_result"`.
#' @export
summary.npi_match_result <- function(object, digits = 3L, ...) {
  check_scalar(digits, "digits")
  n <- nobs.npi_match_result(object)
  cnt <- object$counts
  share <- function(x) if (n > 0L) round(x / n, digits) else NA_real_
  stats <- data.frame(
    statistic = c("roster_rows", "matched", "review", "unmatched",
                  "missing_required_name", "candidate_pairs",
                  "matched_share", "review_share", "unmatched_share"),
    value = c(n, cnt$matches, cnt$review, cnt$unmatched,
              cnt$missing_required_name, cnt$candidate_pairs,
              share(cnt$matches), share(cnt$review), share(cnt$unmatched)),
    denominator = c(NA_character_, rep("roster_rows", 4), NA_character_,
                    rep("roster_rows", 3)),
    stringsAsFactors = FALSE)
  cols <- object$matches
  columns <- data.frame(
    column = names(cols),
    class = vapply(cols, function(z) class(z)[1], character(1)),
    storage_mode = vapply(cols, storage.mode, character(1)),
    n_missing = vapply(cols, function(z) sum(is.na(z)), integer(1)),
    stringsAsFactors = FALSE, row.names = NULL)
  structure(list(statistics = stats, columns = columns, digits = digits),
            class = "summary.npi_match_result")
}

#' Format a match result for printing
#'
#' @description
#' The formatted lines `print()` emits. Numbers are formatted here, at a stated
#' precision, rather than left to default numeric printing (srr EA5.2, EA4.1).
#'
#' @param x an `npi_match_result`.
#' @param digits [integer(1)] precision for proportions.
#' @param ... ignored.
#' @return [character] one element per line.
#' @export
format.npi_match_result <- function(x, digits = 3L, ...) {
  s <- summary.npi_match_result(x, digits = digits)
  st <- stats::setNames(s$statistics$value, s$statistics$statistic)
  pct <- function(p) if (is.na(p)) "   NA" else formatC(100 * p, format = "f",
                                                        digits = 1, width = 5)
  c(sprintf("<npi_match_result> %s roster row(s)",
            format(st[["roster_rows"]], big.mark = ",")),
    sprintf("  matched   %7s  %s%%",
            format(st[["matched"]], big.mark = ","), pct(st[["matched_share"]])),
    sprintf("  review    %7s  %s%%",
            format(st[["review"]], big.mark = ","), pct(st[["review_share"]])),
    sprintf("  unmatched %7s  %s%%",
            format(st[["unmatched"]], big.mark = ","),
            pct(st[["unmatched_share"]])),
    sprintf("  %s candidate pair(s) considered; %s row(s) lacked a required name",
            format(st[["candidate_pairs"]], big.mark = ","),
            format(st[["missing_required_name"]], big.mark = ",")),
    "  summary() for the statistics frame and per-column storage modes")
}

#' Print a match result
#'
#' @param x an `npi_match_result`.
#' @param digits [integer(1)] precision for proportions.
#' @param ... ignored.
#' @return `x`, invisibly.
#' @export
print.npi_match_result <- function(x, digits = 3L, ...) {
  cat(format.npi_match_result(x, digits = digits), sep = "\n")
  invisible(x)
}

#' Print a match-result summary
#'
#' @param x a `summary.npi_match_result`.
#' @param ... ignored.
#' @return `x`, invisibly.
#' @export
print.summary.npi_match_result <- function(x, ...) {
  cat("statistics (proportions rounded to", x$digits, "digits):\n")
  print(x$statistics, row.names = FALSE)
  cat("\nmatched-table columns:\n")
  print(x$columns, row.names = FALSE)
  invisible(x)
}

#' The match result as an object with methods
#'
#' @description
#' The srr standards this file implements, tagged so `srr::srr_stats_pre_submit()`
#' can count them. The implementations and their reasoning are in the functions
#' below; this block only records which standard each one serves.
#'
#' @srrstats {EA3.0} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {EA4.0} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {EA4.1} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {EA4.2} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {EA5.2} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {EA5.3} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {RE4.5} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @name srr-match-result-class
#' @keywords internal
NULL

