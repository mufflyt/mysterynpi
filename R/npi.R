#' Is this a structurally valid NPI?
#'
#' Ten digits with a Luhn check over the `80840` prefix. Cheap, and it catches
#' the truncated, shifted and concatenated identifiers that otherwise join to
#' nothing and look like a matching failure.
#'
#' @param npi character vector.
#' @return logical vector.
#' @export
npi_luhn_ok <- function(npi) {
  ok <- grepl("^[0-9]{10}$", npi)
  if (!any(ok, na.rm = TRUE)) return(ok & FALSE)
  vapply(seq_along(npi), function(i) {
    if (!isTRUE(ok[i])) return(FALSE)
    d <- as.integer(strsplit(paste0("80840", substr(npi[i], 1, 9)), "")[[1]])
    idx <- rev(seq_along(d)); dbl <- d; odd <- which(idx %% 2 == 1)
    dbl[odd] <- dbl[odd] * 2
    dbl[dbl > 9] <- dbl[dbl > 9] - 9
    (10 - (sum(dbl) %% 10)) %% 10 == as.integer(substr(npi[i], 10, 10))
  }, logical(1))
}
