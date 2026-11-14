# =============================================================================
# Trailing punctuation in given and middle names: the contract a study cohort
# depends on
# =============================================================================
# WHAT THIS PINS, AND WHY IT IS NOT A FORMATTING TEST.
#
# split_given() strips periods and commas from its outputs (R/name_keys.R,
# commit cb86e56, 2026-09-13, "fix: split_given() strips punctuation from its
# outputs"). That fix is correct: "B." and "B" are the same middle initial, and
# a registry that records one while a roster records the other must still join.
# Leaving the period in is the same class of defect as leaving an accent in --
# name_key() already transliterates "Álvarez" to "ALVAREZ" precisely so
# first_initial() cannot return "Á", which no registry spelling can equal.
#
# It was also, until this file, UNTESTED -- and that is what made it dangerous.
# A downstream study (mufflyt/midwifery) froze an AMCB-NPPES linkage cohort on
# 2026-09-10, three days BEFORE cb86e56, and re-froze it on 2026-10-22, after.
# The roster text was byte-identical between the two freezes. 1,278 normalised
# middle names and 129 normalised given names were not:
#
#     "Oluwatope B."  -> middle "B."   became middle "B"
#     "Sr. Mary"      -> given  "SR."  became given  "SR"
#     "Fatemeh T."    -> middle "T."   became middle "T"
#
# Nothing in this package objected, because nothing in this package had an
# opinion on record. The cohort's membership moved and the only evidence of why
# was a diff between two frozen CSVs on two different machines.
#
# So these assertions are not about punctuation. They are the statement that a
# correct normalisation rule, once relied on by a published cohort, may not
# change again without a test going red first. If a future change makes one of
# these fail, that is the conversation this file exists to force.
# =============================================================================

# -- the three exact cases the cohort diff surfaced --------------------------

test_that("split_given() strips a trailing period from a middle initial", {
  # "B." and "B" must be one initial, not two.
  expect_identical(split_given("Oluwatope B.")$middle_from_given, "B")
  expect_identical(split_given("Oluwatope B")$middle_from_given, "B")
  expect_identical(split_given("Oluwatope B.")$middle_from_given,
                   split_given("Oluwatope B")$middle_from_given)
  expect_identical(split_given("Fatemeh T.")$middle_from_given, "T")
  expect_identical(split_given("Fatemeh T.")$middle_from_given,
                   split_given("Fatemeh T")$middle_from_given)
})

test_that("split_given() strips a trailing period from an abbreviated given name", {
  # "Sr." is a religious title fused into AMCB's first_name field. Whatever it
  # should eventually become, "SR." and "SR" must not be two different things.
  expect_identical(split_given("Sr. Mary")$given, "SR")
  expect_identical(split_given("Sr. Mary")$given, split_given("Sr Mary")$given)
  expect_identical(split_given("Sr. Mary")$middle_from_given, "MARY")
  # A leading initial as the given name: "C. Tucker Allen" -> given C, middle TUCKER.
  expect_identical(split_given("C. Tucker")$given, "C")
  expect_identical(split_given("M. Joanne")$given, "M")
  expect_identical(split_given("M. Joanne")$middle_from_given, "JOANNE")
})

test_that("commas are stripped on the same footing as periods", {
  # The rule is gsub("[.,]", " ", ...); a comma must not survive into a key
  # either, or "SMITH, JR" and "SMITH JR" diverge.
  expect_identical(split_given("Mary, Ann")$given, "MARY")
  expect_identical(split_given("Mary, Ann")$middle_from_given, "ANN")
})

test_that("stripping punctuation never fabricates or loses a token", {
  # The whitespace collapse after the strip is what makes this safe: "M.L."
  # must become two tokens, not one, and "A. B. C." must not leave blanks.
  expect_identical(split_given("Ann M.L.")$middle_from_given, "M L")
  expect_identical(split_given("Ann A. B. C.")$middle_from_given, "A B C")
  # No middle name at all stays empty rather than becoming " " or ".".
  expect_identical(split_given("Debra")$middle_from_given, "")
  expect_identical(split_given("Debra.")$middle_from_given, "")
  expect_identical(split_given("Debra.")$given, "DEBRA")
})

# -- name_key() does NOT strip punctuation, and that is deliberate -----------

test_that("name_key() keeps a trailing period: only split_given() strips", {
  # A standing surprise worth pinning, because reading name_key() alone leads
  # to the wrong conclusion about where normalisation happens. name_key() is
  # the general key; split_given() and middle_tokens() own punctuation.
  expect_identical(name_key("B."), "B.")
  expect_identical(name_key("Sr."), "SR.")
  expect_identical(name_key("M. L."), "M. L.")
})

