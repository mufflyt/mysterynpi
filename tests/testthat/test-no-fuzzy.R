# The package makes exact claims about identity. An approximate-matching call
# anywhere in it is a defect, not a feature -- one was added and removed inside
# a single day, and it admitted JULIA/JULIE, LEE/LEA and ANN/ANNE as
# non-conflicts. This test is the reason it cannot come back quietly.

test_that("no approximate string matching is called anywhere in the package", {
  src <- unlist(lapply(list.files("../../R", pattern = "[.]R$", full.names = TRUE),
                       readLines, warn = FALSE))
  if (!length(src)) skip("source not reachable from the installed package")
  code <- grep("^\\s*#", src, value = TRUE, invert = TRUE)
  banned <- c("adist", "agrep", "stringdist", "stringsim",
              "jarowinkler", "levenshtein", "soundex", "metaphone")
  for (fn in banned) {
    hits <- grep(paste0("\\b", fn, "\\s*\\("), code, value = TRUE)
    expect_identical(hits, character(0),
                     info = sprintf("%s() is called in package source", fn))
  }
})

test_that("the package declares no approximate-matching dependency", {
  d <- read.dcf(system.file("DESCRIPTION", package = "mysterynpi"))
  deps <- paste(d[, intersect(colnames(d), c("Imports", "Depends", "LinkingTo"))],
                collapse = " ")
  expect_false(grepl("stringdist|fuzzyjoin|RecordLinkage|reclin", deps))
})
