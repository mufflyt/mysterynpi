# =============================================================================
# Duplicate keys, and exactly how their rows disagree
# =============================================================================

#' Which columns differ between rows that share a key?
#'
#' FOR THE MOMENT A FILE ARRIVES with two rows per NPI, or per (state,
#' license), or per board id -- and the question is never just "are there
#' duplicates" but "WHAT is duplicated": the same person recorded twice with
#' a name variant, two snapshots straddling an address change, or two people
#' welded together by a reused id. The temporal-registry defect in
#' [count_rivals()] started exactly here: one person's two snapshot rows,
#' read as two candidates, vetoed their own match.
#'
#' For every key value carried by more than one row, this reports one output
#' row per column WHOSE VALUES DISAGREE within the group: how many rows, the
#' distinct recorded values, and -- the distinction this package will not
#' collapse -- whether the rows differ by VALUE or only by ABSENCE.
#' `absence_only = TRUE` means at most one distinct value is actually
#' recorded and the disagreement is that some rows record nothing: a
#' snapshot pair like (`JR`, `NA`) is one person incompletely transcribed,
#' while (`JR`, `SR`) is two people. A downstream rule fed the first must
#' see uninformative, not conflict.
#'
#' A key whose rows are IDENTICAL in every compared column still appears,
#' once, with `column = "<identical>"` -- pure duplicate rows are a finding,
#' and a report that silently omits them reads as "no duplicates" when it
#' means "no differences".
#'
#' @param df a data.frame.
#' @param key character: the column(s) that should identify one entity --
#'   `"npi"`, or `c("state", "license")`.
#' @param ignore character: columns to exclude from comparison (row ids,
#'   load timestamps -- columns EXPECTED to differ).
#' @return data.frame, sorted by key: the key column(s), then `column`,
#'   `n_rows` (rows sharing the key), `n_values` (distinct recorded,
#'   non-`NA` values in that column), `values` (those values, `" | "`
#'   separated), `has_absence` (any row records nothing), `absence_only`.
#'   Zero rows when no key value repeats.
#' @export
duplicate_differences <- function(df, key, ignore = character(0)) {
  miss <- setdiff(c(key, ignore), names(df))
  if (length(miss)) {
    stop(sprintf("df is missing: %s", paste(miss, collapse = ", ")),
         call. = FALSE)
  }
  cols <- setdiff(names(df), c(key, ignore))
  k <- do.call(paste, c(unname(df[key]), list(sep = "\r")))
  k[Reduce(`|`, lapply(df[key], is.na))] <- NA    # an absent key groups nothing
  dup_keys <- unique(k[!is.na(k) & (duplicated(k) | duplicated(k, fromLast = TRUE))])
  out <- lapply(sort(dup_keys), function(kv) {
    g <- df[!is.na(k) & k == kv, , drop = FALSE]
    diffs <- lapply(cols, function(cl) {
      v <- g[[cl]]
      vals <- sort(unique(v[!is.na(v)]))
      if (length(unique(c(vals, if (anyNA(v)) NA))) <= 1L) return(NULL)
      data.frame(column = cl, n_rows = nrow(g),
                 n_values = length(vals),
                 values = paste(vals, collapse = " | "),
                 has_absence = anyNA(v),
                 absence_only = length(vals) <= 1L,
                 stringsAsFactors = FALSE)
    })
    diffs <- do.call(rbind, diffs)
    if (is.null(diffs)) {
      diffs <- data.frame(column = "<identical>", n_rows = nrow(g),
                          n_values = 0L, values = "", has_absence = FALSE,
                          absence_only = FALSE, stringsAsFactors = FALSE)
    }
    cbind(g[rep(1L, nrow(diffs)), key, drop = FALSE], diffs,
          stringsAsFactors = FALSE)
  })
  out <- if (length(out)) do.call(rbind, out) else {
    empty <- df[0L, key, drop = FALSE]
    cbind(empty, data.frame(column = character(0), n_rows = integer(0),
                            n_values = integer(0), values = character(0),
                            has_absence = logical(0),
                            absence_only = logical(0),
                            stringsAsFactors = FALSE))
  }
  rownames(out) <- NULL
  out
}