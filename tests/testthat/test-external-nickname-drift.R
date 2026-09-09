test_that("external nickname drift scanner passes when consumer repos are available", {
  repo_path <- function(...) {
    candidates <- c(
      file.path(...),
      file.path("..", "..", ...)
    )
    hits <- candidates[file.exists(candidates)]
    if (!length(hits)) return(candidates[[1]])
    normalizePath(hits[[1]], mustWork = FALSE)
  }
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
