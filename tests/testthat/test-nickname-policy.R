# The locked nickname policy (NICKNAME_POLICY, decided 2026-09-07 from the
# frozen-matcher ablation): nicknames are EVIDENCE, not a broad search-
# expansion mechanism. Verdict layer retained globally; candidate expansion
# review-only and source-class-gated; auto-acceptance on nickname evidence
# alone impossible. Eight fail-closed tests, one per policy guarantee.

read_fixture_pol <- function() {
  paste(readLines(testthat::test_path("fixtures", "npi_api_response.json"),
                  warn = FALSE), collapse = "\n")
}

# The ablation's condition A: the given-name rule with the table ablated,
# identical normalization and initial handling. Used by tests 4 and 7.
given_agreement_none <- function(a, b) {
  norm <- function(x) gsub("[.]", "", name_key(x))
  ka <- norm(a); kb <- norm(b)
  vapply(seq_along(ka), function(i) {
    x <- ka[i]; y <- kb[i]
    if (!has_name_information(x) || !has_name_information(y))
      return("uninformative")
    if (x == y) return("corroborates")
    if (nchar(x) == 1L || nchar(y) == 1L)
      return(if (substr(x, 1, 1) == substr(y, 1, 1)) "corroborates"
             else "conflicts")
    "conflicts"
  }, character(1))
}

# The reference policy from vignette("roster-benchmark"), parameterized only
# by the given-name rule -- the exact ablation harness, now a regression pin.
benchmark_decisions <- function(given_rule) {
  b <- ROSTER_BENCHMARK
  ex <- extract_suffix(b$roster_name)
  p <- parse_person(ex$name)
  roster_first <- sub(" .*", "", p$first)
  axes <- data.frame(
    surname = surname_agreement(p$last, b$npi_last,
                                middle_a = p$middle, middle_b = b$npi_middle),
    given   = given_rule(roster_first, b$npi_first),
    middle  = middle_agreement(middle_tokens(p$middle),
                               middle_tokens(b$npi_middle)),
    suffix  = suffix_agreement(ex$suffix, b$npi_suffix),
    gender  = gender_agreement(b$roster_gender, b$npi_gender),
    license = license_agreement(b$roster_license, b$roster_state,
                                b$npi_license, b$npi_state))
  excused <- mapply(function(mt, nl)
    length(intersect(mt, surname_tokens(nl))) > 0,
    middle_tokens(p$middle), b$npi_last)
  conflict <- axes$surname == "conflicts" | axes$given == "conflicts" |
    (axes$middle == "conflicts" & !excused) | axes$suffix == "conflicts"
  name_ok <- axes$surname == "corroborates" & axes$given == "corroborates"
  ifelse(conflict, "reject",
  ifelse(!name_ok, "review",
  ifelse(axes$gender == "conflicts", "review", "accept")))
}

test_that("1: nickname-only candidate expansion cannot auto-accept", {
  skip_if_not_installed("jsonlite")
  fake <- function(u) {
    fn <- sub(".*[?&]first_name=([^&]*).*", "\\1", u)
    if (identical(fn, "BILL")) return('{"result_count":0,"results":[]}')
    if (identical(fn, "WILLIAM")) return(paste0(
      '{"result_count":1,"results":[{"number":"1111111111",',
      '"basic":{"first_name":"WILLIAM","last_name":"SMITH"},"addresses":[]}]}'))
    '{"result_count":0,"results":[]}'
  }
  testthat::local_mocked_bindings(npi_fetch_impl = fake)
  got <- npi_search(first_name = "bill", last_name = "smith",
                    name_expansion = "curated_one_hop",
                    source_class = "informal_capable")
  # the only candidate was found ONLY through BILL>WILLIAM: review-only
  expect_identical(got$review_only, TRUE)
  expect_identical(got$acceptance_contribution, "review_candidate")
  expect_error(assert_nickname_policy(got), "POLICY VIOLATION")
  expect_error(assert_nickname_policy(got), "1111111111")
  # a frame that lost its lineage cannot be auto-accepted either
  expect_error(assert_nickname_policy(got[, setdiff(names(got),
                                                    "review_only")]),
               "review_only")
})

