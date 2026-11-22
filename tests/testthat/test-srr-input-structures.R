# srr input-structure standards: the shapes accepted, and the losses announced

test_that("G2.7: tabular forms beyond data.frame are accepted", {
  df <- data.frame(id = c("a", "b"), surname = c("SMITH", "JONES"),
                   stringsAsFactors = FALSE)
  expect_s3_class(as_linkage_table(df, "roster"), "data.frame")
  # tibble- and data.table-shaped input: the classes are faked rather than
  # depended on, because adding packages to Suggests for a type test alone is
  # what G2.7's own note warns against.
  tbl <- structure(df, class = c("tbl_df", "tbl", "data.frame"))
  expect_s3_class(suppressMessages(as_linkage_table(tbl, "roster")),
                  "data.frame")
  dt <- structure(df, class = c("data.table", "data.frame"))
  out <- suppressMessages(as_linkage_table(dt, "roster"))
  expect_identical(class(out), "data.frame")
  m <- matrix(c("1", "A"), nrow = 1,
              dimnames = list(NULL, c("id", "surname")))
  expect_s3_class(suppressMessages(as_linkage_table(m, "roster")), "data.frame")
})

test_that("G2.9: conversions that lose something say so", {
  df <- data.frame(id = "a", surname = "SMITH", stringsAsFactors = FALSE)
  dt <- structure(df, class = c("data.table", "data.frame"))
  expect_message(as_linkage_table(dt, "roster"), "does not survive")
  expect_message(as_linkage_table(matrix("1", dimnames = list(NULL, "id")),
                                  "roster"),
                 "every column becomes")
  expect_message(read_name_column(factor("SMITH"), "surname"),
                 "labels, not codes")
  expect_warning(read_name_column(c(1001, 1002), "npi"),
                 "loses leading zeros")
  # Silence is available, but it is not the default: the message IS the
  # standard.
  expect_silent(read_name_column(factor("SMITH"), "surname", quiet = TRUE))
})

test_that("G2.4: a numeric identifier never arrives in scientific notation", {
  # 1e+05 is not the identifier 100000, and format(scientific = FALSE) is the
  # difference between a join that works and one that silently matches nothing.
  expect_equal(suppressWarnings(read_name_column(1234567890, "npi")),
               "1234567890")
  expect_equal(suppressWarnings(read_name_column(1e5, "npi")), "100000")
  expect_equal(suppressWarnings(read_name_column(c(1, NA), "npi")),
               c("1", NA))
})

test_that("G2.12: a list column is refused, not stringified", {
  df <- data.frame(id = c("a", "b"), stringsAsFactors = FALSE)
  df$alt <- list(c("X", "Y"), "Z")
  expect_error(as_linkage_table(df, "roster"), "list column")
  expect_error(reject_list_columns(df, "roster"), "refused rather than coerced")
})

test_that("G2.6, G2.11: one-dimensional input is stripped of its attributes", {
  odd <- structure(c(a = "X", b = "Y"), class = "units_like", units = "m")
  expect_null(attributes(drop_vector_attributes(odd)))
  expect_equal(drop_vector_attributes(odd), c("X", "Y"))
  expect_message(read_name_column(odd, "surname"), "stripped from")
  # A data frame is not one-dimensional and must pass through untouched.
  df <- data.frame(a = 1)
  expect_identical(drop_vector_attributes(df), df)
})

test_that("G2.2: scalar arguments reject vectors", {
  expect_error(check_scalar(c(1, 2), "seed"), "not length 2")
  expect_error(check_scalar(NULL, "seed"), "not NULL")
  expect_silent(check_scalar(NULL, "table", null_ok = TRUE))
  expect_silent(check_scalar(1L, "seed"))
})

test_that("EA2.1, EA2.5: index uniqueness is affirmed, not assumed", {
  ok <- data.frame(id = c("a", "b"), stringsAsFactors = FALSE)
  expect_silent(affirm_unique_index(ok, "id", "roster"))
  dup <- data.frame(id = c("a", "a", "b"), stringsAsFactors = FALSE)
  expect_error(affirm_unique_index(dup, "id", "roster"), "is not unique")
  expect_warning(affirm_unique_index(dup, "id", "roster", action = "warn"),
                 "enforces nothing")
  expect_error(affirm_unique_index(ok, "missing_col", "roster"),
               "no column")
})

test_that("G2.2, G2.7: match_npi() accepts the wider shapes and rejects the bad ones", {
  roster <- data.frame(id = "r1", given = "MARY", surname = "JOHNSON",
                       stringsAsFactors = FALSE)
  ref <- data.frame(npi = "1234567893", entity_type = "1", given = "MARY",
                    middle = NA_character_, surname = "JOHNSON",
                    stringsAsFactors = FALSE)
  args <- list(id = "id", given = "given", surname = "surname", npi = "npi",
               entity_type = "entity_type", nppes_given = "given",
               nppes_middle = "middle", nppes_surname = "surname")
  tbl <- structure(roster, class = c("tbl_df", "tbl", "data.frame"))
  res <- suppressMessages(do.call(match_npi, c(list(roster = tbl, nppes = ref), args)))
  expect_equal(nrow(res$matches), 1L)
  bad <- roster; bad$alt <- list("X")
  expect_error(do.call(match_npi, c(list(roster = bad, nppes = ref), args)),
               "list column")
  expect_error(do.call(match_npi, c(list(roster = roster, nppes = ref,
                                         entity_filter = c("1", "2")), args)),
               "entity_filter must be a single value")
})
