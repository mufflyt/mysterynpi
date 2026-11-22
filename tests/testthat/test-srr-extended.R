# Extended tests: srr G5.10, G5.11, G5.12
#
# G5.10 asks that extended tests run under the same framework as the rest but
# be switched on by a flag. G5.11 asks that large assets be fetched rather than
# shipped. G5.12 asks that the conditions be documented.
#
# CONDITIONS TO RUN THESE (G5.12):
#   flag       MYSTERYNPI_EXTENDED_TESTS=true
#   platform   any; no compiled code, no system libraries
#   memory     ~1.5 GB peak for the NPPES extract below
#   runtime    ~4 minutes on the reference laptop, dominated by the download
#   network    required: the asset is fetched, never committed (G5.11)
#   asset      MYSTERYNPI_NPPES_CSV may point at a local copy of the NPPES
#              individual-provider extract to skip the download entirely; set
#              it to a path and no network is used.
#   artefacts  none written outside tempdir(); nothing needs manual inspection
#
# WHY A FETCHED ASSET AND NOT A FIXTURE. The rules in this package were written
# against a 1.5-million-row registry, and every defect they encode was found at
# that scale -- a surname that is unique in a 200-row fixture has 400 bearers
# in the real file. A fixture cannot test the property these tests are for:
# that blocking stays bounded and keys stay unique as the reference grows.

skip_if_not_extended <- function() {
  flag <- tolower(Sys.getenv("MYSTERYNPI_EXTENDED_TESTS", ""))
  testthat::skip_if_not(flag %in% c("true", "1", "yes"),
                        "extended tests: set MYSTERYNPI_EXTENDED_TESTS=true")
}

nppes_extract <- function() {
  local <- Sys.getenv("MYSTERYNPI_NPPES_CSV", "")
  if (nzchar(local)) {
    testthat::skip_if_not(file.exists(local),
                          paste("MYSTERYNPI_NPPES_CSV does not exist:", local))
    return(utils::read.csv(local, colClasses = "character",
                           nrows = 200000L))
  }
  testthat::skip_if_offline()
  url <- Sys.getenv(
    "MYSTERYNPI_NPPES_URL",
    "https://download.cms.gov/nppes/NPPES_Data_Dissemination_Query.zip")
  dest <- file.path(tempdir(), "nppes_query.zip")
  ok <- tryCatch({
    utils::download.file(url, dest, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  testthat::skip_if_not(ok, "extended tests: the NPPES asset did not download")
  inner <- utils::unzip(dest, list = TRUE)$Name
  csv <- grep("[.]csv$", inner, value = TRUE)[1]
  testthat::skip_if(is.na(csv), "extended tests: no CSV inside the asset")
  utils::read.csv(unz(dest, csv), colClasses = "character", nrows = 200000L)
}

test_that("G5.10, G5.11: name keys stay unique-per-person at registry scale", {
  skip_if_not_extended()
  d <- nppes_extract()
  cols <- names(d)
  last <- grep("Last.Name", cols, value = TRUE)[1]
  first <- grep("First.Name", cols, value = TRUE)[1]
  skip_if(is.na(last) || is.na(first), "unexpected NPPES column names")
  k <- name_key(paste(d[[first]], d[[last]]))
  # The property: a key is a blocking key, not an identifier. It must collide
  # (or blocking does nothing) but the collision rate must stay bounded as the
  # reference grows -- the failure this guards is a key so aggressive that a
  # block becomes the whole file.
  rate <- 1 - length(unique(k)) / length(k)
  expect_lt(rate, 0.25)
  expect_gt(rate, 0)
  expect_false(any(is.na(k)))
})

test_that("G5.10: blocking stays bounded on a real reference", {
  skip_if_not_extended()
  d <- nppes_extract()
  last <- grep("Last.Name", names(d), value = TRUE)[1]
  skip_if(is.na(last), "unexpected NPPES column names")
  blocks <- table(blocking_key(d[[last]]))
  # No single block may hold more than a few per cent of the reference, or
  # candidate generation degenerates into a cross join at scale.
  expect_lt(max(blocks) / sum(blocks), 0.05)
})
