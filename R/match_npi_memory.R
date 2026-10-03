#' Generate indexed candidate pairs from an in-memory NPPES reference
#'
#' All matching rows in each block are retained, including repeated NPIs.
#' Exact/name-variant blocks use surname and given tokens or a leading initial.
#' Nickname checks run only inside an exact-surname index. Fuzzy suggestions
#' use exact intersections of single-character deletion signatures from names
#' of at least three characters, anchored by the exact opposite name. These
#' include one-edit variants and some two-edit variants such as transpositions.
#' Expansion is bounded by name length; no approximate scoring is performed.
#' Evidence and deduplication remain the responsibility of the shared evidence
#' helper. A block route never strengthens evidence by itself.
#' @param roster Source roster data frame.
#' @param nppes Full reference data frame (entity filtering happens here).
#' @param columns Column mappings established by match_npi().
#' @param entity_filter Included entity type; defaults to individuals.
#' @return Exactly list(pairs, reference_counts). Counts are sequential:
#'   input, post-entity-filter rows, invalid-NPI exclusions, missing-name
#'   exclusions among valid NPIs, and usable survivors.
#' @keywords internal
#' @noRd
generate_npi_candidates_memory <- function(roster, nppes, columns, entity_filter = "1") {
  if (!is.data.frame(nppes)) stop("nppes must be a data.frame", call. = FALSE)
  reference_fields <- c("npi", "entity_type", "nppes_given", "nppes_middle",
                        "nppes_surname", "nppes_full_name")
  .match_npi_columns(columns, reference_fields, names(nppes), "nppes")
  required <- unique(unlist(columns[reference_fields], use.names = FALSE))
  input_rows <- nrow(nppes)
  # Discard unused payload before filtering, normalization, or index building.
  inputs <- .match_npi_inputs(roster, nppes[required], NULL, columns, entity_filter,
                              "data.frame")
  reference <- inputs$reference
  ref_names <- inputs$reference_names
  valid <- npi_luhn_ok(reference[[columns$npi]])
  valid[is.na(valid)] <- FALSE
  present <- .npi_memory_name_present(ref_names)
  usable <- valid & present
  counts <- c(input = as.integer(input_rows), entity_type = as.integer(nrow(reference)),
              invalid_npi = as.integer(sum(!valid)),
              missing_required_name = as.integer(sum(valid & !present)),
              usable = as.integer(sum(usable)))
  fields <- c("source_id", "npi", "roster_first", "roster_middle", "roster_last",
              "nppes_first", "nppes_middle", "nppes_last", "block_route")
  empty <- stats::setNames(as.data.frame(rep(list(character()), length(fields))), fields)
  if (!any(usable) || !nrow(roster)) return(list(pairs = empty, reference_counts = counts))
  ref_names <- ref_names[usable, , drop = FALSE]
  npis <- as.character(reference[[columns$npi]][usable])
  source_names <- inputs$source_names
  sources <- which(.npi_memory_name_present(source_names))
  if (!length(sources)) return(list(pairs = empty, reference_counts = counts))

  ref_blocks <- .npi_memory_blocks(ref_names)
  indexes <- lapply(ref_blocks, .npi_memory_index)
  source_blocks <- .npi_memory_blocks(source_names)
  source_lead <- name_leading_given(source_names$first)
  ref_lead <- name_leading_given(ref_names$first)
  source_last <- .nm_key(source_names$last)
  ref_last <- .nm_key(ref_names$last)
  chunks <- list()
  k <- 0L
  for (i in sources) {
    for (route in names(indexes)) {
      keys <- source_blocks[[route]][[i]]
      hits <- unique(unlist(indexes[[route]][keys], use.names = FALSE))
      if (!length(hits)) next
      if (route == "nickname_surname") {
        hits <- hits[nchar(source_lead[i]) >= 2L & nchar(ref_lead[hits]) >= 2L &
                       source_lead[i] != ref_lead[hits] &
                       nickname_agreement(rep(source_lead[i], length(hits)),
                                            ref_lead[hits]) == "corroborates"]
      } else if (route == "fuzzy_given_surname") {
        hits <- hits[source_lead[i] != ref_lead[hits]]
      } else if (route == "fuzzy_surname_given") {
        hits <- hits[source_last[i] != ref_last[hits]]
      }
      if (!length(hits)) next
      k <- k + 1L
      chunks[[k]] <- data.frame(
        source_id = rep(as.character(roster[[columns$id]][i]), length(hits)),
        npi = npis[hits], roster_first = rep(source_names$first[i], length(hits)),
        roster_middle = rep(source_names$middle[i], length(hits)),
        roster_last = rep(source_names$last[i], length(hits)),
        nppes_first = ref_names$first[hits], nppes_middle = ref_names$middle[hits],
        nppes_last = ref_names$last[hits], block_route = rep(route, length(hits)))
    }
  }
  pairs <- if (length(chunks)) do.call(rbind, chunks) else empty
  rownames(pairs) <- NULL
  list(pairs = pairs, reference_counts = counts)
}

