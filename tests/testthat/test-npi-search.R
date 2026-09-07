# The parser is tested against a stored SYNTHETIC fixture; no test here ever
# touches the network. npi_search() itself is a thin fetch over this parser
# and is exercised only for its argument validation.

read_fixture <- function() {
  paste(readLines(testthat::test_path("fixtures", "npi_api_response.json"),
                  warn = FALSE), collapse = "\n")
}

test_that("a full record parses into the columns a linkage wants", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(nrow(got), 2L)
  r <- got[1, ]
  expect_identical(r$npi, "1234567893")
  expect_identical(r$first, "JANE")
  expect_identical(r$middle, "QUINN")
  expect_identical(r$last, "EXAMPLESON")
  expect_identical(r$honorific, "DR.")
  expect_identical(r$credential, "M.D.")
  expect_identical(r$gender, "F")
  expect_identical(r$gender_code, "F")
  # LOCATION address wins over MAILING, and zip5 is derived from zip9
  expect_identical(r$zip, "80204")
  expect_identical(r$zip_full, "802044597")
  expect_identical(r$state, "CO")
  expect_identical(r$enumeration_date, "2006-07-01")
  expect_identical(r$years_enumerated, 20L)
  expect_identical(r$last_updated, "2025-01-14")
  expect_identical(r$retrieved, "2026-09-05")
})

test_that("NPPES absence -- missing key, empty, or the '--' sentinel -- is NA", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(got$suffix[1], NA_character_)      # "--" sentinel
  expect_identical(got$middle[2], NA_character_)      # key absent entirely
  expect_identical(got$honorific[2], NA_character_)
  # the sentinel must be uninformative downstream, never a fake veto
  expect_identical(suffix_agreement(got$suffix[1], "JR"), "uninformative")
})

test_that("an unmappable sex code carries its raw value but normalises to NA", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(got$gender_code[2], "X")
  expect_identical(got$gender[2], NA_character_)
  expect_identical(gender_agreement(got$gender[2], "F"), "uninformative")
})

test_that("a record without a LOCATION address falls back to what exists", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(got$zip[2], "80011")
  expect_identical(got$zip_full[2], "80011")
})

test_that("an empty result set is zero rows with every column present", {
  skip_if_not_installed("jsonlite")
  got <- parse_npi_search('{"result_count":0, "results":[]}',
                          retrieved = as.Date("2026-09-05"))
  expect_identical(nrow(got), 0L)
  expect_true(all(c("npi", "first", "middle", "last", "suffix", "honorific",
                    "credential", "gender", "gender_code", "zip", "zip_full",
                    "state", "enumeration_date", "years_enumerated",
                    "last_updated", "retrieved") %in% names(got)))
})

test_that("an API error surfaces as an error, never as an empty success", {
  skip_if_not_installed("jsonlite")
  expect_error(
    parse_npi_search(
      '{"Errors":[{"description":"limit must be <= 200","field":"limit"}]}',
      retrieved = as.Date("2026-09-05")),
    "limit must be")
})

test_that("the parse is reproducible because retrieved is explicit", {
  skip_if_not_installed("jsonlite")
  a <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  b <- parse_npi_search(read_fixture(), retrieved = as.Date("2026-09-05"))
  expect_identical(a, b)
  later <- parse_npi_search(read_fixture(), retrieved = as.Date("2027-09-05"))
  expect_identical(later$years_enumerated[1], 21L)
  expect_error(parse_npi_search(read_fixture(), retrieved = c(Sys.Date(),
                                                              Sys.Date())),
               "single date")
})

test_that("licenses come out long, state-scoped, sentinels dropped", {
  skip_if_not_installed("jsonlite")
  lic <- parse_npi_licenses(read_fixture())
  # provider 1 carries CO + TX licenses; its '--' taxonomy and the whole
  # licenseless provider 2 contribute NOTHING -- a dropped row, not an NA row
  expect_identical(nrow(lic), 2L)
  expect_identical(lic$npi, rep("1234567893", 2))
  expect_identical(lic$state, c("CO", "TX"))
  expect_identical(lic$license, c("MD.0012345", "Q9876"))
  expect_identical(lic$primary, c(TRUE, FALSE))
  expect_false(anyNA(lic$license))
})

test_that("the extracted rows close the loop into license_agreement()", {
  skip_if_not_installed("jsonlite")
  lic <- parse_npi_licenses(read_fixture())
  # a roster carrying the CO license: best verdict across the NPI's rows
  v <- license_agreement(rep("MD-0012345", nrow(lic)), rep("CO", nrow(lic)),
                         lic$license, lic$state)
  expect_identical(v, c("corroborates", "uninformative"))
  # a roster in a third state corroborates nothing and vetoes nothing
  v2 <- license_agreement(rep("555", nrow(lic)), rep("WY", nrow(lic)),
                          lic$license, lic$state)
  expect_true(all(v2 == "uninformative"))
})

