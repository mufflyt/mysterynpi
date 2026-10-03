#' Interpret already-blocked NPI candidate pairs
#'
#' Internal shared evidence policy; this function never generates pairs.
#' Duplicate routes are collapsed and retained as sorted, semicolon-separated
#' `block_routes`. Different normalized name profiles for the same identity
#' pair are quarantined conservatively as `conflicting_candidate_names`.
#'
#' Evidence classes are ordered, weakest to strongest: `conflicting_name`,
#' `weak_name`, `positional_name`, `exact_name`. They describe rules, not
#' probabilities. Exact leading full given names plus exact surnames are exact
#' evidence. Initial expansion or compatible surname components are positional
#' evidence. Nicknames alone, shared nonleading names, two initials, and fuzzy
#' routes remain weak. Nickname agreement corroborates but never promotes a
#' nickname-only candidate. Missing middle names are uninformative.
#'
#' Stable candidate reasons: `exact_name_evidence` and
#' `positional_name_evidence` are eligible; `nickname_only_evidence`,
#' `fuzzy_only_evidence`, and `weak_name_evidence` require review;
#' `middle_name_conflict`, `given_name_conflict`, `surname_name_conflict`,
#' `conflicting_candidate_names`, `invalid_npi`, and `missing_required_name`
#' veto automatic resolution. Route labels themselves never strengthen evidence.
#' @param candidate_pairs Data frame of bounded pairs with source_id, npi,
#'   roster_first/middle/last, nppes_first/middle/last, and block_route.
#' @return One scalar-column evidence row per source_id/npi identity pair.
#' @keywords internal
#' @noRd
build_npi_candidate_evidence <- function(candidate_pairs) {
  fields <- c("source_id", "npi", "roster_first", "roster_middle", "roster_last",
              "nppes_first", "nppes_middle", "nppes_last", "block_route")
  .npi_evidence_require(candidate_pairs, fields, "candidate_pairs")
  out <- candidate_pairs[fields]
  out[] <- lapply(out, as.character)
  if (anyNA(out$source_id) || any(!nzchar(trimws(out$source_id)))) {
    stop("candidate source IDs must be nonblank", call. = FALSE)
  }
  name_fields <- fields[3:8]
  keys <- lapply(out[name_fields], name_key)
  first_a <- name_leading_given(out$roster_first)
  first_b <- name_leading_given(out$nppes_first)
  present <- has_name_information(first_a) & has_name_information(first_b) &
    has_name_information(keys$roster_last) & has_name_information(keys$nppes_last)
  out$given_exact <- present & first_a == first_b & nchar(first_a) >= 2L
  out$given_compatible <- names_have_compatible_given(
    out$roster_first, out$nppes_first, out$roster_middle, out$nppes_middle,
    mode = "positional_ie")
  out$given_position <- name_given_match_position(
    out$roster_first, out$nppes_first, out$roster_middle, out$nppes_middle)
  out$surname_evidence <- name_surname_match_type(out$roster_last, out$nppes_last)
  out$middle_evidence <- middle_agreement(middle_tokens(out$roster_middle),
                                          middle_tokens(out$nppes_middle))
  out$nickname_evidence <- nickname_agreement(first_a, first_b)
  out$npi_valid <- npi_luhn_ok(out$npi)
  out$npi_valid[is.na(out$npi_valid)] <- FALSE
  initial_a <- !is.na(first_a) & grepl("^[A-Z]$", first_a)
  initial_b <- !is.na(first_b) & grepl("^[A-Z]$", first_b)
  expansion <- out$given_compatible & xor(initial_a, initial_b)
  nickname_only <- present & !out$given_exact & !expansion &
    out$nickname_evidence == "corroborates" & !initial_a & !initial_b
  surname_ok <- out$surname_evidence != "none"
  exact <- out$given_exact & out$surname_evidence == "exact"
  positional <- (out$given_exact | expansion) & surname_ok
  classes <- rep("weak_name", nrow(out))
  reasons <- rep("weak_name_evidence", nrow(out))
  # Group by each identifier separately: delimiter-bearing IDs cannot collide.
  groups <- unlist(lapply(split(seq_len(nrow(out)), out$source_id), function(rows) {
    split(rows, match(out$npi[rows], unique(out$npi[rows])))
  }), recursive = FALSE)
  fuzzy <- !is.na(out$block_route) & grepl("fuzzy", out$block_route, ignore.case = TRUE)
  for (rows in groups) fuzzy[rows] <- any(fuzzy[rows])
  reasons[fuzzy | (out$given_exact & !surname_ok)] <- "fuzzy_only_evidence"
  reasons[nickname_only] <- "nickname_only_evidence"
  classes[positional] <- "positional_name"
  reasons[positional] <- "positional_name_evidence"
  classes[exact] <- "exact_name"
  reasons[exact] <- "exact_name_evidence"
  # An absent/weak name is reviewable; an explicit incompatible name is a veto.
  given_conflict <- present & !out$given_compatible & is.na(out$given_position) & !fuzzy &
    !(initial_a & initial_b & out$nickname_evidence == "corroborates")
  surname_conflict <- present & !surname_ok & !fuzzy & !out$given_exact
  vetoes <- list(given_name_conflict = given_conflict,
                 surname_name_conflict = surname_conflict,
                 middle_name_conflict = out$middle_evidence == "conflicts",
                 missing_required_name = !present, invalid_npi = !out$npi_valid)
  for (reason in names(vetoes)) {
    classes[vetoes[[reason]]] <- "conflicting_name"
    reasons[vetoes[[reason]]] <- reason
  }
  out$evidence_class <- ordered(classes, levels = c(
    "conflicting_name", "weak_name", "positional_name", "exact_name"))
  out$middle_rank <- as.integer(out$middle_evidence == "corroborates")
  out$disposition <- ifelse(classes %in% c("positional_name", "exact_name"),
                             "eligible", "review")
  out$reason <- reasons
  out$block_routes <- character(nrow(out))
  if (!nrow(out)) return(out[setdiff(names(out), "block_route")])

  collapsed <- lapply(groups, function(rows) {
    profiles <- unique(as.data.frame(lapply(keys, `[`, rows), stringsAsFactors = FALSE))
    ord <- do.call(order, c(lapply(out[name_fields], `[`, rows),
                           list(na.last = TRUE, method = "radix")))
    row <- out[rows[ord[1L]], , drop = FALSE]
    routes <- out$block_route[rows]
    row$block_routes <- paste(sort(unique(routes[!is.na(routes) & nzchar(routes)])),
                              collapse = ";")
    if (nrow(profiles) > 1L) {
      row$evidence_class[] <- "conflicting_name"
      row$disposition <- "review"
      row$reason <- "conflicting_candidate_names"
    }
    row
  })
  out <- do.call(rbind, collapsed)
  out <- out[order(out$source_id, out$npi, na.last = TRUE, method = "radix"),
             setdiff(names(out), "block_route"), drop = FALSE]
  rownames(out) <- NULL
  out
}

