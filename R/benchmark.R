# =============================================================================
# The benchmark evaluation, as a function instead of a vignette to re-type
# =============================================================================
# WHY THIS EXISTS. vignettes/roster-benchmark.Rmd scores all 190
# ROSTER_BENCHMARK pairs through the six agreement axes, applies the
# maiden-as-middle excusal, and crosstabs the decision against truth. It is a
# genuine reference evaluation -- and it existed only as prose, so a caller who
# wanted to know whether their build still reproduced it had to re-type the
# vignette.
#
# These three functions are that procedure, lifted verbatim in its logic. The
# vignette remains the explanation; this is the thing a test can call.
#
# srr EA3.1 (standardised comparison against reference results), RE4.11
# (goodness-of-fit statistics), G5.7 (behaviour as data properties change) and
# G1.5 (code reproducing stated performance claims) are all this file.
#
# WHAT IT DOES NOT MEASURE, stated here because the vignette states it: this
# evaluates the AGREEMENT RULES, not blocking -- every pair in the benchmark
# was already formed -- and it does so on a corpus built from this package's
# own defect taxonomy, so clean separation is consistency rather than proof of
# generality. WINKLER_CENSUS exists to be harder.
# =============================================================================

#' The six agreement axes for a benchmark-shaped table
#'
#' @description
#' Applies [surname_agreement()], [nickname_agreement()],
#' [middle_agreement()], [suffix_agreement()], [gender_agreement()] and
#' [license_agreement()] to a table of paired roster/registry records, and
#' flags the maiden-as-middle pairs whose middle-name conflict must not veto
#' (the roster's middle token *is* the registry surname, so the surname rescue
#' has already used it).
#'
#' @param data [data.frame] shaped like [ROSTER_BENCHMARK]: `roster_name`,
#'   `roster_gender`, `roster_state`, `roster_license`, `npi_first`,
#'   `npi_middle`, `npi_last`, `npi_suffix`, `npi_gender`, `npi_state`,
#'   `npi_license`.
#' @return [data.frame] one row per input row: the six axes plus `excused`.
#' @examples
#' head(benchmark_axes(ROSTER_BENCHMARK[1:5, ]), 3)
#' @export
benchmark_axes <- function(data = mysterynpi::ROSTER_BENCHMARK) {
  data <- as_linkage_table(data, "data", quiet = TRUE)
  need <- c("roster_name", "roster_gender", "roster_state", "roster_license",
            "npi_first", "npi_middle", "npi_last", "npi_suffix", "npi_gender",
            "npi_state", "npi_license")
  miss <- setdiff(need, names(data))
  if (length(miss)) {
    stop(sprintf("data is missing benchmark column(s): %s",
                 paste(miss, collapse = ", ")), call. = FALSE)
  }
  ex <- extract_suffix(read_name_column(data$roster_name, "roster_name",
                                        quiet = TRUE))
  p <- parse_person(ex$name)
  mt <- middle_tokens(p$middle)
  axes <- data.frame(
    surname = surname_agreement(p$last, data$npi_last,
                                middle_a = p$middle, middle_b = data$npi_middle),
    given = nickname_agreement(sub(" .*", "", p$first), data$npi_first),
    middle = middle_agreement(mt, middle_tokens(data$npi_middle)),
    suffix = suffix_agreement(ex$suffix, data$npi_suffix),
    gender = gender_agreement(data$roster_gender, data$npi_gender),
    license = license_agreement(data$roster_license, data$roster_state,
                                data$npi_license, data$npi_state),
    stringsAsFactors = FALSE)
  axes$excused <- mapply(
    function(tokens, last) length(intersect(tokens, surname_tokens(last))) > 0L,
    mt, data$npi_last)
  axes
}