.npi_memory_name_present <- function(names) {
  has_name_information(name_leading_given(names$first)) &
    lengths(name_surname_components(names$last)) > 0L
}

# Length prefixes keep punctuation and delimiter-bearing names from colliding.
.npi_memory_key <- function(a, b) {
  if (!length(a) || !length(b)) return(character())
  paste0(nchar(a), ":", a, nchar(b), ":", b)
}

.npi_memory_deletions <- function(x) {
  if (!has_name_information(x) || nchar(x) < 3L) return(character())
  positions <- seq_len(nchar(x))
  repeated <- rep(x, length(positions))
  unique(c(x, paste0(substr(repeated, 1L, positions - 1L),
                     substring(repeated, positions + 1L))))
}

# Shared deterministic block definitions, usable by other candidate backends.
# Only fuzzy lookup expands characters, and it emits at most length(name) + 1
# keys per field. Initials and absent names never enter fuzzy blocks.
.npi_memory_blocks <- function(names) {
  lead <- name_leading_given(names$first)
  last <- .nm_key(names$last)
  tokens <- name_given_tokens(names$first, names$middle)
  components <- name_surname_components(names$last)
  present <- has_name_information(lead) & lengths(components) > 0L
  routes <- c("exact_given_surname", "surname_initial", "surname_variant_given",
               "surname_variant_initial", "nickname_surname", "fuzzy_given_surname",
               "fuzzy_surname_given")
  blocks <- stats::setNames(lapply(routes, function(route) vector("list", nrow(names))), routes)
  for (i in seq_len(nrow(names))) {
    if (!present[i]) next
    initial <- substr(lead[i], 1L, 1L)
    family <- unique(c(paste0(components[[i]], collapse = ""),
                        setdiff(components[[i]], NAME_SURNAME_PARTICLES)))
    blocks$exact_given_surname[[i]] <- .npi_memory_key(last[i], tokens[[i]])
    blocks$surname_initial[[i]] <- .npi_memory_key(last[i], initial)
    blocks$surname_variant_given[[i]] <- unlist(lapply(family, function(f) {
      .npi_memory_key(f, tokens[[i]])
    }), use.names = FALSE)
    blocks$surname_variant_initial[[i]] <- .npi_memory_key(family, initial)
    blocks$nickname_surname[[i]] <- last[i]
    blocks$fuzzy_given_surname[[i]] <- .npi_memory_key(last[i], .npi_memory_deletions(lead[i]))
    blocks$fuzzy_surname_given[[i]] <- if (nchar(lead[i]) >= 2L) {
      .npi_memory_key(lead[i], .npi_memory_deletions(last[i]))
    } else character()
  }
  blocks
}

.npi_memory_index <- function(keys) {
  rows <- rep(seq_along(keys), lengths(keys))
  split(rows, unlist(keys, use.names = FALSE))
}