.npi_evidence_require <- function(data, fields, label) {
  if (!is.data.frame(data) || anyDuplicated(names(data))) {
    stop(label, " must be a data frame with unique column names", call. = FALSE)
  }
  missing <- setdiff(fields, names(data))
  if (length(missing)) {
    stop(label, " is missing columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (any(vapply(data[fields], is.list, logical(1)))) {
    stop(label, " requires scalar columns", call. = FALSE)
  }
}

#' Partition original roster rows using conservative candidate evidence
#'
#' Only eligible candidates enter [resolve_one_to_one()]. Ordered evidence
#' class ranks first, middle corroboration second. Unique supported claims yield
#' `unique_best_evidence`. Ties and shared NPI claims yield resolver reason codes
#' `ambiguous_tied_evidence` and `ambiguous_contested_candidate`. Any source with
#' a tied strongest eligible pool still claims every NPI in that pool; those
#' claims also veto another source's unique selection of the same NPI. Eligible
#' alternatives below the strongest pool and review-only candidates do not claim
#' an NPI for this contention guard. Tied sources retain the tied reason.
#' Any source with
#' candidates but no eligible candidate is review with its strongest candidate's
#' reason (lexicographic reason order for equal weak classes). Sources without
#' candidates are unmatched with `no_candidate`. Review rows have no assigned
#' NPI: candidate identities remain available in the candidates component.
#' Sources flagged by missing_name are unmatched with `missing_required_name`;
#' backends must not generate candidates for those sources.
#' @param roster Original source rows including a canonical source ID column.
#' @param candidates Output of build_npi_candidate_evidence().
#' @param id Name of canonical source ID column in roster.
#' @param result_columns Named source_id/npi/reason map established by match_npi;
#'   result NPI/reason names must not overwrite original source columns.
#' @param missing_name Logical vector from source-name normalization, one
#'   nonmissing value per roster row. Passed separately to preserve source fields.
#' @return List of matches, review, unmatched and candidates data frames.
#' @keywords internal
#' @noRd
partition_npi_matches <- function(roster, candidates, id = "source_id",
                                  result_columns = NULL,
                                  missing_name = rep(FALSE, nrow(roster))) {
  .npi_evidence_require(roster, id, "roster")
  .npi_evidence_require(candidates, c("source_id", "npi", "evidence_class",
                                     "middle_rank", "disposition", "reason"), "candidates")
  ids <- as.character(roster[[id]])
  if (anyNA(ids) || any(!nzchar(trimws(ids))) || anyDuplicated(ids)) {
    stop("roster source IDs must be unique and nonblank", call. = FALSE)
  }
  if (anyNA(candidates$source_id) || any(!candidates$source_id %in% ids)) {
    stop("candidates contain unknown source IDs", call. = FALSE)
  }
  if (!is.logical(missing_name) || length(missing_name) != nrow(roster) ||
      anyNA(missing_name)) {
    stop("missing_name must be one nonmissing logical per roster row", call. = FALSE)
  }
  if (any(candidates$source_id %in% ids[missing_name])) {
    stop("candidates must not include missing-name sources", call. = FALSE)
  }
  if (is.null(result_columns)) {
    fields <- c("npi", "reason")
    result_columns <- c(source_id = id, stats::setNames(
      utils::tail(make.unique(c(names(roster), fields)), length(fields)), fields))
  }
  if (!is.character(result_columns) ||
      !all(c("source_id", "npi", "reason") %in% names(result_columns)) ||
      anyNA(result_columns) || any(!nzchar(result_columns)) ||
      anyDuplicated(result_columns) ||
      any(result_columns[c("npi", "reason")] %in% names(roster))) {
    stop("result_columns must map source_id/npi/reason to collision-safe names", call. = FALSE)
  }
  if (result_columns[["source_id"]] != id && result_columns[["source_id"]] %in% names(roster)) {
    stop("result source_id column would overwrite a source column", call. = FALSE)
  }
  eligible <- candidates[candidates$disposition == "eligible", , drop = FALSE]
  gate <- resolve_one_to_one(eligible, id = "source_id", candidate = "npi",
                             rank_by = c(evidence_class = "desc", middle_rank = "desc"))
  # The resolver counts only unique selections as claims. Tied best pools must
  # also contest a supported NPI; compute that guard over bounded evidence only.
  strongest <- unlist(lapply(split(seq_len(nrow(eligible)), eligible$source_id),
    function(rows) {
      rows <- rows[eligible$evidence_class[rows] == max(eligible$evidence_class[rows])]
      rows[eligible$middle_rank[rows] == max(eligible$middle_rank[rows])]
    }), use.names = FALSE)
  claims <- eligible[strongest, , drop = FALSE]
  contested <- names(Filter(function(sources) length(unique(sources)) > 1L,
                            split(claims$source_id, claims$npi)))
  guarded <- gate$resolved$npi %in% contested
  if (any(guarded)) {
    vetoed <- gate$resolved[guarded, , drop = FALSE]
    vetoed$resolution_status <- "ambiguous_contested_candidate"
    gate$quarantined <- rbind(gate$quarantined, vetoed)
    gate$resolved <- gate$resolved[!guarded, , drop = FALSE]
  }
  out <- roster
  out[[result_columns[["source_id"]]]] <- ids
  out[[result_columns[["npi"]]]] <- rep(NA_character_, length(ids))
  reasons <- rep("no_candidate", length(ids))
  reasons[missing_name] <- "missing_required_name"
  disposition <- rep("unmatched", length(ids))
  for (source in unique(candidates$source_id)) {
    i <- match(source, ids)
    rows <- candidates[candidates$source_id == source, , drop = FALSE]
    rank <- order(-as.integer(rows$evidence_class), -rows$middle_rank, rows$reason)
    reasons[i] <- rows$reason[rank[1L]]
    disposition[i] <- "review"
  }
  quarantined <- match(gate$quarantined$source_id, ids)
  reasons[quarantined] <- gate$quarantined$resolution_status
  resolved <- match(gate$resolved$source_id, ids)
  reasons[resolved] <- "unique_best_evidence"
  disposition[resolved] <- "matches"
  out[[result_columns[["npi"]]]][resolved] <- as.character(gate$resolved$npi)
  out[[result_columns[["reason"]]]] <- reasons
  list(matches = out[disposition == "matches", , drop = FALSE],
       review = out[disposition == "review", , drop = FALSE],
       unmatched = out[disposition == "unmatched", , drop = FALSE], candidates = candidates)
}
