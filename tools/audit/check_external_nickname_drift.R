#!/usr/bin/env Rscript
# =============================================================================
# Owner-wide nickname drift scan: consolidation must STAY consolidated
# =============================================================================
# mysterynpi is the single authority for nickname data, equivalence,
# expansion, provenance, and NPPES alias policy. This scanner walks every
# accessible mufflyt/* default branch (GitHub code search; needs `gh` auth)
# and FAILS on newly introduced production occurrences of the forbidden
# patterns below, unless the exact (repository, path, pattern) triple is
# allowlisted with a reason and an expiry in
# inst/extdata/external_nickname_allowlist.csv. No perpetual unexplained
# exception: an expired allowlist row fails the scan too.
#
# Run:  Rscript tools/audit/check_external_nickname_drift.R
# Exit: 0 clean, 1 drift found.
# =============================================================================

FORBIDDEN <- c(
  "NICKNAME_MAP",
  "nickname_map <- list",
  "nickname_dict <- list",
  "use_first_name_alias = TRUE",
  "use_first_name_alias=TRUE",
  '"use_first_name_alias", "True"',
  ".build_nickname_lookup")

allow <- utils::read.csv(
  file.path(dirname(sub("--file=", "", grep("--file=", commandArgs(),
                                            value = TRUE)[1])),
            "..", "..", "inst", "extdata",
            "external_nickname_allowlist.csv"),
  stringsAsFactors = FALSE, comment.char = "#")
today <- Sys.Date()
expired <- allow[as.Date(allow$expires) < today, , drop = FALSE]
fails <- 0L
if (nrow(expired)) {
  cat("EXPIRED allowlist rows (renew with a reason or remove the code):\n")
  print(expired[, c("repository", "path", "pattern", "expires")])
  fails <- fails + nrow(expired)
}
allow_key <- paste(allow$repository, allow$path, allow$pattern, sep = "|")

for (pat in FORBIDDEN) {
  res <- tryCatch(
    jsonlite::fromJSON(system2(
      "gh", c("api", "-X", "GET", "search/code",
              "-f", shQuote(paste0("q=", pat, " org:mufflyt"))),
      stdout = TRUE) |> paste(collapse = "\n"), simplifyVector = FALSE),
    error = function(e) NULL)
  Sys.sleep(7)   # code-search rate limit
  if (is.null(res) || is.null(res$items)) {
    cat("WARN: search failed for pattern '", pat, "' -- a failed search ",
        "is NOT a clean result\n", sep = "")
    fails <- fails + 1L
    next
  }
  for (it in res$items) {
    repo <- it$repository$name; path <- it$path
    key <- paste(repo, path, pat, sep = "|")
    # mysterynpi's own authoritative internals are structural allowlist
    if (identical(repo, "mysterynpi")) next
    if (key %in% allow_key) next
    cat(sprintf("DRIFT: %s %s contains forbidden pattern '%s'\n",
                repo, path, pat))
    fails <- fails + 1L
  }
}
if (fails) {
  cat(sprintf("\nRED: %d drift finding(s). Consolidation contract: nickname\n",
              fails),
      "data/equivalence/expansion/alias policy live ONLY in mysterynpi;\n",
      "consumers call its API. Allowlist additions need reason + expiry.\n")
  quit(status = 1L)
}
cat("GREEN: no unauthorized nickname surfaces on any mufflyt default branch\n")
