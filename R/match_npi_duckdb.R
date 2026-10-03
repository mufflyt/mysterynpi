#' Generate candidate pairs inside a DuckDB connection
#'
#' Structured reference given/surname columns are required; roster full names
#' may be parsed in R. Reference normalization, exclusions, and blocking run in
#' SQL. Only candidate rows and aggregate counts cross the connection boundary.
#' Connection-scoped temporary tables/macros are removed even after an error.
#' No persistent user tables are written. Route evidence is assigned elsewhere.
#' @inheritParams generate_npi_candidates_memory
#' @param con A valid DuckDB DBI connection, including read-only connections.
#' @param table Raw table name or DBI::Id with schema/table identifiers.
#' @keywords internal
#' @noRd
generate_npi_candidates_duckdb <- function(con, table, roster, columns, entity_filter = "1") {
  .npi_duckdb_validate(con, table, roster, columns, entity_filter)
  quote_id <- function(x) as.character(DBI::dbQuoteIdentifier(con, x))
  literal <- function(x) as.character(DBI::dbQuoteLiteral(con, x))
  source_table <- quote_id(table)
  numeric_fields <- .npi_duckdb_numeric_fields(con, source_table, columns, quote_id)
  field <- function(name) {
    if (is.null(columns[[name]])) return("NULL::VARCHAR")
    x <- quote_id(columns[[name]])
    if (!isTRUE(numeric_fields[[name]])) return(paste0("CAST(", x, " AS VARCHAR)"))
    # Mirror .match_npi_text(): whole numbers become plain digits (a DOUBLE
    # would otherwise cast to "1234567893.0"); fractional values keep their
    # decimal text, which never validates as an NPI or equals an entity code.
    paste0("CASE WHEN ", x, " IS NULL THEN NULL WHEN ", x, " = trunc(", x,
           ") AND abs(", x, ") < 1e18 THEN CAST(CAST(", x,
           " AS BIGINT) AS VARCHAR) ELSE CAST(", x, " AS VARCHAR) END")
  }
  # Unique names and explicit temp-schema qualification prevent collisions with
  # persistent tables, including during cleanup after a failed CREATE.
  prefix <- basename(tempfile("mysterynpi_"))
  objects <- list()
  on.exit({
    for (object in rev(objects)) {
      try(DBI::dbExecute(con, paste("DROP", object$type, "IF EXISTS", object$name)),
          silent = TRUE)
    }
  }, add = TRUE)
  temporary <- function(suffix, type = "TABLE") {
    raw <- paste0(prefix, "_", suffix)
    qualified <- quote_id(DBI::Id(schema = "temp", table = raw))
    objects[[length(objects) + 1L]] <<- list(type = type, name = qualified)
    list(raw = raw, sql = qualified)
  }
  write_temp <- function(suffix, data) {
    object <- temporary(suffix)
    DBI::dbWriteTable(con, object$raw, data, temporary = TRUE)
    object$sql
  }
  create_temp <- function(suffix, query) {
    object <- temporary(suffix)
    DBI::dbExecute(con, paste("CREATE TEMP TABLE", quote_id(object$raw), "AS", query))
    object$sql
  }
  macro <- function(suffix, args, expression) {
    object <- temporary(suffix, "MACRO")
    DBI::dbExecute(con, paste0("CREATE TEMP MACRO ", quote_id(object$raw), "(", args,
                               ") AS (", expression, ")"))
    object$sql
  }

  source_names <- .match_npi_names(roster, columns$given, columns$middle,
                                   columns$surname, columns$full_name)
  source <- data.frame(row_id = seq_len(nrow(roster)),
                       source_id = as.character(roster[[columns$id]]), source_names,
                       lead = name_leading_given(source_names$first),
                       last_key = .nm_key(source_names$last))
  sources <- write_temp("roster", source)
  source_blocks <- .npi_memory_blocks(source_names)
  blocks <- lapply(names(source_blocks), function(route) {
    keys <- source_blocks[[route]]
    data.frame(row_id = rep(seq_along(keys), lengths(keys)),
               block_route = rep(route, sum(lengths(keys))),
               key = as.character(unlist(keys, use.names = FALSE)))
  })
  blocks <- write_temp("roster_blocks", do.call(rbind, blocks))

  # This small Unicode dictionary is generated independently of reference data.
  # ICU supplies the same Latin-ASCII mapping as name_key; NFC happens in SQL.
  # BMP Latin, punctuation, and presentation forms cover supported name keys.
  # Combining marks that survive NFC (no precomposed form, e.g. o + U+0329)
  # are dropped before the per-character lookup: ICU's Latin-ASCII removes
  # them in context, but a lone mark is not in the dictionary.
  chars <- intToUtf8(setdiff(seq_len(65535L), 55296L:57343L), multiple = TRUE)
  transliterated <- stringi::stri_trans_general(chars, "Latin-ASCII")
  german <- c("\u00fc", "\u00dc", "\u00f6", "\u00d6", "\u00e4", "\u00c4", "\u00df")
  transliterated[match(german, chars)] <- c("UE", "UE", "OE", "OE", "AE", "AE", "SS")
  changed <- chars != transliterated
  transliteration <- write_temp("transliteration",
    data.frame(ch = chars[changed], replacement = transliterated[changed]))
  normalize <- macro("normalize", "value", paste0(
    "CASE WHEN value IS NULL THEN NULL ELSE upper(coalesce((SELECT ",
    "string_agg(coalesce(m.replacement, c.ch), '' ORDER BY c.pos) FROM ",
    "unnest(string_split(regexp_replace(nfc_normalize(value), '\\p{Mn}', '', 'g'), '')) ",
    "WITH ORDINALITY c(ch, pos) ",
    "LEFT JOIN ", transliteration, " m ON m.ch = c.ch), '')) END"))
  reg <- function(x, pattern, replacement) {
    paste0("regexp_replace(", x, ", ", literal(pattern), ", ", literal(replacement), ", 'g')")
  }
  normalized <- paste0(normalize, "(value)")
  normalized <- reg(normalized, "([A-Za-z'])\\(([^)]*)\\)", "\\1\\2")
  normalized <- reg(normalized, "\\([^)]*\\)", " ")
  normalized <- reg(normalized, "\\([^)]*$", " ")
  normalized <- reg(normalized, "[][()]", " ")
  normalized <- reg(normalized, "\\s+", " ")
  name_key_sql <- macro("name_key", "value", paste0("trim(", normalized, ")"))
  key_sql <- macro("key", "value", reg("value", "['\u2019`]", ""))
  tokens_sql <- macro("tokens", "value", paste0(
    "list_filter(regexp_split_to_array(", key_sql,
    "(coalesce(value, '')), '[^A-Za-z]+'), x -> length(x) >= 2)"))
  # list_distinct reorders values; retain the first occurrence for surname
  # concatenation, whose order is part of the memory backend's contract.
  unique_sql <- macro("unique_tokens", "value", paste0(
    "list_filter(value, (x, i) -> list_position(value, x) = i)"))
  deletion_sql <- macro("deletions", "value", paste0(
    "CASE WHEN length(value) >= 3 THEN list_prepend(value, ",
    "list_transform(range(1, length(value) + 1), i -> ",
    "substr(value, 1, i - 1) || substr(value, i + 1))) ELSE []::VARCHAR[] END"))
  pair_key <- macro("pair_key", "a, b", "length(a)::VARCHAR || ':' || a || length(b) || ':' || b")
  selected <- paste0("SELECT ", field("npi"), " AS npi, ",
    name_key_sql, "(", field("nppes_given"), ") AS first, ",
    name_key_sql, "(", field("nppes_middle"), ") AS middle, ",
    name_key_sql, "(", field("nppes_surname"), ") AS last FROM ", source_table,
    " WHERE ", field("entity_type"), " = ", literal(entity_filter))
  # Luhn's 80840 prefix contributes 24; positions 1,3,5,7,9 are doubled.
  luhn <- paste0(
    "coalesce(regexp_full_match(npi, '[0-9]{10}') AND ",
    "(24 + list_sum(list_transform(range(1, 11), i -> CASE WHEN i % 2 = 1 THEN ",
    "(try_cast(substr(npi, i, 1) AS INTEGER) * 2) // 10 + ",
    "(try_cast(substr(npi, i, 1) AS INTEGER) * 2) % 10 ELSE ",
    "try_cast(substr(npi, i, 1) AS INTEGER) END))) % 10 = 0, FALSE)")
  particles <- paste(literal(NAME_SURNAME_PARTICLES), collapse = ", ")
  reference <- create_temp("reference", paste0(
    "WITH names AS (", selected, "), keys AS (SELECT *, ", key_sql, "(last) AS last_key, ",
    "nullif(regexp_extract(", key_sql, "(first), '[A-Za-z]+'), '') AS lead, ",
    unique_sql, "(", tokens_sql, "(last)) AS components, ",
    tokens_sql, "(coalesce(first, '') || ' ' || coalesce(middle, '')) AS tokens, ",
    luhn, " AS valid FROM names) SELECT row_number() OVER () AS row_id, *, ",
    "lead IS NOT NULL AND length(components) > 0 AS present, ",
    "list_prepend(array_to_string(components, ''), ",
    "list_filter(components, x -> x NOT IN (", particles, "))) AS family FROM keys"))
  counts <- DBI::dbGetQuery(con, paste0(
    "SELECT (SELECT count(*) FROM ", source_table, ") AS input, count(*) AS entity_type, ",
    "count(*) FILTER (WHERE NOT valid) AS invalid_npi, ",
    "count(*) FILTER (WHERE valid AND NOT present) AS missing_required_name, ",
    "count(*) FILTER (WHERE valid AND present) AS usable FROM ", reference))
  counts <- stats::setNames(as.integer(counts[1, ]), names(counts))
  if (counts[["entity_type"]] == 0L) {
    stop("no reference rows remain after entity filtering", call. = FALSE)
  }

  route <- function(name, key, from = "", where = "") {
    paste0("SELECT r.row_id, ", literal(name), " AS block_route, ", key,
           " AS key FROM usable r ", from, " ", where)
  }
  pair <- function(a, b) paste0(pair_key, "(", a, ", ", b, ")")
  routes <- c(
    route("exact_given_surname", pair("last_key", "t"), ", unnest(tokens) v(t)"),
    route("surname_initial", pair("last_key", "substr(lead, 1, 1)")),
    route("surname_variant_given", pair("f", "t"),
          ", unnest(family) a(f), unnest(tokens) b(t)"),
    route("surname_variant_initial", pair("f", "substr(lead, 1, 1)"),
          ", unnest(family) a(f)"),
    route("nickname_surname", "last_key"),
    route("fuzzy_given_surname", pair("last_key", "d"),
          paste0(", unnest(", deletion_sql, "(lead)) a(d)")),
    route("fuzzy_surname_given", pair("lead", "d"),
          paste0(", unnest(", deletion_sql, "(last_key)) a(d)"), "WHERE length(lead) >= 2"))
  pairs <- DBI::dbGetQuery(con, paste0(
    "WITH usable AS MATERIALIZED (SELECT * FROM ", reference, " WHERE valid AND present), ",
    "reference_blocks AS (", paste(routes, collapse = " UNION ALL "), "), ",
    "hits AS (SELECT DISTINCT s.row_id AS source_row, r.row_id AS reference_row, ",
    "s.block_route FROM ", blocks, " s JOIN reference_blocks r USING (key, block_route)) ",
    "SELECT s.source_id, r.npi, s.first AS roster_first, s.middle AS roster_middle, ",
    "s.last AS roster_last, r.first AS nppes_first, r.middle AS nppes_middle, ",
    "r.last AS nppes_last, h.block_route FROM hits h ",
    "JOIN ", sources, " s ON s.row_id = h.source_row ",
    "JOIN usable r ON r.row_id = h.reference_row WHERE ",
    "(h.block_route != 'nickname_surname' OR ",
    "(length(s.lead) >= 2 AND length(r.lead) >= 2 AND s.lead != r.lead)) AND ",
    "(h.block_route != 'fuzzy_given_surname' OR s.lead != r.lead) AND ",
    "(h.block_route != 'fuzzy_surname_given' OR s.last_key != r.last_key) ",
    "ORDER BY s.row_id, h.block_route, r.row_id"))
  # As in the memory backend, canonical nickname agreement filters only the
  # exact-surname block after retrieval. No unrestricted reference data or
  # dictionary-derived alternate-name index is transferred into R.
  nickname_rows <- which(pairs$block_route == "nickname_surname")
  keep <- rep(TRUE, nrow(pairs))
  if (length(nickname_rows)) {
    keep[nickname_rows] <- nickname_agreement(
      name_leading_given(pairs$roster_first[nickname_rows]),
      name_leading_given(pairs$nppes_first[nickname_rows])) == "corroborates"
  }
  pairs <- pairs[keep, , drop = FALSE]
  rownames(pairs) <- NULL
  list(pairs = pairs, reference_counts = counts)
}

