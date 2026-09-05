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

# The grep above reads lines; this walks the parse tree, so aliasing evades
# nothing: `sd <- stringdist::stringdist` is caught at the `::` reference and
# a renamed wrapper is caught at its own call site when it calls the real
# thing. Pattern from the capability guard in mufflyt/mysterymaps: fuzzy
# machinery may not arrive without this file noticing.
test_that("the parse tree references no approximate-matching capability", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  banned_fns <- c("adist", "agrep", "agrepl", "stringdist", "stringsim",
                  "amatch", "stringdistmatrix", "jarowinkler", "soundex",
                  "nysiis", "metaphone", "phonetic", "fastLink",
                  "compare.dedup", "pair_blocking")
  banned_pkgs <- c("stringdist", "phonics", "RecordLinkage", "fastLink",
                   "reclin", "reclin2", "fuzzyjoin")
  refs <- new.env(parent = emptyenv())
  walk <- function(e) {
    if (is.call(e)) {
      h <- e[[1]]
      if (is.symbol(h)) assign(as.character(h), TRUE, refs)
      if (is.call(h) && is.symbol(h[[1]]) &&
          as.character(h[[1]]) %in% c("::", ":::")) {
        assign(as.character(h[[2]]), TRUE, refs)          # the package
        assign(as.character(h[[3]]), TRUE, refs)          # the function
      }
      if (is.symbol(h) && as.character(h) %in% c("::", ":::")) {
        assign(as.character(e[[2]]), TRUE, refs)
        assign(as.character(e[[3]]), TRUE, refs)
      }
      # empty args (x[, 1]) must be tested by INDEX, never bound to a loop
      # variable -- evaluating a name bound to the empty symbol is itself the
      # missing-argument error
      args <- as.list(e)[-1]
      for (i in seq_along(args)) {
        if (!identical(args[[i]], quote(expr = ))) walk(args[[i]])
      }
    } else if (is.function(e)) {
      walk(body(e))
    } else if (is.pairlist(e) || is.expression(e)) {
      for (i in seq_along(e)) walk(e[[i]])
    }
  }
  for (f in files) walk(parse(f, keep.source = FALSE))
  seen <- ls(refs)
  expect_identical(intersect(seen, banned_fns), character(0))
  expect_identical(intersect(seen, banned_pkgs), character(0))
})

# The two guards above read SOURCE files, which are absent when tests run
# against the installed package under R CMD check -- there they skip, and a
# skipped guard proves nothing on the day it matters (loudness rule from
# derek73/python-nameparser's ja-extra CI job). This walk inspects the
# INSTALLED namespace's function bodies, so it runs everywhere, always.
test_that("no function in the installed namespace references fuzzy machinery", {
  ns <- asNamespace("mysterynpi")
  fns <- Filter(is.function, mget(ls(ns, all.names = TRUE), envir = ns,
                                  ifnotfound = list(NULL)))
  seen <- unique(unlist(lapply(fns, referenced_symbols)))
  banned <- c("adist", "agrep", "agrepl", "stringdist", "stringsim",
              "amatch", "stringdistmatrix", "jarowinkler", "soundex",
              "nysiis", "metaphone", "phonetic", "fastLink",
              "compare.dedup", "pair_blocking",
              "phonics", "RecordLinkage", "reclin", "reclin2", "fuzzyjoin")
  expect_identical(intersect(seen, banned), character(0))
  expect_gt(length(fns), 30)     # the guard must actually be seeing the package
})

test_that("the package declares no approximate-matching dependency", {
  d <- read.dcf(system.file("DESCRIPTION", package = "mysterynpi"))
  deps <- paste(d[, intersect(colnames(d), c("Imports", "Depends", "LinkingTo"))],
                collapse = " ")
  expect_false(grepl("stringdist|fuzzyjoin|RecordLinkage|reclin", deps))
})
