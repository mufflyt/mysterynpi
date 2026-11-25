# =============================================================================
# The join ledger: rows in, rows out, and the arithmetic that must connect them
# =============================================================================
#
# THE TWO SILENT DEFECTS every linkage pipeline eventually ships: rows LOST
# (an inner join quietly dropping the people one side never heard of) and
# rows MANUFACTURED (a duplicate key fanning one person into many). Both are
# invisible at the call site and obvious in a ledger -- rows in, rows out,
# matched, unmatched, per join, per step. The field calls this ROW-COUNT
# RECONCILIATION; no tool ships the artifact (dbt-core #3142 is the
# data-engineering world asking for it), so this package does.
#
# THE VOCABULARY IS BORROWED, NOT COINED. Declarations use dplyr 1.1's
# `relationship` values and `unmatched` semantics verbatim -- that is what
# the field settled on, and a second vocabulary would be a second copy. The
# ledger fields follow the join-integrity ledger of mufflyt/midwifery's
# Safe Join Standard (R/join_safety.R). And `min_match_rate` exists because
# of a deprecation in mufflyt/isochrones' earlier safe_join.R: its inner
# join accepted `expected_min = 0`, under which 100% data loss passed
# silently. A row-count lower bound of zero is not a check.
#
# ABSENCE IS NOT A JOIN KEY. base::merge() matches NA against NA by default,
# which is the nzchar(NA) defect wearing a join: two people with no recorded
# license would "match" on their shared absence. Here a row with NA in any
# key column can never match anything -- it is counted, kept or dropped by
# the join kind, and LEDGERED, but absence never becomes a key.
# =============================================================================

key_paste <- function(d, cols) {
  if (!nrow(d)) return(character(0))  # paste() recycles empty inputs to ">"
  # Each field is LENGTH-PREFIXED ("<bytes>:<value>") before joining, which
  # makes the encoding injective: a literal "\r" inside a value cannot fuse
  # two different key tuples into one string. Plain paste(sep = "\r") could --
  # ("a\rb", "c") and ("a", "b\rc") produced the same key, and the ledger then
  # counted matches merge() never made, tripping `conserved` with a message
  # blaming this package for the caller's data.
  enc <- lapply(d[cols], function(v) {
    v <- as.character(v)   # paste() coerced silently; nchar() will not
    paste0(nchar(v, type = "bytes"), ":", v)
  })
  k <- do.call(paste, c(enc, list(sep = "\r")))
  k[Reduce(`|`, lapply(d[cols], is.na))] <- NA
  k
}

# merge() joins MULTI-column keys by paste()-ing them with "\r" internally,
# so two different key tuples whose pasted forms coincide FALSE-MATCH:
# ("a\rb", "c") against ("a", "b\rc") is the measured case, and it produced a
# clean-looking wrong join. Single-column keys are safe -- no paste, exact
# comparison -- which is why only the multi-column path needs this. Merging on
# key_paste()'s injective encoding cannot collide; the real key columns are
# then rebuilt by coalescing the two sides, reproducing merge()'s schema
# (by.x names first, then x columns, then y columns).
.coalesce_key <- function(xv, yv) {
  if (is.factor(xv) || is.factor(yv)) {
    lx <- if (is.factor(xv)) levels(xv) else unique(xv[!is.na(xv)])
    ly <- if (is.factor(yv)) levels(yv) else unique(yv[!is.na(yv)])
    v <- ifelse(is.na(xv), as.character(yv), as.character(xv))
    return(factor(v, levels = union(lx, ly)))
  }
  miss <- is.na(xv)
  out <- xv
  out[miss] <- yv[miss]
  out
}

