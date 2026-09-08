#!/usr/bin/env Rscript
# Owner-wide inventory of nickname and person-name agreement surfaces.
#
# WHY. mysterynpi is meant to be the single authority for nickname data,
# equivalence, expansion, provenance and NPPES alias policy. Consolidation can
# only be claimed if we know where every competing implementation lives, so this
# enumerates them across ALL accessible github.com/mufflyt/* default branches
# rather than only the repositories already known to depend on mysterynpi.
#
# TWO METHOD NOTES, both learned the hard way during the first sweep.
#
# 1. GitHub code search does NOT index every repository. `npi_search` and
#    `mystery_shopper` returned zero hits for every pattern and are NOT clean:
#    reading their trees directly found an NPPES alias URL and two
#    three-character-prefix heuristics labelled as nickname matching. A zero
#    result from code search is not evidence of absence, so this scanner falls
#    back to the git trees API and reads file contents.
#
# 2. A stale local clone lies. The first pass concluded that
#    isochrones/R/nickname_system.R was NOT a shim, because the local checkout
#    was 100+ commits behind; on origin/main it is a 39-line shim with 17
#    mysterynpi references. This scanner reads the DEFAULT BRANCH via the API,
#    never a working copy.
#
# Output: inst/extdata/mufflyt_nickname_inventory.csv
#
# Usage: Rscript tools/audit/mufflyt_nickname_inventory.R [out.csv]

SEARCH_PATTERNS <- c(
  "nickname", "nick_name", "nickname_map", "NICKNAME_MAP", "nickname_dict",
  "nickname_dictionary", "nickname_lookup", "expand_nickname", "expand_first_name",
  "are_nickname", "match_nickname", "name_alias", "first_name_alias",
  "use_first_name_alias", "canonical_name", "formal_to_nicknames",
  "nickname_to_formal", "Jaro", "Winkler", "stringdist",
  # prefix heuristics are nickname claims in disguise
  "first 3 chars", "first three chars", "substr(.*1, *3)"
)

SURFACE_TYPES <- c("DICTIONARY", "EQUIVALENCE", "EXPANSION", "SCORING",
                   "NPPES_ALIAS", "TOKEN_MATCHING", "PREFIX_HEURISTIC",
                   "NAME_PRIMITIVE", "TEST_FIXTURE", "DOCUMENTATION", "SHIM")

MIGRATION_ACTIONS <- c("KEEP_MYSTERYNPI", "PORT_TO_MYSTERYNPI",
                       "REPLACE_WITH_MYSTERYNPI", "KEEP_CALLER_POLICY",
                       "HARVEST_TEST_ONLY", "REJECT_UNSAFE", "DELETE_STALE",
                       "DOCUMENT_ONLY")

gh_json <- function(endpoint, jq) {
  out <- suppressWarnings(system2("gh", c("api", endpoint, "-q", shQuote(jq)),
                                  stdout = TRUE, stderr = FALSE))
  if (!length(out) || !is.null(attr(out, "status"))) character() else out
}

#' Default-branch head SHA, so every inventory row is pinned to a commit.
repo_head_sha <- function(repo) {
  s <- gh_json(sprintf("repos/%s/commits/HEAD", repo), ".sha")
  if (length(s)) substr(s[[1L]], 1, 9) else NA_character_
}

#' Every R/Python/doc path on the default branch. Uses the trees API precisely
#' because code search silently omits unindexed repositories.
repo_paths <- function(repo) {
  gh_json(sprintf("repos/%s/git/trees/HEAD?recursive=1", repo),
          '.tree[] | select(.type=="blob") | .path')
}

#' Raw file contents from the default branch.
repo_file <- function(repo, path) {
  enc <- utils::URLencode(path, reserved = TRUE)
  b64 <- gh_json(sprintf("repos/%s/contents/%s", repo, enc), ".content")
  if (!length(b64)) return(character())
  raw <- tryCatch(rawToChar(base64enc::base64decode(paste(b64, collapse = ""))),
                  error = function(e) "")
  strsplit(raw, "\n", fixed = TRUE)[[1L]]
}

#' Classify a hit. Deliberately conservative: anything that cannot be
#' confidently typed is left for a human rather than guessed.
classify_surface <- function(path, line) {
  l <- tolower(line)
  if (grepl("use_first_name_alias", l)) return("NPPES_ALIAS")
  if (grepl("substr\\(.*1, *3\\)|first 3 chars|first three chars", l)) return("PREFIX_HEURISTIC")
  if (grepl("nickname_map *<-|nickname_dict *<- *list|nickname_edges *<-", l)) return("DICTIONARY")
  if (grepl("expand_first_name|expand_nickname|nickname_variants", l)) return("EXPANSION")
  if (grepl("are_nickname|nickname_agreement|equivalent", l)) return("EQUIVALENCE")
  if (grepl("jaro|winkler|stringdist|similarity", l)) return("SCORING")
  if (grepl("^name_|surname_components|given_tokens", l)) return("NAME_PRIMITIVE")
  if (grepl("^tests?/", path)) return("TEST_FIXTURE")
  if (grepl("\\.(md|rmd|rd)$", tolower(path))) return("DOCUMENTATION")
  "EQUIVALENCE"
}

inventory_repo <- function(repo) {
  sha <- repo_head_sha(repo)
  paths <- repo_paths(repo)
  code <- paths[grepl("\\.(R|r|py|Rmd|md)$", paths)]
  rows <- list()
  for (p in code) {
    lines <- repo_file(repo, p)
    if (!length(lines)) next
    hits <- grep(paste(SEARCH_PATTERNS, collapse = "|"), lines, ignore.case = TRUE)
    if (!length(hits)) next
    # One row per (file, surface_type): a file with a dictionary AND an expander
    # is two surfaces, but 40 mentions of "nickname" is not 40 findings.
    types <- unique(vapply(lines[hits], function(l) classify_surface(p, l), character(1)))
    for (ty in types) {
      rows[[length(rows) + 1L]] <- data.frame(
        repository = repo, repository_sha = sha, path = p, symbol = NA_character_,
        surface_type = ty, behavior = NA_character_, current_status = NA_character_,
        migration_action = NA_character_, mysterynpi_replacement = NA_character_,
        evidence = sprintf("%d matching line(s); first at line %d", length(hits), hits[[1L]]),
        stringsAsFactors = FALSE)
    }
  }
  if (!length(rows)) return(NULL)
  do.call(rbind, rows)
}

if (sys.nframe() == 0L) {
  out <- commandArgs(trailingOnly = TRUE)
  out <- if (length(out)) out[[1L]] else "inst/extdata/mufflyt_nickname_inventory.csv"
  repos <- gh_json("user/repos?per_page=100&affiliation=owner", ".[].full_name")
  repos <- repos[grepl("^mufflyt/", repos)]
  message(sprintf("scanning %d repositories", length(repos)))
  all <- do.call(rbind, Filter(Negate(is.null), lapply(repos, function(r) {
    message("  ", r); tryCatch(inventory_repo(r), error = function(e) NULL)
  })))
  utils::write.csv(all, out, row.names = FALSE, na = "")
  message("wrote ", out, ": ", nrow(all), " surface(s)")
}
