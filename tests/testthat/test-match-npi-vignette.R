vignette_source <- function() {
  candidates <- c(testthat::test_path("..", "..", "vignettes", "end-to-end-nppes-matching.Rmd"),
                  system.file("doc", "end-to-end-nppes-matching.Rmd", package = "mysterynpi"))
  candidates <- candidates[nzchar(candidates) & file.exists(candidates)]
  if (!length(candidates)) skip("vignette source is not available in this checkout")
  candidates[[1L]]
}

test_that("the end-to-end vignette carries the required sections and stays synthetic", {
  text <- readLines(vignette_source(), encoding = "UTF-8")
  source <- paste(text, collapse = "\n")
  # Two Mermaid flowcharts: the data paths and the evidence/resolution policy.
  expect_gte(sum(grepl("^```mermaid", text)), 2L)
  expect_match(source, "flowchart LR", fixed = TRUE)
  expect_match(source, "flowchart TD", fixed = TRUE)
  # Both backends are demonstrated; the DuckDB source is reopened read-only.
  expect_match(source, "match_npi(\n  roster, nppes,", fixed = TRUE)
  expect_match(source, "match_npi(\n  roster, con, table = \"npidata\"", fixed = TRUE)
  expect_match(source, "read_only = TRUE", fixed = TRUE)
  expect_match(source, "identical(result_db$matches, result$matches)", fixed = TRUE)
  # Figures: the candidate funnel, dispositions, and mysterymaps state maps.
  expect_match(source, "{r funnel", fixed = TRUE)
  expect_match(source, "{r dispositions", fixed = TRUE)
  expect_match(source, "mysterymaps_geographic_map", fixed = TRUE)
  expect_match(source, "eval = maps_available", fixed = TRUE)
  # Explicit interpretation limits and the non-evaluated real-data examples.
  expect_match(source, "## What this does not do", fixed = TRUE)
  expect_match(source, "{r national-df, eval = FALSE}", fixed = TRUE)
  expect_match(source, "{r national-db, eval = FALSE}", fixed = TRUE)
  # Synthetic only: no network, no mounted drive, no private data in evaluated code.
  evaluated <- source
  evaluated <- gsub("```\\{r[^}]*eval = FALSE[^}]*\\}.*?```", "", evaluated)
  expect_false(grepl("/Volumes/|https?://|read_csv\\(\"npidata", evaluated))
  # The vignette's synthetic NPIs pass the package's validity check, except the
  # one row documented as deliberately invalid.
  npis <- regmatches(source, gregexpr("\"1[0-9]{9}\"", source))[[1]]
  npis <- unique(gsub("\"", "", npis))
  expect_identical(npis[!npi_luhn_ok(npis)], "1234567890")
})

test_that("the end-to-end vignette knits offline and its evaluated claims hold", {
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not_installed("duckdb")
  skip_if_not_installed("DBI")
  skip_if_not(rmarkdown::pandoc_available("2.0"), "pandoc is not available")
  source <- vignette_source()
  out_dir <- withr::local_tempdir()
  html <- rmarkdown::render(source, output_dir = out_dir, intermediates_dir = out_dir,
                            quiet = TRUE, envir = new.env(parent = globalenv()))
  expect_true(file.exists(html))
  rendered <- paste(readLines(html, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  # Pandoc's highlighter entity-escapes code output; compare against plain text.
  rendered <- gsub("&quot;", "\"", gsub("&lt;", "<", gsub("&gt;", ">", rendered, fixed = TRUE),
                                        fixed = TRUE), fixed = TRUE)
  # Both backends ran and agreed on every partition and on the candidates.
  expect_gte(lengths(regmatches(rendered, gregexpr("#> \\[1\\] TRUE", rendered))), 4L)
  expect_match(rendered, "state_evidence", fixed = TRUE)
  expect_match(rendered, "blocked_by_attribute", fixed = TRUE)
  expect_match(rendered, "#> [1] \"backend\" \"table\"", fixed = TRUE)
  # Every disposition reason the vignette explains appears in its own output.
  for (reason in c("unique_best_evidence", "nickname_only_evidence", "fuzzy_only_evidence",
                   "ambiguous_tied_evidence", "ambiguous_contested_candidate",
                   "missing_required_name", "no_candidate")) {
    expect_match(rendered, reason, fixed = TRUE)
  }
  # The funnel and disposition figures are embedded; the maps are embedded
  # when mysterymaps is installed and otherwise replaced by the documented note.
  figures <- regmatches(rendered, gregexpr("<img[^>]*alt=\"", rendered))[[1]]
  state_map <- tryCatch(getExportedValue("mysterymaps", "mysterymaps_geographic_map"),
                        error = function(e) NULL)
  maps_available <- !is.null(state_map) &&
    all(vapply(c("maps", "ggplot2"), requireNamespace, logical(1), quietly = TRUE))
  expect_identical(length(figures), if (maps_available) 4L else 2L)
  if (!maps_available) expect_match(rendered, "state maps", fixed = TRUE)
  expect_false(grepl("#> Warning", rendered, fixed = TRUE))
  expect_false(grepl("#> Error", rendered, fixed = TRUE))
})
