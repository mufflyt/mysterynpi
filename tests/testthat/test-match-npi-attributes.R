attr_roster <- function() {
  data.frame(
    record = c("tie_state", "tie_cred", "gender_veto", "tax", "lic", "grad", "blank"),
    first = c("Mary", "Mary", "Jane", "Anne", "Carol", "Dana", "Evan"),
    last = c("Jones", "Jones", "Doe", "Nelson", "White", "Reed", "Stone"),
    state = c("RI", NA, "CO", NA, "CO", NA, NA),
    sex = c(NA, NA, "F", NA, NA, NA, NA),
    credential = c(NA, "DO", NA, NA, NA, NA, NA),
    taxonomy = c(NA, NA, NA, "207V", NA, NA, NA),
    license = c(NA, NA, NA, NA, "C-100", NA, NA),
    license_state = c(NA, NA, NA, NA, "CO", NA, NA),
    grad_year = c(NA, NA, NA, NA, NA, 2010, NA),
    stringsAsFactors = FALSE)
}

attr_reference <- function() {
  data.frame(
    provider = c("1012000000", "1020000000", "1234567893", "1245319599", "1004000000",
                 "1038000000", "1046000000", "1053000000", "1061000000"),
    type = "1",
    first = c("Mary", "Mary", "Jane", "Anne", "Carol", "Carol", "Dana", "Evan", "Mary"),
    last = c("Jones", "Jones", "Doe", "Nelson", "White", "White", "Reed", "Stone", "Jones"),
    st = c("CO", "RI", "CO", "CO", "CO", "CO", NA, NA, NA),
    sex = c(NA, NA, "M", NA, NA, NA, NA, NA, NA),
    cred = c("M.D.", "MD", NA, NA, NA, NA, NA, NA, "DO, PhD"),
    tax = c(NA, NA, NA, "207V00000X", NA, NA, NA, NA, NA),
    lic = c(NA, NA, NA, NA, "C100", "C200", NA, NA, NA),
    lic_state = c(NA, NA, NA, NA, "CO", "CO", NA, NA, NA),
    cred_year = c(NA, NA, NA, NA, NA, NA, "1985-01-01", NA, NA),
    stringsAsFactors = FALSE)
}

attr_map <- function() {
  list(state = c(roster = "state", nppes = "st"),
       gender = c(roster = "sex", nppes = "sex"),
       credential = c(roster = "credential", nppes = "cred"),
       taxonomy = c(roster = "taxonomy", nppes = "tax"),
       license = c(roster = "license", roster_state = "license_state",
                   nppes = "lic", nppes_state = "lic_state"),
       graduation_year = c(roster = "grad_year", nppes = "cred_year"))
}

attr_match <- function(roster = attr_roster(), nppes = attr_reference(), ...) {
  match_npi(roster, nppes, id = "record", given = "first", surname = "last",
            npi = "provider", entity_type = "type", nppes_given = "first",
            nppes_surname = "last", ...)
}

reason_of <- function(result, record) {
  all <- rbind(result$matches, result$review, result$unmatched)
  all$reason[all$record == record]
}

test_that("attributes veto, corroborate, and break ties with canonical verdicts", {
  plain <- attr_match()
  expect_identical(reason_of(plain, "tie_state"), "ambiguous_tied_evidence")
  expect_identical(reason_of(plain, "tie_cred"), "ambiguous_tied_evidence")
  expect_identical(reason_of(plain, "gender_veto"), "unique_best_evidence")
  expect_identical(reason_of(plain, "lic"), "ambiguous_tied_evidence")
  expect_identical(reason_of(plain, "grad"), "unique_best_evidence")
  expect_false("state_evidence" %in% names(plain$candidates))
  expect_true(all(plain$candidates$attribute_rank == 0L))

  result <- attr_match(attributes = attr_map())
  # Two conflicting Mary Joneses drop out; the RI one is left standing alone.
  expect_identical(reason_of(result, "tie_state"), "unique_best_evidence")
  expect_identical(result$matches$npi[result$matches$record == "tie_state"], "1020000000")
  # A DO against two MDs and one "DO, PhD": shared degree corroborates.
  expect_identical(result$matches$npi[result$matches$record == "tie_cred"], "1061000000")
  # Gender conflict vetoes a name-exact candidate into review.
  expect_identical(reason_of(result, "gender_veto"), "gender_conflict")
  expect_true(is.na(result$review$npi[result$review$record == "gender_veto"]))
  # Taxonomy prefix corroborates; license number + state breaks the White tie.
  expect_identical(reason_of(result, "tax"), "unique_best_evidence")
  expect_identical(result$matches$npi[result$matches$record == "lic"], "1004000000")
  # Graduation year beyond ten years is a flag: review, not deletion.
  expect_identical(reason_of(result, "grad"), "graduation_year_conflict")
  # Blank on either side changes nothing.
  expect_identical(reason_of(result, "blank"), "unique_best_evidence")

  cand <- result$candidates
  expect_true(all(c("state_evidence", "gender_evidence", "credential_evidence",
                    "taxonomy_evidence", "license_evidence", "graduation_year_evidence",
                    "attribute_rank") %in% names(cand)))
  expect_identical(cand$state_evidence[cand$source_id == "tie_state" & cand$npi == "1012000000"],
                   "conflicts")
  expect_identical(cand$state_evidence[cand$source_id == "tie_state" & cand$npi == "1020000000"],
                   "corroborates")
  expect_identical(cand$state_evidence[cand$source_id == "tie_state" & cand$npi == "1061000000"],
                   "uninformative")
  expect_identical(cand$license_evidence[cand$source_id == "lic" & cand$npi == "1004000000"],
                   "corroborates")
  expect_identical(cand$license_evidence[cand$source_id == "lic" & cand$npi == "1038000000"],
                   "uninformative")
  expect_identical(cand$taxonomy_evidence[cand$source_id == "tax"], "corroborates")
  expect_identical(cand$attribute_rank[cand$source_id == "lic" & cand$npi == "1004000000"], 2L)
  expect_identical(result$counts$blocked_by_attribute,
                   stats::setNames(integer(6), names(attr_map())))
  expect_identical(result$run_manifest$attributes, attr_map())
  expect_identical(result$run_manifest$block, character())
})

