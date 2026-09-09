repo_path <- function(...) {
  candidates <- c(
    file.path(...),
    file.path("..", "..", ...)
  )
  hits <- candidates[file.exists(candidates)]
  if (!length(hits)) return(candidates[[1]])
  normalizePath(hits[[1]], mustWork = FALSE)
}

test_that("external nickname drift scanner passes when consumer repos are available", {
  scan_root <- Sys.getenv(
    "MUFFLYT_NICKNAME_SCAN_ROOT",
    "/Users/tylermuffly/nickname-consolidation-worktrees"
  )
  consumers <- c("isochrones", "midwifery", "obgyns", "npi_search",
                 "mystery_shopper")
  if (!dir.exists(scan_root) ||
      !any(file.exists(file.path(scan_root, consumers)))) {
    skip("consumer repository scan root is not available")
  }

  script <- repo_path("tools", "audit", "check_external_nickname_drift.R")
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", script),
    stdout = TRUE,
    stderr = TRUE
  )
  expect_identical(attr(result, "status"), NULL)
  expect_true(any(grepl("owner-wide nickname drift scan: PASS", result,
                        fixed = TRUE)))
})

test_that("external nickname drift scanner detects forbidden consumer patterns", {
  root <- file.path(tempdir(), paste0("nickname-drift-fixture-", Sys.getpid()))
  if (dir.exists(root)) unlink(root, recursive = TRUE)
  on.exit(unlink(root, recursive = TRUE), add = TRUE)

  write_fixture <- function(repo, path, lines) {
    file <- file.path(root, repo, path)
    dir.create(dirname(file), recursive = TRUE, showWarnings = FALSE)
    writeLines(lines, file)
  }

  write_fixture("isochrones", file.path("R", "strategies", "strategy_19_name_alias.R"),
                c("NICKNAME_MAP <- c(ELIZABETH = 'BETH')"))
  write_fixture("obgyns", file.path("R", "centralized_npi_matching.R"),
                c("nickname_map <- list(JOHN = 'JOHNNY')"))
  write_fixture("npi_search", file.path("R", "nppes.R"),
                c("params <- list(use_first_name_alias = TRUE)"))
  write_fixture("midwifery", file.path("R", "lib", "isochrones_dep.R"),
                c("source(file.path(ISOCHRONES_R, 'nickname_system.R'))"))
  write_fixture("mystery_shopper", file.path("R", "healthgrades.R"),
                c("# nickname rule based on first three characters",
                  "ok <- substr(first_clean, 1, 3) == substr(profile_clean, 1, 3)"))

  script <- repo_path("tools", "audit", "check_external_nickname_drift.R")
  result <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", script),
    stdout = TRUE,
    stderr = TRUE,
    env = paste0("MUFFLYT_NICKNAME_SCAN_ROOT=", root)
  )

  expect_false(is.null(attr(result, "status")))
  expect_true(any(grepl("drift_hits: 5", result, fixed = TRUE)))
  expect_true(any(grepl("local nickname map", result, fixed = TRUE)))
  expect_true(any(grepl("NPPES alias TRUE", result, fixed = TRUE)))
  expect_true(any(grepl("midwifery isochrones nickname layer", result,
                        fixed = TRUE)))
  expect_true(any(grepl("prefix labelled as nickname", result, fixed = TRUE)))
})
