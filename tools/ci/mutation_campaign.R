# =============================================================================
# Mutation campaign for the matching rules
# =============================================================================
#
# WHAT THIS MEASURES. Each mutant below reintroduces a defect the package
# exists to prevent -- the floor lowered, the veto loosened, absence read as
# evidence -- and the test suite must FAIL under it. A mutant that survives is
# a hole in the TESTS, not a bug in the code, and it fails this campaign.
#
# Mechanics imported from the harnesses in mufflyt/midwifery and
# mufflyt/twostep, which learned them the hard way:
#
# * CONTROL FIRST, NON-OPTIONAL. The unmutated suite must pass before any
#   mutant runs -- a suite that is already broken "kills" every mutation and
#   reports perfect confidence while measuring nothing.
# * ASSERTION FLOOR IN THE CONTROL. Zero failures and zero assertions are not
#   the same as agreement: a suite whose tests all silently erred or skipped
#   reports zero failures while running nothing. (This harness's own probe
#   demonstrated it: test_dir() without loading the package recorded 12 of
#   238 assertions and zero failures.) The control must record at least
#   MIN_ASSERTIONS or the campaign aborts.
# * EXACTLY-ONCE ANCHORS. A mutant's `find` string must occur exactly once in
#   its target file. Zero means the catalogue entry has rotted and is testing
#   nothing; two means the mutation is no longer the change it claims to be.
#   Either fails loudly.
# * BYTE-FOR-BYTE CUSTODY. Every target file is snapshotted in memory,
#   restored via on.exit, and verified byte-identical at the end. A leftover
#   mutation in the working tree is worse than not running at all.
# * A CRASH IS A KILL. A mutant that breaks the build was detected.
#
# Run from the package root:  Rscript tools/ci/mutation_campaign.R
# =============================================================================

MIN_ASSERTIONS <- 200L   # baseline is 238; the floor catches wholesale
                         # discovery loss, not ordinary edits

CATALOGUE <- list(
  list(id = "surname-token-floor",
       file = "R/tokens.R",
       find = "MIN_SURNAME_TOKEN <- 4L",
       repl = "MIN_SURNAME_TOKEN <- 2L",
       why  = "two-letter fragments become blocking keys; unrelated people collide on DE or LA"),
  list(id = "person-match-and-to-or",
       file = "R/agreement.R",
       find = "same_last & shared",
       repl = "same_last | shared",
       why  = "a shared surname alone, or a shared given name alone, becomes a person match"),
  list(id = "middle-absence-becomes-conflict",
       file = "R/agreement.R",
       find = "if (!length(a) || !length(b)) return(\"uninformative\")",
       repl = "if (!length(a) || !length(b)) return(\"conflicts\")",
       why  = "absence of a middle name reads as evidence of difference; the 82-row defect returns"),
  list(id = "gender-agreement-flip",
       file = "R/gender.R",
       find = "out[known] <- ifelse(ga[known] == gb[known], \"corroborates\", \"conflicts\")",
       repl = "out[known] <- ifelse(ga[known] != gb[known], \"corroborates\", \"conflicts\")",
       why  = "the gender veto fires on agreement and blesses disagreement"),
  list(id = "gender-numeric-guessed",
       file = "R/gender.R",
       find = "u %in% c(\"M\", \"MALE\")",
       repl = "u %in% c(\"M\", \"MALE\", \"1\")",
       why  = "a numeric convention is guessed at; sources on the opposite convention flip wholesale"),
  list(id = "nickname-direction-reversed",
       file = "R/nicknames.R",
       find = "split(edges$name, edges$nickname)",
       repl = "split(edges$nickname, edges$name)",
       why  = "the one-hop lookup walks the wrong way; hub nicknames weld ALBERT to ALEXANDER"),
  list(id = "suffix-generation-corrupted",
       file = "R/suffix.R",
       find = "II = 2L",
       repl = "II = 3L",
       why  = "JR and II stop being the same generation; house style becomes a veto"),
  list(id = "license-ignores-state",
       file = "R/license.R",
       find = "sa == sb & na == nb",
       repl = "na == nb & na == nb",
       why  = "a Colorado number corroborates a Texas number; a coincidence becomes evidence"),
  list(id = "license-strips-zeros",
       file = "R/license.R",
       find = "[ .\\\\-]",
       repl = "[ .\\\\-0]",
       why  = "zero-padding is erased and 0052 corroborates 52"),
  list(id = "clerical-blinding-lost",
       file = "R/clerical.R",
       find = "cols <- setdiff(cols, class)",
       repl = "cols <- unique(c(cols))     ",
       why  = "a caller listing the class column gets it on the reviewer sheet; blinding is gone"),
  list(id = "resolve-keeps-weakest",
       file = "R/resolve.R",
       find = "as.integer(stats::ave(d[[class]], key, FUN = min))[keep]",
       repl = "as.integer(stats::ave(d[[class]], key, FUN = max))[keep]",
       why  = "collapse keeps the weakest class per pair; every pool ranks on its worst evidence"))

