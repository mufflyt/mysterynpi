memory_columns <- function() {
  list(id = "record", given = "first", middle = "middle", surname = "last",
       npi = "provider", entity_type = "type", nppes_given = "first",
       nppes_middle = "middle", nppes_surname = "last")
}

memory_roster <- function(first = "Jane", last = "Doe", middle = NA_character_) {
  data.frame(record = paste0("r", seq_along(first)), first = first,
             middle = middle, last = last)
}

memory_reference <- function(first = "Jane", last = "Doe", middle = NA_character_,
                             provider = "1234567893", type = "1") {
  data.frame(provider = provider, type = type, first = first, middle = middle, last = last)
}

test_that("memory postings use hash backing and retrieve exact distinct reference rows", {
  index <- .npi_memory_index(list(c("A", "B", "A"), character(), "A", "C"))
  expect_true(is.environment(index))
  if (is.environment(index)) expect_false(is.null(env.profile(index)))
  expect_identical(.npi_memory_lookup(index, c("B", "A", "B", "missing")), c(1L, 3L))
  expect_identical(.npi_memory_lookup(index, "C"), 4L)
  expect_identical(.npi_memory_lookup(index, c("missing", "mean")), integer())
  expect_identical(.npi_memory_lookup(index, character()), integer())
  expect_identical(.npi_memory_lookup(index, c("", NA_character_, "A")), c(1L, 3L))
  empty <- .npi_memory_index(list(character(), character()))
  expect_true(is.environment(empty))
  if (is.environment(empty)) expect_false(is.null(env.profile(empty)))
  expect_identical(.npi_memory_lookup(empty, "A"), integer())
  blank <- .npi_memory_index(list(c("", NA_character_), "A"))
  expect_identical(.npi_memory_lookup(blank, c("", NA_character_, "A")), 2L)
})

test_that("memory candidates filter entities and account sequential reference exclusions", {
  reference <- memory_reference(
    first = c("Jane", "Jane", "Jane", "", "Jane", "Jane"),
    last = c("Doe", "Doe", "Doe", "Doe", NA, "Doe"),
    provider = c("1234567893", "1245319599", "1234567890", "1234567893",
                 "1234567893", "1234567893"), type = c("1", "2", "1", "1", "1", NA))
  reference$irrelevant <- I(rep(list(list(a = "large unused payload")), 6))
  before <- reference
  result <- generate_npi_candidates_memory(memory_roster(), reference, memory_columns())
  expect_named(result, c("pairs", "reference_counts"))
  expect_named(result$pairs, c("source_id", "npi", "roster_first", "roster_middle",
                              "roster_last", "nppes_first", "nppes_middle", "nppes_last",
                              "block_route"))
  expect_identical(unique(result$pairs$npi), "1234567893")
  expect_identical(result$reference_counts,
                   c(input = 6L, entity_type = 4L, invalid_npi = 1L,
                     missing_required_name = 2L, usable = 1L))
  type2 <- generate_npi_candidates_memory(memory_roster(), reference,
                                         memory_columns(), entity_filter = "2")
  expect_identical(unique(type2$pairs$npi), "1245319599")
  expect_identical(type2$reference_counts,
                   c(input = 6L, entity_type = 1L, invalid_npi = 0L,
                     missing_required_name = 0L, usable = 1L))
  expect_identical(reference, before)
})

test_that("memory blocks recall exact variants nicknames fuzzy and ambiguous candidates", {
  roster <- memory_roster(c("Jane", "Mary", "Robert James", "Bob", "Alice", "David",
                           "Jane", "Zelda", NA),
                         c("Doe", "Barlow Reed", "Jones", "Muffly", "Smith", "Clark",
                           "Doe", "Zzyzx", "Doe"))
  reference <- memory_reference(
    c("Jane", "Mary", "James Robert", "Robert", "Alyce", "David", "Jane"),
    c("Doe", "Barlow-Reed", "Jones", "Muffly", "Smith", "Clarke", "Doe"),
    provider = c("1234567893", "1245319599", "1999999984", "1234567893",
                 "1245319599", "1999999984", "1999999984"))
  pairs <- generate_npi_candidates_memory(roster, reference, memory_columns())$pairs
  identities <- unique(pairs[c("source_id", "npi")])
  identities <- identities[order(identities$source_id, identities$npi), ]
  rownames(identities) <- NULL
  expect_identical(identities, data.frame(
    source_id = c("r1", "r1", "r2", "r3", "r4", "r5", "r6", "r7", "r7"),
    npi = c("1234567893", "1999999984", "1245319599", "1999999984", "1234567893",
            "1245319599", "1999999984", "1234567893", "1999999984")))
  evidence <- build_npi_candidate_evidence(pairs)
  expect_identical(evidence$reason[evidence$source_id == "r2"], "positional_name_evidence")
  expect_identical(evidence$reason[evidence$source_id == "r3"], "weak_name_evidence")
  expect_identical(evidence$reason[evidence$source_id == "r4"], "nickname_only_evidence")
  expect_identical(evidence$reason[evidence$source_id == "r5"], "fuzzy_only_evidence")
  expect_identical(evidence$reason[evidence$source_id == "r6"], "fuzzy_only_evidence")
  expect_true(all(grepl("fuzzy", evidence$block_routes[evidence$source_id %in% c("r5", "r6")])))
})

