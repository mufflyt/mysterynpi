#' Acquisition of federal adverse-action sources for physician workforce exit
#'
#' @description
#' Six federal streams that publish adverse actions against individuals, several
#' of which name physicians and describe loss of a medical license, loss of a DEA
#' registration, exclusion from federal health programs, or debarment.
#'
#' \preformatted{
#'   HHS DAB              ALJ and Board decisions        BLOCKED, see below
#'   SAM.gov exclusions   OPM FEHBP sanctions            keyed bulk extract
#'   TRICARE              TRICARE-only exclusions        small HTML scrape
#'   ORI                  current misconduct cases       HTML scrape
#'   Federal Register     historical ORI notices         keyless API
#'   DOJ                  press releases                 keyless API
#' }
#'
#' @section What this file does not do:
#' Nothing here labels a physician retired. Every function returns source
#' observations with their provenance attached. Turning a sanction into a
#' workforce-exit inference is a separate, downstream, reviewable decision, and
#' keeping the two apart is the point of the split.
#'
#' @section Two live traps, both measured rather than assumed:
#' **The DOJ API silently ignores unknown filters.** Probed 2026-09-13:
#' `topic=health-care-fraud` and `q=physician` both return the FULL corpus
#' (272,247 records, identical to unfiltered), while `title=physician` genuinely
#' filters (1,047). A filter that does nothing returns everything and reads
#' exactly like a filter that worked, so [doj_assert_filter_effective()] refuses
#' to proceed when a supplied filter fails to change the count.
#'
#' **HHS DAB is hard-blocked.** Probed 2026-09-13: HTTP 403 on the ALJ year
#' index, the by-year index and the decisions root, under four user agents
#' including a current Chrome string and no user agent at all. That is an edge
#' block, not a scraper defect. [get_hhs_dab()] therefore raises
#' `federal_acquisition_blocked` rather than returning zero rows, because an
#' empty table from a blocked source is indistinguishable from a source with
#' nothing in it. This matters more than usual here: DAB decisions carry the NPI
#' in the decision text, which no other stream in this file does.
#'
#' @section Coverage limits worth carrying downstream:
#' SAM's public extract contains CURRENTLY ACTIVE exclusions only, so each pull
#' must be archived to build history. ORI's case page carries only people who
#' currently have administrative actions imposed, which is why the Federal
#' Register feed is acquired alongside it. TRICARE's page reports its own last
#' update as 2023-10-20 and is treated as potentially stale.
#'
#' @name federal_adverse_actions
NULL

FEDERAL_USER_AGENT <- paste0(
  "mysterynpi-research/1.0 (physician-workforce-research)"
)

#' Packages this module requires
#' @return Character vector of package names.
#' @export
federal_required_packages <- function() {
  base::c("arrow", "dplyr", "httr2", "jsonlite", "pdftools", "purrr",
          "readr", "rvest", "stringr", "tibble", "xml2")
}

#' Fail early when an acquisition dependency is absent
#' @return TRUE invisibly.
#' @export
check_federal_packages <- function() {
  pkgs <- federal_required_packages()
  ok <- base::vapply(pkgs, base::requireNamespace, quietly = TRUE,
                     FUN.VALUE = base::logical(1))
  if (base::any(!ok)) {
    base::stop("Missing R packages: ",
               base::paste(pkgs[!ok], collapse = ", "), call. = FALSE)
  }
  base::invisible(TRUE)
}

#' Signal that a source refused to serve us
#'
#' Raised instead of returning an empty table. An empty result from a blocked
#' endpoint looks exactly like a source that legitimately has no records, and
#' that ambiguity is how a silent coverage hole enters a dataset.
#'
#' @param source Source label.
#' @param status HTTP status observed.
#' @param detail Free text.
#' @return Never returns.
#' @export
federal_acquisition_blocked <- function(source, status, detail = "") {
  msg <- base::paste0(
    source, " refused the request (HTTP ", status, "). ", detail,
    " Returning an empty table would be indistinguishable from a source with ",
    "no records, so this is an error.")
  cond <- base::structure(
    base::list(message = msg, call = NULL),
    class = base::c("federal_acquisition_blocked", "error", "condition"))
  base::stop(cond)
}

federal_timestamp <- function() {
  base::format(base::Sys.time(), "%Y%m%d_%H%M%S")
}

