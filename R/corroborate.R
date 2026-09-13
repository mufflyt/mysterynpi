# =============================================================================
# Corroborating NPI candidates against an authoritative registry snapshot
# =============================================================================

#' Corroborate candidate NPIs against a registry snapshot
#'
#' A checksum is a WEAK gate: roughly one in ten arbitrary 10-digit strings
#' passes the NPI Luhn check by chance, so a candidate harvested from a
#' generic identifier field (a state license number, a Medicaid provider id)
#' can look structurally valid and still belong to nobody. The gate that
#' actually decides is existence in an authoritative registry snapshot,
#' with name and state agreement reported alongside. Measured in the
#' 2026-09-13 Medicaid exclusion linkage: of 66 generic-field candidates
#' that passed the checksum, 63 existed in NPPES and 3 did not.
#'
#' THE SNAPSHOT'S VINTAGE IS PART OF THE ANSWER. "Absent from the 2024
#' snapshot" is not "fake": 241 of 15,902 linkage NPIs in the same audit
#' were real identifiers that predated or postdated the snapshot. Record
#' which snapshot you corroborated against, and treat `unverified` as
#' "not confirmed by THIS snapshot", never as proof of forgery.
#'
#' Name agreement uses identity tokens (the [org_name_matches_person()]
#' rule), so a person candidate matching their own professional
#' corporation's organizational NPI still reports `TRUE`. State agreement
#' is exact after trimming and case-folding. Both are `NA` whenever either
#' side lacks the information -- absence is never evidence.
#'
#' @param npi character vector of candidate NPIs.
#' @param name optional character vector, same length: the candidate's name
#'   as the source published it.
#' @param state optional character vector, same length: the candidate's
#'   two-letter state.
#' @param snapshot data.frame holding the registry snapshot. Must contain
#'   the column named by `snapshot_cols["npi"]`, with no duplicate NPIs (a
#'   duplicate would fan out the join and double-count corroboration).
#'   Name and state columns are used when present, skipped when absent.
#' @param snapshot_cols named character vector mapping the roles `npi`,
#'   `last_name`, `first_name`, `org_name`, `state` to the snapshot's
#'   column names. Defaults expect those literal names.
#' @return data.frame, one row per candidate, in input order:
#'   `npi`, `structurally_valid` ([npi_luhn_ok()]; `NA` for `NA` input),
#'   `in_snapshot`, `name_match`, `state_match`, and `confidence`:
#'   `"invalid"` (fails the structural check), `"corroborated"` (valid and
#'   present in the snapshot), `"unverified"` (valid, absent from this
#'   snapshot), `NA` (no NPI supplied).
#' @export
npi_corroborate <- function(npi, name = NULL, state = NULL, snapshot,
                            snapshot_cols = c(npi = "npi",
                                              last_name = "last_name",
                                              first_name = "first_name",
                                              org_name = "org_name",
                                              state = "state")) {
  n <- length(npi)
  for (arg in list(name = name, state = state)) {
    if (!is.null(arg) && length(arg) != n) {
      stop("name and state must be NULL or the same length as npi",
           call. = FALSE)
    }
  }
  if (!is.data.frame(snapshot)) stop("snapshot must be a data.frame", call. = FALSE)
  npi_col <- snapshot_cols[["npi"]]
  if (!npi_col %in% names(snapshot)) {
    stop("snapshot lacks the NPI column '", npi_col, "'", call. = FALSE)
  }
  snap_npi <- as.character(snapshot[[npi_col]])
  if (anyDuplicated(snap_npi)) {
    stop("snapshot holds duplicate NPIs; a duplicate fans out the join ",
         "and double-counts corroboration", call. = FALSE)
  }

  npi <- as.character(npi)
  valid <- npi_luhn_ok(npi)
  # NA in, NA out, independent of npi_luhn_ok()'s own NA behaviour (PR #13):
  # a missing candidate NPI is not an invalid one.
  valid[is.na(npi)] <- NA
  row <- match(npi, snap_npi)
  in_snapshot <- !is.na(row)
  in_snapshot[is.na(npi)] <- NA

  snap_field <- function(role) {
    if (!role %in% names(snapshot_cols)) return(NULL)
    col <- snapshot_cols[[role]]
    if (is.null(col) || is.na(col) || !col %in% names(snapshot)) return(NULL)
    out <- rep(NA_character_, n)
    out[!is.na(row)] <- as.character(snapshot[[col]])[row[!is.na(row)]]
    out
  }

  name_match <- rep(NA, n)
  if (!is.null(name)) {
    pieces <- list(snap_field("last_name"), snap_field("first_name"),
                   snap_field("org_name"))
    pieces <- Filter(Negate(is.null), pieces)
    if (length(pieces)) {
      snap_name <- do.call(paste, c(lapply(pieces, function(p) {
        ifelse(is.na(p), "", p)
      }), sep = " "))
      snap_name[!nzchar(trimws(snap_name))] <- NA_character_
      name_match <- org_name_matches_person(snap_name, name)
    }
  }

  state_match <- rep(NA, n)
  snap_state <- snap_field("state")
  if (!is.null(state) && !is.null(snap_state)) {
    norm <- function(x) toupper(trimws(ifelse(is.na(x), NA_character_, x)))
    a <- norm(state); b <- norm(snap_state)
    state_match <- a == b
    state_match[is.na(a) | is.na(b) | !nzchar(a) | !nzchar(b)] <- NA
  }

  confidence <- rep(NA_character_, n)
  confidence[!is.na(valid) & !valid] <- "invalid"
  confidence[isTRUE_v(valid) & isTRUE_v(in_snapshot)] <- "corroborated"
  confidence[isTRUE_v(valid) & !is.na(in_snapshot) & !in_snapshot] <- "unverified"

  data.frame(npi = npi, structurally_valid = valid, in_snapshot = in_snapshot,
             name_match = name_match, state_match = state_match,
             confidence = confidence, stringsAsFactors = FALSE)
}

# Vectorised isTRUE: TRUE where x is TRUE, FALSE for FALSE or NA.
isTRUE_v <- function(x) !is.na(x) & x
