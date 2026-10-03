#' Match a source roster against user-provided NPPES data
#'
#' One call takes roster rows through bounded candidate generation, shared
#' name evidence, conservative one-to-one resolution, and rationale-bearing
#' result partitions. `nppes` is either a data frame (the in-memory backend)
#' or a DuckDB DBI connection plus `table` (the DuckDB backend); both backends
#' use the same candidate blocks, evidence classes, reason codes, tie
#' behaviour, and output schema. The reference universe is filtered to
#' `entity_filter` (Type 1 individuals by default) before matching.
#'
#' Column mappings are character column names. Supply either given and surname
#' mappings (with optional middle), or a full-name mapping, for each input.
#' Full names use [parse_person()] and therefore require humaniformat; the
#' DuckDB backend requires structured reference given and surname columns.
#'
#' Candidate generation never compares every roster row with every reference
#' row: it joins exact surname/given keys, surname-component variants, an
#' exact-surname nickname block, and single-character deletion signatures
#' anchored on the exact opposite name. Nickname-only and fuzzy-only evidence
#' can surface a candidate for review but never resolves a match on its own.
#' A record resolves only when exactly one eligible candidate holds its
#' strongest evidence; ties, NPIs claimed by more than one record, and name
#' conflicts go to `review` with a stable reason. The DuckDB source is read
#' only: no persistent table is created, replaced, or altered.
#'
#' @param roster Source roster data frame, preserved in disposition partitions.
#' @param nppes Reference data frame or DuckDB DBI connection.
#' @param table Reference table identifier (name or [DBI::Id()]) for a DBI
#'   connection; must be `NULL` for a data frame.
#' @param id Stable, unique, nonblank source ID column.
#' @param given,middle,surname,full_name Source name column mappings.
#' @param npi,entity_type Reference NPI and entity-type column mappings.
#' @param nppes_given,nppes_middle,nppes_surname,nppes_full_name Reference name mappings.
#' @param entity_filter Entity type to include; defaults to individuals ("1").
#' @param backend One of "auto", "data.frame", or "duckdb".
#' @return A list with:
#' \describe{
#'   \item{matches}{Roster rows with one uniquely supported NPI (reason
#'     `unique_best_evidence`).}
#'   \item{review}{Roster rows with candidates that cannot safely resolve
#'     (`ambiguous_tied_evidence`, `ambiguous_contested_candidate`,
#'     `nickname_only_evidence`, `fuzzy_only_evidence`, `weak_name_evidence`,
#'     or a named conflict). No NPI is assigned; see `candidates`.}
#'   \item{unmatched}{Roster rows with no candidate (`no_candidate`) or without
#'     enough source name (`missing_required_name`).}
#'   \item{candidates}{One row per source/NPI identity pair with the blocking
#'     routes, evidence fields, evidence class, disposition, and reason.}
#'   \item{counts}{Roster, partition, candidate, and reference-exclusion counts.}
#'   \item{run_manifest}{Package and nickname-policy versions, backend, table,
#'     entity filter, column maps, candidate-generation settings, result column
#'     names, and input/exclusion row counts; `execution_status` is
#'     `"complete"`.}
#' }
#' Source columns are preserved; result columns `source_id`, `npi`, and
#' `reason` are renamed with [make.unique()] when the roster already uses those
#' names (the names used are recorded in `run_manifest$result_columns`). NPI
#' result columns are character.
#' @export
#' @examples
#' roster <- data.frame(record = c("r1", "r2", "r3"),
#'                      first = c("Jane", "Bob", NA), last = c("Doe", "Smith", "Lee"))
#' nppes <- data.frame(provider = c("1234567893", "1245319599", "1004000000"),
#'                     type = c("1", "1", "2"),
#'                     first = c("Jane", "Robert", "Jane"), last = c("Doe", "Smith", "Doe"))
#' result <- match_npi(roster, nppes, id = "record", given = "first", surname = "last",
#'                     npi = "provider", entity_type = "type",
#'                     nppes_given = "first", nppes_surname = "last")
#' result$matches[, c("record", "npi", "reason")]
#' result$review[, c("record", "reason")]
#' result$unmatched[, c("record", "reason")]
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
  fields <- c("source_id", "npi", "reason")
  output_names <- utils::tail(make.unique(c(names(roster), fields)), length(fields))
  result_columns <- stats::setNames(output_names, fields)
  generated <- if (inputs$backend == "duckdb") {
    generate_npi_candidates_duckdb(nppes, table, roster, columns, entity_filter)
  } else {
    generate_npi_candidates_memory(roster, nppes, columns, entity_filter)
  }
  candidates <- build_npi_candidate_evidence(generated$pairs)
  partitions <- partition_npi_matches(roster, candidates, id = id,
                                      result_columns = result_columns,
                                      missing_name = inputs$missing_name)
  reference_counts <- generated$reference_counts
  counts <- list(
    roster_rows = nrow(roster), matches = nrow(partitions$matches),
    review = nrow(partitions$review), unmatched = nrow(partitions$unmatched),
    candidates = nrow(candidates), candidate_pairs = nrow(generated$pairs),
    missing_required_name = sum(inputs$missing_name),
    reference = as.list(reference_counts))
  c(partitions, list(counts = counts, run_manifest = .match_npi_manifest(
    inputs, table, entity_filter, result_columns, roster, reference_counts,
    generated$pairs, candidates)))
}

