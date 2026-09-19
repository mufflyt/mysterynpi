# =============================================================================
# Taxonomy as an IDENTITY screen: three-valued, never a specialty classifier
# =============================================================================
#
# THE DEFECT CLASS THIS EXISTS FOR: a name-proposed NPI that belongs to a
# different PROFESSION entirely. The isochrones gold-standard audit found
# ~30% of name-proposed (name, NPI) pairs wrong with every error passing the
# Luhn check digit -- a dentist, an optometrist, a counselor, an organization
# record -- and its 2026-09-18 matcher QA measured 74.3% taxonomy
# inconsistency among ambiguous name-only matches against a 1.9% floor on
# exact matches. Taxonomy separates those cleanly BECAUSE the failure is
# cross-profession, where NUCC families do not overlap.
#
# WHAT THIS MUST NEVER BECOME: a subspecialty classifier. Measured against
# board certification, NPPES taxonomy runs 57-82% sensitivity and 58-65% PPV
# for subspecialty, wrong in both directions at once (isochrones
# non-negotiable #16). The screen therefore answers only "is this record's
# PROFESSION-level family consistent with the roster's board specialty" and
# answers in THREE values -- TRUE / FALSE / NA -- so "no basis to judge" can
# never silently pass as "clean".
# =============================================================================

#' NUCC family patterns for board specialties (identity screen only)
#'
#' Named character vector: board-specialty label -> pipe-separated NUCC code
#' prefixes a genuinely-that-specialty clinician's record may carry. Absence
#' from this table means "no expectation defined", which
#' [taxonomy_consistent()] reports as `NA`, never as a pass or a fail.
#' Deliberately coarse: prefixes name profession-level families, not
#' subspecialty codes, because subspecialty is board data's to decide.
#' @family taxonomy-agreement
#' @export
TAXONOMY_FAMILY_PATTERNS <- c(
  "Obstetrics & Gynecology" = "207V",
  "Family Medicine" = "207Q",
  "Internal Medicine" = "207R",
  "Anesthesiology" = "207L",
  "Psychiatry" = "2084",
  "Clinical Genetics" = "207SG|2084G|207S",
  "Clinical Genetics and Genomics" = "207SG|2084G|207S",
  "Anatomic Pathology" = "207Z",
  "Pathology - Anatomic/Pathology - Clinical" = "207Z",
  "Public Health & General Preventive Medicine" = "2083")

#' Expected taxonomy pattern for a board specialty, or `NA`
#'
#' @param specialty character vector of board-specialty labels.
#' @return character vector of prefix patterns, `NA` where no expectation is
#'   defined.
#' @family taxonomy-agreement
#' @export
taxonomy_family_pattern <- function(specialty) {
  out <- unname(TAXONOMY_FAMILY_PATTERNS[as.character(specialty)])
  out[is.na(out)] <- NA_character_
  out
}

#' Is a record's taxonomy consistent with a board specialty? Three-valued.
#'
#' Inspects the FULL pipe-concatenated code string, never just the first
#' code: an NPPES record may retain a residency code (`390200000X`) ahead of
#' `207V00000X`, and a first-segment shortcut misreads that clinician as a
#' non-physician (a real review-tool defect from the 2026-09-19 promotion
#' audit, caught because the audit's full-string screen disagreed with it).
#'
#' Returns `TRUE` when any code in the record starts with any expected
#' prefix, `FALSE` when codes exist and none do (a wrong-person signal),
#' and `NA` when the record has no codes OR no expectation is defined --
#' three-valued on purpose, so unknown can never read as clean.
#'
#' @param taxonomy character vector of pipe-concatenated NUCC codes (empty
#'   segments tolerated).
#' @param expected character vector of pipe-separated prefix patterns, e.g.
#'   from [taxonomy_family_pattern()].
#' @return logical vector: `TRUE` / `FALSE` / `NA`.
#' @family taxonomy-agreement
#' @export
taxonomy_consistent <- function(taxonomy, expected) {
  n <- max(length(taxonomy), length(expected))
  taxonomy <- rep_len(as.character(taxonomy), n)
  expected <- rep_len(as.character(expected), n)
  mapply(function(tx, ex) {
    if (is.na(tx) || is.na(ex)) return(NA)
    codes <- strsplit(tx, "|", fixed = TRUE)[[1]]
    codes <- codes[nzchar(codes)]
    if (!length(codes)) return(NA)
    prefixes <- strsplit(ex, "|", fixed = TRUE)[[1]]
    any(vapply(prefixes, function(p) any(startsWith(codes, p)), logical(1)))
  }, taxonomy, expected, USE.NAMES = FALSE)
}

#' Tie-break rank from a three-valued consistency verdict
#'
#' `0` consistent, `1` unknown, `2` inconsistent -- so a sort ascending on
#' this rank prefers consistent over unknown over inconsistent. Position the
#' rank AFTER every stronger ordering criterion (recency, confidence tier):
#' it exists to resolve ties, never to override stronger evidence. Measured
#' origin: the isochrones dedup broke ties by lowest NPI, blind to identity
#' quality, and the 2026-09-19 production promotion audit showed the rank
#' changing 360 of 22,002 selections, every one tied on recency and
#' confidence, zero rank regressions.
#'
#' @param consistent logical vector from [taxonomy_consistent()].
#' @return integer vector of 0/1/2.
#' @family taxonomy-agreement
#' @export
taxonomy_tiebreak_rank <- function(consistent) {
  out <- rep.int(1L, length(consistent))
  out[consistent %in% TRUE] <- 0L
  out[consistent %in% FALSE] <- 2L
  out
}
