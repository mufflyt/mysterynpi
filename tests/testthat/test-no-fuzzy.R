# The package makes exact claims about identity, and an approximate-matching
# call in the VERDICT path is a defect, not a feature -- one was added and
# removed inside a single day, and it admitted JULIA/JULIE, LEE/LEA and
# ANN/ANNE as non-conflicts.
#
# 2026-09-19 (owner ruling): numeric similarity is a FIRST-CLASS governed
# primitive (R/similarity.R) -- Jaro-Winkler and Levenshtein are
# deterministic functions, and the defect this guard exists for was always
# hand-rolled fuzz in the VERDICT path, not fuzz itself. So the fence is
# retargeted, not retired. The claim that still matters, stated three ways
# below: similarity machinery exists ONLY inside the similarity modules, no
# verdict-side source file references it, and no categorical *_agreement()
# rule can REACH a similarity engine through any call chain. A mutation in
# the campaign (middle-agreement-smuggles-similarity) proves the
# reachability guard fires on exactly that smuggling.

SIMILARITY_MODULES <- c("similarity.R", "similarity_scoring.R")
BANNED_FNS <- c("adist", "agrep", "agrepl", "stringdist", "stringsim",
                "amatch", "stringdistmatrix", "jarowinkler", "soundex",
                "nysiis", "metaphone", "phonetic", "fastLink",
                "compare.dedup", "pair_blocking")
BANNED_PKGS <- c("stringdist", "phonics", "RecordLinkage", "fastLink",
                 "reclin", "reclin2", "fuzzyjoin")
SIMILARITY_FNS <- c("create_nickname_dictionary", "get_nickname_dictionary",
                    "get_canonical_name", "are_nickname_equivalents",
                    "get_nicknames_for_name",
                    "calculate_enhanced_first_name_similarity",
                    "surname_similarity", "middle_name_similarity",
                    "given_name_similarity", ".similarity_engine",
                    ".nickname_mask", "compact_equal",
                    "assert_similarity_contract",
                    "JW_PREFIX_WEIGHT", "NICKNAME_SIMILARITY")

test_that("outside the similarity modules, no source file touches approximate matching", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  files <- files[!basename(files) %in% SIMILARITY_MODULES]
  src <- unlist(lapply(files, readLines, warn = FALSE))
  code <- grep("^\\s*#", src, value = TRUE, invert = TRUE)
  for (fn in BANNED_FNS) {
    hits <- grep(paste0("\\b", fn, "\\s*\\("), code, value = TRUE)
    expect_identical(hits, character(0),
                     info = sprintf("%s() called outside %s", fn,
                                    paste(SIMILARITY_MODULES, collapse = "/")))
  }
})

test_that("outside the similarity modules, no parse tree references similarity capability", {
  files <- list.files("../../R", pattern = "[.]R$", full.names = TRUE)
  if (!length(files)) skip("source not reachable from the installed package")
  files <- files[!basename(files) %in% SIMILARITY_MODULES]
  seen <- unique(unlist(lapply(files, function(f)
    referenced_symbols(parse(f, keep.source = FALSE)))))
  expect_identical(intersect(seen, BANNED_FNS), character(0))
  expect_identical(intersect(seen, BANNED_PKGS), character(0))
  # verdict-side code never calls into the similarity surface; the decision
  # layer (0.8.0) will consume it EXPLICITLY and join this exemption list
  # when it lands.
  expect_identical(intersect(seen, SIMILARITY_FNS), character(0))
})

# The reachability guard: from every verdict function, walk the call graph
# through the installed namespace and assert no similarity engine is
# reachable. This runs against the INSTALLED package (never skips under
# R CMD check), and it is the guard the smuggling mutant must trip.
test_that("no agreement verdict can reach similarity machinery, transitively", {
  ns <- asNamespace("mysterynpi")
  fns <- Filter(is.function, mget(ls(ns, all.names = TRUE), envir = ns,
                                  ifnotfound = list(NULL)))
  refs <- lapply(fns, referenced_symbols)
  roots <- setdiff(names(fns), SIMILARITY_FNS)
  reachable <- character(0)
  frontier <- roots
  while (length(frontier)) {
    new_syms <- setdiff(unique(unlist(refs[frontier])), reachable)
    reachable <- c(reachable, new_syms)
    frontier <- intersect(new_syms, names(fns))
  }
  expect_identical(intersect(reachable, BANNED_FNS), character(0))
  expect_identical(intersect(reachable, BANNED_PKGS), character(0))
  expect_identical(intersect(reachable, SIMILARITY_FNS), character(0))
  # and the guard is looking at something: the similarity engine itself DOES
  # reach stringdist, so an empty banned list would mean a broken walker
  expect_true("stringdist" %in% referenced_symbols(fns[[".similarity_engine"]]))
  expect_gt(length(fns), 40)
})

test_that("the similarity engine is a declared, pinned dependency", {
  # 2026-09-19: stringdist moved Suggests -> Imports when similarity became
  # first-class. The old assertion (verdicts declare no approximate-matching
  # dependency) is superseded by the reachability guard above, which proves
  # the stronger property: the dependency exists, and verdicts still cannot
  # reach it.
  d <- read.dcf(system.file("DESCRIPTION", package = "mysterynpi"))
  expect_true(grepl("stringdist", d[, "Imports"]))
  expect_false(grepl("stringdist", d[, "Suggests"]))
})
