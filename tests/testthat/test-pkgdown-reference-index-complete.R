# Every documented topic must appear in the pkgdown reference index.
#
# pkgdown's build_reference_index() fails the whole site build when a topic has
# an .Rd file but no entry, and the error names the topic without saying that
# the index is the thing at fault. That is how exporting
# nickname_dictionary_version broke the pkgdown check on 2026-09-09: the export
# and its documentation were correct, and the omission was one line in
# _pkgdown.yml.
#
# Deliberately uses NEITHER rprojroot NOR yaml. Adding a package to Suggests for
# one structural test raises "unstated dependencies in tests" in R CMD check on
# every platform, which is what the first version of this file did. The index
# entries are plain "  - topic" lines, so readLines is enough.

.idx_root <- function() {
  # The source tree is present when tests run from the repo, and absent when
  # R CMD check runs against an installed package. Skip rather than fail there:
  # this test is about repository structure, not installed behaviour.
  candidates <- c(testthat::test_path("..", ".."), ".", "..")
  for (p in candidates) {
    if (file.exists(file.path(p, "_pkgdown.yml")) && dir.exists(file.path(p, "man"))) {
      return(p)
    }
  }
  NULL
}

.idx_listed <- function(root) {
  ln <- readLines(file.path(root, "_pkgdown.yml"), warn = FALSE)
  hits <- grep("^\\s*-\\s+[A-Za-z._][A-Za-z0-9._]*\\s*$", ln, value = TRUE)
  topics <- trimws(sub("^\\s*-\\s+", "", hits))
  unique(topics)
}

.idx_rd <- function(root) {
  tools::file_path_sans_ext(list.files(file.path(root, "man"), pattern = "[.]Rd$"))
}

testthat::test_that("every man/*.Rd topic is listed in the pkgdown index", {
  root <- .idx_root()
  testthat::skip_if(is.null(root), "source tree not present (installed-package check)")
  missing <- setdiff(.idx_rd(root), .idx_listed(root))
  testthat::expect_equal(
    missing, character(0),
    info = paste0("Documented but absent from _pkgdown.yml, which fails the ",
                  "pkgdown build: ", paste(missing, collapse = ", ")))
})

testthat::test_that("the index does not list topics that no longer exist", {
  # The mirror failure: a stale entry for a deleted topic breaks the build too.
  root <- .idx_root()
  testthat::skip_if(is.null(root), "source tree not present (installed-package check)")
  stale <- setdiff(.idx_listed(root), .idx_rd(root))
  testthat::expect_equal(
    stale, character(0),
    info = paste0("Listed in _pkgdown.yml with no matching man/*.Rd: ",
                  paste(stale, collapse = ", ")))
})

testthat::test_that("the accessor this test was written for is indexed", {
  # Negative control for the specific defect, so a regression is unambiguous.
  root <- .idx_root()
  testthat::skip_if(is.null(root), "source tree not present (installed-package check)")
  testthat::expect_true("nickname_dictionary_version" %in% .idx_listed(root))
})