# The manifest is deterministic for a given input: no timestamps, so two
# backends run on the same data produce manifests that differ only in
# `backend` and `table`.
.match_npi_manifest <- function(inputs, table, entity_filter, result_columns, roster,
                                reference_counts, pairs, candidates) {
  table_label <- if (inputs$backend != "duckdb") NULL
    else if (inherits(table, "Id")) paste(table@name, collapse = ".") else table
  list(
    package = "mysterynpi",
    package_version = as.character(utils::packageVersion("mysterynpi")),
    nickname_policy = NICKNAME_POLICY$policy_id,
    nickname_dictionary_version = nickname_dictionary_version(),
    backend = inputs$backend,
    table = table_label,
    entity_filter = as.character(entity_filter),
    columns = inputs$columns,
    result_columns = result_columns,
    candidate_settings = list(
      routes = c("exact_given_surname", "surname_initial", "surname_variant_given",
                 "surname_variant_initial", "nickname_surname", "fuzzy_given_surname",
                 "fuzzy_surname_given"),
      fuzzy_rule = "exact intersection of single-character deletion signatures (names of 3+ characters), anchored on the exact opposite name",
      nickname_rule = "nickname_agreement() inside the exact-surname block; review only",
      resolution_rule = "resolve_one_to_one() on eligible candidates ranked by evidence class then middle corroboration; ties and contested NPIs go to review"),
    roster_rows = nrow(roster),
    roster_missing_required_name = sum(inputs$missing_name),
    reference_rows = reference_counts[["input"]],
    reference_rows_filtered = reference_counts[["entity_type"]],
    reference_excluded_invalid_npi = reference_counts[["invalid_npi"]],
    reference_excluded_missing_required_name = reference_counts[["missing_required_name"]],
    reference_rows_usable = reference_counts[["usable"]],
    candidate_pairs = nrow(pairs),
    candidates = nrow(candidates),
    execution_status = "complete")
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
  if (connection && is.null(table)) stop("a DBI connection requires table", call. = FALSE)
  if (!connection && !is.null(table)) {
    stop("table applies only to a DBI connection; pass the reference data frame as nppes",
         call. = FALSE)
  }
  required <- c("id", "npi", "entity_type")
  if (any(vapply(columns[required], is.null, logical(1)))) {
    stop("id, npi, and entity_type column mappings are required", call. = FALSE)
  }
  .match_npi_columns(columns, c("id", "given", "middle", "surname", "full_name"),
                     names(roster), "roster")
  .match_npi_name_mode(columns$given, columns$middle, columns$surname,
                       columns$full_name, "roster")
  ids <- as.character(roster[[columns$id]])
  if (anyNA(ids) || any(!nzchar(trimws(ids))) || anyDuplicated(ids)) {
    stop("source IDs must be unique and nonblank", call. = FALSE)
  }
  if (!is.character(entity_filter) || length(entity_filter) != 1L ||
      is.na(entity_filter) || !nzchar(trimws(entity_filter))) {
    stop("entity_filter must be a nonblank character value", call. = FALSE)
  }
  source_names <- .match_npi_names(roster, columns$given, columns$middle,
                                  columns$surname, columns$full_name)
  missing_name <- !has_name_information(source_names$first) |
    !has_name_information(source_names$last)
  if (connection) {
    # Reference validation, filtering, and normalization happen inside DuckDB.
    return(list(backend = backend, columns = columns, source_names = source_names,
                reference_names = NULL, reference = NULL, missing_name = missing_name))
  }
  .match_npi_columns(columns, c("npi", "entity_type", "nppes_given", "nppes_middle",
                                "nppes_surname", "nppes_full_name"), names(nppes), "nppes")
  .match_npi_name_mode(columns$nppes_given, columns$nppes_middle, columns$nppes_surname,
                       columns$nppes_full_name, "nppes")
  keep <- .match_npi_text(nppes[[columns$entity_type]]) == entity_filter
  reference <- nppes[!is.na(keep) & keep, , drop = FALSE]
  if (!nrow(reference)) stop("no reference rows remain after entity filtering", call. = FALSE)
  reference[[columns$npi]] <- .match_npi_text(reference[[columns$npi]])
  reference_names <- .match_npi_names(reference, columns$nppes_given, columns$nppes_middle,
                                     columns$nppes_surname, columns$nppes_full_name)
  list(backend = backend, columns = columns, source_names = source_names,
       reference_names = reference_names, reference = reference,
       missing_name = missing_name)
}
