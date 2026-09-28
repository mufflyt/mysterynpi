# Deterministic candidate generation.
#
# Candidate generation determines who is considered. Identity evidence
# determines what can be concluded about those candidates.

.candidate_column <- function(records, column, argument) {
  ok <- is.character(column) && length(column) == 1L &&
    !is.na(column) && nzchar(column)
  if (!ok || !column %in% names(records)) {
    stop("generate_candidates: ", argument,
         " must name one existing column.", call. = FALSE)
  }
  records[[column]]
}

.candidate_specs <- function(strategies) {
  if (inherits(strategies, "mysterynpi_blocking_spec")) {
    strategies <- list(strategies)
  }
  valid <- is.list(strategies) && length(strategies) > 0L &&
    all(vapply(strategies, inherits, logical(1),
               what = "mysterynpi_blocking_spec"))
  if (!valid) {
    stop("generate_candidates: every strategy must come from blocking_spec().",
         call. = FALSE)
  }
  labels <- vapply(strategies, function(spec) spec$label, character(1))
  if (anyDuplicated(labels)) {
    stop("generate_candidates: blocking_spec() strategy labels must be unique.",
         call. = FALSE)
  }
  strategies[order(labels)]
}

.candidate_unique_ids <- function(values, argument) {
  if (anyNA(values)) {
    stop("generate_candidates: ", argument, " cannot contain NA.",
         call. = FALSE)
  }
  if (anyDuplicated(values)) {
    stop("generate_candidates: ", argument,
         " must be unique; duplicate identifiers are ambiguous.",
         call. = FALSE)
  }
  invisible(TRUE)
}

.candidate_pair_count <- function(source_keys, candidate_keys) {
  source_table <- table(source_keys[!is.na(source_keys)])
  candidate_table <- table(candidate_keys[!is.na(candidate_keys)])
  shared <- intersect(names(source_table), names(candidate_table))
  if (!length(shared)) {
    return(0)
  }
  sum(as.numeric(source_table[shared]) *
        as.numeric(candidate_table[shared]))
}