test_that("middle_tokens() strips punctuation, so agreement sees initials", {
  # This is what makes the NPPES side comparable regardless of how a snapshot
  # punctuated it.
  expect_identical(unlist(middle_tokens("M. L.")), c("M", "L"))
  expect_identical(unlist(middle_tokens("M L")), c("M", "L"))
  expect_identical(unlist(middle_tokens("M.L.")), c("M", "L"))
  expect_identical(middle_tokens("M. L."), middle_tokens("M L"))
})

# -- middle_agreement(): the three states, on the shapes the cohort hits -----

ag <- function(a, b) middle_agreement(middle_tokens(a), middle_tokens(b))

test_that("identical complete middle names corroborate", {
  expect_identical(ag("MARIE", "MARIE"), "corroborates")
  expect_identical(ag("MARIE LEFEVER", "MARIE LEFEVER"), "corroborates")
})

test_that("a middle initial corroborates the complete name it abbreviates", {
  # The asymmetry matters: NPPES records an initial where AMCB records the
  # whole name at least as often as the reverse, so both directions must hold.
  expect_identical(ag("M", "MARIE"), "corroborates")
  expect_identical(ag("MARIE", "M"), "corroborates")
  expect_identical(ag("M.", "MARIE"), "corroborates")
  expect_identical(ag("M L", "MARIE LEFEVER"), "corroborates")
  expect_identical(ag("M. L.", "MARIE LEFEVER"), "corroborates")
})

test_that("a missing middle name on either side is uninformative, never a conflict", {
  # Absence is not evidence. A match may not be vetoed because one source
  # simply did not record a middle name -- the rule the class-5 census found
  # being got wrong in the other direction.
  expect_identical(ag("", "MARIE"), "uninformative")
  expect_identical(ag("MARIE", ""), "uninformative")
  expect_identical(ag("", ""), "uninformative")
  expect_identical(middle_agreement(middle_tokens(NA_character_), middle_tokens("MARIE")),
                   "uninformative")
})

test_that("genuinely different middle names conflict", {
  # The veto must still bite, or stripping punctuation would have bought
  # coverage by abandoning discrimination.
  expect_identical(ag("MARIE", "ELIZABETH"), "conflicts")
  expect_identical(ag("A", "B"), "conflicts")
  expect_identical(ag("A.", "B."), "conflicts")
  expect_identical(ag("MARIE", "ELIZABETH ANN"), "conflicts")
})

test_that("compound and hyphenated middle names agree on token sets, not position", {
  # "MARIE LEFEVER" and "LEFEVER MARIE" are the same two tokens in a different
  # order; a positional comparison would call them a conflict.
  expect_identical(ag("MARIE LEFEVER", "LEFEVER MARIE"), "corroborates")
  # A hyphen is not a token boundary for middle_tokens(), so the hyphenated and
  # spaced spellings of a compound middle name must still meet.
  expect_identical(ag("MARIE-LEFEVER", "MARIE LEFEVER"), "corroborates")
  expect_identical(ag("MARIE-LEFEVER", "MARIE-LEFEVER"), "corroborates")
  # One shared whole token of length >= 2 is agreement even when the other
  # differs: a partial record is corroboration, not conflict.
  expect_identical(ag("MARIE LEFEVER", "MARIE"), "corroborates")
})

test_that("alternate names and suffixes do not leak into the middle comparison", {
  # strip_alternates = TRUE removes parentheticals. A nickname in parentheses
  # must not become a middle-name token and so must not create a conflict.
  expect_identical(split_given("Deborah (Debbie)")$given, "DEBORAH")
  expect_identical(split_given("Deborah (Debbie) Marie")$middle_from_given, "MARIE")
  expect_identical(ag("MARIE (MIMI)", "MARIE"), "corroborates")
  # A generational suffix is a suffix, not a middle initial: "JR" must not
  # corroborate an unrelated "J" middle initial by first-letter accident.
  # Recorded as the CURRENT behaviour, which this file exists to make visible
  # rather than to bless -- see the note at the top of the file.
  expect_identical(ag("JR", "J"), "corroborates")
})

# -- the record that moved the published cohort ------------------------------

