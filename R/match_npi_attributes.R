#' Attributes match_npi() can block or corroborate on
#'
#' Beyond names, `match_npi()` can weigh six optional attributes, each judged
#' by the package's canonical rule for that field and each reported in the
#' shared three-verdict vocabulary (`corroborates`, `conflicts`,
#' `uninformative`). Absence on either side is always uninformative.
#'
#' \describe{
#'   \item{gender}{[gender_agreement()].}
#'   \item{credential}{[normalize_credential()] on both sides; any shared
#'     degree corroborates, disjoint non-blank degrees (MD against DO)
#'     conflict.}
#'   \item{taxonomy}{[taxonomy_consistent()]: the roster value is one or more
#'     `|`-separated code prefixes, the reference value one or more codes.}
#'   \item{license}{[license_agreement()], which needs the issuing state on
#'     both sides and can only corroborate, never conflict.}
#'   \item{graduation_year}{[graduation_year_agreement()]: the roster holds the
#'     graduation year, the reference a credentialing or enumeration year (a
#'     date's leading four digits are used). Beyond ten years conflicts; that
#'     rule's documentation asks for the conflict to be a flag, so leave it
#'     out of `block`.}
#'   \item{state}{Two-letter codes compared after trimming and upper-casing.}
#' }
#'
#' A conflicting attribute vetoes a candidate (it goes to `review` with reason
#' `<attribute>_conflict`) unless the attribute is named in `block`, in which
#' case the candidate is removed before evidence and counted in
#' `counts$blocked_by_attribute`. Corroborating attributes are counted into
#' `attribute_rank`, the tie-break applied after evidence class and middle
#' corroboration inside [resolve_one_to_one()].
#' @format A character vector of the six attribute names.
#' @export
MATCH_NPI_ATTRIBUTES <- c("gender", "credential", "taxonomy", "license",
                          "graduation_year", "state")