test_that("block removes conflicting candidates before evidence and counts them", {
  result <- attr_match(attributes = attr_map(), block = c("state", "gender"))
  expect_identical(reason_of(result, "tie_state"), "unique_best_evidence")
  expect_false(any(result$candidates$source_id == "tie_state" &
                     result$candidates$npi == "1012000000"))
  # The gender-conflicting Jane Doe is gone entirely: no candidate remains.
  expect_identical(reason_of(result, "gender_veto"), "no_candidate")
  expect_false(any(result$candidates$source_id == "gender_veto"))
  expect_identical(result$counts$blocked_by_attribute[["state"]], 1L)
  expect_identical(result$counts$blocked_by_attribute[["gender"]], 1L)
  expect_identical(result$counts$blocked_by_attribute[["credential"]], 0L)
  expect_identical(result$run_manifest$block, c("state", "gender"))
  # Graduation year left out of block still flags rather than deletes.
  expect_identical(reason_of(result, "grad"), "graduation_year_conflict")
})

test_that("attribute specs are validated before any matching runs", {
  expect_error(attr_match(attributes = list(c(roster = "state", nppes = "st"))), "named list")
  expect_error(attr_match(attributes = list(zip = c(roster = "state", nppes = "st"))),
               "unknown attribute")
  expect_error(attr_match(attributes = list(state = c(roster = "state"))), "roster, nppes")
  expect_error(attr_match(attributes = list(license = c(roster = "license", nppes = "lic"))),
               "roster_state")
  expect_error(attr_match(attributes = list(state = c(roster = "zip", nppes = "st"))),
               "roster is missing attribute column")
  expect_error(attr_match(attributes = list(state = c(roster = "state", nppes = "zip"))),
               "nppes is missing attribute column")
  expect_error(attr_match(attributes = list(state = c(roster = "state", nppes = "st")),
                          block = "gender"), "block names must be mapped")
  expect_error(attr_match(block = "state"), "block names must be mapped")
})

test_that("disagreeing reference rows for one NPI make the attribute uninformative", {
  nppes <- attr_reference()
  nppes <- rbind(nppes, nppes[nppes$provider == "1020000000", ])
  nppes$st[nrow(nppes)] <- "TX"
  result <- attr_match(nppes = nppes, attributes = list(state = c(roster = "state", nppes = "st")))
  cand <- result$candidates
  expect_identical(cand$state_evidence[cand$source_id == "tie_state" & cand$npi == "1020000000"],
                   "uninformative")
  expect_identical(reason_of(result, "tie_state"), "ambiguous_tied_evidence")
})

test_that("attribute verdicts are identical through the DuckDB backend", {
  skip_if_not_installed("duckdb")
  roster <- attr_roster()
  reference <- attr_reference()
  reference$provider_num <- as.numeric(reference$provider)
  memory <- match_npi(roster, reference, id = "record", given = "first", surname = "last",
                      npi = "provider_num", entity_type = "type", nppes_given = "first",
                      nppes_surname = "last", attributes = attr_map(), block = "state")
  path <- withr::local_tempfile(fileext = ".duckdb")
  con <- DBI::dbConnect(duckdb::duckdb(), path)
  DBI::dbWriteTable(con, "reference", reference)
  DBI::dbDisconnect(con, shutdown = TRUE)
  con <- DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)
  withr::defer(DBI::dbDisconnect(con, shutdown = TRUE))
  before <- DBI::dbGetQuery(con, "SELECT table_name FROM duckdb_tables() WHERE NOT temporary")
  duck <- match_npi(roster, con, table = "reference", id = "record", given = "first",
                    surname = "last", npi = "provider_num", entity_type = "type",
                    nppes_given = "first", nppes_surname = "last",
                    attributes = attr_map(), block = "state")
  for (part in c("matches", "review", "unmatched", "candidates", "counts")) {
    expect_identical(duck[[part]], memory[[part]], info = part)
  }
  expect_identical(DBI::dbGetQuery(con, "SELECT table_name FROM duckdb_tables() WHERE NOT temporary"),
                   before)
  expect_equal(DBI::dbGetQuery(con,
    "SELECT count(*) AS n FROM duckdb_tables() WHERE temporary")$n, 0)
  expect_error(match_npi(roster, con, table = "reference", id = "record", given = "first",
                         surname = "last", npi = "provider_num", entity_type = "type",
                         nppes_given = "first", nppes_surname = "last",
                         attributes = list(state = c(roster = "state", nppes = "zip"))),
               "nppes is missing attribute column")
})