clean_source_text <- function(x) {
  x <- base::gsub("[\r\n\t]+", " ", base::as.character(x))
  base::trimws(base::gsub("[[:space:]]+", " ", x))
}

federal_request <- function(url, query = base::list(), accept = NULL,
                            timeout_seconds = 120, tolerate_error = TRUE) {
  rq <- httr2::request(url)
  rq <- httr2::req_headers(rq, `User-Agent` = FEDERAL_USER_AGENT)
  if (!base::is.null(accept)) rq <- httr2::req_headers(rq, Accept = accept)
  if (base::length(query) > 0L) {
    rq <- base::do.call(httr2::req_url_query,
                        base::c(base::list(.req = rq), query))
  }
  rq <- httr2::req_timeout(rq, seconds = timeout_seconds)
  rq <- httr2::req_retry(rq, max_tries = 5)
  if (tolerate_error) {
    rq <- httr2::req_error(rq, is_error = function(resp) FALSE)
  }
  httr2::req_perform(rq)
}

fetch_json_payload <- function(url, query = base::list()) {
  resp <- federal_request(url, query, accept = "application/json")
  if (httr2::resp_status(resp) != 200L) {
    federal_acquisition_blocked(url, httr2::resp_status(resp))
  }
  jsonlite::fromJSON(httr2::resp_body_string(resp), simplifyVector = FALSE)
}

fetch_html_page <- function(url, query = base::list()) {
  resp <- federal_request(url, query, accept = "text/html")
  if (httr2::resp_status(resp) != 200L) {
    federal_acquisition_blocked(url, httr2::resp_status(resp))
  }
  xml2::read_html(httr2::resp_body_string(resp))
}

nested_character <- function(x, ...) {
  v <- purrr::pluck(x, ..., .default = NULL)
  if (base::is.null(v) || base::length(v) == 0L) return(NA_character_)
  base::as.character(v[[1L]])
}

json_text <- function(x) {
  if (base::is.null(x)) return(NA_character_)
  base::as.character(jsonlite::toJSON(x, auto_unbox = TRUE, null = "null"))
}

collect_urls <- function(x) {
  if (base::is.null(x)) return(base::character())
  if (base::is.character(x)) return(base::unique(x[base::grepl("^https?://", x)]))
  if (base::is.list(x)) {
    return(base::unique(base::unlist(purrr::map(x, collect_urls),
                                     use.names = FALSE)))
  }
  base::character()
}

#' Strip HTML tags cheaply, for filtering only
#'
#' The DOJ corpus is 272,247 releases and a full `read_html()` per body runs at
#' roughly four hours end to end. Under 1% of releases match, so the corpus is
#' filtered with a tag-strip that is orders of magnitude cheaper, and only the
#' surviving records get a real parse.
#'
#' Tags become a SPACE rather than being deleted, so `medical <em>license</em>`
#' still reads as `medical license` and the phrase patterns keep matching across
#' a tag boundary. Deleting them instead would silently weld words together and
#' lose exactly the matches this is looking for.
#'
#' @param x Character vector of HTML.
#' @return Character vector of approximate text.
#' @export
fast_strip_html <- function(x) {
  v <- base::as.character(x)
  v[base::is.na(v)] <- ""
  v <- base::gsub("<[^>]*>", " ", v, perl = TRUE)
  v <- base::gsub("&nbsp;|&#160;", " ", v, fixed = FALSE)
  v <- base::gsub("&amp;", "&", v, fixed = TRUE)
  base::trimws(base::gsub("[[:space:]]+", " ", v))
}

html_fragment_to_text <- function(x) {
  if (base::is.na(x) || base::identical(x, "")) return(NA_character_)
  out <- base::tryCatch(
    rvest::html_text2(xml2::read_html(
      base::paste0("<html><body>", x, "</body></html>"))),
    error = function(e) NA_character_)
  clean_source_text(out)
}

