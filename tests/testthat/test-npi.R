test_that("Luhn validation accepts real NPIs and rejects malformed ones", {
  expect_true(npi_luhn_ok("1396113270"))
  expect_false(npi_luhn_ok("1396113271"))   # wrong check digit
  expect_false(npi_luhn_ok("139611327"))    # nine digits
  expect_false(npi_luhn_ok("13961132700"))  # eleven
  expect_false(npi_luhn_ok("abcdefghij"))
  expect_identical(npi_luhn_ok(c("1396113270", "bad")), c(TRUE, FALSE))
})

test_that("NPIs must begin with 1 or 2 -- REGRESSION", {
  # Real fakes from the 2026-09-13 OpenSanctions Medicaid linkage: state
  # provider numbers that PASS the Luhn checksum but cannot be NPIs because
  # CMS only issues leading digits 1 and 2. Each previously returned TRUE.
  expect_false(npi_luhn_ok("3413469008"))   # NY Medicaid provider id
  expect_false(npi_luhn_ok("0103000788"))   # PA provider id
  expect_false(npi_luhn_ok("0008801710"))   # TX provider id
  # a leading-2 NPI with a correct check digit is structurally valid
  two <- vapply(0:9, function(d) paste0("200000000", d), character(1))
  expect_identical(sum(npi_luhn_ok(two)), 1L)  # exactly one check digit works
})

test_that("NA in, NA out: absence is never read as invalidity", {
  expect_identical(npi_luhn_ok(NA_character_), NA)
  expect_identical(npi_luhn_ok(c("1396113270", NA, "bad")),
                   c(TRUE, NA, FALSE))
  expect_identical(npi_luhn_ok(character(0)), logical(0))
})

test_that("vectorised Luhn agrees with the per-element reference -- REGRESSION", {
  reference <- function(one) {
    if (is.na(one)) return(NA)
    if (!grepl("^[12][0-9]{9}$", one)) return(FALSE)
    d <- as.integer(strsplit(paste0("80840", substr(one, 1, 9)), "")[[1]])
    idx <- rev(seq_along(d)); dbl <- d; odd <- which(idx %% 2 == 1)
    dbl[odd] <- dbl[odd] * 2
    dbl[dbl > 9] <- dbl[dbl > 9] - 9
    (10 - (sum(dbl) %% 10)) %% 10 == as.integer(substr(one, 10, 10))
  }
  set.seed(80840)
  pool <- c(
    vapply(1:200, function(i) paste0(sample(c("0","1","2","3","9"), 1),
      paste(sample(0:9, 9, replace = TRUE), collapse = "")), character(1)),
    "1396113270", "1609986611", NA_character_, "", "bad", "139611327"
  )
  expect_identical(npi_luhn_ok(pool),
                   vapply(pool, function(p) reference(p), logical(1),
                          USE.NAMES = FALSE))
  # single-element and empty vectors keep their shape
  expect_identical(npi_luhn_ok("1396113270"), TRUE)
  expect_identical(npi_luhn_ok(character(0)), logical(0))
})
