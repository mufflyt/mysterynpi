# Every documented topic must appear in the pkgdown reference index.
#
# pkgdown's build_reference_index() fails the whole site build when a topic has
# an .Rd file but no entry, and the error names the topic without saying that
# the index is the thing at fault. That is how exporting
# nickname_dictionary_version broke the pkgdown check on 2026-09-09: the export
# and its documentation were correct, and the omission was one line in
# _pkgdown.yml.
#
# This is the class rather than the instance: any future export hits the same
# wall, and this test names the cause instead of leaving it to be rediscovered
# from a build log.

testthat::test_that("every man/*.Rd topic is listed in the pkgdown index", {
  root <- rprojroot::find_root(rprojroot::has_file("DESCRIPTION"))
  idx <- yaml::yaml.load_file(file.path(root, "_pkgdown.yml"))
  listed <- trimws(unique(unlist(lapply(idx$reference, function(s) s$contents))))
  rd <- tools::file_path_sans_ext(list.files(file.path(root, "man"), pattern = "[.]Rd$"))

  missing <- setdiff(rd, listed)
  testthat::expect_equal(
    missing, character(0),
    info = paste0("These topics have documentation but no _pkgdown.yml entry, ",
                  "which fails the pkgdown build: ", paste(missing, collapse = ", ")))
})

testthat::test_that("the index does not list topics that no longer exist", {
  # The mirror failure: a stale entry for a deleted topic also breaks the build.
  root <- rprojroot::find_root(rprojroot::has_file("DESCRIPTION"))
  idx <- yaml::yaml.load_file(file.path(root, "_pkgdown.yml"))
  listed <- trimws(unique(unlist(lapply(idx$reference, function(s) s$contents))))
  listed <- listed[!grepl("^(starts_with|ends_with|matches|has_concept)\\(", listed)]
  rd <- tools::file_path_sans_ext(list.files(file.path(root, "man"), pattern = "[.]Rd$"))

  stale <- setdiff(listed, rd)
  testthat::expect_equal(
    stale, character(0),
    info = paste0("Listed in _pkgdown.yml but no matching man/*.Rd: ",
                  paste(stale, collapse = ", ")))
})

testthat::test_that("the accessor this test was written for is indexed", {
  # Negative control for the specific defect, so a regression is unambiguous.
  root <- rprojroot::find_root(rprojroot::has_file("DESCRIPTION"))
  idx <- yaml::yaml.load_file(file.path(root, "_pkgdown.yml"))
  listed <- trimws(unique(unlist(lapply(idx$reference, function(s) s$contents))))
  testthat::expect_true("nickname_dictionary_version" %in% listed)
})
