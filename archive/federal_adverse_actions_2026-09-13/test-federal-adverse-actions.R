# =============================================================================
# Federal adverse-action acquisition: the guards, not the network.
# =============================================================================
#
# These tests do not hit the network. What they pin is the set of decisions that
# were made because a live probe on 2026-09-13 showed the naive version would
# have been silently wrong:
#
#   1. The DOJ API ACCEPTS filters it does not apply. `topic=health-care-fraud`
#      and `q=physician` both returned the full 272,247-record corpus, byte
#      identical to unfiltered, while `title` genuinely filtered to 1,047. A
#      crawl behind an ignored filter succeeds, looks plausible, and describes a
#      different population than the one asked for.
#
#   2. HHS DAB returns 403 to everything. Four user agents, three URLs. A
#      scraper that returns an empty frame there is indistinguishable from a
#      source with no decisions in it.
#
#   3. The first TRICARE parser reported 9 pages and returned 0 records, without
#      erroring, because a zero-width lookahead split does not behave as assumed
#      in R.
#
# Each of those is a silent-wrongness failure, which is why the guards exist and
# why they are tested rather than the happy path.
# =============================================================================

testthat::local_edition(3)

.root <- local({
  d <- normalizePath(".", mustWork = FALSE)
  while (!file.exists(file.path(d, "DESCRIPTION")) && dirname(d) != d) d <- dirname(d)
  d
})
source(file.path(.root, "R", "federal_adverse_actions.R"))

# --- the tag strip, which the whole DOJ crawl depends on --------------------

testthat::test_that("tags become a space so phrases survive a tag boundary", {
  # Deleting tags instead of replacing them welds words together and destroys
  # exactly the matches the crawl is looking for.
  testthat::expect_equal(
    fast_strip_html("surrendered his medical <em>license</em> in 2019"),
    "surrendered his medical license in 2019")
  testthat::expect_equal(fast_strip_html("<p>a</p><p>b</p>"), "a b")
  testthat::expect_false(grepl("medicallicense",
                               fast_strip_html("medical<br/>license")))
})

testthat::test_that("NEGATIVE CONTROL: a tag-split phrase still matches the pattern", {
  html <- "The defendant <b>surrendered</b> his medical <i>license</i>."
  testthat::expect_true(grepl(DOJ_ACTION_PATTERN, fast_strip_html(html),
                              ignore.case = TRUE, perl = TRUE))
  # and the raw HTML, unstripped, is what would have been missed
  testthat::expect_false(grepl("medical licen[cs]e", html, ignore.case = TRUE))
})

testthat::test_that("fast_strip_html is NA-safe and length-preserving", {
  out <- fast_strip_html(c("<p>x</p>", NA, ""))
  testthat::expect_equal(length(out), 3L)
  testthat::expect_equal(out[[2]], "")
})

# --- what counts as a physician action --------------------------------------

testthat::test_that("the action pattern fires on real DOJ phrasings", {
  for (s in c("agreed to surrender his medical license",
              "surrendered her DEA registration",
              "excluded from all federal health care programs",
              "agreed not to practice medicine in the state",
              "was barred from practicing medicine")) {
    testthat::expect_true(grepl(DOJ_ACTION_PATTERN, s, ignore.case = TRUE,
                                perl = TRUE), info = s)
  }
})

testthat::test_that("NEGATIVE CONTROL: an ordinary fraud release is not an action", {
  # A conviction is not, by itself, evidence that anyone stopped practising.
  # If these matched, the crawl would return most of the health-care-fraud
  # corpus and the signal would be meaningless.
  for (s in c("was sentenced to 36 months in prison for health care fraud",
              "agreed to pay $4 million to resolve False Claims Act allegations",
              "pleaded guilty to one count of conspiracy")) {
    testthat::expect_false(grepl(DOJ_ACTION_PATTERN, s, ignore.case = TRUE,
                                 perl = TRUE), info = s)
  }
})

