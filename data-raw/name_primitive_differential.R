#!/usr/bin/env Rscript

suppressPackageStartupMessages(pkgload::load_all(".", quiet = TRUE))

isochrones_checkout <- Sys.getenv(
  "ISOCHRONES_CHECKOUT",
  "/Users/tylermuffly/nickname-consolidation-worktrees/isochrones"
)
isochrones_source <- file.path(isochrones_checkout, "R", "name_matching_primitives.R")
if (!file.exists(isochrones_source)) {
  stop("missing isochrones primitive source: ", isochrones_source, call. = FALSE)
}

old <- new.env(parent = baseenv())
assign("normalize_name_key",
       function(x) gsub("\\s+", " ", mysterynpi::normalize_string(x)),
       envir = old)
assign("are_nickname_variants",
       function(a, b) {
         mysterynpi::are_nickname_equivalents(
           a, b, mysterynpi::get_nickname_dictionary()
         )
       },
       envir = old)
sys.source(isochrones_source, envir = old)

value_string <- function(expr, env = parent.frame()) {
  value <- try(eval(expr, envir = env), silent = TRUE)
  if (inherits(value, "try-error")) {
    return(paste0("ERROR: ", conditionMessage(attr(value, "condition"))))
  }
  paste(deparse(value, width.cutoff = 500L), collapse = " ")
}

row <- function(case_id, fn, inputs, expr, classification = "NO_CHANGE",
                reason = "same result") {
  old_value <- value_string(expr, old)
  new_value <- value_string(expr, parent.frame())
  data.frame(
    case_id = case_id,
    function_name = fn,
    inputs = inputs,
    isochrones_result = old_value,
    mysterynpi_result = new_value,
    same = identical(old_value, new_value),
    classification = if (identical(old_value, new_value)) "NO_CHANGE" else classification,
    reason = if (identical(old_value, new_value)) "same result" else reason,
    stringsAsFactors = FALSE
  )
}

rows <- list(
  row("surname_substring_anderson", "names_have_compatible_surname",
      "Anderson / Sanderson",
      quote(names_have_compatible_surname("Anderson", "Sanderson"))),
  row("surname_substring_williams", "names_have_compatible_surname",
      "Williams / Williamson",
      quote(names_have_compatible_surname("Williams", "Williamson"))),
  row("surname_substring_martin", "names_have_compatible_surname",
      "Martin / Martinez",
      quote(names_have_compatible_surname("Martin", "Martinez"))),
  row("surname_apostrophe", "names_have_compatible_surname",
      "O'Connor / Oconnor",
      quote(names_have_compatible_surname("O'Connor", "Oconnor"))),
  row("surname_component_subset", "names_have_compatible_surname",
      "Nelson / Nelson-Becker",
      quote(names_have_compatible_surname("Nelson", "Nelson-Becker"))),
  row("surname_concatenated", "name_surname_match_type",
      "Abu-Ghazaleh / Abughazaleh",
      quote(name_surname_match_type("Abu-Ghazaleh", "Abughazaleh"))),
  row("surname_blank", "names_have_compatible_surname",
      "'' / Smith",
      quote(names_have_compatible_surname("", "Smith"))),
  row("surname_na", "names_have_compatible_surname",
      "NA / NA",
      quote(names_have_compatible_surname(NA_character_, NA_character_))),
  row("surname_scalar_broadcast", "names_have_compatible_surname",
      "Smith / c(Smith,Jones)",
      quote(names_have_compatible_surname("Smith", c("Smith", "Jones")))),
  row("surname_same_length_vector", "name_surname_match_type",
      "c(Nelson,Anderson) / c(Nelson-Becker,Sanderson)",
      quote(name_surname_match_type(c("Nelson", "Anderson"),
                                    c("Nelson-Becker", "Sanderson")))),
  row("surname_illegal_lengths", "names_have_compatible_surname",
      "c(Smith,Jones) / c(Smith,Jones,Brown)",
      quote(names_have_compatible_surname(c("Smith", "Jones"),
                                          c("Smith", "Jones", "Brown")))),
  row("given_initial_full", "names_have_compatible_given",
      "C / Chad positional_ie",
      quote(names_have_compatible_given("C", "Chad", mode = "positional_ie"))),
  row("given_two_initials", "names_have_compatible_given",
      "S / S positional_ie",
      quote(names_have_compatible_given("S", "S", mode = "positional_ie"))),
  row("given_positional_nickname", "names_have_compatible_given",
      "Beth / Elizabeth positional_ie",
      quote(names_have_compatible_given("Beth", "Elizabeth",
                                        mode = "positional_ie"))),
  row("given_positional_prefix_false_positive", "names_have_compatible_given",
      "Carol / Carla positional_ie",
      quote(names_have_compatible_given("Carol", "Carla",
                                        mode = "positional_ie"))),
  row("given_any_token_middle", "names_have_compatible_given",
      "Mary / Angela Mary any_token",
      quote(names_have_compatible_given("Mary", "Angela", b_middle = "Mary",
                                        mode = "any_token"))),
  row("given_position_middle", "name_given_match_position",
      "Mary / Angela Mary",
      quote(name_given_match_position("Mary", "Angela", NULL, "Mary"))),
  row("given_tokens_middle_broadcast", "name_given_tokens",
      "c(Mary,Jane) / Ann",
      quote(name_given_tokens(c("Mary", "Jane"), "Ann"))),
  row("given_tokens_illegal_middle", "name_given_tokens",
      "Mary / c(Ann,Jane)",
      quote(name_given_tokens("Mary", c("Ann", "Jane")))),
  row("surname_particle", "name_surname_match_type",
      "Van / van Erven",
      quote(name_surname_match_type("Van", "van Erven"))),
  row("surname_hyphenated", "name_surname_components",
      "Barlow-Reed",
      quote(name_surname_components("Barlow-Reed"))),
  row("given_leading_initial", "name_leading_given",
      "S. Addreina",
      quote(name_leading_given("S. Addreina"))),
  row("given_missing", "names_have_compatible_given",
      "NA / Mary positional_ie",
      quote(names_have_compatible_given(NA_character_, "Mary",
                                        mode = "positional_ie")))
)

out <- do.call(rbind, rows)
allowed <- c("NO_CHANGE", "INTENTIONAL_FIX", "INTENTIONAL_API_DIFFERENCE",
             "UNINTENDED_REGRESSION")
stopifnot(all(out$classification %in% allowed))
stopifnot(sum(out$classification == "UNINTENDED_REGRESSION") == 0L)

dir.create("tests/fixtures", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(out, "tests/fixtures/name_primitive_differential.csv",
                 row.names = FALSE, na = "")
cat("name primitive differential rows:", nrow(out), "\n")
print(table(out$classification))
