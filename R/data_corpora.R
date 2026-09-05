# =============================================================================
# Vendored evaluation corpora. Licenses summarised in inst/COPYRIGHTS.
# =============================================================================

#' Winkler's synthetic census pairs, via the SecondString project
#'
#' Two relations of SYNTHETIC person records (A: 449 rows, B: 392) authored
#' by William Winkler for record-linkage evaluation and distributed with the
#' SecondString project. Deliberately full of classic name pathology: typos
#' (`BENITEZ`/`BENETAS`), truncated and swapped given names
#' (`LEARONAD`/`LENARD`), and household confusion. An `id` present in BOTH
#' relations is the same synthetic person -- 327 labeled matches. Eleven ids
#' additionally repeat within a relation; those duplicates are kept, and
#' [duplicate_differences()] is how to look at them. No real individual is
#' described.
#'
#' @format data.frame with columns `relation`, `id`, `surname`, `given`,
#'   `middle`, `house`, `street`; 841 rows.
#' @source \url{https://github.com/TeamCohen/secondstring} (`data/censusText.txt`,
#'   pinned commit in `data-raw/WINKLER_CENSUS.R`). License: Carnegie Mellon
#'   University, 2003, permissive with notice retention -- shipped as
#'   `system.file("secondstring-LICENSE", package = "mysterynpi")`.
"WINKLER_CENSUS"

#' The 1,000 most frequent U.S. surnames, Census 2010
#'
#' The top of the Census Bureau's "Frequently Occurring Surnames from the
#' 2010 Census" file: aggregate frequencies, no individuals. Vendored for
#' term-frequency awareness -- agreement on `SMITH` (rank 1) is weaker
#' evidence than agreement on a rare surname, and an ordered-class policy
#' may rank it accordingly -- and for generating realistic synthetic
#' fixtures ([ROSTER_BENCHMARK] draws its surnames here).
#'
#' @format data.frame with columns `surname`, `rank`, `count`, `per_100k`;
#'   1,000 rows.
#' @source U.S. Census Bureau,
#'   \url{https://www.census.gov/topics/population/genealogy/data/2010_surnames.html}
#'   -- a U.S. government work in the public domain. Derivation:
#'   `data-raw/SURNAME_FREQUENCIES.R`.
"SURNAME_FREQUENCIES"

#' A labeled, fully synthetic roster-to-registry matching benchmark
#'
#' One row per (roster record, registry candidate) pair: a free-text roster
#' name with the fields state boards actually hold, against NPPES-shaped
#' split fields, with `truth` (`"match"`/`"nonmatch"`) assigned BY
#' CONSTRUCTION and `family` naming the defect each pair encodes -- from
#' `exact` through `nickname`, `maiden-as-middle`, `suffix-generations`,
#' `stale-gender`, `spelling-trap`, `cross-gender-derivative`,
#' `hub-nickname`, `license-anchor`, `stacked-defects` and `absence`.
#' 190 pairs: 132 matches, 58 nonmatches.
#'
#' WHY IT EXISTS. No public benchmark for roster-to-NPPES name matching
#' exists, because NPPES describes real providers and a labeled gold
#' standard would name real people. Every pair here is synthetic and
#' authored in reviewable code (`data-raw/ROSTER_BENCHMARK.R`); surnames
#' come from the public-domain Census frequency file. A pair whose truth a
#' reviewer could not assign did not go in. The same table ships as plain
#' CSV for use outside R:
#' `system.file("extdata", "roster_benchmark.csv", package = "mysterynpi")`.
#'
#' `vignette("roster-benchmark")` evaluates the package's own rules against
#' it and shows the [clerical_sample()] / [clerical_precision()] workflow.
#'
#' @format data.frame, 190 rows: `pair_id`, `family`, `truth`, `note`,
#'   `roster_name`, `roster_gender`, `roster_state`, `roster_license`,
#'   `npi_first`, `npi_middle`, `npi_last`, `npi_suffix`, `npi_credential`,
#'   `npi_gender`, `npi_state`, `npi_license`.
#' @source Authored with this package; MIT like the package itself.
"ROSTER_BENCHMARK"