# --- NPI extraction ---------------------------------------------------------

testthat::test_that("an NPI stated in decision text is recovered", {
  testthat::expect_equal(extract_npis_from_text("Petitioner's NPI: 1265450621."),
                         "1265450621")
  testthat::expect_equal(
    extract_npis_from_text("NPI 1265450621 and NPI 1548367295"),
    "1265450621;1548367295")
})

testthat::test_that("NEGATIVE CONTROL: a bare 10-digit number is not an NPI", {
  # Case numbers, phone numbers and dollar amounts are all 10 digits sometimes.
  # Requiring the NPI label is what keeps those out.
  testthat::expect_true(is.na(extract_npis_from_text("Case No. 1234567890")))
  testthat::expect_true(is.na(extract_npis_from_text("call 2125550123")))
  testthat::expect_true(is.na(extract_npis_from_text("")))
  # NPIs begin with 1 or 2; a 9-prefixed number is not one even if labelled
  testthat::expect_true(is.na(extract_npis_from_text("NPI: 9265450621")))
})

# --- the blocked-source contract --------------------------------------------

testthat::test_that("a blocked source raises a typed condition, never an empty frame", {
  e <- tryCatch(federal_acquisition_blocked("HHS DAB", 403L, "probe"),
                condition = function(c) c)
  testthat::expect_s3_class(e, "federal_acquisition_blocked")
  testthat::expect_s3_class(e, "error")
  testthat::expect_match(conditionMessage(e), "403")
})

testthat::test_that("get_hhs_dab is declared, and cannot quietly return nothing", {
  # It either raises (blocked, the current state) or raises (reachable, parser
  # never written). There is no path on which it returns an unvalidated frame.
  testthat::expect_true(is.function(get_hhs_dab))
  b <- body(get_hhs_dab)
  src <- paste(deparse(b), collapse = " ")
  testthat::expect_match(src, "federal_acquisition_blocked")
  testthat::expect_false(grepl("tibble::tibble\\(\\)", src))
})

# --- the ignored-filter guard -----------------------------------------------

testthat::test_that("doj_assert_filter_effective exists and is wired to the count", {
  testthat::expect_true(is.function(doj_assert_filter_effective))
  src <- paste(deparse(body(doj_assert_filter_effective)), collapse = " ")
  # It must compare against the unfiltered count. A guard that only checks the
  # request succeeded would pass on exactly the failure it exists to catch.
  testthat::expect_match(src, "unfiltered_count")
  testthat::expect_match(src, "stop")
})

# --- provenance that must travel with the rows ------------------------------

testthat::test_that("coverage limits are recorded in the source, not just the prose", {
  src <- paste(readLines(file.path(.root, "R", "federal_adverse_actions.R")),
               collapse = "\n")
  # SAM's extract is active-only; ORI's page is current-only. Both are coverage
  # holes that become invisible the moment a pull is read as a census.
  testthat::expect_match(src, "currently_active_exclusions_only")
  testthat::expect_match(src, "current_administrative_actions_only")
  # TRICARE's staleness and its own reported total must both be carried.
  testthat::expect_match(src, "source_last_updated")
  testthat::expect_match(src, "source_reported_total")
})

testthat::test_that("a DOJ release is labelled as a press release, not a court document", {
  src <- paste(readLines(file.path(.root, "R", "federal_adverse_actions.R")),
               collapse = "\n")
  testthat::expect_match(src, "DOJ_PRESS_RELEASE")
})

testthat::test_that("nothing in this module labels a physician retired", {
  # The acquisition layer records what an agency published. Turning a sanction
  # into a workforce-exit inference is a separate, reviewable decision, and the
  # separation is the point.
  src <- paste(readLines(file.path(.root, "R", "federal_adverse_actions.R")),
               collapse = "\n")
  testthat::expect_false(grepl("retirement_year|is_retired|no_longer_practicing",
                               src))
})
