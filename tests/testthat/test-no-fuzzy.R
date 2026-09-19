# The package makes exact claims about identity, and an approximate-matching
# call ANYWHERE in it is a defect, not a feature. One was added to a verdict
# and removed inside a single day (it admitted JULIA/JULIE, LEE/LEA and
# ANN/ANNE as non-conflicts); a "fenced" scoring exception lived here during
# 2026-09 and was REMOVED by owner ruling on 2026-09-19: mysterynpi must not
# provide fuzzy person-name matching in any form - no option, no deprecated
# export, no dark-by-default capability. Exact normalisation, declared
# nickname equivalence, initials, documented surname history and structured
# evidence are the identity architecture; approximate spelling similarity is
# not.
#
# So the guard returns to its original, stronger shape: NO fuzzy machinery
# anywhere in the package, with NO exempt module - source scan, parse-tree
# scan, and call-graph reachability over the installed namespace. A mutation
# in the campaign (middle-agreement-reintroduces-edit-distance) proves the
# guard fires on a direct reintroduction.

BANNED_FNS <- c("adist", "agrep", "agrepl", "stringdist", "stringsim",
                "amatch", "stringdistmatrix", "jarowinkler", "soundex",
                "nysiis", "metaphone", "phonetic", "fastLink",
                "compare.dedup", "pair_blocking",
                # the two exports deleted 2026-09-19; re-vendoring them is
                # reintroduction, and the guard catches it by name
                "calculate_enhanced_first_name_similarity",
                "create_nickname_aware_similarity",
                "surname_similarity", "middle_name_similarity",
                "given_name_similarity")
BANNED_PKGS <- c("stringdist", "phonics", "RecordLinkage", "fastLink",
                 "reclin", "reclin2", "fuzzyjoin")

test_that("no source file anywhere touches approximate matching", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  src <- unlist(lapply(files, readLines, warn = FALSE))
  code <- grep("^\\s*#", src, value = TRUE, invert = TRUE)
  for (fn in BANNED_FNS) {
    hits <- grep(paste0("\\b", fn, "\\s*\\("), code, value = TRUE)
    expect_identical(hits, character(0),
                     info = sprintf("%s() called somewhere in R/", fn))
  }
})

test_that("no parse tree anywhere references fuzzy capability", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  seen <- unique(unlist(lapply(files, function(f)
    referenced_symbols(parse(f, keep.source = FALSE)))))
  expect_identical(intersect(seen, BANNED_FNS), character(0))
  expect_identical(intersect(seen, BANNED_PKGS), character(0))
})

# Reachability over the installed namespace: with the engine gone there is
# nothing to fence, but the walk stays - it is what catches a reintroduction
# that hides behind indirection, and the mutation campaign proves it fires.
test_that("no function in the namespace can reach fuzzy machinery, transitively", {
  ns <- asNamespace("mysterynpi")
  fns <- Filter(is.function, mget(ls(ns, all.names = TRUE), envir = ns,
                                  ifnotfound = list(NULL)))
  refs <- lapply(fns, referenced_symbols)
  reachable <- character(0)
  frontier <- names(fns)
  while (length(frontier)) {
    new_syms <- setdiff(unique(unlist(refs[frontier])), reachable)
    reachable <- c(reachable, new_syms)
    frontier <- intersect(new_syms, names(fns))
  }
  expect_identical(intersect(reachable, BANNED_FNS), character(0))
  expect_identical(intersect(reachable, BANNED_PKGS), character(0))
  # POSITIVE CONTROL for the walker itself: a symbol we know is referenced
  # must appear, or an empty banned intersection would also be produced by a
  # broken walker that sees nothing.
  expect_true("normalize_string" %in% reachable)
  expect_gt(length(fns), 40)
})

test_that("no approximate-matching dependency is declared anywhere", {
  d <- read.dcf(system.file("DESCRIPTION", package = "mysterynpi"))
  all_deps <- paste(d[, intersect(colnames(d),
                                  c("Imports", "Depends", "LinkingTo",
                                    "Suggests", "Enhances"))],
                    collapse = " ")
  expect_false(grepl("stringdist|fuzzyjoin|RecordLinkage|reclin|phonics",
                     all_deps))
})