.match_npi_attribute_spec <- function(attributes, block) {
  if (is.null(attributes)) attributes <- list()
  if (!is.list(attributes) || (length(attributes) && (is.null(names(attributes)) ||
      anyNA(names(attributes)) || any(!nzchar(names(attributes)))))) {
    stop("attributes must be a named list of column maps", call. = FALSE)
  }
  if (anyDuplicated(names(attributes))) stop("attributes must not repeat a name", call. = FALSE)
  unknown <- setdiff(names(attributes), MATCH_NPI_ATTRIBUTES)
  if (length(unknown)) {
    stop("unknown attribute(s): ", paste(unknown, collapse = ", "), "; supported: ",
         paste(MATCH_NPI_ATTRIBUTES, collapse = ", "), call. = FALSE)
  }
  for (name in names(attributes)) {
    map <- attributes[[name]]
    needed <- .match_npi_attribute_slots(name)
    if (!is.character(map) || is.null(names(map)) || length(map) != length(needed) ||
        !setequal(names(map), needed) || anyNA(map) || any(!nzchar(trimws(map)))) {
      stop("attribute '", name, "' must map ", paste(needed, collapse = ", "),
           " to column names", call. = FALSE)
    }
  }
  if (!is.character(block) || anyNA(block)) {
    stop("block must be a character vector of attribute names", call. = FALSE)
  }
  missing <- setdiff(block, names(attributes))
  if (length(missing)) {
    stop("block names must be mapped attributes: ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  list(attributes = attributes, block = unique(block))
}

.match_npi_attribute_slots <- function(name) {
  if (identical(name, "license")) c("roster", "roster_state", "nppes", "nppes_state")
  else c("roster", "nppes")
}

# Column names an attribute spec needs on one side ("roster" or "nppes").
.match_npi_attribute_columns <- function(spec, side) {
  unique(unlist(lapply(spec$attributes, function(map) {
    unname(map[startsWith(names(map), side)])
  }), use.names = FALSE))
}

.match_npi_attribute_check <- function(spec, roster_names, nppes_names) {
  for (name in names(spec$attributes)) {
    map <- spec$attributes[[name]]
    for (slot in names(map)) {
      available <- if (startsWith(slot, "roster")) roster_names else nppes_names
      if (!map[[slot]] %in% available) {
        stop(if (startsWith(slot, "roster")) "roster" else "nppes",
             " is missing attribute column for ", name, ": ", map[[slot]], call. = FALSE)
      }
    }
  }
}

.match_npi_blank <- function(x) is.na(x) | !nzchar(trimws(as.character(x)))

.match_npi_year <- function(x) {
  suppressWarnings(as.integer(substr(trimws(as.character(x)), 1L, 4L)))
}

.match_npi_attribute_verdict <- function(name, a, b, state_a = NULL, state_b = NULL) {
  a <- as.character(a)
  b <- as.character(b)
  out <- switch(name,
    gender = gender_agreement(a, b),
    license = license_agreement(a, as.character(state_a), b, as.character(state_b)),
    state = ifelse(toupper(trimws(a)) == toupper(trimws(b)), "corroborates", "conflicts"),
    credential = {
      x <- normalize_credential(a)
      y <- normalize_credential(b)
      as.character(mapply(function(p, q) {
        if (!nzchar(p) || !nzchar(q)) return("uninformative")
        shared <- intersect(strsplit(p, ", ", fixed = TRUE)[[1]],
                            strsplit(q, ", ", fixed = TRUE)[[1]])
        if (length(shared)) "corroborates" else "conflicts"
      }, x, y, USE.NAMES = FALSE))
    },
    taxonomy = {
      ok <- taxonomy_consistent(b, a)
      ifelse(is.na(ok), "uninformative", ifelse(ok, "corroborates", "conflicts"))
    },
    graduation_year = graduation_year_agreement(.match_npi_year(b), .match_npi_year(a)),
    stop("unknown attribute: ", name, call. = FALSE))
  out <- as.character(out)
  if (!length(a)) return(character())
  out[.match_npi_blank(a) | .match_npi_blank(b)] <- "uninformative"
  out
}

# One row per NPI. Several reference rows for one NPI that disagree on an
# attribute make that attribute uninformative rather than picking a row.
.match_npi_collapse_reference <- function(values, cols) {
  npis <- unique(values$.npi)
  out <- data.frame(.npi = npis, stringsAsFactors = FALSE)
  for (col in cols) {
    x <- as.character(values[[col]])
    x[.match_npi_blank(x)] <- NA_character_
    collapsed <- vapply(split(x, factor(values$.npi, levels = npis)), function(v) {
      u <- unique(v[!is.na(v)])
      if (length(u) == 1L) u else NA_character_
    }, character(1))
    out[[col]] <- unname(collapsed)
  }
  out
}

# Apply mapped attributes to evidence rows: add <attribute>_evidence columns,
# count corroborations into attribute_rank, veto or block conflicts.
.match_npi_apply_attributes <- function(candidates, spec, roster_values, reference_values) {
  candidates$attribute_rank <- rep(0L, nrow(candidates))
  blocked <- stats::setNames(integer(length(spec$attributes)), names(spec$attributes))
  keep <- rep(TRUE, nrow(candidates))
  source_rows <- match(candidates$source_id, roster_values$.source_id)
  reference_rows <- match(candidates$npi, reference_values$.npi)
  for (name in names(spec$attributes)) {
    map <- spec$attributes[[name]]
    a <- roster_values[[map[["roster"]]]][source_rows]
    b <- reference_values[[map[["nppes"]]]][reference_rows]
    state_a <- if (name == "license") roster_values[[map[["roster_state"]]]][source_rows]
    state_b <- if (name == "license") reference_values[[map[["nppes_state"]]]][reference_rows]
    verdict <- .match_npi_attribute_verdict(name, a, b, state_a, state_b)
    candidates[[paste0(name, "_evidence")]] <- verdict
    conflict <- verdict == "conflicts"
    if (name %in% spec$block) {
      blocked[[name]] <- sum(conflict & keep)
      keep <- keep & !conflict
    } else {
      # An existing name veto keeps its reason; otherwise the attribute vetoes.
      veto <- conflict & candidates$evidence_class != "conflicting_name"
      candidates$evidence_class[veto] <- "conflicting_name"
      candidates$disposition[veto] <- "review"
      candidates$reason[veto] <- paste0(name, "_conflict")
    }
    candidates$attribute_rank <- candidates$attribute_rank + as.integer(verdict == "corroborates")
  }
  candidates <- candidates[keep, , drop = FALSE]
  rownames(candidates) <- NULL
  list(candidates = candidates, blocked = blocked)
}