test_that("an empty result set yields the empty license frame", {
  skip_if_not_installed("jsonlite")
  lic <- parse_npi_licenses('{"result_count":0, "results":[]}')
  expect_identical(nrow(lic), 0L)
  expect_identical(names(lic), c("npi", "state", "license", "taxonomy_code",
                                 "taxonomy_desc", "primary"))
})

test_that("npi_search refuses bad arguments before touching the network", {
  expect_error(npi_search(), "at least one search criterion")
  expect_error(npi_search(last_name = "SMITH", limit = 0), "between 1 and 200")
  expect_error(npi_search(last_name = "SMITH", limit = 500), "between 1 and 200")
})

test_that("nickname_variants is the auditable expansion PLAN, one hop", {
  v <- nickname_variants("BILL")
  expect_identical(names(v), c("input_first_name", "queried_first_name",
                               "alias_edge_id", "alias_dictionary_version"))
  expect_identical(v$queried_first_name[1], "BILL")   # the query leads
  expect_true(is.na(v$alias_edge_id[1]))              # identity row: no edge
  expect_true(all(v$input_first_name == "BILL"))
  expect_true(all(c("WILLIAM", "BILLY") %in% v$queried_first_name))
  # every fan-out row is attributable to one real row of the dictionary,
  # at the version the plan was computed against
  fanned <- v[-1, ]
  expect_true(all(fanned$alias_edge_id %in% mysterynpi::NICKNAME_EDGES$edge_id))
  # BILL~WILLIAM is recorded in both directions; the FORWARD edge is credited
  expect_identical(v$alias_edge_id[v$queried_first_name == "WILLIAM"],
                   "BILL>WILLIAM")
  expect_identical(unique(v$alias_dictionary_version),
                   attr(mysterynpi::NICKNAME_EDGES, "version"))
  a <- nickname_variants("ALBERT")$queried_first_name
  expect_true("AL" %in% a)
  expect_false("ALEXANDER" %in% a)                    # one hop, never closure
  expect_false("WILLIAM" %in%                          # issue-4 fix holds
                 nickname_variants("ROBERT")$queried_first_name)
  expect_identical(nickname_variants("XZQK")$queried_first_name, "XZQK")
  expect_identical(nrow(nickname_variants(NA)), 0L)
  expect_identical(nrow(nickname_variants("")), 0L)
  custom <- data.frame(name = "XZQK", nickname = "XQ", stringsAsFactors = FALSE)
  vc <- nickname_variants("XZQK", edges = custom)
  expect_identical(vc$queried_first_name, c("XZQK", "XQ"))
  expect_identical(vc$alias_edge_id, c(NA, "XZQK>XQ"))
  expect_true(is.na(vc$alias_dictionary_version[1]))  # unversioned table: NA
})

test_that("a second hop is reachable in the corpus but never traversed", {
  # real-corpus fixture: BILL reaches FRED in one hop, FRED reaches
  # FREDERICK in one hop -- so a refactor that closed the graph WOULD
  # surface FREDERICK under BILL, and this test would catch it
  expect_true("FRED" %in% nickname_variants("BILL")$queried_first_name)
  expect_true("FREDERICK" %in% nickname_variants("FRED")$queried_first_name)
  expect_false("FREDERICK" %in% nickname_variants("BILL")$queried_first_name)
  # synthetic chain: A-B recorded, B-C recorded, A never reaches C
  chain <- data.frame(name = c("AAAA", "BBBB"), nickname = c("BBBB", "CCCC"),
                      stringsAsFactors = FALSE)
  expect_identical(nickname_variants("AAAA", edges = chain)$queried_first_name,
                   c("AAAA", "BBBB"))
  # synthetic 2-cycle: both directions recorded; terminates, no closure
  cyc <- data.frame(name = c("AAAA", "BBBB"), nickname = c("BBBB", "AAAA"),
                    stringsAsFactors = FALSE)
  vc <- nickname_variants("AAAA", edges = cyc)
  expect_identical(vc$queried_first_name, c("AAAA", "BBBB"))
  expect_identical(vc$alias_edge_id, c(NA, "AAAA>BBBB"))  # forward credited
})

test_that("cardinality guard: fan-out above max_expansion stops, loudly", {
  wide <- data.frame(name = "AAAA", nickname = paste0("B", LETTERS[1:26]),
                     stringsAsFactors = FALSE)
  expect_error(nickname_variants("AAAA", edges = wide),
               "dictionary defect")
  # raising the ceiling explicitly IS the review; no silent truncation
  expect_identical(nrow(nickname_variants("AAAA", edges = wide,
                                          max_expansion = 40L)), 27L)
  # the shipped corpus's widest name (CHRIS, 18 variants) clears the default
  expect_identical(nrow(nickname_variants("CHRIS")), 19L)
  expect_error(nickname_variants("BILL", max_expansion = 0),
               "positive integer")
})

test_that("name_expansion is an enum, and unknown modes are rejected", {
  expect_error(npi_search(last_name = "SMITH", name_expansion = "fuzzy"))
  expect_error(npi_search(last_name = "SMITH", name_expansion = TRUE))
  expect_error(npi_search(last_name = "SMITH", name_expansion = "both"))
})