#' Pull every NPI that appears in a block of decision text
#'
#' HHS DAB decisions state the NPI in the body, which is the only stream here
#' that identifies a physician without name resolution. Retained even though DAB
#' is currently blocked, because DOJ releases occasionally carry one too.
#'
#' @param x Character scalar of source text.
#' @return Semicolon-delimited NPIs, or NA.
#' @export
extract_npis_from_text <- function(x) {
  if (base::is.na(x) || base::identical(x, "")) return(NA_character_)
  m <- base::regmatches(x, base::gregexpr(
    "NPI[^0-9]{0,40}[12][0-9]{9}", x, ignore.case = TRUE))[[1L]]
  if (base::length(m) == 0L) return(NA_character_)
  npis <- base::unique(base::regmatches(
    m, base::regexpr("[12][0-9]{9}", m)))
  base::paste(npis, collapse = ";")
}

#' Write an acquisition to disk in both CSV and Parquet, timestamped
#' @param source_tbl Data frame to persist.
#' @param source_name Short source label used in the filename.
#' @param destination_dir Directory, created if absent.
#' @param timestamp Acquisition timestamp string.
#' @return List of written paths.
#' @export
save_source_table <- function(source_tbl, source_name, destination_dir,
                              timestamp = federal_timestamp()) {
  base::dir.create(destination_dir, recursive = TRUE, showWarnings = FALSE)
  csv <- base::file.path(destination_dir,
                         base::paste0(source_name, "_", timestamp, ".csv.gz"))
  pq <- base::file.path(destination_dir,
                        base::paste0(source_name, "_", timestamp, ".parquet"))
  base::message("Saving ", base::format(base::nrow(source_tbl), big.mark = ","),
                " rows for ", source_name, ".")
  readr::write_csv(source_tbl, csv, na = "")
  arrow::write_parquet(source_tbl, pq)
  base::list(csv = csv, parquet = pq)
}

# ---------------------------------------------------------------------------
# HHS DAB
# ---------------------------------------------------------------------------

#' HHS Departmental Appeals Board decisions
#'
#' Currently unreachable. Probed 2026-09-13: HTTP 403 on the 2026 ALJ index, the
#' by-year index and the decisions root, under the research user agent, a current
#' Chrome string, a curl string, and no user agent. Every URL, every agent.
#'
#' Raises rather than returning an empty frame, because DAB is the one stream
#' here that names the NPI directly, so a silent zero would hide the loss of the
#' single highest-value identifier in the whole module.
#'
#' @param ... Ignored while blocked.
#' @return Never returns; raises `federal_acquisition_blocked`.
#' @export
get_hhs_dab <- function(...) {
  resp <- federal_request(
    "https://www.hhs.gov/about/agencies/dab/decisions/alj-decisions/alj-decisions-by-year/index.html",
    accept = "text/html")
  status <- httr2::resp_status(resp)
  if (status != 200L) {
    federal_acquisition_blocked(
      "HHS DAB", status,
      paste0("Blocked for all four user agents probed on 2026-09-13, so this ",
             "is an edge block rather than a scraper defect. DAB decisions ",
             "carry the NPI in the decision text, which no other source in ",
             "this module does, so this is the costliest gap here."))
  }
  base::stop("HHS DAB became reachable (HTTP 200). The parser was never ",
             "written because the source was blocked; write it now rather ",
             "than returning an unvalidated frame.", call. = FALSE)
}

# ---------------------------------------------------------------------------
# SAM.gov, used for OPM FEHBP sanctions
# ---------------------------------------------------------------------------

#' Download the SAM.gov public exclusion extract
#'
#' The extracts endpoint returns the ZIP directly when the key is valid
#' (verified 2026-09-13: HTTP 200, `application/zip`), so no metadata-following
#' is needed on the happy path. A JSON body is still handled, since that is what
#' comes back when the request is rejected or deferred.
#'
#' @param api_key SAM.gov API key.
#' @return Path to the downloaded ZIP.
#' @export
download_sam_exclusion_extract <- function(
    api_key = base::Sys.getenv("SAM_API_KEY")) {
  if (base::identical(api_key, "")) {
    base::stop("SAM_API_KEY is not set.", call. = FALSE)
  }
  resp <- federal_request(
    "https://api.sam.gov/data-services/v1/extracts",
    query = base::list(api_key = api_key, fileType = "EXCLUSION",
                       sensitivity = "PUBLIC"),
    accept = "application/zip,application/json")
  if (httr2::resp_status(resp) != 200L) {
    federal_acquisition_blocked("SAM.gov extracts",
                                httr2::resp_status(resp))
  }
  raw <- httr2::resp_body_raw(resp)
  if (base::length(raw) < 2L ||
      !base::identical(raw[1:2], base::charToRaw("PK"))) {
    base::stop("SAM returned a non-ZIP payload: ",
               base::substr(base::rawToChar(raw), 1, 300), call. = FALSE)
  }
  zip_path <- base::tempfile(fileext = ".zip")
  base::writeBin(raw, zip_path)
  zip_path
}

