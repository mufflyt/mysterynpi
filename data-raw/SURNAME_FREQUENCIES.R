# =============================================================================
# Vendor the top of the U.S. Census Bureau 2010 surname frequency file
# =============================================================================
#
# Source: https://www2.census.gov/topics/genealogy/2010surnames/names.zip
# (Census Bureau, "Frequently Occurring Surnames from the 2010 Census") -- a
# U.S. government work in the public domain. Aggregate frequencies only; no
# individual is described. The 2010 file is a finished, immutable release,
# so unlike the nickname table there is no upstream to drift from; this
# script exists to make the derivation reviewable, not to track anything.
#
# The package vendors the top 1,000 surnames: enough for term-frequency
# awareness (agreement on SMITH is weaker evidence than agreement on a rare
# name) and for generating realistic synthetic fixtures, without shipping
# the 160k-row file.
#
# Rerun from the package root:  Rscript data-raw/SURNAME_FREQUENCIES.R

url <- "https://www2.census.gov/topics/genealogy/2010surnames/names.zip"
tmp <- tempfile(fileext = ".zip")
download.file(url, tmp, quiet = TRUE, mode = "wb")
csv <- unzip(tmp, "Names_2010Census.csv", exdir = tempdir())
raw <- read.csv(csv, stringsAsFactors = FALSE)

stopifnot(identical(raw$name[1], "SMITH"), nrow(raw) > 160000)
top <- raw[raw$rank >= 1 & raw$rank <= 1000,
           c("name", "rank", "count", "prop100k")]
names(top) <- c("surname", "rank", "count", "per_100k")
top$per_100k <- as.numeric(top$per_100k)
SURNAME_FREQUENCIES <- top[order(top$rank), ]
rownames(SURNAME_FREQUENCIES) <- NULL

stopifnot(nrow(SURNAME_FREQUENCIES) == 1000L,
          identical(SURNAME_FREQUENCIES$surname[1], "SMITH"),
          !anyNA(SURNAME_FREQUENCIES))

save(SURNAME_FREQUENCIES, file = "data/SURNAME_FREQUENCIES.rda",
     compress = "bzip2", version = 2)
cat(nrow(SURNAME_FREQUENCIES), "surnames written to data/SURNAME_FREQUENCIES.rda\n")