test_that("2: informal-name source classes may create review candidates", {
  skip_if_not_installed("jsonlite")
  testthat::local_mocked_bindings(npi_fetch_impl = function(u)
    read_fixture_pol())
  got <- npi_search(first_name = "bill", last_name = "smith",
                    name_expansion = "curated_one_hop",
                    source_class = "informal_capable")
  expect_gt(nrow(got), 0L)
  expect_identical(unique(got$source_class), "informal_capable")
  expect_true(all(got$candidate_expansion_used))
  # rows found by the input itself remain direct evidence and pass the guard
  direct <- got[!got$review_only, , drop = FALSE]
  expect_identical(assert_nickname_policy(direct), direct,
                   ignore_attr = TRUE)
})

test_that("3: formal/legal-name source classes cannot invoke expansion", {
  expect_error(npi_search(first_name = "bill", last_name = "smith",
                          name_expansion = "curated_one_hop"),
               "formal_record source class")
  expect_error(npi_search(first_name = "bill", last_name = "smith",
                          name_expansion = "curated_one_hop",
                          source_class = "formal_record"),
               NICKNAME_POLICY$policy_id, fixed = TRUE)
  expect_error(npi_search(last_name = "smith", source_class = "webby"))
})

test_that("4: verdict-layer nickname evidence rescues adjudicated true matches", {
  B <- benchmark_decisions(nickname_agreement)
  b <- ROSTER_BENCHMARK
  expect_identical(sum(B == "accept" & b$truth == "match"), 126L)
  expect_identical(sum(B == "accept" & b$truth == "nonmatch"), 0L)
  expect_identical(sum(B == "reject" & b$truth == "match"), 0L)
})

test_that("5: verdict-layer conflicts reject known nonmatches", {
  B <- benchmark_decisions(nickname_agreement)
  b <- ROSTER_BENCHMARK
  expect_identical(sum(B == "reject" & b$truth == "nonmatch"), 58L)
  # the vetoes are the table speaking, not edit distance
  expect_identical(nickname_agreement("JANE", "JOAN"), "conflicts")
  expect_identical(nickname_agreement("ELISABETH", "ELIZABETH"), "conflicts")
})

test_that("6: all ten ghost negative controls remain rejected", {
  ghosts <- data.frame(
    a = c("MARVIN", "GEORGE", "CHRISTINA", "PATRICIA", "DANIELLE",
          "ROBERT", "HAROLD", "ALBERT", "ELISABETH", "JANE"),
    b = c("MORRIS", "GRETA", "CHRISTOPHER", "PATRICK", "DANIEL",
          "WILLIAM", "HENRY", "ALEXANDER", "ELIZABETH", "JOAN"),
    stringsAsFactors = FALSE)
  expect_true(all(nickname_agreement(ghosts$a, ghosts$b) == "conflicts"))
  reached <- mapply(function(x, y)
    y %in% nickname_variants(x)$queried_first_name, ghosts$a, ghosts$b)
  expect_false(any(reached))
})

test_that("7: removing nickname evidence reproduces the expected E2 losses", {
  A <- benchmark_decisions(given_agreement_none)
  b <- ROSTER_BENCHMARK
  # the ablation's condition-A table, pinned exactly: 93 accepts, 33 true
  # matches wrongly rejected, still zero false accepts
  expect_identical(sum(A == "accept" & b$truth == "match"), 93L)
  expect_identical(sum(A == "reject" & b$truth == "match"), 33L)
  expect_identical(sum(A == "accept" & b$truth == "nonmatch"), 0L)
})

test_that("8: the run manifest names the governing SHA and dictionary", {
  skip_if_not_installed("jsonlite")
  testthat::local_mocked_bindings(npi_fetch_impl = function(u)
    read_fixture_pol())
  got <- npi_search(first_name = "jane", last_name = "exampleson")
  m <- attr(got, "run_manifest")
  expect_identical(m$nickname_policy, "nickname-policy-2026-09-07")
  expect_identical(m$governing_matcher_sha,
                   "fa7216f8966214cf8e1cc4e265b1b5efe56e2c88")
  expect_identical(m$dictionary_version,
                   attr(mysterynpi::NICKNAME_EDGES, "version"))
  expect_identical(m$name_expansion, "none")
  expect_identical(m$source_class, "formal_record")
  expect_identical(m$verdict_layer, "retain_global")
  expect_identical(m$package_version,
                   as.character(utils::packageVersion("mysterynpi")))
})
