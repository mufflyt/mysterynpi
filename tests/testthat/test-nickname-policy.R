# The locked nickname policy (NICKNAME_POLICY): governed configuration with
# machine-readable evidence. The pinned counts live in
# fixtures/ablation/ablation_pins_v1.csv; the coupling test freezes that
# fixture's checksum NEXT TO the policy_id, so editing the evidence without
# superseding the policy fails here, by construction.

read_fixture_pol <- function() {
  paste(readLines(testthat::test_path("fixtures", "npi_api_response.json"),
                  warn = FALSE), collapse = "\n")
}
ablation_pins <- function() {
  p <- utils::read.csv(testthat::test_path("fixtures", "ablation",
                                           "ablation_pins_v1.csv"),
                       comment.char = "#", stringsAsFactors = FALSE)
  stats::setNames(p$value, paste(p$arm, p$metric, sep = "."))
}

# The ablation's condition A: the given-name rule with the table ablated,
# identical normalization and initial handling.
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

# The overlapping-NPI mock: 1111111111 found by BILL and WILLIAM;
# 2222222222 by BILL only; 3333333333 by WILLIAM only.
overlap_mock <- function(u) {
  fn <- sub(".*[?&]first_name=([^&]*).*", "\\1", u)
  npis <- switch(fn,
                 BILL    = c("1111111111", "2222222222"),
                 WILLIAM = c("1111111111", "3333333333"),
                 character(0))
  if (!length(npis)) return('{"result_count":0,"results":[]}')
  rows <- paste(sprintf(
    '{"number":"%s","basic":{"first_name":"%s","last_name":"SMITH"},"addresses":[]}',
    npis, fn), collapse = ",")
  sprintf('{"result_count":%d,"results":[%s]}', length(npis), rows)
}

test_that("A1: the policy object is versioned and frozen with its evidence", {
  p <- NICKNAME_POLICY
  expect_identical(p$policy_id, "nickname-policy-2026-09-07")
  expect_identical(p$effective_date, "2026-09-07")
  expect_identical(p$supersedes, NA_character_)
  expect_identical(p$verdict_layer, "retain_global")
  expect_identical(p$candidate_expansion, "retain_review_only")
  expect_identical(p$auto_accept_rule, "never_on_nickname_evidence_alone")
  expect_identical(p$governing_matcher_sha,
                   "fa7216f8966214cf8e1cc4e265b1b5efe56e2c88")
  expect_identical(p$dictionary_version, "2026-09-06.1")
  expect_true(nzchar(p$governing_evidence))
  # COUPLING: the evidence fixture's checksum is pinned NEXT TO the
  # policy_id. Changing the fixture without a new policy version (a new
  # policy_id, evidence, and supersedes chain) fails right here.
  fx <- paste(readLines(testthat::test_path("fixtures", "ablation",
                                            "ablation_pins_v1.csv")),
              collapse = "\n")
  expect_identical(sum(utf8ToInt(fx)), 69444L)
})

test_that("A2: the source-class registry is canonical and fail-closed", {
  expect_identical(SOURCE_CLASSES$class,
                   c("formal_record", "informal_capable", "unknown"))
  expect_identical(SOURCE_CLASSES$expansion,
                   c("forbidden", "review_only", "fail_closed"))
  # unregistered classes earn fail_closed, never a permission
  expect_identical(source_class_permission("faculty_page"), "fail_closed")
  expect_identical(source_class_permission(NA_character_), "fail_closed")
})

test_that("A7: ROBERT>BILL stands as governed evidence, exactly as tested", {
  g <- NICKNAME_POLICY$governed_edges[["ROBERT>BILL"]]
  expect_identical(g$observed_rescues, 0L)
  expect_identical(g$observed_candidate_inflation, "present")
  expect_identical(g$policy_containment, "review_only")
  expect_true("ROBERT>BILL" %in% mysterynpi::NICKNAME_EDGES$edge_id)
})

test_that("1: nickname-only candidate expansion cannot auto-accept", {
  skip_if_not_installed("jsonlite")
  fake <- function(u) {
    fn <- sub(".*[?&]first_name=([^&]*).*", "\\1", u)
    if (identical(fn, "WILLIAM")) return(paste0(
      '{"result_count":1,"results":[{"number":"1111111111",',
      '"basic":{"first_name":"WILLIAM","last_name":"SMITH"},"addresses":[]}]}'))
    '{"result_count":0,"results":[]}'
  }
  testthat::local_mocked_bindings(npi_fetch_impl = fake)
  got <- npi_search(first_name = "bill", last_name = "smith",
                    name_expansion = "curated_one_hop",
                    source_class = "informal_capable")
  # all other evidence absent: the candidate exists ONLY because of the
  # BILL>WILLIAM edge. It may enter the review queue; it may never be
  # auto-accepted.
  expect_identical(got$review_only, TRUE)
  expect_identical(got$acceptance_contribution, "nickname_only")
  expect_error(assert_nickname_policy(got), "POLICY VIOLATION")
  expect_error(assert_nickname_policy(got), "1111111111")
  expect_error(assert_nickname_policy(got[, setdiff(names(got),
                                                    "review_only")]),
               "lineage column")
})

