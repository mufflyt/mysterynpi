# =============================================================================
# Searching NPPES: the registry's answers, and the questions it cannot answer
# =============================================================================

#' Parse an NPPES API response into one row per provider
#'
#' The pure half of [npi_search()], split out so it can be tested against a
#' stored fixture with no network anywhere near the test suite. Give it the
#' raw JSON text of an NPPES API v2.1 response and the date the response was
#' RETRIEVED, and it returns the fields a linkage wants, one row per provider.
#'
#' WHAT THE COLUMNS MEAN, AND WHAT IS MISSING ON PURPOSE:
#'
#' * `honorific`, `suffix`: NPPES `name_prefix` / `name_suffix`. The registry
#'   writes absence three ways -- a missing key, an empty string, and the
#'   literal sentinel `"--"` -- and all three become `NA` here, because a
#'   sentinel that survives into an agreement rule becomes a fake veto
#'   (`suffix_agreement("--", "JR")` must be reachable only as
#'   uninformative).
#' * `gender`: [normalize_gender()] applied to NPPES `sex`; the raw code is
#'   kept in `gender_code`.
#' * `zip`: the first five digits of the practice LOCATION address postal
#'   code (`zip_full` keeps all nine); `state` rides along because a license
#'   number without its state is not yet a license.
#' * `years_enumerated`: whole years between `enumeration_date` and
#'   `retrieved`. **This is not years in practice.** NPI enumeration began in
#'   mid-2005, so every career older than that is truncated to the same
#'   ceiling; treat it as a lower bound and say so in your methods.
#' * **There is no birth year.** NPPES does not publish one, and no column
#'   here pretends otherwise. A birth year must come from a licensure board
#'   or roster source, where [gender_agreement()]-style absence discipline
#'   applies: a source that lacks it decides nothing.
#' * `last_updated` and `retrieved` together are the vintage: what the
#'   registry claimed, and when you asked. Record both; a match found today
#'   against a row last updated in 2019 is a claim about 2019.
#'
#' @param txt character: the JSON text of an NPPES API v2.1 response
#'   (length-one string, or lines to be pasted together).
#' @param retrieved the [Date] the response was fetched. Explicit, never
#'   defaulted, so the parse of a stored response is reproducible.
#' @return data.frame with columns `npi`, `first`, `middle`, `last`,
#'   `suffix`, `honorific`, `credential`, `gender`, `gender_code`, `zip`,
#'   `zip_full`, `state`, `enumeration_date`, `years_enumerated`,
#'   `last_updated`, `retrieved`; zero rows when the search matched nothing.
#' @export
parse_npi_search <- function(txt, retrieved) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("parse_npi_search() requires the jsonlite package.\n",
         "  install.packages(\"jsonlite\")", call. = FALSE)
  }
  retrieved <- as.Date(retrieved)
  if (length(retrieved) != 1L || is.na(retrieved)) {
    stop("retrieved must be a single date", call. = FALSE)
  }
  res <- jsonlite::fromJSON(paste(txt, collapse = "\n"),
                            simplifyVector = FALSE)
  if (!is.null(res$Errors)) {
    stop("NPPES API error: ",
         paste(vapply(res$Errors, function(e) e$description %||% "unknown",
                      character(1)), collapse = "; "),
         call. = FALSE)
  }
  # absence is written three ways in NPPES; all of them are NA here
  fld <- function(l, k) {
    v <- l[[k]]
    if (is.null(v) || !nzchar(v) || identical(v, "--")) NA_character_
    else as.character(v)
  }
  rows <- lapply(res$results, function(r) {
    b <- r$basic
    loc <- NULL
    for (ad in r$addresses) {
      if (identical(ad$address_purpose, "LOCATION")) { loc <- ad; break }
    }
    if (is.null(loc) && length(r$addresses)) loc <- r$addresses[[1]]
    zip_full <- fld(loc, "postal_code")
    enum <- fld(b, "enumeration_date")
    yrs <- if (is.na(enum)) NA_integer_ else
      as.integer(floor(as.numeric(retrieved - as.Date(enum)) / 365.25))
    data.frame(
      npi = fld(r, "number"),
      first = fld(b, "first_name"),
      middle = fld(b, "middle_name"),
      last = fld(b, "last_name"),
      suffix = fld(b, "name_suffix"),
      honorific = fld(b, "name_prefix"),
      credential = fld(b, "credential"),
      gender = normalize_gender(fld(b, "sex")),
      gender_code = fld(b, "sex"),
      zip = if (is.na(zip_full)) NA_character_ else substr(zip_full, 1L, 5L),
      zip_full = zip_full,
      state = fld(loc, "state"),
      enumeration_date = enum,
      years_enumerated = yrs,
      last_updated = fld(b, "last_updated"),
      retrieved = as.character(retrieved),
      stringsAsFactors = FALSE)
  })
  out <- if (length(rows)) do.call(rbind, rows) else
    parse_npi_search('{"result_count":0,"results":[{}]}', retrieved)[0, ]
  rownames(out) <- NULL
  out
}

`%||%` <- function(a, b) if (is.null(a)) b else a

