snapshot <- data.frame(
  npi = c("1609986611", "1265620405", "1083937122"),
  last_name = c("BAMONTE", NA, "DOE"),
  first_name = c("ANTHONY", NA, "JANE"),
  org_name = c(NA, "NADINE H. YASSA, M.D., INC.", NA),
  state = c("OH", "CA", "NY"),
  stringsAsFactors = FALSE
)

test_that("existence in the snapshot decides the confidence tier", {
  # "1396113271" has a wrong check digit; once the leading-digit rule (#10)
  # merges, checksum-passing fakes like "3413469008" also land in "invalid".
  r <- npi_corroborate(
    npi = c("1609986611", "1234567893", "1396113271", NA),
    name = c("Anthony Bamonte", "Nobody Known", "Shannon Finch", "X"),
    state = c("OH", "CA", "NY", "CA"),
    snapshot = snapshot
  )
  expect_identical(r$confidence,
                   c("corroborated", "unverified", "invalid", NA))
  expect_identical(r$in_snapshot, c(TRUE, FALSE, FALSE, NA))
  expect_identical(r$structurally_valid, c(TRUE, TRUE, FALSE, NA))
})

test_that("a person matches their own professional corporation's org NPI", {
  # the person/organization boundary: candidate is a person, the snapshot
  # row is her corporation
  r <- npi_corroborate("1265620405", name = "Nadine H. Yassa",
                       state = "CA", snapshot = snapshot)
  expect_identical(r$confidence, "corroborated")
  expect_true(r$name_match)
  expect_true(r$state_match)
})

test_that("name and state agreement are NA when information is absent", {
  r <- npi_corroborate("1609986611", snapshot = snapshot)
  expect_identical(r$name_match, NA)
  expect_identical(r$state_match, NA)
  # snapshot without name/state columns: matches stay NA even with a name
  bare <- snapshot["npi"]
  r2 <- npi_corroborate("1609986611", name = "Anthony Bamonte",
                        state = "OH", snapshot = bare)
  expect_identical(r2$confidence, "corroborated")
  expect_identical(r2$name_match, NA)
  expect_identical(r2$state_match, NA)
})

test_that("a wrong name or state is reported, not silently absorbed", {
  r <- npi_corroborate("1609986611", name = "Zelda Quux", state = "TX",
                       snapshot = snapshot)
  expect_identical(r$confidence, "corroborated")  # existence is the tier
  expect_false(r$name_match)                       # agreement travels alongside
  expect_false(r$state_match)
})

test_that("duplicate snapshot NPIs are refused: no silent join fan-out", {
  dup <- rbind(snapshot, snapshot[1, ])
  expect_error(npi_corroborate("1609986611", snapshot = dup), "duplicate")
})

test_that("snapshot_cols maps nonstandard column names", {
  renamed <- data.frame(id = "1609986611", surname = "BAMONTE",
                        st = "OH", stringsAsFactors = FALSE)
  r <- npi_corroborate("1609986611", name = "Anthony Bamonte", state = "OH",
                       snapshot = renamed,
                       snapshot_cols = c(npi = "id", last_name = "surname",
                                         state = "st"))
  expect_identical(r$confidence, "corroborated")
  expect_true(r$name_match)
  expect_true(r$state_match)
})
