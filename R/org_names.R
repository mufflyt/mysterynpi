# =============================================================================
# Organization names: corporate noise, and the person-vs-organization bridge
# =============================================================================

#' Corporate-form and generic-descriptor tokens in organization names.
#'
#' The organizational counterpart of [NAME_NOISE]: tokens that describe the
#' FORM of an organization, never its identity. Dropped before a person name
#' is compared against an organization name, because they are exactly the
#' tokens the two sides never share.
#' @export
ORG_NOISE <- c(
  "INC","LLC","LLP","LTD","CORP","CORPORATION","PC","PA","PLLC","PLC",
  "CO","COMPANY","GROUP","ASSOCIATES","ASSOC","PARTNERS","DBA",
  "MEDICAL","MEDICINE","HEALTH","HEALTHCARE","CLINIC","CLINICS",
  "CENTER","CENTERS","CENTRE","INSTITUTE","FOUNDATION","SERVICES",
  "CARE","PROFESSIONAL","PRACTICE","OFFICE","OFFICES",
  "THE","OF","AND","A","AN")

# Identity tokens of a name string: name_key() normalisation, split on
# whitespace, corporate-form and credential vocabulary removed. Shared by
# org_name_matches_person() and npi_corroborate().
#
# CREDENTIAL REMOVAL GOES THROUGH strip_name_noise(), NOT A BARE
# setdiff(..., NAME_NOISE), so a surname that collides with a credential
# token (`DO`, the Vietnamese surname vs. the Doctor of Osteopathic Medicine
# credential -- see strip_name_noise()'s "THE DO CARVE-OUT") gets the same
# protection here as everywhere else NAME_NOISE is applied. A practice
# literally named after the physician's own colliding surname --
# "Do Family Medicine Clinic" for a physician named Anh Do, the organisation
# form of the exact defect strip_name_noise() exists to prevent -- used to
# strip "DO" unconditionally and lose the only shared identity token,
# reporting no match between a person and their own practice.
#
# THIS MUST RUN ON THE RAW STRING, BEFORE name_key() UPPERCASES IT.
# strip_name_noise()'s title-case carve-out ("Do", never "DO") is a case
# distinction; running it after normalisation would destroy the very signal
# it reads.
.identity_tokens <- function(x) {
  stripped <- strip_name_noise(x)
  keys <- name_key(stripped, fold_hyphens = TRUE)
  lapply(strsplit(ifelse(is.na(keys), "", keys), " ", fixed = TRUE), function(t) {
    t <- t[nchar(t) >= 2L]
    setdiff(t, ORG_NOISE)
  })
}

#' Does an organization name carry a person's identity?
#'
#' Provider data constantly crosses the person/organization NPI boundary: a
#' sanctioned physician's identifier resolves to their own professional
#' corporation ("Nadine H. Yassa" against "NADINE H. YASSA, M.D., INC."), or
#' to the practice they run ("Francis Peter Lagattuta" against "LAGS SPINE &
#' SPORTSCARE MEDICAL CENTERS INC"). A person-name comparison sees only a
#' mismatch there. Measured in the 2026-09-13 Medicaid exclusion linkage, all
#' 14 of the name "mismatches" among NPPES-corroborated NPIs were this
#' pattern, not wrong people.
#'
#' The rule: after [name_key()] normalisation, drop corporate-form tokens
#' ([ORG_NOISE]) and credentials ([NAME_NOISE]) from both sides; the names
#' match when any identity token remains shared. Hyphens are folded so
#' "ABBAS-RODRIGUEZ MEDICAL GROUP" meets "Abbas Rodriguez" -- this is a
#' surname-style comparison, where folding is the documented correct setting.
#'
#' A shared identity token is DELIBERATELY weak evidence -- "SMITH" ties
#' "John Smith" to "SMITH MEDICAL GROUP" -- so treat a `TRUE` as
#' corroboration to weigh, never as an identity match on its own; pair it
#' with an identifier the way [npi_corroborate()] does.
#'
#' @param org character vector of organization names.
#' @param person character vector of person names, the same length.
#' @return logical vector: `TRUE` when an identity token is shared, `FALSE`
#'   when both sides carry identity tokens and share none, `NA` when either
#'   side has no identity tokens left after noise removal (nothing to
#'   compare).
#' @export
org_name_matches_person <- function(org, person) {
  n <- length(org)
  if (length(person) != n) {
    stop("org and person must be the same length", call. = FALSE)
  }
  to <- .identity_tokens(org)
  tp <- .identity_tokens(person)
  vapply(seq_len(n), function(i) {
    if (!length(to[[i]]) || !length(tp[[i]])) return(NA)
    length(intersect(to[[i]], tp[[i]])) > 0L
  }, logical(1))
}