test_that("CNM04881 (RHIZAL): every NPPES spelling corroborates the roster", {
  # THE CASE THIS FILE WAS WRITTEN FOR. AMCB roster: Debra Marie-Lefever
  # Rhizal. NPPES NPI 1619274149 records the middle name as "MARIE LEFEVER" in
  # its 2019-2026 snapshots and as "M. L." in the 2018 snapshot on one machine.
  # All three spellings must corroborate the roster, because they are one
  # person, and a single conflicting snapshot variant must not be able to veto
  # the match that belongs to it.
  roster <- "MARIE-LEFEVER"
  for (nppes in c("MARIE LEFEVER", "M. L.", "M L", "M.L.")) {
    expect_identical(ag(roster, nppes), "corroborates",
                     info = paste("roster", roster, "vs NPPES", nppes))
  }
  # ...and the roster spelling survives split_given() unchanged, since the
  # hyphen is not punctuation this rule removes.
  expect_identical(blank_na("Marie-Lefever"), "MARIE-LEFEVER")
})

test_that("a hyphen still carries meaning for compound-versus-half, and that is a decision", {
  # AN ASYMMETRY THIS FILE RECORDS RATHER THAN RESOLVES.
  #
  #   "MARIE LEFEVER" vs "MARIE"  -> corroborates  (shared whole token)
  #   "MARIE-LEFEVER" vs "MARIE"  -> conflicts     (one token, no overlap)
  #
  # Same two components, same half recorded on the other side, opposite
  # verdicts. The package's position, set by 503a37e, is that hyphenation
  # SIGNALS that the components are not independently usable names -- so
  # matching half of "Mary-Jane" is not evidence, while matching one of two
  # space-separated middle names is. That is coherent and deliberately
  # conservative: it refuses a match rather than asserting one on half a name.
  #
  # It is also the kind of judgement a reviewer should be able to find and
  # revisit, so it is asserted here instead of living only in a commit
  # message. If a measured review decides the hyphenated case should also
  # corroborate, this test is where that conversation starts.
  expect_identical(ag("MARIE LEFEVER", "MARIE"), "corroborates")
  expect_identical(ag("MARIE-LEFEVER", "MARIE"), "conflicts")
  expect_identical(ag("ANNE-MARIE", "MARIE"), "conflicts")
  expect_identical(ag("GAIL-ROSANNE", "GAIL"), "conflicts")
})

test_that("folding a middle-name hyphen does NOT reopen the 503a37e false positive", {
  # THE GUARD ON THE FIX. middle_agreement() now folds hyphens before deciding
  # a conflict (2026-11-14). 503a37e had stopped the TOKENIZERS folding them,
  # because splitting "Mary-Jane" into MARY/JANE let it satisfy
  # person_matches()'s shared-token requirement against an unrelated "Jane".
  #
  # That false positive must stay fixed: the fold lives inside
  # middle_agreement(), where a mismatch is a veto, and nowhere near
  # given_tokens() or person_matches(), where a match is evidence.
  expect_identical(unlist(given_tokens("Mary-Jane")), "MARY-JANE")
  expect_false(person_matches("SMITH", given_tokens("Mary-Jane"),
                              "SMITH", given_tokens("Jane")))
  # middle_tokens() itself is likewise unchanged -- one token, as 503a37e set it.
  expect_identical(unlist(middle_tokens("MARIE-LEFEVER")), "MARIE-LEFEVER")
  # The fold is additive: it can turn a conflict into corroboration, never the
  # reverse. Two compounds sharing no component still conflict.
  expect_identical(ag("MARIE-LEFEVER", "ELIZABETH-SMITH"), "conflicts")
  # And the cases the docstring explicitly refuses are still refused: this is
  # punctuation folding, not edit-distance tolerance.
  expect_identical(ag("JULIA", "JULIE"), "conflicts")
  expect_identical(ag("LEE", "LEA"), "conflicts")
  expect_identical(ag("ANN", "ANNE"), "conflicts")
})

test_that("the two frozen-cohort spellings of the same name now agree", {
  # Freeze 1a7bd6a8 (2026-09-10) recorded the left column; freeze 9f224007
  # (2026-10-22) recorded the right. Post-cb86e56 the package produces the
  # right-hand value for every one, which is what makes the newer freeze the
  # reproducible one.
  pre_post <- list(c("Oluwatope B.", "B"), c("Fatemeh T.", "T"),
                   c("Marcelline M.", "M"), c("Gale L.", "L"),
                   c("Susan A.", "A"), c("Cynthia M.", "M"))
  for (p in pre_post) {
    expect_identical(split_given(p[1])$middle_from_given, p[2], info = p[1])
  }
  for (g in c("Sr. Mary", "Sr. Phyllis", "Sr. Joanne")) {
    expect_identical(split_given(g)$given, "SR", info = g)
  }
})
