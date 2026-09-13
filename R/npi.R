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
  out <- vapply(seq_along(npi), function(i) {
    if (!isTRUE(ok[i])) return(FALSE)
    d <- as.integer(strsplit(paste0("80840", substr(npi[i], 1, 9)), "")[[1]])
    idx <- rev(seq_along(d)); dbl <- d; odd <- which(idx %% 2 == 1)
    dbl[odd] <- dbl[odd] * 2
    dbl[dbl > 9] <- dbl[dbl > 9] - 9
    (10 - (sum(dbl) %% 10)) %% 10 == as.integer(substr(npi[i], 10, 10))
  }, logical(1))
  # NA in, NA out -- the same contract name_key() documents. "No NPI
  # recorded" and "recorded NPI is invalid" are different findings; returning
  # FALSE for NA reads absence as evidence of invalidity.
  out[is.na(npi)] <- NA
  out
}
