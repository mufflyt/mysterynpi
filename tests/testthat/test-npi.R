test_that("Luhn validation accepts real NPIs and rejects malformed ones", {
  expect_true(npi_luhn_ok("1396113270"))
  expect_false(npi_luhn_ok("1396113271"))   # wrong check digit
  expect_false(npi_luhn_ok("139611327"))    # nine digits
  expect_false(npi_luhn_ok("13961132700"))  # eleven
  expect_false(npi_luhn_ok("abcdefghij"))
  expect_identical(npi_luhn_ok(c("1396113270", "bad")), c(TRUE, FALSE))
})