# ---- subprocess runner ------------------------------------------------------
# The suite runs in a fresh R process per mutant so no stale bytecode from a
# previous load can mask the mutation. The fenced marker is parsed, never the
# human-readable output.
run_suite <- function() {
  expr <- paste(
    "suppressMessages(pkgload::load_all('.', quiet = TRUE));",
    "r <- testthat::test_dir('tests/testthat', reporter = 'silent',",
    "                        stop_on_failure = FALSE);",
    "d <- as.data.frame(r);",
    "cat(sprintf('<<RESULT:pass=%d;fail=%d;error=%d;skip=%d>>',",
    "            sum(d$passed), sum(d$failed), sum(d$error), sum(d$skipped)))")
  out <- suppressWarnings(system2(file.path(R.home("bin"), "Rscript"),
                                  c("-e", shQuote(expr)),
                                  stdout = TRUE, stderr = TRUE))
  m <- regmatches(out, regexpr("<<RESULT:pass=\\d+;fail=\\d+;error=\\d+;skip=\\d+>>", out))
  m <- m[nzchar(m)]
  if (!length(m)) return(NULL)                       # crashed before reporting
  n <- as.integer(regmatches(m[1], gregexpr("\\d+", m[1]))[[1]])
  list(pass = n[1], fail = n[2], error = n[3], skip = n[4])
}

read_bytes  <- function(f) readBin(f, "raw", file.info(f)$size)
write_bytes <- function(f, b) writeBin(b, f)

# ---- custody ----------------------------------------------------------------
targets <- unique(vapply(CATALOGUE, `[[`, character(1), "file"))
for (f in targets) if (!file.exists(f))
  stop("catalogue names a missing file: ", f, " (run from the package root)")
snapshot <- setNames(lapply(targets, read_bytes), targets)
restore_all <- function() for (f in targets) write_bytes(f, snapshot[[f]])
on.exit(restore_all(), add = TRUE)

# ---- control ----------------------------------------------------------------
cat("== control: unmutated suite must pass and clear the assertion floor\n")
ctl <- run_suite()
if (is.null(ctl)) stop("control run crashed; nothing can be measured")
cat(sprintf("   pass=%d fail=%d error=%d skip=%d (floor %d)\n",
            ctl$pass, ctl$fail, ctl$error, ctl$skip, MIN_ASSERTIONS))
if (ctl$fail + ctl$error > 0)
  stop("control suite is red; a broken suite would kill every mutant while measuring nothing")
if (ctl$pass < MIN_ASSERTIONS)
  stop(sprintf("control recorded %d assertions, floor is %d: the suite is not being discovered",
               ctl$pass, MIN_ASSERTIONS))

# ---- campaign ---------------------------------------------------------------
survived <- character(0)
for (m in CATALOGUE) {
  txt <- rawToChar(snapshot[[m$file]])
  hits <- gregexpr(m$find, txt, fixed = TRUE)[[1]]
  n_hits <- if (hits[1] == -1L) 0L else length(hits)
  if (n_hits != 1L) {
    restore_all()
    stop(sprintf("mutant %s: anchor occurs %d times in %s (must be exactly 1); the catalogue has rotted",
                 m$id, n_hits, m$file))
  }
  write_bytes(m$file, charToRaw(sub(m$find, m$repl, txt, fixed = TRUE)))
  res <- run_suite()
  write_bytes(m$file, snapshot[[m$file]])
  if (is.null(res)) {
    cat(sprintf("   KILLED   %-32s (crash counts as detection)\n", m$id))
  } else if (res$fail + res$error > 0 || res$pass < MIN_ASSERTIONS) {
    cat(sprintf("   KILLED   %-32s fail=%d error=%d pass=%d\n",
                m$id, res$fail, res$error, res$pass))
  } else {
    cat(sprintf("   SURVIVED %-32s suite green under: %s\n", m$id, m$why))
    survived <- c(survived, m$id)
  }
}

# ---- verify custody ---------------------------------------------------------
for (f in targets) if (!identical(read_bytes(f), snapshot[[f]])) {
  restore_all()
  stop("working tree was not restored byte-for-byte: ", f)
}

if (length(survived)) {
  stop(sprintf("%d mutant(s) SURVIVED -- holes in the tests, not bugs in the code: %s",
               length(survived), paste(survived, collapse = ", ")))
}
cat(sprintf("== all %d mutants killed; working tree verified clean\n",
            length(CATALOGUE)))
