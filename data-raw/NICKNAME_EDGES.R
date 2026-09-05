# =============================================================================
# Vendor the carltonnorthern/nicknames edge list as NICKNAME_EDGES
# =============================================================================
#
# Source: https://github.com/carltonnorthern/nicknames (Apache-2.0; the license
# text ships with this package as inst/nicknames-LICENSE). The download is
# pinned to a commit so rebuilding this data is reproducible, not a function of
# whatever upstream looks like today. To take an upstream update: bump the SHA,
# rerun, and review the diff of the .rda like any other code change.
#
# Rerun from the package root with:  Rscript data-raw/NICKNAME_EDGES.R

sha <- "1524308b6859f04335693b76de86f349dc5b78da"  # names.csv as of 2026-08-02
url <- sprintf(
  "https://raw.githubusercontent.com/carltonnorthern/nicknames/%s/names.csv",
  sha)

raw <- read.csv(url, stringsAsFactors = FALSE)
stopifnot(identical(names(raw), c("name1", "relationship", "name2")),
          all(raw$relationship == "has_nickname"))

# The same normalisation the agreement rule applies to its inputs: uppercase,
# periods removed (the corpus writes a few initialism nicknames as "k.c.").
norm <- function(x) gsub("[.]", "", toupper(trimws(x)))

NICKNAME_EDGES <- unique(data.frame(name = norm(raw$name1),
                                    nickname = norm(raw$name2),
                                    stringsAsFactors = FALSE))
stopifnot(!anyNA(NICKNAME_EDGES), all(nzchar(NICKNAME_EDGES$name)),
          all(nzchar(NICKNAME_EDGES$nickname)),
          all(grepl("^[A-Z]+$", NICKNAME_EDGES$name)),
          all(grepl("^[A-Z]+$", NICKNAME_EDGES$nickname)))
NICKNAME_EDGES <- NICKNAME_EDGES[order(NICKNAME_EDGES$name,
                                       NICKNAME_EDGES$nickname), ]
rownames(NICKNAME_EDGES) <- NULL

save(NICKNAME_EDGES, file = "data/NICKNAME_EDGES.rda", compress = "bzip2",
     version = 2)
cat(nrow(NICKNAME_EDGES), "edges written to data/NICKNAME_EDGES.rda\n")
