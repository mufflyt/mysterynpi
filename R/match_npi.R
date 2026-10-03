#' Match a source roster against user-provided NPPES data
#'
#' Column mappings are character column names. Supply either given and surname
#' mappings (with optional middle), or a full-name mapping, for each input.
#' Full names use [parse_person()] and therefore require humaniformat.
#' This initial contract returns empty candidate/match/review partitions;
#' candidate generation is provided by the backend workflow.
#'
#' @param roster Source roster data frame, preserved in disposition partitions.
#' @param nppes Reference data frame or DuckDB DBI connection.
#' @param table Reference table identifier for a DBI connection.
#' @param id Stable, unique, nonblank source ID column.
#' @param given,middle,surname,full_name Source name column mappings.
#' @param npi,entity_type Reference NPI and entity-type column mappings.
#' @param nppes_given,nppes_middle,nppes_surname,nppes_full_name Reference name mappings.
#' @param entity_filter Entity type to include; defaults to individuals ("1").
#' @param backend One of "auto", "data.frame", or "duckdb".
#' @return List with matches, review, unmatched, candidates, counts, and run_manifest.
#'   NPI result columns are character. Missing source names are unmatched with
#'   reason `missing_required_name`. Other rows have reason `matching_pending`
#'   until candidate generation runs; the manifest execution status is also
#'   `matching_pending`.
#' @export
match_npi <- function(roster, nppes, table = NULL, id, given = NULL, middle = NULL,
                      surname = NULL, full_name = NULL, npi, entity_type,
                      nppes_given = NULL, nppes_middle = NULL, nppes_surname = NULL,
                      nppes_full_name = NULL, entity_filter = "1",
                      backend = c("auto", "data.frame", "duckdb")) {
  columns <- list(id = id, given = given, middle = middle, surname = surname,
                  full_name = full_name, npi = npi, entity_type = entity_type,
                  nppes_given = nppes_given, nppes_middle = nppes_middle,
                  nppes_surname = nppes_surname, nppes_full_name = nppes_full_name)
  inputs <- .match_npi_inputs(roster, nppes, table, columns, entity_filter, backend)
  out <- roster
  fields <- c("source_id", "npi", "reason")
  output_names <- tail(make.unique(c(names(roster), fields)), length(fields))
  result_columns <- stats::setNames(output_names, fields)
  out[[result_columns[["source_id"]]]] <- as.character(roster[[id]])
  out[[result_columns[["npi"]]]] <- rep(NA_character_, nrow(roster))
  reasons <- rep("matching_pending", nrow(roster))
  reasons[inputs$missing_name] <- "missing_required_name"
  out[[result_columns[["reason"]]]] <- reasons
  empty <- out[FALSE, , drop = FALSE]
  list(
    matches = empty, review = empty, unmatched = out,
    candidates = data.frame(source_id = character(), npi = character(), reason = character()),
    counts = list(roster_rows = nrow(roster), matches = 0L, review = 0L,
                  unmatched = nrow(roster), candidates = 0L),
    run_manifest = list(backend = inputs$backend, entity_filter = as.character(entity_filter),
                        execution_status = "matching_pending",
                        columns = columns, result_columns = result_columns,
                        roster_rows = nrow(roster),
                        reference_rows = nrow(nppes),
                        reference_rows_filtered = nrow(inputs$reference))
  )
}

.match_npi_columns <- function(columns, fields, available, label) {
  for (field in fields) {
    column <- columns[[field]]
    if (is.null(column)) next
    if (!is.character(column) || length(column) != 1L || is.na(column) ||
        !nzchar(trimws(column))) {
      stop(field, " must be a single character column name", call. = FALSE)
    }
    if (!column %in% available) {
      stop(label, " is missing mapped column: ", column, call. = FALSE)
    }
  }
}

.match_npi_names <- function(data, given, middle, surname, full_name) {
  if (!nrow(data)) {
    return(data.frame(first = character(), middle = character(), last = character()))
  }
  if (!is.null(full_name)) return(parse_person(data[[full_name]]))
  data.frame(first = name_key(data[[given]]),
             middle = if (is.null(middle)) rep(NA_character_, nrow(data))
             else name_key(data[[middle]]), last = name_key(data[[surname]]))
}