#' The licenses inside an NPPES response, one row per (NPI, license)
#'
#' NPPES's `taxonomies` array carries STATE LICENSE NUMBERS with their
#' issuing states -- after the NPI itself the strongest deterministic key a
#' candidate pair can share, and exactly the input [license_agreement()]
#' wants. This is the long companion to [parse_npi_search()]: same JSON
#' text in, one row per recorded (NPI, license) out, taxonomy entries
#' without a usable license dropped (a taxonomy code alone says what a
#' record is for, not which licenses its person holds).
#'
#' THE INTENDED USE closes the search-to-agreement loop: a roster license
#' is compared against EVERY row its candidate NPI carries here, and the
#' best verdict stands -- one `"corroborates"` outweighs any number of
#' `"uninformative"`, which is [license_agreement()]'s design (a quarter of
#' NPIs carry more than one license; disagreement between two of them is
#' two glimpses of one career).
#'
#' \preformatted{
#'   lic <- parse_npi_licenses(txt)
#'   v <- license_agreement(rep(roster_num, nrow(lic)),
#'                          rep(roster_state, nrow(lic)),
#'                          lic$license, lic$state)
#'   any(v == "corroborates")
#' }
#'
#' @param txt character: the JSON text of an NPPES API v2.1 response.
#' @return data.frame: `npi`, `state`, `license`, `taxonomy_code`,
#'   `taxonomy_desc`, `primary`; zero rows when no result carries one.
#'   NPPES's absence sentinels (missing, empty, `"--"`) are dropped rows
#'   here, never `NA` rows -- a licenseless taxonomy is not a license.
#' @export
parse_npi_licenses <- function(txt) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("parse_npi_licenses() requires the jsonlite package.", call. = FALSE)
  }
  res <- jsonlite::fromJSON(paste(txt, collapse = "\n"),
                            simplifyVector = FALSE)
  if (!is.null(res$Errors)) {
    stop("NPPES API error: ",
         paste(vapply(res$Errors, function(e) e$description %||% "unknown",
                      character(1)), collapse = "; "),
         call. = FALSE)
  }
  fld <- function(l, k) {
    v <- l[[k]]
    if (is.null(v) || !nzchar(v) || identical(v, "--")) NA_character_
    else as.character(v)
  }
  rows <- list()
  for (r in res$results) {
    npi <- fld(r, "number")
    for (tx in r$taxonomies) {
      lic <- fld(tx, "license")
      st  <- fld(tx, "state")
      if (is.na(lic)) next
      rows[[length(rows) + 1L]] <- data.frame(
        npi = npi, state = st, license = lic,
        taxonomy_code = fld(tx, "code"), taxonomy_desc = fld(tx, "desc"),
        primary = isTRUE(tx$primary), stringsAsFactors = FALSE)
    }
  }
  out <- if (length(rows)) do.call(rbind, rows) else
    data.frame(npi = character(0), state = character(0),
               license = character(0), taxonomy_code = character(0),
               taxonomy_desc = character(0), primary = logical(0),
               stringsAsFactors = FALSE)
  rownames(out) <- NULL
  out
}

#' Search the NPPES registry for providers
#'
#' A thin fetch over [parse_npi_search()], which documents every column and
#' every deliberate absence (no birth year -- NPPES does not publish one;
#' `years_enumerated` is a lower bound on years in practice, truncated at
#' the 2005 start of enumeration).
#'
#' This function performs a NETWORK call to the public NPPES API
#' (`npiregistry.cms.hhs.gov`) and belongs in interactive exploration and
#' pipeline candidate generation -- never inside a test suite, which is why
#' the parser is a separate, fixture-testable function.
#'
#' @param first_name,last_name,state,postal_code,npi search criteria; any may
#'   be omitted, but the API requires something. NPPES treats `first_name`
#'   and `last_name` as case-insensitive and supports a trailing `*`
#'   wildcard on names of two or more characters.
#' @param limit maximum results, 1 to 200.
#' @param licenses when `TRUE`, one fetch returns BOTH frames as
#'   `list(providers, licenses)` -- the licenses via
#'   [parse_npi_licenses()], ready for [license_agreement()]. Default
#'   `FALSE` keeps the plain provider frame.
#' @return see [parse_npi_search()]; with `licenses = TRUE`, a list of two
#'   data.frames, `providers` and `licenses`.
#' @export
npi_search <- function(first_name = NULL, last_name = NULL, state = NULL,
                       postal_code = NULL, npi = NULL, limit = 10L,
                       licenses = FALSE) {
  limit <- as.integer(limit)
  if (is.na(limit) || limit < 1L || limit > 200L) {
    stop("limit must be between 1 and 200", call. = FALSE)
  }
  params <- c(version = "2.1", limit = limit,
              first_name = first_name, last_name = last_name,
              state = state, postal_code = postal_code, number = npi)
  if (length(params) == 2L) {
    stop("give at least one search criterion", call. = FALSE)
  }
  q <- paste(names(params),
             vapply(params, utils::URLencode, character(1), reserved = TRUE),
             sep = "=", collapse = "&")
  u <- paste0("https://npiregistry.cms.hhs.gov/api/?", q)
  con <- url(u)
  on.exit(try(close(con), silent = TRUE))
  txt <- readLines(con, warn = FALSE)
  providers <- parse_npi_search(txt, retrieved = Sys.Date())
  if (!isTRUE(licenses)) return(providers)
  list(providers = providers, licenses = parse_npi_licenses(txt))
}