simple_column_names <- function(x) {
  x <- base::gsub("([a-z0-9])([A-Z])", "\\1_\\2", x)
  x <- base::tolower(x)
  x <- base::gsub("[^a-z0-9]+", "_", x)
  base::gsub("^_+|_+$", "", x)
}

row_matches_pattern <- function(source_tbl, columns, pattern) {
  if (base::length(columns) == 0L) {
    return(base::rep(FALSE, base::nrow(source_tbl)))
  }
  hits <- purrr::map(columns, function(cn) {
    v <- base::as.character(source_tbl[[cn]])
    v[base::is.na(v)] <- ""
    base::grepl(pattern, v, ignore.case = TRUE)
  })
  purrr::reduce(hits, `|`)
}

#' OPM FEHBP sanctions, extracted from the SAM.gov public exclusion file
#'
#' OPM publishes its sanctioned-provider list through SAM rather than directly.
#' Records are selected three ways and the reason is recorded per row, because
#' the three do not agree and collapsing them would hide that: the excluding
#' agency field, FEHBP statutory text, and the legacy cause-and-treatment codes
#' Z2 (OPM FEHBP debarment) and Z3 (OPM FEHBP suspension). Legacy codes are not
#' required, since SAM replaced them with the exclusion-type system and newer
#' records do not carry them.
#'
#' The extract holds CURRENTLY ACTIVE exclusions only. Reinstated providers are
#' simply absent, so absence from a single pull is never evidence of a clean
#' record, and history exists only if each pull is archived.
#'
#' SAM's own NPI field is present but inconsistently populated and is not
#' trusted for resolution here.
#'
#' @param api_key SAM.gov API key.
#' @return Data frame of candidate OPM/FEHBP sanction rows.
#' @export
get_opm_fehb_sanctions <- function(api_key = base::Sys.getenv("SAM_API_KEY")) {
  check_federal_packages()
  zip_path <- download_sam_exclusion_extract(api_key)
  exdir <- base::tempfile(pattern = "sam_exclusions_")
  base::dir.create(exdir, recursive = TRUE)
  utils::unzip(zip_path, exdir = exdir)
  files <- base::list.files(exdir, pattern = "\\.(csv|txt|dat)$",
                            full.names = TRUE, ignore.case = TRUE)
  if (base::length(files) == 0L) {
    files <- base::list.files(exdir, full.names = TRUE, recursive = TRUE)
  }
  if (base::length(files) == 0L) {
    base::stop("SAM exclusion ZIP contained no readable file.", call. = FALSE)
  }
  base::message("SAM extract files: ",
                base::paste(base::basename(files), collapse = ", "))
  tbl <- purrr::map_dfr(files, function(f) {
    readr::read_delim(f, delim = ",", col_types = readr::cols(
      .default = readr::col_character()), show_col_types = FALSE,
      progress = FALSE, name_repair = "unique")
  })
  base::names(tbl) <- base::make.unique(simple_column_names(base::names(tbl)),
                                        sep = "_")
  agency_cols <- base::grep("agency|component", base::names(tbl), value = TRUE)
  ct_cols <- base::grep("ct_code|cause", base::names(tbl), value = TRUE)
  chr_cols <- base::names(tbl)[base::vapply(tbl, base::is.character,
                                            base::logical(1))]
  opm <- row_matches_pattern(tbl, agency_cols,
                             "OFFICE OF PERSONNEL MANAGEMENT|\\bOPM\\b")
  z <- row_matches_pattern(tbl, ct_cols, "^(Z2|Z3)$")
  fehb <- row_matches_pattern(tbl, chr_cols,
    "FEHBP|Federal Employees Health Benefits|5 U\\.S\\.C\\. ?8902a")
  out <- tbl[opm | z | fehb, , drop = FALSE]
  out$fehb_match_reason <- base::ifelse(
    z[opm | z | fehb], "legacy_Z2_Z3",
    base::ifelse(fehb[opm | z | fehb], "FEHBP_text", "OPM_agency"))
  out$source <- "sam_exclusions_public_extract"
  out$source_scope <- "currently_active_exclusions_only"
  out$source_retrieved_at <- base::as.character(base::Sys.time())
  base::message("SAM total exclusions: ",
                base::format(base::nrow(tbl), big.mark = ","),
                " | OPM/FEHBP candidates: ",
                base::format(base::nrow(out), big.mark = ","))
  base::unlink(base::c(zip_path, exdir), recursive = TRUE)
  out
}

