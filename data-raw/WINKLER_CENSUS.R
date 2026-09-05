# =============================================================================
# Vendor William Winkler's synthetic census pairs from TeamCohen/secondstring
# =============================================================================
#
# Source: https://github.com/TeamCohen/secondstring, data/censusText.txt --
# the SecondString project's copy of Winkler's SYNTHETIC census data: two
# relations (A: 449 rows, B: 392 rows) of person records deliberately full of
# classic name-matching pathology (typos, swapped and truncated given names,
# household confusion). Truth is encoded in the record IDs: an ID present in
# BOTH relations is the same synthetic person (327 labeled matches). Eleven
# IDs additionally repeat WITHIN a relation -- household-confusion
# duplicates, kept deliberately: they are what duplicate_differences()
# exists for. No real individual is described.
#
# License: Carnegie Mellon University, 2003 -- a permissive notice-retention
# license; the full text ships as inst/secondstring-LICENSE and is summarised
# in inst/COPYRIGHTS. Pinned to a commit for reproducibility.
#
# Rerun from the package root:  Rscript data-raw/WINKLER_CENSUS.R

sha <- "44d67bb2c8af8e03c963717ce4c799ab051583ca"  # repo head as of 2026-09-05
url <- sprintf(
  "https://raw.githubusercontent.com/TeamCohen/secondstring/%s/data/censusText.txt",
  sha)

lines <- readLines(url, warn = FALSE)
parts <- strsplit(lines, "\t")
stopifnot(all(lengths(parts) == 3L))
relation <- vapply(parts, `[[`, character(1), 1L)
id       <- vapply(parts, `[[`, character(1), 2L)
body     <- vapply(parts, `[[`, character(1), 3L)

# The third field is fixed-width: 1 pad, surname 14, given 13, middle 1,
# 1 pad, house 13, street to end.
f <- function(from, to) trimws(substr(body, from, to))
WINKLER_CENSUS <- data.frame(
  relation = relation,
  id       = id,
  surname  = f(2L, 15L),
  given    = f(16L, 28L),
  middle   = f(29L, 29L),
  house    = f(31L, 43L),
  street   = f(44L, max(nchar(body))),
  stringsAsFactors = FALSE)

stopifnot(
  nrow(WINKLER_CENSUS) == 841L,
  identical(as.integer(table(WINKLER_CENSUS$relation)[c("A", "B")]),
            c(449L, 392L)),
  all(nzchar(WINKLER_CENSUS$surname)),
  all(nchar(WINKLER_CENSUS$middle) <= 1L),
  # the labeled matches: ids present in both relations
  length(with(WINKLER_CENSUS,
              intersect(id[relation == "A"], id[relation == "B"]))) == 327L,
  # household-confusion duplicates within a relation, kept deliberately
  sum(duplicated(paste(WINKLER_CENSUS$relation, WINKLER_CENSUS$id))) == 11L)

save(WINKLER_CENSUS, file = "data/WINKLER_CENSUS.rda", compress = "bzip2",
     version = 2)
cat(nrow(WINKLER_CENSUS), "rows written to data/WINKLER_CENSUS.rda\n")
