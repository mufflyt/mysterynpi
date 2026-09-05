test_that("the landmines: every kind of gone is NOT retired", {
  # FL Deceased(350), IL DECEASED(19): death, not retirement
  expect_identical(normalize_license_status(c("Deceased", "DECEASED")),
                   c("deceased", "deceased"))
  # NY-OPMC: entirely disciplinary -- exit, not retirement
  expect_identical(
    normalize_license_status(c("Surrendered", "Revoked",
                               "Surrendered in Lieu of Discipline")),
    rep("disciplinary", 3))
  # CO/DE/WI: dominated by Expired/Revoked, not retirement
  expect_identical(normalize_license_status(c("Expired", "Lapsed",
                                              "Delinquent")),
                   rep("lapsed", 3))
  got <- normalize_license_status(c("Deceased", "Surrendered", "Expired",
                                    "Revoked", "Inactive"))
  expect_false(any(got == "retired", na.rm = TRUE))
})

test_that("only the board's own word for retired is retirement", {
  expect_identical(normalize_license_status(c("Retired", "retired ",
                                              "Emeritus",
                                              "Voluntarily Retired")),
                   rep("retired", 4))
})

test_that("practicing statuses are never exits", {
  expect_identical(normalize_license_status(c("Active", "Current",
                                              "In Good Standing")),
                   rep("active", 3))
  # discipline while still licensed is restriction, not exit
  expect_identical(normalize_license_status(c("Probation", "Suspended")),
                   rep("restricted", 2))
})

test_that("formatting is formatting: case, whitespace, punctuation", {
  expect_identical(normalize_license_status(c("  ACTIVE  ", "Null & Void",
                                              "NULL AND VOID",
                                              "Voluntary-Surrender")),
                   c("active", "lapsed", "lapsed", "disciplinary"))
})

test_that("unmapped decides nothing -- the anti-inflation rule itself", {
  expect_identical(normalize_license_status(c("Status 47", "", NA, "ZZZ")),
                   rep(NA_character_, 4))
})

test_that("a caller-supplied vocabulary extends without a code change", {
  extra <- rbind(LICENSE_STATUS_LEVELS,
                 data.frame(status = "SENIOR ACTIVE", class = "retired",
                            stringsAsFactors = FALSE))
  expect_identical(normalize_license_status("Senior Active", levels = extra),
                   "retired")
  expect_identical(normalize_license_status("Senior Active"), NA_character_)
  expect_error(normalize_license_status("A", levels = data.frame(x = 1)),
               "status and class")
})

test_that("the vocabulary itself is clean", {
  expect_false(anyDuplicated(LICENSE_STATUS_LEVELS$status) > 0)
  expect_setequal(unique(LICENSE_STATUS_LEVELS$class),
                  c("active", "restricted", "retired", "deceased",
                    "disciplinary", "lapsed"))
})

test_that("the shipped contract passes, and can fail", {
  expect_true(assert_license_status_contract())
  inflator <- function(x) rep("retired", length(x))
  expect_error(assert_license_status_contract(inflator))
})