.ledger_merge_multi <- function(xc, yc, bx, by_y, kind) {
  tmp <- "..ledger_key"
  while (tmp %in% c(names(xc), names(yc))) tmp <- paste0(".", tmp)
  xc[[tmp]] <- key_paste(xc, bx)
  yc[[tmp]] <- key_paste(yc, by_y)
  out <- merge(xc, yc, by = tmp,
               all.x = kind %in% c("left", "full"),
               all.y = kind %in% c("right", "full"))
  out[[tmp]] <- NULL
  # Locate each key pair's columns: merge() suffixes any name present on both
  # sides, and with `by = tmp` every shared name collides.
  xk <- ynk <- character(length(bx))
  for (i in seq_along(bx)) {
    xk[i] <- if (bx[i] %in% names(yc)) paste0(bx[i], ".x") else bx[i]
    ynk[i] <- if (by_y[i] %in% names(xc)) paste0(by_y[i], ".y") else by_y[i]
  }
  keys <- lapply(seq_along(bx), function(i) {
    .coalesce_key(out[[xk[i]]], out[[ynk[i]]])
  })
  names(keys) <- bx
  out <- out[, setdiff(names(out), c(xk, ynk)), drop = FALSE]
  out <- cbind(as.data.frame(keys, stringsAsFactors = FALSE), out)
  # merge() sorted by its internal pasted key, not by the tuple -- re-sort on
  # the rebuilt columns so row order means the same thing as a real merge.
  ord <- do.call(order, c(lapply(out[bx], identity),
                        list(method = "radix", na.last = TRUE)))
  out <- out[ord, , drop = FALSE]
  rownames(out) <- NULL
  out
}

#' The accounting for one join, from its inputs and its output
#'
#' Pure arithmetic, engine-agnostic: hand it the two inputs, the result, and
#' the keys -- from [ledgered_join()], from a dplyr pipeline, from anything
#' -- and it returns the one-row ledger. The load-bearing column is
#' `conserved`: the row count the join SHOULD have produced is recomputed
#' from the inputs (matched pairs plus whatever the join kind keeps), and
#' `conserved` says whether the output actually has it. `FALSE` means rows
#' were lost or manufactured somewhere the call site cannot see -- including
#' by an engine that matched NA keys to each other.
#'
#' Accumulate entries with `rbind()` across a pipeline and ship the frame
#' with the study: it is the row-count reconciliation table a reviewer can
#' read without running anything.
#'
#' @param x,y the join inputs.
#' @param out the join result.
#' @param by character: shared key columns, or a named vector mapping x
#'   columns to y columns (`c(npi = "provider_npi")`).
#' @param kind `"left"`, `"inner"`, `"full"`, or `"right"`.
#' @param step a label for the ledger -- which join, in which script.
#' @return one-row data.frame: `step`, `kind`, `by`, `rows_x`, `rows_y`,
#'   `rows_out`, `rows_expected`, `matched_pairs`, `unmatched_x`,
#'   `unmatched_y`, `na_key_x`, `na_key_y`, `match_rate_x`, `max_fanout`,
#'   `conserved`. NA-key rows count as unmatched on their side, never as
#'   matched: absence is not evidence of anything, including a match.
#' @export
join_ledger_entry <- function(x, y, out, by, kind, step = "join") {
  kind <- match.arg(kind, c("left", "inner", "full", "right"))
  bx <- if (is.null(names(by))) by else
    ifelse(nzchar(names(by)), names(by), by)
  by_y <- unname(by)
  kx <- key_paste(x, bx); ky <- key_paste(y, by_y)
  tx <- table(kx[!is.na(kx)]); ty <- table(ky[!is.na(ky)])
  shared <- intersect(names(tx), names(ty))
  matched_pairs <- sum(as.numeric(tx[shared]) * as.numeric(ty[shared]))
  unmatched_x <- sum(is.na(kx)) + sum(tx[setdiff(names(tx), shared)])
  unmatched_y <- sum(is.na(ky)) + sum(ty[setdiff(names(ty), shared)])
  expected <- matched_pairs +
    (if (kind %in% c("left", "full")) unmatched_x else 0) +
    (if (kind %in% c("right", "full")) unmatched_y else 0)
  fan <- if (length(shared)) {
    max(as.numeric(tx[shared]) * as.numeric(ty[shared]))
  } else 0
  data.frame(
    step = step, kind = kind,
    by = paste(ifelse(bx == by_y, bx, paste0(bx, "=", by_y)), collapse = "+"),
    rows_x = nrow(x), rows_y = nrow(y), rows_out = nrow(out),
    rows_expected = as.numeric(expected),
    matched_pairs = as.numeric(matched_pairs),
    unmatched_x = as.numeric(unmatched_x),
    unmatched_y = as.numeric(unmatched_y),
    na_key_x = sum(is.na(kx)), na_key_y = sum(is.na(ky)),
    match_rate_x = if (nrow(x)) (nrow(x) - unmatched_x) / nrow(x) else NA_real_,
    max_fanout = as.numeric(fan),
    conserved = nrow(out) == expected,
    stringsAsFactors = FALSE)
}

