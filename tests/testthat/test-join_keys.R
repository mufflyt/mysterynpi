# Equality-join surname keys: both conventions, positional trailing letter.

test_that("compact_name_key collapses punctuation and case to letters only", {
  expect_identical(compact_name_key(c("Jones-Cox", "O'Brien", "van de Ven", "  Smith ")),
                   c("JONESCOX", "OBRIEN", "VANDEVEN", "SMITH"))
})

test_that("compact_name_key: NA in NA out, and no-letters is NA never ''", {
  expect_identical(compact_name_key(c(NA, "---", "12")), c(NA_character_, NA, NA))
})

test_that("surname_key_variants emits BOTH conventions", {
  v <- surname_key_variants(c("Van Houten", "Van Le", "de la Cruz", "Smith"))
  expect_identical(v$key_full,  c("VANHOUTEN", "VANLE", "DELACRUZ", "SMITH"))
  expect_identical(v$key_final, c("HOUTEN", "LE", "CRUZ", "SMITH"))
  # single-token surnames: the two variants coincide
  expect_identical(v$key_full[4], v$key_final[4])
})

test_that("the Dutch record and the Vietnamese record are BOTH reachable", {
  # The measured trade this design exists to refuse: a glued-only key loses
  # "Linda Van Le" (registry surname LE); a final-token-only key loses
  # "Laura Van Houten" when the registry glues (VAN HOUTEN). Each registry
  # spelling must be reachable through at least one emitted variant.
  v <- surname_key_variants(c("Van Houten", "Van Le"))
  registry <- c("VANHOUTEN", "LE")   # how each really appears in NPPES
  expect_true(registry[1] %in% c(v$key_full[1], v$key_final[1]))
  expect_true(registry[2] %in% c(v$key_full[2], v$key_final[2]))
})

test_that("a trailing single letter never becomes a surname key", {
  v <- surname_key_variants("Goodyear V")
  expect_identical(v$key_full, "GOODYEAR")
  expect_identical(v$key_final, "GOODYEAR")
})

test_that("NEGATIVE CONTROL: a single-letter-only surname is not emptied", {
  # The positional rule requires ANOTHER token to fall back on.
  v <- surname_key_variants("X")
  expect_identical(v$key_full, "X")
  expect_identical(v$key_final, "X")
})

test_that("NEGATIVE CONTROL: compaction does not merge unrelated surnames", {
  k <- compact_name_key(c("Smith", "Smythe", "Jones", "Johnson"))
  expect_identical(length(unique(k)), 4L)
})
