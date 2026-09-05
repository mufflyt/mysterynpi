# The frozen snapshot: every verdict over the deterministic grid must
# reproduce bit-for-bit. Pattern from moj-analytical-services/splink (MIT),
# tests/test_compare_splink2.py, hardened from approx-equality to identity
# because these rules are deterministic. A failure here is a BEHAVIOUR
# CHANGE: if intended, regenerate via data-raw/verdict_snapshot.R, review the
# verdict diff row by row, and record it in NEWS -- the contracts call that a
# major version bump.

test_that("every frozen verdict reproduces bit-for-bit", {
  snap <- read.csv(testthat::test_path("fixtures", "golden", "snapshot.csv"),
                   comment.char = "#", colClasses = "character")
  un_na <- function(x) { x[x == "<NA>"] <- NA_character_; x }
  a <- un_na(snap$a); b <- un_na(snap$b)
  sa <- un_na(snap$state_a); sb <- un_na(snap$state_b)
  got <- character(nrow(snap))
  for (r in unique(snap$rule)) {
    i <- snap$rule == r
    got[i] <- switch(r,
      middle   = middle_agreement(middle_tokens(a[i]), middle_tokens(b[i])),
      gender   = gender_agreement(a[i], b[i]),
      nickname = nickname_agreement(a[i], b[i]),
      suffix   = suffix_agreement(a[i], b[i]),
      license  = license_agreement(a[i], sa[i], b[i], sb[i]),
      surname  = surname_agreement(a[i], b[i]),
      stop("snapshot names an unknown rule: ", r))
  }
  mism <- which(got != snap$verdict)
  expect_identical(length(mism), 0L,
                   label = sprintf("first mismatch: %s(%s | %s) gave %s, frozen %s",
                                   snap$rule[mism[1]], a[mism[1]], b[mism[1]],
                                   got[mism[1]], snap$verdict[mism[1]]))
  expect_gt(nrow(snap), 4000)
})