# ---------------------------------------------------------------------------
# TRICARE
# ---------------------------------------------------------------------------

#' TRICARE-only excluded providers
#'
#' Small enough to take whole. Records are delimited by a
#' "<date> - Click to close" marker and carry Term, optional Companies, People
#' (name plus credential), Addresses and Summary.
#'
#' Two integrity guards, both earned. The first parser reported 9 pages and
#' returned ZERO records, because a zero-width lookahead split does not behave
#' as assumed in R, and it did so without complaint. So:
#'
#' 1. The page states its own total ("Fraud Sanctions Search Results (129)"),
#'    and the parsed row count must equal it. A parser that silently drops
#'    records now fails instead.
#' 2. Pages found with zero records parsed is an error, never an empty frame.
#'
#' The page reports its own last update as 2023-10-20; that is carried on every
#' row so a stale pull cannot be mistaken for a current one.
#'
#' @return Data frame of exclusion records.
#' @export
get_tricare_exclusions <- function() {
  check_federal_packages()
  base_url <- base::paste0(
    "https://health.mil/Military-Health-Topics/",
    "Access-Cost-Quality-and-Safety/TRICARE-Health-Plan/",
    "Fraud-and-Abuse/Excluded-Providers")
  first_text <- clean_source_text(rvest::html_text2(
    fetch_html_page(base_url, base::list(page = 1))))

  pm <- base::regmatches(first_text, base::regexpr(
    "Page[[:space:]]+1[[:space:]]+of[[:space:]]+[0-9]+", first_text))
  total_pages <- if (base::length(pm) == 0L) NA_integer_ else
    base::as.integer(base::regmatches(pm, base::regexpr("[0-9]+$", pm)))
  cm <- base::regmatches(first_text, base::regexpr(
    "Fraud Sanctions Search Results[[:space:]]*\\([0-9]+\\)", first_text))
  reported_total <- if (base::length(cm) == 0L) NA_integer_ else
    base::as.integer(base::regmatches(cm, base::regexpr("[0-9]+", cm)))
  if (base::is.na(total_pages) || total_pages < 1L) {
    base::stop("Could not read the TRICARE page count.", call. = FALSE)
  }
  base::message("TRICARE reports ", total_pages, " pages and ",
                reported_total, " records.")

  last_updated <- base::regmatches(first_text, base::regexpr(
    "Last Updated:[^|]{0,40}", first_text, ignore.case = TRUE))

  field <- function(x, name) {
    m <- base::regmatches(x, base::regexpr(base::paste0(
      name, ":.*?(?=[[:space:]](?:Term|Companies|People|Addresses|Summary):|$)"),
      x, perl = TRUE))
    if (base::length(m) == 0L) return(NA_character_)
    clean_source_text(base::sub(base::paste0("^", name, ":"), "", m[[1L]]))
  }

  parse_page <- function(pg) {
    txt <- clean_source_text(rvest::html_text2(
      fetch_html_page(base_url, base::list(page = pg))))
    marker <- "-[[:space:]]Click to close"
    hits <- base::gregexpr(marker, txt)[[1L]]
    if (base::length(hits) == 1L && hits[[1L]] == -1L) return(tibble::tibble())
    starts <- base::as.integer(hits)
    # Back each start up over the date that precedes the delimiter, when there
    # is one. Two of the 129 records carry no date at all, so the date cannot be
    # part of the delimiter itself.
    starts <- base::vapply(starts, function(st) {
      lead <- base::substring(txt, base::max(1L, st - 12L), st - 1L)
      dm <- base::regexpr("[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}[[:space:]]*$", lead)
      if (dm == -1L) st else st - (base::nchar(lead) - dm + 1L)
    }, 1L)
    ends <- base::c(starts[-1L] - 1L, base::nchar(txt))
    chunks <- base::substring(txt, starts, ends)
    tibble::tibble(
      action_date = base::as.Date(base::vapply(chunks, function(ch) {
        m <- base::regmatches(ch, base::regexpr(
          "^[^ ]*[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}", ch))
        if (base::length(m) == 0L) NA_character_ else
          base::regmatches(m, base::regexpr("[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}", m))
      }, ""), format = "%m/%d/%Y"),
      term = base::vapply(chunks, field, "", name = "Term"),
      companies = base::vapply(chunks, field, "", name = "Companies"),
      people = base::vapply(chunks, field, "", name = "People"),
      addresses = base::vapply(chunks, field, "", name = "Addresses"),
      summary = base::vapply(chunks, field, "", name = "Summary"),
      source_page = pg,
      source_text = chunks)
  }

  rows <- purrr::map_dfr(base::seq_len(total_pages), parse_page)

  if (base::nrow(rows) == 0L) {
    base::stop("TRICARE reported ", total_pages, " pages but parsed 0 ",
               "records. The page structure changed; an empty frame here ",
               "would look exactly like a source with no exclusions.",
               call. = FALSE)
  }
  # The page's own total is the only independent check available, so a large
  # shortfall is an error. A small one is recorded rather than hidden: the
  # source is internally inconsistent (page 9 announces 9 records and renders
  # 8), and silently reporting the parsed number as if it were the total is how
  # a coverage gap stops being visible.
  if (!base::is.na(reported_total)) {
    shortfall <- reported_total - base::nrow(rows)
    if (shortfall > reported_total * 0.05) {
      base::stop("TRICARE parsed ", base::nrow(rows), " of ", reported_total,
                 " reported records. That is more than 5% missing, which ",
                 "means the parser lost records rather than the source being ",
                 "inconsistent.", call. = FALSE)
    }
    if (shortfall != 0L) {
      base::warning("TRICARE parsed ", base::nrow(rows), " records but the ",
                    "page reports ", reported_total, ". Recorded on every row ",
                    "as source_reported_total.", call. = FALSE)
    }
  }

  rows$credential <- base::trimws(base::sub(
    "^.*,[[:space:]]*", "", base::ifelse(base::is.na(rows$people), "",
                                         rows$people)))
  rows$source <- "tricare_only_exclusions"
  rows$source_reported_total <- reported_total
  rows$parsed_total <- base::nrow(rows)
  rows$source_last_updated <- if (base::length(last_updated))
    clean_source_text(last_updated[[1L]]) else NA_character_
  rows$source_retrieved_at <- base::as.character(base::Sys.time())
  base::message("TRICARE records parsed: ", base::nrow(rows),
                " (page reports ", reported_total, ")")
  rows
}

