#' srr documentation standards
#'
#' @description
#' The documentation standards, tagged where they are satisfied: the README and
#' the vignettes rather than any one function. Each tag names the section that
#' satisfies it, so a reviewer can check the claim instead of taking it.
#'
#' @srrstats {G1.0} Winkler's census surname work and the Fellegi-Sunter
#'   agree/disagree/uninformative vocabulary are cited in R/surname.R and
#'   R/name_matching.R, and `WINKLER_CENSUS` ships the reference table itself.
#' @srrstats {G1.1} README section "What this re-implements, and what is
#'   original": the primitives are established linkage practice and
#'   `parse_person()` wraps humaniformat; what is original is the refusals.
#' @srrstats {G1.2} README section "Life cycle": which surfaces are stable,
#'   which are maturing, what is deliberately out of scope, and why the package
#'   is not yet 1.0.
#' @srrstats {G1.3} Every verdict and evidence class is defined in roxygen and
#'   narrated in `vignette("vetoes-and-quarantine")`.
#' @srrstats {G1.4} roxygen2 throughout; every exported function has an .Rd
#'   page and the pkgdown site is published.
#' @srrstats {G1.5} `benchmark_comparison()` reproduces the performance claims
#'   of `vignette("roster-benchmark")` as a callable function.
#' @srrstats {G1.6} `vignette("comparison-with-alternatives")` measures these
#'   rules against a base-R edit-distance baseline on the same 190-pair corpus,
#'   reporting precision, recall and every disagreeing pair. It is a vignette
#'   rather than an exported function because
#'   tests/testthat/test-no-fuzzy.R refuses approximate matching anywhere in
#'   R/: the comparison must not make fuzzy machinery reachable from the
#'   namespace whose whole argument is that it should not be.
#'
#' @srrstats {EA1.0} README states the audience: pipelines linking person
#'   rosters to NPI.
#' @srrstats {EA1.1} The kinds of data are stated per function and in
#'   `vignette("resolving-a-roster")`: character name fields on a roster, and
#'   an NPPES-shaped reference table.
#' @srrstats {EA1.2} The questions are stated in the README's opening: does
#'   this pair name the same person, and which candidate wins one-to-one.
#' @srrstats {EA1.3} Per-function `@param` documentation on every entry point.
#'
#' @srrstats {RE5.0} `vignette("roster-benchmark")` documents how runtime and
#'   candidate counts scale with roster size.
#'
#' @name srr-stats-documentation
#' @keywords internal
NULL
