#' Is this a structurally valid NPI?
#'
#' Ten digits beginning with 1 or 2, with a Luhn check over the `80840`
#' prefix. Cheap, and it catches the truncated, shifted and concatenated
#' identifiers that otherwise join to nothing and look like a matching
#' failure.
#'
#' THE LEADING DIGIT IS PART OF THE FORMAT. CMS has only ever issued NPIs
#' beginning with 1 (and reserves 2); roughly one in ten arbitrary 10-digit
#' strings passes the Luhn checksum by chance, so the checksum alone is a
#' weak gate. Measured on a real linkage (39 state Medicaid exclusion
#' datasets, 2026-09-13): of 9 checksum-passing candidates that turned out
#' not to exist in NPPES, 7 began with 0 or 3 -- state provider numbers that
#' happened to satisfy the checksum. The leading-digit rule rejects those
#' without any registry lookup.
#'
#' `NA` in, `NA` out -- the same contract [name_key()] documents. A missing
#' NPI is not an invalid NPI: "the source recorded nothing" and "the source
#' recorded a broken identifier" are different findings, and a `FALSE` for
#' `NA` silently converts absence into evidence of invalidity.
#'
#' @param npi character vector.
#' @return logical vector; `NA` where `npi` is `NA`.
#' @export
npi_luhn_ok <- function(npi) {
  npi <- as.character(npi)
  ok <- grepl("^[12][0-9]{9}$", npi)
  out <- rep(FALSE, length(npi))
  if (any(ok)) {
    v <- npi[ok]
    # "80840" + the first 9 digits is a FIXED 14-character string, so the
    # Luhn positions to double are the fixed even columns -- which is what
    # lets the whole computation run as one digit matrix instead of a
    # per-element strsplit loop (measured ~4x faster: 1M NPIs in ~4.3s vs
    # ~17s; NPPES holds 8.27M NPIs).
    base <- paste0("80840", substr(v, 1, 9))
    digs <- vapply(1:14, function(j) as.integer(substr(base, j, j)),
                   integer(length(v)))
    dim(digs) <- c(length(v), 14L)
    even <- seq(2L, 14L, by = 2L)
    digs[, even] <- digs[, even] * 2L
    digs[digs > 9L] <- digs[digs > 9L] - 9L
    check <- (10L - (as.integer(rowSums(digs)) %% 10L)) %% 10L
    out[ok] <- check == as.integer(substr(v, 10, 10))
  }
  # NA in, NA out -- the same contract name_key() documents. "No NPI
  # recorded" and "recorded NPI is invalid" are different findings; returning
  # FALSE for NA reads absence as evidence of invalidity.
  out[is.na(npi)] <- NA
  out
}