# Which mapped reference columns are numeric in DuckDB, by declared type.
.npi_duckdb_numeric_fields <- function(con, source_table, columns, quote_id) {
  fields <- c("npi", "entity_type", "nppes_given", "nppes_middle", "nppes_surname")
  fields <- fields[!vapply(columns[fields], is.null, logical(1))]
  selected <- vapply(fields, function(name) {
    paste0(quote_id(columns[[name]]), " AS ", quote_id(name))
  }, character(1))
  described <- DBI::dbGetQuery(con, paste0(
    "DESCRIBE SELECT ", paste(selected, collapse = ", "), " FROM ", source_table))
  numeric <- grepl(paste0("^(U?TINYINT|U?SMALLINT|U?INTEGER|U?BIGINT|U?HUGEINT|",
                          "FLOAT|REAL|DOUBLE|DECIMAL|NUMERIC)"),
                   toupper(described$column_type))
  stats::setNames(as.list(numeric), described$column_name)
}

.npi_duckdb_validate <- function(con, table, roster, columns, entity_filter) {
  if (!requireNamespace("DBI", quietly = TRUE) ||
      !inherits(con, "duckdb_connection") || !DBI::dbIsValid(con)) {
    stop("con must be a valid DuckDB DBI connection", call. = FALSE)
  }
  if ((!is.character(table) || length(table) != 1L || is.na(table) || !nzchar(table)) &&
      !inherits(table, "Id")) {
    stop("table must be a nonblank table name or DBI::Id", call. = FALSE)
  }
  if (inherits(table, "SQL")) stop("table requires raw identifiers, not SQL", call. = FALSE)
  if (!DBI::dbExistsTable(con, table)) stop("reference table does not exist", call. = FALSE)
  if (!is.data.frame(roster)) stop("roster must be a data.frame", call. = FALSE)
  if (any(vapply(columns, inherits, logical(1), "SQL"))) {
    stop("column mappings require raw column names, not SQL", call. = FALSE)
  }
  if (any(vapply(columns[c("id", "npi", "entity_type")], is.null, logical(1)))) {
    stop("id, npi, and entity_type column mappings are required", call. = FALSE)
  }
  .match_npi_columns(columns, c("id", "given", "middle", "surname", "full_name"),
                     names(roster), "roster")
  .match_npi_columns(columns, c("npi", "entity_type", "nppes_given", "nppes_middle",
                                "nppes_surname", "nppes_full_name"),
                     DBI::dbListFields(con, table), "nppes")
  .match_npi_name_mode(columns$given, columns$middle, columns$surname,
                       columns$full_name, "roster")
  if (!is.null(columns$nppes_full_name) || is.null(columns$nppes_given) ||
      is.null(columns$nppes_surname)) {
    stop("DuckDB requires structured reference given and surname columns; ",
         "parse full reference names before loading DuckDB or use the memory backend",
         call. = FALSE)
  }
  ids <- as.character(roster[[columns$id]])
  if (anyNA(ids) || any(!nzchar(trimws(ids))) || anyDuplicated(ids)) {
    stop("source IDs must be unique and nonblank", call. = FALSE)
  }
  if (!is.character(entity_filter) || length(entity_filter) != 1L ||
      is.na(entity_filter) || !nzchar(trimws(entity_filter))) {
    stop("entity_filter must be a nonblank character value", call. = FALSE)
  }
}