#' The accept / review / reject decision for benchmark pairs
#'
#' @description
#' The decision rule the benchmark vignette argues for: any conflicting axis
#' rejects (middle-name conflicts excepted when excused), a pair without both
#' surname and given corroboration goes to review, a gender conflict goes to
#' review rather than to deletion, and everything else is accepted.
#'
#' @param data [data.frame] shaped like [ROSTER_BENCHMARK].
#' @param axes [data.frame] from [benchmark_axes()]; computed if not supplied.
#' @return [character] `"accept"`, `"review"` or `"reject"` per row.
#' @examples
#' table(benchmark_decisions(ROSTER_BENCHMARK))
#' @export
benchmark_decisions <- function(data = mysterynpi::ROSTER_BENCHMARK,
                                axes = NULL) {
  if (is.null(axes)) axes <- benchmark_axes(data)
  conflict <- axes$surname == "conflicts" | axes$given == "conflicts" |
    (axes$middle == "conflicts" & !axes$excused) | axes$suffix == "conflicts"
  name_ok <- axes$surname == "corroborates" & axes$given == "corroborates"
  ifelse(conflict, "reject",
         ifelse(!name_ok, "review",
                ifelse(axes$gender == "conflicts", "review", "accept")))
}

#' Evaluate the agreement rules against the shipped benchmark
#'
#' @description
#' Runs the benchmark evaluation and returns the confusion table beside the
#' three properties the vignette claims for it, each with an explicit pass
#' column: every accept is a true match, every reject a true nonmatch, and
#' every reviewed pair is a true match (the stale-gender family routed to a
#' person rather than deleted).
#'
#' @param data [data.frame] shaped like [ROSTER_BENCHMARK], with a `truth`
#'   column of `"match"` / `"nonmatch"`.
#' @param digits [integer(1)] precision for the reported rates (srr EA4.1).
#' @return a list with `table` (decision by truth), `properties` (one row per
#'   claimed property, with `pass`), and `rates` (accept/review/reject shares
#'   and precision among accepts). Attribute `"all_pass"` is `TRUE` when every
#'   property holds.
#' @examples
#' b <- benchmark_comparison()
#' b$properties
#' @seealso `vignette("roster-benchmark", package = "mysterynpi")` for the
#'   construction of the corpus and the caveats on what it can show.
#' @export
benchmark_comparison <- function(data = mysterynpi::ROSTER_BENCHMARK,
                                 digits = 3L) {
  check_scalar(digits, "digits")
  if (!"truth" %in% names(data)) {
    stop("data needs a truth column of \"match\" / \"nonmatch\"", call. = FALSE)
  }
  decision <- benchmark_decisions(data)
  truth <- as.character(data$truth)
  tab <- table(decision = decision, truth = truth)
  got <- function(d, t) if (d %in% rownames(tab) && t %in% colnames(tab))
    as.integer(tab[d, t]) else 0L
  n <- length(decision)
  props <- data.frame(
    property = c("every accept is a true match",
                 "every reject is a true nonmatch",
                 "every reviewed pair is a true match"),
    violations = c(got("accept", "nonmatch"), got("reject", "match"),
                   got("review", "nonmatch")),
    stringsAsFactors = FALSE)
  props$pass <- props$violations == 0L
  accepts <- got("accept", "match") + got("accept", "nonmatch")
  rates <- data.frame(
    statistic = c("pairs", "accept_share", "review_share", "reject_share",
                  "precision_among_accepts"),
    value = c(n,
              round(sum(decision == "accept") / n, digits),
              round(sum(decision == "review") / n, digits),
              round(sum(decision == "reject") / n, digits),
              if (accepts > 0L) round(got("accept", "match") / accepts, digits)
              else NA_real_),
    stringsAsFactors = FALSE)
  structure(list(table = tab, properties = props, rates = rates),
            all_pass = all(props$pass))
}


#' Reference comparison
#'
#' @description
#' The srr standards this file implements, tagged so `srr::srr_stats_pre_submit()`
#' can count them. The implementations and their reasoning are in the functions
#' below; this block only records which standard each one serves.
#'
#' @srrstats {EA3.1} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {RE4.11} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {G1.5} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @srrstats {G5.7} implemented in this file; see the function documentation and the file header for the defect it prevents.
#' @name srr-benchmark
#' @keywords internal
NULL