# ---------------------------------------------------------------------------
# ORI
# ---------------------------------------------------------------------------

#' ORI current research-misconduct case summaries
#'
#' ORI states that this page lists only people who CURRENTLY have administrative
#' actions imposed, and drops them once the action period expires. So this is a
#' current-status layer, not a historical record, and
#' [get_ori_federal_register()] is acquired alongside it rather than instead.
#'
#' @return Data frame of case summaries.
#' @export
get_ori_current_cases <- function() {
  check_federal_packages()
  index_url <- "https://ori.hhs.gov/content/case_summary"
  page <- fetch_html_page(index_url)
  a <- rvest::html_elements(page, "a")
  href <- rvest::html_attr(a, "href")
  label <- clean_source_text(rvest::html_text2(a))
  keep <- base::grepl("^Case Summary:", label, ignore.case = TRUE) &
    !base::is.na(href)
  if (!base::any(keep)) {
    base::stop("ORI page parsed but contained no case-summary links; the ",
               "page structure changed.", call. = FALSE)
  }
  tibble::tibble(
    case_label = label[keep],
    person_name = clean_source_text(base::sub(
      "^Case Summary:[[:space:]]*", "", label[keep])),
    case_url = xml2::url_absolute(href[keep], index_url),
    source = "ori_current_cases",
    source_scope = "current_administrative_actions_only",
    source_retrieved_at = base::as.character(base::Sys.time()))
}