# -- BEHAVIORAL alias tests: mock the transport, assert on real URLs ----------
# The first alias-back-on campaign run proved source-text inspection is not a
# guard: `if (FALSE) <flag>` still contains the flag string. These tests
# intercept npi_fetch_impl -- the single network seam -- and assert on what
# would actually go over the wire.

test_that("every outbound name query carries use_first_name_alias=False", {
  skip_if_not_installed("jsonlite")
  seen <- character(0)
  testthat::local_mocked_bindings(
    npi_fetch_impl = function(u) { seen[[length(seen) + 1L]] <<- u
                                   read_fixture() })
  got <- npi_search(first_name = "bill", last_name = "smith", state = "CO",
                    name_expansion = "curated_one_hop")
  plan <- nickname_variants("BILL")
  expect_identical(length(seen), nrow(plan))          # one fetch per plan row
  expect_true(all(grepl("use_first_name_alias=False", seen, fixed = TRUE)))
  # the URLs execute the plan verbatim, in plan order
  sent <- sub(".*[?&]first_name=([^&]*).*", "\\1", seen)
  expect_identical(sent, plan$queried_first_name)
  # dedup keeps the identity row's provenance (fixture repeats its NPIs)
  expect_identical(nrow(got), 2L)
  expect_identical(unique(got$input_first_name), "BILL")
  expect_identical(unique(got$queried_first_name), "BILL")
  expect_true(all(is.na(got$alias_edge_id)))
  expect_identical(unique(got$alias_dictionary_version),
                   attr(mysterynpi::NICKNAME_EDGES, "version"))
})

test_that("name_expansion='none' sends exactly one query, still alias-off", {
  skip_if_not_installed("jsonlite")
  seen <- character(0)
  testthat::local_mocked_bindings(
    npi_fetch_impl = function(u) { seen[[length(seen) + 1L]] <<- u
                                   read_fixture() })
  got <- npi_search(first_name = "bill", last_name = "smith")
  expect_identical(length(seen), 1L)
  expect_true(grepl("use_first_name_alias=False", seen, fixed = TRUE))
  expect_true(grepl("first_name=bill", seen, fixed = TRUE))
  # provenance columns are ALWAYS present, expansion or not
  expect_identical(unique(got$input_first_name), "bill")
  expect_identical(unique(got$queried_first_name), "bill")
  expect_true(all(is.na(got$alias_edge_id)))
})

test_that("a query without a first name sends neither the name nor the flag", {
  skip_if_not_installed("jsonlite")
  seen <- character(0)
  testthat::local_mocked_bindings(
    npi_fetch_impl = function(u) { seen[[length(seen) + 1L]] <<- u
                                   read_fixture() })
  got <- npi_search(npi = "1234567893")
  expect_identical(length(seen), 1L)
  expect_false(grepl("first_name", seen, fixed = TRUE))
  expect_false(grepl("use_first_name_alias", seen, fixed = TRUE))
  expect_true(all(is.na(got$input_first_name)))
  expect_true(all(is.na(got$queried_first_name)))
})

test_that("licenses=TRUE unions licenses across the expanded fetches", {
  skip_if_not_installed("jsonlite")
  testthat::local_mocked_bindings(npi_fetch_impl = function(u) read_fixture())
  got <- npi_search(first_name = "bill", last_name = "smith",
                    name_expansion = "curated_one_hop", licenses = TRUE)
  expect_identical(names(got), c("providers", "licenses"))
  expect_identical(nrow(got$licenses), 2L)            # unique(), not stacked
  expect_true(all(c("input_first_name", "alias_edge_id") %in%
                    names(got$providers)))
})

test_that("INVARIANT: exactly one route from input name to query variants", {
  # No function outside the canonical module may read the dictionary to
  # manufacture first-name variants, and only npi_search may execute the
  # expansion. all.names() sees both bare and mysterynpi::-qualified uses.
  ns <- asNamespace("mysterynpi")
  fns <- Filter(function(n) is.function(get0(n, envir = ns)),
                ls(ns, all.names = TRUE))
  # scan the BODY and the FORMALS: `edges = mysterynpi::NICKNAME_EDGES`
  # default arguments live in formals, not the body
  uses <- function(f, sym) {
    g <- get(f, envir = ns)
    syms <- c(all.names(body(g)),
              unlist(lapply(formals(g), function(d)
                tryCatch(all.names(d), error = function(e) character(0)))))
    sym %in% syms
  }
  edge_readers <- Filter(function(f) uses(f, "NICKNAME_EDGES"), fns)
  expect_true(all(edge_readers %in% c("nickname_agreement",
                                      "nickname_variants",
                                      "create_nickname_dictionary")),
              info = paste("unexpected NICKNAME_EDGES reader:",
                           paste(edge_readers, collapse = ", ")))
  expanders <- Filter(function(f) uses(f, "nickname_variants"), fns)
  expect_identical(sort(expanders), "npi_search")
})