#' Join with the cardinality declared, verified, and ledgered
#'
#' A join whose row count cannot silently surprise you.
#'
#' * **The relationship is DECLARED and VERIFIED** -- dplyr 1.1's values,
#'   verbatim: `"one-to-one"`, `"one-to-many"`, `"many-to-one"`,
#'   `"many-to-many"`. A duplicate key on a side declared unique stops the
#'   run and names the offending keys. There is deliberately no default:
#'   declaring what the join may do to the row count is the point, and a
#'   guessed cardinality is how fan-out ships.
#' * **`unmatched = "error"`** (dplyr's semantics): stop if the join DROPS
#'   unmatched rows -- both sides for `"inner"`, the y side for `"left"`,
#'   the x side for `"right"`, nothing for `"full"` (it drops nothing).
#'   The default `"ledger"` records the counts and lets policy live with
#'   the caller.
#' * **`min_match_rate`**: the share of x rows that must match, for joins
#'   where silent loss is the risk. The default 0 is NOT a check -- that is
#'   the lesson of the deprecated isochrones safe_join, whose
#'   `expected_min = 0` let 100% data loss pass silently -- so an inner
#'   join in a pipeline should always declare one.
#' * **NA keys never match** (see the file header); by join kind they are
#'   kept as unmatched rows or dropped, and either way the ledger counts
#'   them.
#'
#' The result returns with its [join_ledger_entry()], and the entry's
#' `conserved` flag is additionally ASSERTED here -- a ledgered join that
#' fails its own arithmetic is a bug in this package, and stops.
#'
#' @param x,y data.frames.
#' @param by character: shared key columns, or a named vector mapping x
#'   columns to y columns.
#' @param kind `"left"`, `"inner"`, `"full"`, or `"right"`.
#' @param relationship required; verified, never assumed.
#' @param unmatched `"ledger"` (record) or `"error"` (stop when the join
#'   would drop unmatched rows).
#' @param min_match_rate stop when `match_rate_x` falls below this. 0 -- the
#'   default -- checks nothing, deliberately visibly.
#' @param step ledger label.
#' @return list of `result` (deterministically sorted by key) and `ledger`
#'   (one row). `rbind()` the ledgers across a pipeline.
#' @export
ledgered_join <- function(x, y, by, kind, relationship,
                          unmatched = c("ledger", "error"),
                          min_match_rate = 0, step = "join") {
  kind <- match.arg(kind, c("left", "inner", "full", "right"))
  unmatched <- match.arg(unmatched)
  if (missing(relationship)) {
    stop("relationship must be declared: one-to-one, one-to-many, ",
         "many-to-one or many-to-many. Declaring what the join may do to ",
         "the row count is the point.", call. = FALSE)
  }
  relationship <- match.arg(relationship, c("one-to-one", "one-to-many",
                                            "many-to-one", "many-to-many"))
  bx <- if (is.null(names(by))) by else
    ifelse(nzchar(names(by)), names(by), by)
  by_y <- unname(by)
  miss <- c(setdiff(bx, names(x)), setdiff(by_y, names(y)))
  if (length(miss)) {
    stop(sprintf("join keys missing: %s",
                 paste(unique(miss), collapse = ", ")), call. = FALSE)
  }
  kx <- key_paste(x, bx); ky <- key_paste(y, by_y)
  name_dups <- function(k, side) {
    d <- unique(k[!is.na(k) & duplicated(k)])
    stop(sprintf(
      "relationship '%s' declares %s keys unique, but %d repeat (e.g. %s)",
      relationship, side, length(d),
      paste(gsub("\r", "+", utils::head(d, 3)), collapse = ", ")),
      call. = FALSE)
  }
  if (relationship %in% c("one-to-one", "one-to-many") &&
      anyDuplicated(kx[!is.na(kx)])) name_dups(kx, "x")
  if (relationship %in% c("one-to-one", "many-to-one") &&
      anyDuplicated(ky[!is.na(ky)])) name_dups(ky, "y")

  # absence never joins: hold NA-key rows out, merge the rest
  xn <- x[is.na(kx), , drop = FALSE]; xc <- x[!is.na(kx), , drop = FALSE]
  yn <- y[is.na(ky), , drop = FALSE]; yc <- y[!is.na(ky), , drop = FALSE]
  out <- if (length(bx) == 1L) {
    merge(xc, yc, by.x = bx, by.y = by_y,
          all.x = kind %in% c("left", "full"),
          all.y = kind %in% c("right", "full"), sort = TRUE)
  } else {
    .ledger_merge_multi(xc, yc, bx, by_y, kind)
  }
  # Held-out rows are merged against an EMPTY slice of the other side, so
  # merge() itself assigns the .x/.y-suffixed names it gave the matched rows.
  # Padding the raw rows instead dropped every colliding column's value: a
  # shared non-key name like "note" arrives here as "note" but the template
  # only has "note.x"/"note.y", so the unmatched row's data silently became NA.
  if (kind %in% c("left", "full") && nrow(xn)) {
    xa <- merge(xn, yc[0, , drop = FALSE], by.x = bx, by.y = by_y,
                all.x = TRUE, all.y = FALSE, sort = TRUE)
    out <- rbind(out, xa[names(out)])
  }
  if (kind %in% c("right", "full") && nrow(yn)) {
    ya <- merge(xc[0, , drop = FALSE], yn, by.x = bx, by.y = by_y,
                all.x = FALSE, all.y = TRUE, sort = TRUE)
    out <- rbind(out, ya[names(out)])
  }
  rownames(out) <- NULL
  ledger <- join_ledger_entry(x, y, out, by, kind, step)
  if (!ledger$conserved) {
    stop(sprintf(paste0(
      "ledgered_join arithmetic violated at step '%s': expected %s rows, ",
      "got %d. This is a bug in mysterynpi; please report it."),
      step, format(ledger$rows_expected), nrow(out)), call. = FALSE)
  }
  drops_x <- kind %in% c("inner", "right")
  drops_y <- kind %in% c("inner", "left")
  if (identical(unmatched, "error")) {
    if (drops_x && ledger$unmatched_x > 0) {
      stop(sprintf("step '%s': %s drops %d unmatched x row(s), and unmatched = \"error\"",
                   step, kind, ledger$unmatched_x), call. = FALSE)
    }
    if (drops_y && ledger$unmatched_y > 0) {
      stop(sprintf("step '%s': %s drops %d unmatched y row(s), and unmatched = \"error\"",
                   step, kind, ledger$unmatched_y), call. = FALSE)
    }
  }
  if (min_match_rate > 0 && !is.na(ledger$match_rate_x) &&
      ledger$match_rate_x < min_match_rate) {
    stop(sprintf("step '%s': match rate %.3f below the declared minimum %.3f",
                 step, ledger$match_rate_x, min_match_rate), call. = FALSE)
  }
  list(result = out, ledger = ledger)
}