# NPI and entity-type identifiers may arrive as numbers. Whole numbers render
# as plain digits (as.character() would write 1004000000 as "1.004e+09" and a
# valid NPI would silently fail validation); fractional values keep their
# decimal text and can never pass NPI validation or equal an entity code. The
# DuckDB backend mirrors this rendering in SQL.
.match_npi_text <- function(x) {
  out <- as.character(x)
  if (is.numeric(x)) {
    whole <- !is.na(x) & is.finite(x) & x == trunc(x) & abs(x) < 1e18
    out[whole] <- sprintf("%.0f", x[whole])
  }
  out
}

.match_npi_name_mode <- function(given, middle, surname, full_name, label) {
  structured <- !is.null(given) && !is.null(surname)
  any_structured <- !is.null(given) || !is.null(middle) || !is.null(surname)
  if ((!is.null(full_name) && any_structured) ||
      (is.null(full_name) && !structured)) {
    stop(label, " requires either given and surname name mappings or full_name", call. = FALSE)
  }
}

.match_npi_inputs <- function(roster, nppes, table, columns, entity_filter, backend) {
  backend <- match.arg(backend, c("auto", "data.frame", "duckdb"))
  if (!is.data.frame(roster)) stop("roster must be a data.frame", call. = FALSE)
  connection <- requireNamespace("DBI", quietly = TRUE) && inherits(nppes, "DBIConnection")
  if (!is.data.frame(nppes) && !connection) {
    stop("nppes must be a data.frame or DBI connection", call. = FALSE)
  }
  if (backend == "auto") backend <- if (connection) "duckdb" else "data.frame"
  if (backend == "duckdb" && !connection) {
    stop("duckdb backend requires a DBI connection", call. = FALSE)
  }
  if (backend == "data.frame" && !is.data.frame(nppes)) {
    stop("data.frame backend requires a data.frame", call. = FALSE)
  }
  if (connection) {
    if (is.null(table)) stop("a DBI connection requires table", call. = FALSE)
    stop("DuckDB candidate backend is not yet available", call. = FALSE)
  }
  required <- c("id", "npi", "entity_type")
  if (any(vapply(columns[required], is.null, logical(1)))) {
    stop("id, npi, and entity_type column mappings are required", call. = FALSE)
  }
  .match_npi_columns(columns, c("id", "given", "middle", "surname", "full_name"),
                     names(roster), "roster")
  .match_npi_columns(columns, c("npi", "entity_type", "nppes_given", "nppes_middle",
                                "nppes_surname", "nppes_full_name"), names(nppes), "nppes")
  .match_npi_name_mode(columns$given, columns$middle, columns$surname,
                       columns$full_name, "roster")
  .match_npi_name_mode(columns$nppes_given, columns$nppes_middle, columns$nppes_surname,
                       columns$nppes_full_name, "nppes")
  ids <- as.character(roster[[columns$id]])
  if (anyNA(ids) || any(!nzchar(trimws(ids))) || anyDuplicated(ids)) {
    stop("source IDs must be unique and nonblank", call. = FALSE)
  }
  if (!is.character(entity_filter) || length(entity_filter) != 1L ||
      is.na(entity_filter) || !nzchar(trimws(entity_filter))) {
    stop("entity_filter must be a nonblank character value", call. = FALSE)
  }
  keep <- .match_npi_text(nppes[[columns$entity_type]]) == entity_filter
  reference <- nppes[!is.na(keep) & keep, , drop = FALSE]
  if (!nrow(reference)) stop("no reference rows remain after entity filtering", call. = FALSE)
  reference[[columns$npi]] <- .match_npi_text(reference[[columns$npi]])
  source_names <- .match_npi_names(roster, columns$given, columns$middle,
                                  columns$surname, columns$full_name)
  reference_names <- .match_npi_names(reference, columns$nppes_given, columns$nppes_middle,
                                     columns$nppes_surname, columns$nppes_full_name)
  list(backend = backend, columns = columns, source_names = source_names,
       reference_names = reference_names, reference = reference,
       missing_name = !has_name_information(source_names$first) |
         !has_name_information(source_names$last))
}
