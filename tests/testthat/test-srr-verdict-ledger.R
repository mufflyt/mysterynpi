# srr/verdict-ledger.csv is the table srr/standards-compliance.md counts from.
# A ledger that drifts from the tags is worse than no ledger: it reads as
# evidence while being out of date, which is the failure this package's whole
# standards effort kept running into (a generated tag justification that named
# no code, a tag in the wrong file, a claimed standard that was an overcount).
# So the ledger is checked against the source of truth rather than trusted.
#
# STRUCTURAL, SO IT SKIPS ON AN INSTALLED PACKAGE, like
# test-pkgdown-reference-index-complete.R: R CMD check runs the suite against
# the installed tree, which has neither R/ nor srr/.

# THE VERDICT LABEL "NA" IS A VALUE, NOT A MISSING MARKER, and read.csv cannot
# tell the difference: with default na.strings every not-applicable row reads
# back as absent, which is how the first version of this gate failed. That is
# the package's own subject matter turning up in its own test fixture, so the
# reader is wrapped once and asserts the column is complete.
read_ledger <- function(root) {
  x <- utils::read.csv(file.path(root, "srr", "verdict-ledger.csv"),
                       stringsAsFactors = FALSE, na.strings = character(0))
  stopifnot(!anyNA(x$verdict), all(nzchar(x$verdict)))
  x
}

ledger_root <- function() {
  p <- testthat::test_path("..", "..")
  if (file.exists(file.path(p, "srr", "verdict-ledger.csv"))) p else NA_character_
}

tags_by_id <- function(root) {
  files <- c(list.files(file.path(root, "R"), "[.]R$", full.names = TRUE),
             list.files(file.path(root, "tests"), "[.]R$", full.names = TRUE,
                        recursive = TRUE))
  txt <- unlist(lapply(files, readLines, warn = FALSE))
  out <- list()
  for (kind in c("srrstatsNA", "srrstats")) {
    # NA first, so the plain-tag pattern cannot also claim an NA tag: the two
    # names share a prefix and "@srrstats \\{" matches inside "@srrstatsNA {".
    hits <- regmatches(txt, regexpr(sprintf("@%s \\{[^}]+\\}", kind), txt))
    ids <- unlist(strsplit(gsub(sprintf("@%s \\{|\\}", kind), "", hits), ","))
    ids <- trimws(ids)
    ids <- ids[grepl("^(G|EA|RE|TS)[0-9]", ids)]
    for (i in setdiff(ids, names(out))) out[[i]] <- kind
  }
  out
}

test_that("the verdict ledger agrees with the tags in the source", {
  root <- ledger_root()
  skip_if(is.na(root), "source tree not present (installed-package check)")
  led <- read_ledger(root)
  tags <- tags_by_id(root)

  expect_setequal(led$standard, names(tags))

  # A Y verdict must carry @srrstats; N and NA must carry @srrstatsNA, because
  # srr has no third tag. That mapping is what the assessment documents.
  want <- ifelse(led$verdict == "Y", "srrstats", "srrstatsNA")
  got <- unlist(tags[led$standard], use.names = FALSE)
  disagree <- led$standard[want != got]
  expect_identical(disagree, character(0),
                   info = paste("ledger and tag disagree for:",
                                paste(disagree, collapse = ", ")))
})

test_that("the ledger covers every standard in the canonical checklist", {
  root <- ledger_root()
  skip_if(is.na(root), "source tree not present (installed-package check)")
  cl <- file.path(root, "srr", "srr-standards.md")
  skip_if_not(file.exists(cl), "srr-standards.md not present")
  ln <- readLines(cl, warn = FALSE)
  m <- regmatches(ln, regexpr("\\*\\*(G|EA|RE|TS)[0-9][0-9.]*[a-z]?\\*\\*", ln))
  ids <- unique(gsub("\\*", "", m))
  led <- read_ledger(root)
  expect_setequal(led$standard, ids)
})

test_that("each ledger row names a file that carries the tag", {
  root <- ledger_root()
  skip_if(is.na(root), "source tree not present (installed-package check)")
  led <- read_ledger(root)
  expect_true(all(nzchar(led$tagged_in)))
  missing <- character(0)
  for (i in seq_len(nrow(led))) {
    for (f in strsplit(led$tagged_in[i], ";", fixed = TRUE)[[1]]) {
      if (!file.exists(file.path(root, f))) missing <- c(missing, f)
    }
  }
  expect_identical(unique(missing), character(0))
})