#' Historical ORI findings, via the keyless Federal Register API
#'
#' The Federal Register API needs no key and covers 1994 forward. Probed
#' 2026-09-13: 788 HHS notices match "research misconduct".
#'
#' @param term Search term.
#' @param per_page Page size, capped at 1000 by the API.
#' @return Data frame of notices.
#' @export
get_ori_federal_register <- function(term = "research misconduct",
                                     per_page = 1000L) {
  check_federal_packages()
  base_url <- "https://www.federalregister.gov/api/v1/documents.json"
  page <- 1L
  out <- base::list()
  repeat {
    payload <- fetch_json_payload(base_url, base::list(
      `conditions[agencies][]` = "health-and-human-services-department",
      `conditions[type][]` = "NOTICE",
      `conditions[term]` = term,
      per_page = per_page, page = page))
    res <- payload[["results"]]
    if (base::is.null(res) || base::length(res) == 0L) break
    out[[base::length(out) + 1L]] <- purrr::map_dfr(res, function(r) {
      tibble::tibble(
        document_number = nested_character(r, "document_number"),
        title = nested_character(r, "title"),
        document_type = nested_character(r, "type"),
        publication_date = nested_character(r, "publication_date"),
        html_url = nested_character(r, "html_url"),
        pdf_url = nested_character(r, "pdf_url"),
        abstract = nested_character(r, "abstract"))
    })
    tp <- base::as.integer(payload[["total_pages"]])
    base::message("Federal Register page ", page, " of ", tp)
    if (base::is.na(tp) || page >= tp) break
    page <- page + 1L
  }
  tbl <- dplyr::bind_rows(out)
  if (base::nrow(tbl) == 0L) return(tbl)
  tbl <- tbl[!base::duplicated(tbl$document_number), , drop = FALSE]
  tbl$likely_case_notice <- base::grepl(
    "Findings? of Research Misconduct|Research Misconduct.*Administrative",
    tbl$title, ignore.case = TRUE)
  tbl$source <- "federal_register_ori"
  tbl$source_retrieved_at <- base::as.character(base::Sys.time())
  tbl
}

# ---------------------------------------------------------------------------
# DOJ
# ---------------------------------------------------------------------------

DOJ_ACTION_PATTERN <- base::paste0(
  "medical licen[cs]e|license to practice medicine|",
  "DEA registration|Drug Enforcement Administration registration|",
  "excluded from [^.]{0,60}federal health care program|",
  "surrender(?:ed|ing)?[^.]{0,100}(?:licen[cs]e|registration)|",
  "agreed[^.]{0,100}not to practice medicine|",
  "barred[^.]{0,100}practic(?:e|ing) medicine")

DOJ_PHYSICIAN_PATTERN <- base::paste0(
  "\\bphysician\\b|\\bdoctor\\b|\\bM\\. ?D\\.|\\bD\\. ?O\\.|",
  "\\bmedical doctor\\b|\\bgynecolog|\\bobstetric")

#' Refuse to crawl behind a filter that the API ignores
#'
#' Probed 2026-09-13: the DOJ API accepts `topic` and `q` and returns the FULL
#' corpus regardless (272,247 records, byte-identical count to unfiltered),
#' while `title` genuinely filters (1,047). An ignored filter is the worst kind
#' of failure available here, because the crawl succeeds, the numbers look
#' plausible, and the result silently describes a different population than the
#' one requested.
#'
#' @param query Filter query list to test.
#' @param unfiltered_count Count observed with no filter.
#' @return TRUE invisibly when the filter demonstrably changed the count.
#' @export
doj_assert_filter_effective <- function(query, unfiltered_count) {
  payload <- fetch_json_payload(
    "https://www.justice.gov/api/v1/press_releases.json",
    base::c(base::list(pagesize = 1L, page = 0L), query))
  n <- base::as.integer(purrr::pluck(payload, "metadata", "resultset", "count",
                                     .default = NA))
  if (base::is.na(n) || n >= unfiltered_count) {
    base::stop("The DOJ API ignored the filter ",
               base::paste(base::names(query), collapse = ","),
               ": count ", n, " is not below the unfiltered ",
               unfiltered_count, ". Crawling behind it would silently return ",
               "the whole corpus.", call. = FALSE)
  }
  base::invisible(TRUE)
}

