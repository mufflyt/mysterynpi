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
