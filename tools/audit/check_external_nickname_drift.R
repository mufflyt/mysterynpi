#!/usr/bin/env Rscript

repo_names <- c(
  "mysterynpi",
  "isochrones",
  "midwifery",
  "obgyns",
  "npi_search",
  "mystery_shopper"
)

script_path <- tryCatch(normalizePath(sys.frame(1)$ofile), error = function(e) NA_character_)
repo_root <- if (!is.na(script_path)) {
  normalizePath(file.path(dirname(script_path), "..", ".."))
} else {
  normalizePath(".")
}

scan_root <- Sys.getenv("MUFFLYT_NICKNAME_SCAN_ROOT")
if (!nzchar(scan_root)) {
  candidate <- "/Users/tylermuffly/nickname-consolidation-worktrees"
  scan_root <- if (dir.exists(candidate)) candidate else dirname(repo_root)
}
scan_root <- normalizePath(scan_root, mustWork = FALSE)

allowlist_path <- file.path(repo_root, "inst", "extdata",
                            "external_nickname_allowlist.csv")
allowlist <- if (file.exists(allowlist_path)) {
  utils::read.csv(allowlist_path, stringsAsFactors = FALSE)
} else {
  data.frame(repository = character(), path = character(), pattern = character(),
             reason = character(), expires = character())
}

required_allowlist_cols <- c("repository", "path", "pattern", "reason", "expires")
if (!all(required_allowlist_cols %in% names(allowlist))) {
  stop("external nickname allowlist has the wrong schema", call. = FALSE)
}
if (nrow(allowlist)) {
  bad <- !nzchar(allowlist$reason) | !nzchar(allowlist$expires)
  if (any(bad)) {
    stop("every nickname drift allowlist row requires reason and expires",
         call. = FALSE)
  }
}

patterns <- data.frame(
  pattern_name = c(
    "local nickname map",
    "local nickname map",
    "local nickname dictionary",
    "local nickname lookup",
    "local nickname lookup builder",
    "NPPES alias TRUE",
    "local nickname expander",
    "local nickname variants implementation",
    "midwifery isochrones nickname layer",
    "prefix labelled as nickname"
  ),
  regex = c(
    "\\bNICKNAMES?(_MAP)?\\s*<-",
    "\\bnickname_map\\s*<-\\s*list\\s*\\(",
    "\\bnickname_dict\\s*<-\\s*list\\s*\\(",
    "\\bnickname_lookup\\s*<-",
    "\\.build_nickname_lookup\\b",
    "use_first_name_alias\\s*=\\s*(TRUE|True|true|['\"]TRUE['\"]|['\"]True['\"]|['\"]true['\"])",
    "\\bexpand_first_name\\s*<-\\s*function\\b",
    "\\bnickname_variants\\s*<-\\s*function\\b",
    "source\\s*\\([^\\n]*nickname_system[.]R",
    "(nickname(.|\\n){0,160}substr\\s*\\([^\\n]*,\\s*1\\s*,\\s*3\\s*\\)|substr\\s*\\([^\\n]*,\\s*1\\s*,\\s*3\\s*\\)(.|\\n){0,160}nickname)"
  ),
  stringsAsFactors = FALSE
)
patterns$repository_scope <- NA_character_
patterns$repository_scope[
  patterns$pattern_name == "midwifery isochrones nickname layer"
] <- "midwifery"

is_text_file <- function(path) {
  grepl("[.](R|r|ya?ml|json)$", path) |
    basename(path) %in% c("DESCRIPTION", "NAMESPACE")
}

is_production_path <- function(path) {
  if (grepl("(^|/)(tests?|testthat|fixtures|docs|doc|vignettes|man)/", path)) {
    return(FALSE)
  }
  if (grepl("(^|/)README([.]md|[.]html)?$", path, ignore.case = TRUE)) {
    return(FALSE)
  }
  TRUE
}

is_allowed <- function(repo, path, pattern_name) {
  if (!nrow(allowlist)) return(FALSE)
  any(allowlist$repository == repo &
        allowlist$path == path &
        allowlist$pattern == pattern_name)
}

hits <- list()
for (repo in repo_names) {
  repo_dir <- file.path(scan_root, repo)
  if (!dir.exists(repo_dir)) next
  files <- list.files(repo_dir, recursive = TRUE, all.files = TRUE,
                      full.names = TRUE, no.. = TRUE)
  files <- files[file.exists(files)]
  files <- files[!grepl("(^|/)([.]git|renv|packrat|data|outputs|cache|logs)/",
                        files)]
  files <- files[is_text_file(files)]
  info <- file.info(files)
  files <- files[!is.na(info$size) & info$size < 1000000L & !info$isdir]

  for (file in files) {
    rel <- sub(paste0("^", gsub("([\\W])", "\\\\\\1", repo_dir), "/?"), "", file)
    if (repo == "mysterynpi") next
    if (!is_production_path(rel)) next

    text <- tryCatch(readLines(file, warn = FALSE), error = function(e) character())
    if (!length(text)) next
    collapsed <- paste(text, collapse = "\n")
    for (i in seq_len(nrow(patterns))) {
      scope <- patterns$repository_scope[i]
      if (!is.na(scope) && !identical(repo, scope)) next
      if (grepl(patterns$regex[i], collapsed, perl = TRUE)) {
        if (!is_allowed(repo, rel, patterns$pattern_name[i])) {
          hits[[length(hits) + 1L]] <- data.frame(
            repository = repo,
            path = rel,
            pattern = patterns$pattern_name[i],
            stringsAsFactors = FALSE
          )
        }
      }
    }
  }
}

hits <- if (length(hits)) do.call(rbind, hits) else data.frame(
  repository = character(),
  path = character(),
  pattern = character()
)

cat("scan_root:", scan_root, "\n")
cat("repositories_seen:", paste(repo_names[file.exists(file.path(scan_root, repo_names))],
                                collapse = ","), "\n")
cat("drift_hits:", nrow(hits), "\n")
if (nrow(hits)) {
  print(hits)
  quit(status = 1L)
}
cat("owner-wide nickname drift scan: PASS\n")