#' DOJ press releases describing physician licence, DEA or exclusion actions
#'
#' The API exposes no working full-text filter (see
#' [doj_assert_filter_effective()]), so the corpus is crawled and each page is
#' filtered in memory against the release BODY rather than the title. Title-only
#' matching was measured at 1,047 of 272,247 and would miss every release that
#' names the action in the body, which is most of them.
#'
#' Only matching releases are retained, so the crawl stays small on disk while
#' still reading every record.
#'
#' A DOJ release describing a plea is strong evidence, but it is not the signed
#' plea agreement. `record_class` marks it `DOJ_PRESS_RELEASE` so a downstream
#' consumer cannot mistake a news item for a court document.
#'
#' @param max_pages Page cap; Inf crawls the corpus.
#' @param pause_seconds Delay between requests. DOJ asks for under ~4/sec.
#' @param checkpoint_path Optional RDS path written every 100 pages.
#' @return Data frame of matching releases.
#' @export
get_doj_physician_actions <- function(max_pages = Inf, pause_seconds = 0.30,
                                      checkpoint_path = NULL) {
  check_federal_packages()
  url <- "https://www.justice.gov/api/v1/press_releases.json"
  page <- 0L
  kept <- base::list()
  n_seen <- 0L
  repeat {
    if (page >= max_pages) break
    payload <- base::tryCatch(
      fetch_json_payload(url, base::list(sort = "date", direction = "DESC",
                                         pagesize = 50L, page = page)),
      error = function(e) { base::message("DOJ page ", page, ": ",
                                          base::conditionMessage(e)); NULL })
    if (base::is.null(payload)) { page <- page + 1L; next }
    res <- payload[["results"]]
    if (base::is.null(res) || base::length(res) == 0L) break
    # Cheap pass first: strip tags with a regex and test the pattern. Only the
    # survivors are parsed properly, which is what makes a 272k-record corpus
    # tractable.
    bodies <- base::vapply(res, function(r) {
      b <- nested_character(r, "body"); if (base::is.na(b)) "" else b
    }, "")
    titles <- base::vapply(res, function(r) {
      t <- nested_character(r, "title"); if (base::is.na(t)) "" else t
    }, "")
    approx <- fast_strip_html(bodies)
    hit <- base::grepl(DOJ_ACTION_PATTERN, approx, ignore.case = TRUE, perl = TRUE) &
      base::grepl(DOJ_PHYSICIAN_PATTERN, base::paste(titles, approx),
                  ignore.case = TRUE, perl = TRUE)
    n_seen <- n_seen + base::length(res)
    if (base::any(hit)) {
      idx <- base::which(hit)
      k <- purrr::map_dfr(idx, function(i) {
        r <- res[[i]]
        body_text <- html_fragment_to_text(bodies[[i]])
        tibble::tibble(
          uuid = nested_character(r, "uuid"),
          publication_date = nested_character(r, "date"),
          title = nested_character(r, "title"),
          source_url = nested_character(r, "url"),
          body_text = body_text,
          component_json = json_text(r[["component"]]),
          attachment_urls = base::paste(
            collect_urls(base::list(r[["attachment"]])), collapse = ";"))
      })
      k$matched_action_text <- base::vapply(k$body_text, function(b) {
        m <- base::regmatches(b, base::regexpr(DOJ_ACTION_PATTERN, b,
                                               ignore.case = TRUE, perl = TRUE))
        if (base::length(m) == 0L) NA_character_ else m[[1L]]
      }, "")
      k$npi_in_text <- base::vapply(k$body_text, extract_npis_from_text, "")
      kept[[base::length(kept) + 1L]] <- k
    }
    if (page %% 50L == 0L) {
      base::message("DOJ page ", page, " | seen ",
                    base::format(n_seen, big.mark = ","), " | kept ",
                    base::format(base::sum(base::vapply(kept, base::nrow, 1L)),
                                 big.mark = ","))
      if (!base::is.null(checkpoint_path) && base::length(kept)) {
        base::saveRDS(dplyr::bind_rows(kept), checkpoint_path)
      }
    }
    page <- page + 1L
    if (pause_seconds > 0) base::Sys.sleep(pause_seconds)
  }
  out <- dplyr::bind_rows(kept)
  if (base::nrow(out) == 0L) return(out)
  out$record_class <- "DOJ_PRESS_RELEASE"
  out$source <- "doj_press_releases"
  out$records_scanned <- n_seen
  out$source_retrieved_at <- base::as.character(base::Sys.time())
  out[!base::duplicated(out$uuid), , drop = FALSE]
}
