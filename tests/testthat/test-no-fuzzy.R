# The package makes exact claims about identity, and an approximate-matching
# call in the VERDICT path is a defect, not a feature -- one was added and
# removed inside a single day, and it admitted JULIA/JULIE, LEE/LEA and
# ANN/ANNE as non-conflicts.
#
# Since 2026-09 the package also ships R/similarity_scoring.R: candidate-
# RANKING machinery (extracted from isochrones) that legitimately uses
# Jaro-Winkler, exactly as the README always allowed for the blocking stage.
# So the guard evolved from "no fuzzy anywhere" to the claim that actually
# matters, stated three ways below: fuzzy machinery exists ONLY inside the
# fenced scoring module, nothing outside the module references it, and no
# agreement verdict can REACH it through any call chain. A mutation in the
# campaign (middle-agreement-smuggles-similarity) proves the reachability
# guard fires on exactly the smuggling it exists for.

SCORING_MODULE <- "similarity_scoring.R"
BANNED_FNS <- c("adist", "agrep", "agrepl", "stringdist", "stringsim",
                "amatch", "stringdistmatrix", "jarowinkler", "soundex",
                "nysiis", "metaphone", "phonetic", "fastLink",
                "compare.dedup", "pair_blocking")
BANNED_PKGS <- c("stringdist", "phonics", "RecordLinkage", "fastLink",
                 "reclin", "reclin2", "fuzzyjoin")
SCORING_FNS <- c("create_nickname_dictionary", "get_nickname_dictionary",
                 "get_canonical_name", "are_nickname_equivalents",
                 "get_nicknames_for_name",
                 "calculate_enhanced_first_name_similarity",
                 "create_nickname_aware_similarity")

test_that("outside the fence, no source file touches approximate matching", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  files <- files[basename(files) != SCORING_MODULE]
  src <- unlist(lapply(files, readLines, warn = FALSE))
  code <- grep("^\\s*#", src, value = TRUE, invert = TRUE)
  for (fn in BANNED_FNS) {
    hits <- grep(paste0("\\b", fn, "\\s*\\("), code, value = TRUE)
    expect_identical(hits, character(0),
                     info = sprintf("%s() called outside %s", fn,
                                    SCORING_MODULE))
  }
})

test_that("outside the fence, no parse tree references fuzzy capability", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  files <- files[basename(files) != SCORING_MODULE]
  seen <- unique(unlist(lapply(files, function(f)
    referenced_symbols(parse(f, keep.source = FALSE)))))
  expect_identical(intersect(seen, BANNED_FNS), character(0))
  expect_identical(intersect(seen, BANNED_PKGS), character(0))
  # the fence has one gate: nothing outside the module calls into it
  expect_identical(intersect(seen, SCORING_FNS), character(0))
})

# The reachability guard: from every verdict function, walk the call graph
# through the installed namespace and assert no banned symbol is reachable.
# This runs against the INSTALLED package (never skips under R CMD check),
# and it is the guard the smuggling mutant must trip.
test_that("no agreement verdict can reach fuzzy machinery, transitively", {
  ns <- asNamespace("mysterynpi")
  fns <- Filter(is.function, mget(ls(ns, all.names = TRUE), envir = ns,
                                  ifnotfound = list(NULL)))
  refs <- lapply(fns, referenced_symbols)
  roots <- setdiff(names(fns), SCORING_FNS)
  reachable <- character(0)
  frontier <- roots
  while (length(frontier)) {
    new_syms <- setdiff(unique(unlist(refs[frontier])), reachable)
    reachable <- c(reachable, new_syms)
    frontier <- intersect(new_syms, names(fns))
  }
  expect_identical(intersect(reachable, BANNED_FNS), character(0))
  expect_identical(intersect(reachable, BANNED_PKGS), character(0))
  expect_identical(intersect(reachable, SCORING_FNS), character(0))
  # and the guard is looking at something: the scoring module itself DOES
  # reach stringdist, so an empty banned list would mean a broken walker
  expect_true("stringdist" %in%
                referenced_symbols(fns[["calculate_enhanced_first_name_similarity"]]))
  expect_gt(length(fns), 40)
})

test_that("verdict machinery declares no approximate-matching dependency", {
  d <- read.dcf(system.file("DESCRIPTION", package = "mysterynpi"))
  deps <- paste(d[, intersect(colnames(d), c("Imports", "Depends", "LinkingTo"))],
                collapse = " ")
  expect_false(grepl("stringdist|fuzzyjoin|RecordLinkage|reclin", deps))
  # scoring's engine lives in Suggests, loaded at its point of use only
  expect_true(grepl("stringdist", d[, "Suggests"]))
})
