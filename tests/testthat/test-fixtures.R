# Every fixture must say where it came from, and a fixture nobody registered
# must fail loudly. Pattern from howardjp/phonics (BSD-2-Clause),
# tests/testthat/test-fixtures.R, whose provenance registry maps each
# reference CSV to its origin and whose meta-test keeps the mapping honest --
# including the honest label "original source unrecorded" when that is true.

fixture_provenance <- c(
  "golden/verdicts.csv" =
    "hand-adjudicated synthetic verdict corpus; contract and per-row sources in its header",
  "humaniformat_boundary.csv" =
    "recorded humaniformat::parse_names() outputs, 2026-09-05; vendor-boundary tripwire",
  "golden/snapshot.csv" =
    "generated verdict snapshot; regenerate only deliberately via data-raw/verdict_snapshot.R")

fixture_dir <- testthat::test_path("fixtures")

test_that("every fixture file is registered, and every registration exists", {
  found <- list.files(fixture_dir, recursive = TRUE)
  expect_setequal(found, names(fixture_provenance))
})

test_that("every fixture opens with a provenance header", {
  for (f in names(fixture_provenance)) {
    head <- readLines(file.path(fixture_dir, f), n = 20, warn = FALSE)
    expect_true(startsWith(head[1], "##"),
                label = sprintf("%s starts with a header comment", f))
    expect_true(any(grepl("Provenance:", head)),
                label = sprintf("%s names its provenance", f))
  }
})

test_that("fixtures are non-empty, character-clean, and duplicate-free", {
  for (f in names(fixture_provenance)) {
    d <- read.csv(file.path(fixture_dir, f), comment.char = "#",
                  colClasses = "character")
    expect_gt(nrow(d), 0)
    expect_false(anyNA(d), label = sprintf("%s has no NA cells", f))
    expect_identical(anyDuplicated(d), 0L,
                     label = sprintf("%s has no duplicate rows", f))
  }
})
