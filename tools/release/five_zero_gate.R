# =============================================================================
# The five-zero release gate: run before EVERY tag.
#
#   Rscript tools/release/five_zero_gate.R
#
# Owner ruling 2026-09-19: mysterynpi must not provide fuzzy person-name
# matching in any form - no option, no deprecated export, no dark-by-default
# capability. A tag asserts that of the RELEASED ARTIFACT, so this gate
# verifies the INSTALLED NAMESPACE, never the source tree - grep over source
# proves what the tree says, not what the artifact does (install the candidate
# first: R CMD INSTALL .). The five zeros, each printed and each fatal:
#
#   ZERO 1  fuzzy person-name APIs exported
#   ZERO 2  Jaro-Winkler paths reachable from any namespace function
#   ZERO 3  Levenshtein / edit-distance paths reachable
#   ZERO 4  Soundex / phonetic paths reachable
#   ZERO 5  approximate-matching dependencies declared in ANY tier
#
# Reachability is a transitive call-graph walk over every function in the
# installed namespace (the same walker as tests/testthat/helper-ast.R,
# vendored here so the gate has no dependency on the test tree). The walk
# carries its own POSITIVE CONTROL: a walker that sees nothing would report
# every zero for free, so the gate FAILS unless known-referenced symbols
# appear and the function census is plausible.
#
# Exit status: 0 only if all five zeros hold AND the controls pass.
# =============================================================================

PKG <- "mysterynpi"

# -- the banned surface, one place ------------------------------------------
JW_FNS <- c("jarowinkler", "stringsim", "jw_similarity",
            "calculate_enhanced_first_name_similarity",
            "create_nickname_aware_similarity",
            "surname_similarity", "middle_name_similarity",
            "given_name_similarity")
LEV_FNS <- c("adist", "agrep", "agrepl", "amatch", "stringdist",
             "stringdistmatrix", "levenshtein", "lv_distance")
PHONETIC_FNS <- c("soundex", "nysiis", "metaphone", "phonetic",
                  "caverphone", "cologne")
BANNED_PKGS <- c("stringdist", "phonics", "RecordLinkage", "fastLink",
                 "reclin", "reclin2", "fuzzyjoin")
BANNED_EXPORT_NAMES <- unique(c(JW_FNS, LEV_FNS, PHONETIC_FNS))

fail <- FALSE
zero <- function(label, offenders) {
  ok <- length(offenders) == 0L
  cat(sprintf("  %s  %s%s\n", if (ok) "PASS" else "FAIL", label,
              if (ok) "" else paste0(": ", paste(offenders, collapse = ", "))))
  if (!ok) fail <<- TRUE
  invisible(ok)
}

# -- the artifact, not the tree ----------------------------------------------
if (!requireNamespace(PKG, quietly = TRUE)) {
  cat(sprintf("FATAL: %s is not installed; the gate verifies the installed\n", PKG))
  cat("artifact. Run R CMD INSTALL . on the release candidate first.\n")
  quit(status = 1L)
}
ns <- asNamespace(PKG)
desc <- utils::packageDescription(PKG)
cat(sprintf("[five-zero] %s %s at %s\n", PKG, desc$Version,
            dirname(attr(desc, "file"))))

# -- vendored call-graph walker (mirror of tests/testthat/helper-ast.R) ------
referenced_symbols <- function(x) {
  refs <- new.env(parent = emptyenv())
  walk <- function(e) {
    if (is.call(e)) {
      h <- e[[1]]
      if (is.symbol(h)) {
        assign(as.character(h), TRUE, refs)
        if (as.character(h) %in% c("::", ":::")) {
          assign(as.character(e[[2]]), TRUE, refs)
          assign(as.character(e[[3]]), TRUE, refs)
        }
      }
      if (is.call(h)) walk(h)
      args <- as.list(e)[-1]
      for (i in seq_along(args)) {
        if (!identical(args[[i]], quote(expr = ))) walk(args[[i]])
      }
    } else if (is.function(e)) {
      walk(body(e))
      d <- formals(e)
      for (i in seq_along(d)) {
        if (!identical(d[[i]], quote(expr = ))) walk(d[[i]])
      }
    } else if (is.pairlist(e) || is.expression(e) || is.list(e)) {
      for (i in seq_along(e)) {
        if (!identical(e[[i]], quote(expr = ))) walk(e[[i]])
      }
    }
  }
  walk(x)
  ls(refs)
}

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

# -- positive controls FIRST: a blind walker passes every zero for free ------
cat("[five-zero] walker controls\n")
controls_ok <- TRUE
ctl <- function(label, ok) {
  cat(sprintf("  %s  control: %s\n", if (ok) "PASS" else "FAIL", label))
  if (!ok) controls_ok <<- FALSE
}
ctl(sprintf("namespace census plausible (%d functions > 40)", length(fns)),
    length(fns) > 40L)
ctl("a known-referenced symbol is reachable (normalize_string)",
    "normalize_string" %in% reachable)
ctl("the walker sees base calls (paste0 or sprintf reachable)",
    any(c("paste0", "sprintf") %in% reachable))
if (!controls_ok) {
  cat("[five-zero] FATAL: the walker cannot be trusted; zeros not evaluated.\n")
  quit(status = 1L)
}

# -- the five zeros -----------------------------------------------------------
cat("[five-zero] the five zeros\n")
exports <- getNamespaceExports(PKG)
internals <- ls(ns, all.names = TRUE)
dep_fields <- c("Depends", "Imports", "Suggests", "LinkingTo", "Enhances")
declared_deps <- unlist(lapply(dep_fields, function(f) {
  v <- desc[[f]]
  if (is.null(v)) return(character(0))
  trimws(sub("\\s*\\(.*", "", strsplit(v, ",")[[1]]))
}))

zero("ZERO 1: fuzzy person-name APIs exported",
     intersect(exports, BANNED_EXPORT_NAMES))
zero("ZERO 2: Jaro-Winkler paths reachable",
     intersect(reachable, JW_FNS))
zero("ZERO 3: Levenshtein/edit-distance paths reachable",
     intersect(reachable, LEV_FNS))
zero("ZERO 4: Soundex/phonetic paths reachable",
     intersect(reachable, PHONETIC_FNS))
zero("ZERO 5: approximate-matching dependencies declared",
     intersect(declared_deps, BANNED_PKGS))

# supporting assertions, same fatality: an unexported body is still
# smuggleable via :::, and a reachable banned PACKAGE prefix (pkg::fn the
# walker records both halves of) is a path even if the fn name is novel
zero("SUPPORT: banned names absent from namespace internals",
     intersect(internals, BANNED_EXPORT_NAMES))
zero("SUPPORT: banned package prefixes unreachable",
     intersect(reachable, BANNED_PKGS))
zero("SUPPORT: no similarity-scoring option fence survives",
     if (!is.null(getOption("mysterynpi.enable_similarity_scoring")))
       "option mysterynpi.enable_similarity_scoring is set" else character(0))

if (fail) {
  cat("[five-zero] FAIL: the artifact carries fuzzy capability; DO NOT TAG.\n")
  quit(status = 1L)
}
cat("[five-zero] all five zeros hold on the installed artifact; safe to tag.\n")