test_that("memory blocks support initial compound and apostrophe variants", {
  roster <- memory_roster(c("J.", "Anne", "Sean", "Anne"),
                         c("Doe", "Nelson", "O'Connor", "Abu Ghazaleh"))
  reference <- memory_reference(c("Jane", "Anne", "Sean", "Anne"),
                                c("Doe", "Nelson-Becker", "Oconnor", "Abughazaleh"))
  evidence <- build_npi_candidate_evidence(
    generate_npi_candidates_memory(roster, reference, memory_columns())$pairs)
  expect_identical(evidence$source_id, c("r1", "r2", "r3", "r4"))
  expect_true(all(evidence$disposition == "eligible"))
})

test_that("fuzzy review blocks use exact deletion signatures without distance scoring", {
  roster <- memory_roster(c("Xlice", "David", "Alice", "David"),
                         c("Smith", "Clark", "Smith", "Clark"))
  reference <- memory_reference(c("Alice", "David"), c("Smith", "Clrak"),
                                provider = c("1234567893", "1999999984"))
  pairs <- generate_npi_candidates_memory(roster, reference, memory_columns())$pairs
  evidence <- build_npi_candidate_evidence(pairs)
  expect_identical(evidence$source_id, c("r1", "r2", "r3", "r4"))
  expect_identical(evidence$reason,
                   c("fuzzy_only_evidence", "fuzzy_only_evidence",
                     "exact_name_evidence", "fuzzy_only_evidence"))
  expect_false(any(grepl("fuzzy", pairs$block_route[pairs$source_id == "r3"])))
})

test_that("memory candidates preserve repeated NPI profiles and multiple routes", {
  reference <- memory_reference(c("Jane", "Jane", "Janet"), rep("Doe", 3))
  pairs <- generate_npi_candidates_memory(memory_roster(), reference, memory_columns())$pairs
  expect_true(sum(pairs$nppes_first == "JANE") >= 2L)
  expect_true(length(unique(pairs$block_route[pairs$nppes_first == "JANE"])) >= 2L)
  expect_true("JANET" %in% pairs$nppes_first)
  evidence <- build_npi_candidate_evidence(pairs)
  expect_equal(nrow(evidence), 1L)
  expect_identical(evidence$reason, "conflicting_candidate_names")
})

test_that("memory candidate generation does not truncate large name blocks", {
  reference <- memory_reference(rep("Jane", 240), rep("Doe", 240))
  pairs <- generate_npi_candidates_memory(memory_roster(), reference, memory_columns())$pairs
  expect_equal(sum(pairs$block_route == "exact_given_surname"), 240L)
})

test_that("indexed memory candidates stay far below a synthetic Cartesian product", {
  # Double each code letter so distinct surnames have disjoint single-deletion
  # signatures; every roster row has one exact hit in this separated fixture.
  letters3 <- apply(expand.grid(LETTERS, LETTERS, LETTERS), 1, function(x) {
    paste0(rep(x, each = 2L), collapse = "")
  })
  reference <- memory_reference(rep("Jane", 2000), paste0("FAMILY", letters3[1:2000]))
  roster <- memory_roster(rep("Jane", 100), reference$last[1:100])
  pairs <- generate_npi_candidates_memory(roster, reference, memory_columns())$pairs
  exact <- pairs[pairs$block_route == "exact_given_surname", ]
  expect_equal(nrow(exact), 100L)
  expect_setequal(exact$source_id, paste0("r", 1:100))
  expect_lt(nrow(pairs), 0.05 * nrow(roster) * nrow(reference))
})

test_that("memory candidates return typed empty pairs for unmatched and unusable inputs", {
  for (roster in list(memory_roster("Zelda", "Zzyzx"), memory_roster()[FALSE, ])) {
    result <- generate_npi_candidates_memory(roster, memory_reference(), memory_columns())
    expect_equal(nrow(result$pairs), 0L)
    expect_true(all(vapply(result$pairs, is.character, logical(1))))
  }
  reference <- memory_reference(provider = "invalid")
  result <- generate_npi_candidates_memory(memory_roster(), reference, memory_columns())
  expect_equal(nrow(result$pairs), 0L)
  expect_identical(result$reference_counts,
                   c(input = 1L, entity_type = 1L, invalid_npi = 1L,
                     missing_required_name = 0L, usable = 0L))
})

test_that("memory candidate normalization supports full-name mappings", {
  skip_if_not_installed("humaniformat")
  roster <- data.frame(record = "r1", name = "Jane Doe")
  reference <- data.frame(provider = "1234567893", type = "1", name = "Jane Doe")
  columns <- list(id = "record", full_name = "name", npi = "provider", entity_type = "type",
                  nppes_full_name = "name")
  result <- generate_npi_candidates_memory(roster, reference, columns)
  expect_identical(unique(result$pairs$npi), "1234567893")
  expect_identical(unique(result$pairs$roster_first), "JANE")
})