test_that("A8 inverse: independent evidence plus nickname evidence may be
           accepted, with nickname recorded as not independently sufficient", {
  skip_if_not_installed("jsonlite")
  testthat::local_mocked_bindings(npi_fetch_impl = overlap_mock)
  got <- npi_search(first_name = "bill", last_name = "smith",
                    name_expansion = "curated_one_hop",
                    source_class = "informal_capable")
  shared <- got[got$npi == "1111111111", ]
  # both paths preserved, never collapsed
  expect_identical(shared$found_by_edges, "input|BILL>WILLIAM")
  expect_identical(shared$acceptance_contribution, "supporting")
  expect_false(shared$review_only)
  only_input <- got[got$npi == "2222222222", ]
  expect_identical(only_input$acceptance_contribution, "none")
  only_edge <- got[got$npi == "3333333333", ]
  expect_identical(only_edge$acceptance_contribution, "nickname_only")
  # acceptance may occur for the supported rows; the nickname-only row is
  # refused by the same guard in the same frame
  ok <- got[got$acceptance_contribution %in% c("none", "supporting"), ]
  expect_identical(assert_nickname_policy(ok), ok, ignore_attr = TRUE)
  expect_error(assert_nickname_policy(got), "POLICY VIOLATION")
})

test_that("A4: broken lineage fails closed, whatever the verdict flags say", {
  skip_if_not_installed("jsonlite")
  testthat::local_mocked_bindings(npi_fetch_impl = overlap_mock)
  got <- npi_search(first_name = "bill", last_name = "smith",
                    name_expansion = "curated_one_hop",
                    source_class = "informal_capable")
  clean <- got[got$acceptance_contribution %in% c("none", "supporting"), ]
  hole <- clean; hole$alias_dictionary_version <- NA_character_
  expect_error(assert_nickname_policy(hole), "alias_dictionary_version")
  hole2 <- clean; hole2$found_by_edges <- NA_character_
  expect_error(assert_nickname_policy(hole2), "found_by_edges")
  gone <- clean[, setdiff(names(clean), "acceptance_contribution")]
  expect_error(assert_nickname_policy(gone), "lineage column")
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
  direct <- got[!got$review_only, , drop = FALSE]
  expect_identical(assert_nickname_policy(direct), direct,
                   ignore_attr = TRUE)
})

test_that("3: formal and unknown source classes cannot invoke expansion", {
  expect_error(npi_search(first_name = "bill", last_name = "smith",
                          name_expansion = "curated_one_hop"),
               "forbidden")
  expect_error(npi_search(first_name = "bill", last_name = "smith",
                          name_expansion = "curated_one_hop",
                          source_class = "formal_record"),
               NICKNAME_POLICY$policy_id, fixed = TRUE)
  # unknown fails CLOSED: no implicit fallback to informal-capable
  expect_error(npi_search(first_name = "bill", last_name = "smith",
                          name_expansion = "curated_one_hop",
                          source_class = "unknown"),
               "fail_closed")
  # free text never reaches the registry
  expect_error(npi_search(last_name = "smith", source_class = "webby"))
})

test_that("4+5: verdict layer reproduces the pinned ablation fixture", {
  pins <- ablation_pins()
  B <- benchmark_decisions(nickname_agreement)
  b <- ROSTER_BENCHMARK
  expect_identical(sum(B == "accept" & b$truth == "match"),
                   pins[["with_table.auto_accept_true"]])
  expect_identical(sum(B == "accept" & b$truth == "nonmatch"),
                   pins[["with_table.auto_accept_false"]])
  expect_identical(sum(B == "reject" & b$truth == "match"),
                   pins[["with_table.rejected_true_matches"]])
  expect_identical(sum(B == "review"),
                   pins[["with_table.review_queue"]])
  expect_identical(sum(B == "reject" & b$truth == "nonmatch"),
                   pins[["with_table.nonmatch_rejected"]])
  expect_identical(nickname_agreement("JANE", "JOAN"), "conflicts")
  expect_identical(nickname_agreement("ELISABETH", "ELIZABETH"), "conflicts")
})

test_that("6: all ten ghost negative controls remain rejected", {
  pins <- ablation_pins()
  ghosts <- data.frame(
    a = c("MARVIN", "GEORGE", "CHRISTINA", "PATRICIA", "DANIELLE",
          "ROBERT", "HAROLD", "ALBERT", "ELISABETH", "JANE"),
    b = c("MORRIS", "GRETA", "CHRISTOPHER", "PATRICK", "DANIEL",
          "WILLIAM", "HENRY", "ALEXANDER", "ELIZABETH", "JOAN"),
    stringsAsFactors = FALSE)
  expect_identical(sum(nickname_agreement(ghosts$a, ghosts$b) ==
                         "corroborates"),
                   pins[["controls.ghosts_corroborated"]])
  reached <- mapply(function(x, y)
    y %in% nickname_variants(x)$queried_first_name, ghosts$a, ghosts$b)
  expect_identical(sum(reached),
                   pins[["controls.ghosts_reachable_by_expansion"]])
})

test_that("7: removing nickname evidence reproduces the pinned E2 losses", {
  pins <- ablation_pins()
  A <- benchmark_decisions(given_agreement_none)
  b <- ROSTER_BENCHMARK
  expect_identical(sum(A == "accept" & b$truth == "match"),
                   pins[["without_table.auto_accept_true"]])
  expect_identical(sum(A == "reject" & b$truth == "match"),
                   pins[["without_table.rescued_by_table"]])
  expect_identical(sum(A == "accept" & b$truth == "nonmatch"),
                   pins[["without_table.auto_accept_false"]])
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

test_that("A3: the manifest reads the dictionary only through the accessor", {
  syms <- all.names(body(npi_search))
  expect_false("NICKNAME_EDGES" %in% syms)
  expect_true("nickname_dictionary_version" %in% syms)
  expect_identical(mysterynpi:::nickname_dictionary_version(),
                   attr(mysterynpi::NICKNAME_EDGES, "version"))
})
