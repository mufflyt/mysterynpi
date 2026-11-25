# =============================================================================
# phrase_key(): the phrase-equality contract -- fold, apostrophes closed,
# punctuation demoted to a single-space separator, absence never ""
# =============================================================================

test_that("phrase_key() is normalize_string() plus the phrase contract", {
  # The fold is delegated, not reimplemented: whatever normalize_string()
  # decides an accented or German-umlaut phrase keys as, phrase_key() must
  # agree -- that is the whole point of building on it.
  inputs <- c("Müller", "Straße", "García", "O'Brien", "St. Mary",
              "VAN  DER BERG", "JOHN-JACOB JINGLEHEIMER")
  expect_identical(
    phrase_key(inputs),
    gsub("\\s+", " ", trimws(gsub("[^A-Z0-9 ]", " ",
         normalize_string(inputs, remove_apostrophes = TRUE))))
  )
})

test_that("apostrophes close the token -- all four codepoints", {
  # THE DEFECT THIS FUNCTION EXISTS TO PREVENT. Spacing an apostrophe splits
  # one recorded surname into two keys: "O'Brien" -> "O BRIEN" never equals
  # "OBRIEN", so two spellings of one person count as a disagreement. Found
  # in a downstream AMCB-NPPES linkage where 49 roster surnames changed key
  # and 27 cross-arm agreements were gained by deleting instead.
  expect_identical(phrase_key("O'Brien"), "OBRIEN")
  expect_identical(phrase_key("OBrien"), "OBRIEN")
  expect_identical(phrase_key("O'Brien"), phrase_key("OBrien"))
  # curly, modifier-letter and okina forms fold onto the straight apostrophe
  # inside normalize_string() before the delete runs
  expect_identical(phrase_key("O’Brien"), "OBRIEN")
  expect_identical(phrase_key("OʼBrien"), "OBRIEN")
  expect_identical(phrase_key("OʻBrien"), "OBRIEN")
})

test_that("punctuation becomes a separator, never a deletion or a keeper", {
  # Neither neighbour's contract: name_key() keeps "ST. MARY" and
  # compact_name_key() glues "VAN DER BERG" into "VANDERBERG". The phrase
  # contract demotes punctuation to a word boundary and keeps it.
  expect_identical(phrase_key("St. Mary"), "ST MARY")
  expect_identical(phrase_key("Mary-Jo"), "MARY JO")
  expect_identical(phrase_key("VAN  DER BERG"), "VAN DER BERG")
  expect_identical(phrase_key("RN-12 345"), "RN 12 345")
  # Digits survive: a phrase key is not a name key.
  expect_identical(phrase_key("APT 4B"), "APT 4B")
})

test_that("parenthesised text is data, not an alternate name", {
  # name_key() drops "(Cindi)" because in a person name it is an alternate.
  # In a phrase it is part of the value -- an organisation name like
  # "Michigan Otolaryngology (MOSA)" must not lose its qualifier.
  expect_identical(
    phrase_key("Michigan Otolaryngology (MOSA)"),
    "MICHIGAN OTOLARYNGOLOGY MOSA"
  )
})

test_that("absence is NA, never an empty string", {
  # A missing value must not group with a real empty-string key, and a phrase
  # that is all punctuation has no keyable content at all.
  expect_identical(phrase_key(NA_character_), NA_character_)
  expect_identical(phrase_key(""), NA_character_)
  expect_identical(phrase_key("   "), NA_character_)
  expect_identical(phrase_key("---"), NA_character_)
  expect_identical(phrase_key(character(0)), character(0))
  expect_identical(phrase_key(NULL), character(0))
})

test_that("remove_apostrophes = FALSE restores the split, deliberately", {
  # The dangerous behaviour stays reachable for a caller that genuinely
  # wants punctuation-as-separator semantics -- but it is opt-in, never the
  # default a join key inherits by accident.
  expect_identical(phrase_key("O'Brien", remove_apostrophes = FALSE),
                   "O BRIEN")
})

test_that("vectorised and NA-preserving", {
  out <- phrase_key(c("O'Brien", NA, "St. Mary"))
  expect_identical(out, c("OBRIEN", NA_character_, "ST MARY"))
})