#' Generate deterministic candidate pairs
#'
#' Candidate generation determines who is considered. Identity evidence
#' determines what can be concluded about those candidates.
#'
#' Applies governed blocking specifications and retains every named route
#' that generated a logical pair. It does not compute agreement, similarity,
#' confidence, evidence classes, or identity verdicts.
#'
#' @param source,candidates Data frames of source and candidate records.
#' @param strategies One blocking_spec() or a non-empty list of them.
#' @param source_id,candidate_id Names of unique stable identifier columns.
#' @param source_last,source_first Source surname and given-name columns.
#' @param candidate_last,candidate_first Candidate surname and given-name
#'   columns.
#' @param max_pairs Maximum raw pairs any one strategy may generate.
#' @return A list with ordinary data frames pairs, provenance, and ledger.
#' @family blocking
#' @export
generate_candidates <- function(
    source,
    candidates,
    strategies,
    source_id,
    candidate_id,
    source_last,
    source_first,
    candidate_last,
    candidate_first,
    max_pairs = 1000000L) {
  if (!is.data.frame(source) || !is.data.frame(candidates)) {
    stop("generate_candidates: source and candidates must be data frames.",
         call. = FALSE)
  }
  max_ok <- is.numeric(max_pairs) && length(max_pairs) == 1L &&
    !is.na(max_pairs) && is.finite(max_pairs) &&
    max_pairs >= 0 && max_pairs == trunc(max_pairs)
  if (!max_ok) {
    stop("generate_candidates: max_pairs must be one finite whole number >= 0.",
         call. = FALSE)
  }

  source_ids <- .candidate_column(source, source_id, "source_id")
  candidate_ids <- .candidate_column(candidates, candidate_id, "candidate_id")
  source_surnames <- .candidate_column(source, source_last, "source_last")
  source_given <- .candidate_column(source, source_first, "source_first")
  candidate_surnames <- .candidate_column(
    candidates, candidate_last, "candidate_last"
  )
  candidate_given <- .candidate_column(
    candidates, candidate_first, "candidate_first"
  )
  .candidate_unique_ids(source_ids, source_id)
  .candidate_unique_ids(candidate_ids, candidate_id)
  specs <- .candidate_specs(strategies)

  provenance_pieces <- vector("list", length(specs))
  ledger_pieces <- vector("list", length(specs))

  for (index in seq_along(specs)) {
    spec <- specs[[index]]
    source_keys <- blocking_key(
      source_surnames, source_given, spec$mode, spec$n
    )
    candidate_keys <- blocking_key(
      candidate_surnames, candidate_given, spec$mode, spec$n
    )
    generated_pairs <- .candidate_pair_count(source_keys, candidate_keys)

    if (generated_pairs > max_pairs) {
      stop("generate_candidates: strategy '", spec$label,
           "' would generate ", generated_pairs,
           " pairs, exceeding max_pairs = ", max_pairs,
           ". Refusing candidate expansion before materializing the join.",
           call. = FALSE)
    }

    source_blocks <- data.frame(
      key = source_keys,
      source_id = source_ids,
      stringsAsFactors = FALSE
    )
    candidate_blocks <- data.frame(
      key = candidate_keys,
      candidate_npi = candidate_ids,
      stringsAsFactors = FALSE
    )
    joined <- ledgered_join(
      source_blocks,
      candidate_blocks,
      by = "key",
      kind = "inner",
      relationship = "many-to-many",
      step = spec$label
    )

    if (nrow(joined$result)) {
      strategy_provenance <- unique(data.frame(
        source_id = joined$result$source_id,
        candidate_npi = joined$result$candidate_npi,
        strategy = rep(spec$label, nrow(joined$result)),
        stringsAsFactors = FALSE
      ))
      strategy_provenance <- strategy_provenance[
        order(strategy_provenance$source_id,
              strategy_provenance$candidate_npi,
              strategy_provenance$strategy),
        ,
        drop = FALSE
      ]
      row.names(strategy_provenance) <- NULL
    } else {
      strategy_provenance <- data.frame(
        source_id = source_ids[FALSE],
        candidate_npi = candidate_ids[FALSE],
        strategy = character(0),
        stringsAsFactors = FALSE
      )
    }

    unique_pairs <- nrow(strategy_provenance)
    provenance_pieces[[index]] <- strategy_provenance
    ledger_pieces[[index]] <- data.frame(
      strategy = spec$label,
      source_rows = nrow(source),
      candidate_rows = nrow(candidates),
      informative_source_keys = sum(!is.na(source_keys)),
      informative_candidate_keys = sum(!is.na(candidate_keys)),
      generated_pairs = as.numeric(generated_pairs),
      unique_pairs = as.numeric(unique_pairs),
      duplicate_pairs = as.numeric(generated_pairs - unique_pairs),
      conserved = isTRUE(joined$ledger$conserved) &&
        identical(as.numeric(nrow(joined$result)), generated_pairs),
      stringsAsFactors = FALSE
    )
  }

  provenance <- do.call(rbind, provenance_pieces)
  if (nrow(provenance)) {
    provenance <- unique(provenance)
    provenance <- provenance[
      order(provenance$source_id, provenance$candidate_npi,
            provenance$strategy),
      ,
      drop = FALSE
    ]
  }
  row.names(provenance) <- NULL

  pairs <- unique(provenance[c("source_id", "candidate_npi")])
  if (nrow(pairs)) {
    pairs <- pairs[
      order(pairs$source_id, pairs$candidate_npi),
      ,
      drop = FALSE
    ]
  }
  row.names(pairs) <- NULL

  ledger <- do.call(rbind, ledger_pieces)
  ledger <- ledger[order(ledger$strategy), , drop = FALSE]
  row.names(ledger) <- NULL

  list(pairs = pairs, provenance = provenance, ledger = ledger)
}
