#!/usr/bin/env Rscript
# Differential proof: the isochrones name primitives versus the mysterynpi ones.
#
# The two implementations define the same seven functions with the same
# signatures. Before the isochrones copy is deleted, every behavioural
# difference has to be observed and classified, not assumed away. A line-count
# or hash difference is NOT evidence of a behavioural difference, and neither is
# its absence evidence of equivalence.
#
# Classification is exactly one of:
#   NO_CHANGE                    identical result
#   INTENTIONAL_FIX              mysterynpi is correct where isochrones was wrong
#   INTENTIONAL_API_DIFFERENCE   deliberate contract change
#   UNINTENDED_REGRESSION        mysterynpi is worse; BLOCKS the migration
#
# Required outcome: UNINTENDED_REGRESSION = 0.
#
# Output: tests/fixtures/name_primitive_differential.csv

ISO <- Sys.getenv("ISOCHRONES_PRIMITIVES", "/tmp/src_isochrones.R")
MNP <- "R/name_matching.R"

# BOTH implementations depend on helpers their host package supplies
# (normalize_string, surname_tokens). Running each against its own helpers would
# measure HELPER differences and attribute them to the primitives. Both are
# therefore sourced into an environment whose parent is the mysterynpi
# namespace, so the helpers are identical and the only thing varying is the
# primitive body under test. That is what makes this a differential of the
# primitives rather than of two packages.
suppressMessages(pkgload::load_all(".", quiet = TRUE))
.helpers <- asNamespace("mysterynpi")

# The isochrones primitives additionally call normalize_name_key(), which is an
# isochrones helper rather than a mysterynpi one. Supply it so the isochrones
# side can actually execute; without it every isochrones case errors and the
# differential would compare "error" against a real value, which proves nothing.
ISO_HELPERS <- Sys.getenv("ISOCHRONES_STRING_NORMALIZATION", "/tmp/iso_strnorm.R")

load_impl <- function(path, extra_helpers = NULL) {
  e <- new.env(parent = .helpers)
  if (!is.null(extra_helpers) && file.exists(extra_helpers)) {
    tryCatch(sys.source(extra_helpers, envir = e), error = function(err) invisible(NULL))
  }
  sys.source(path, envir = e)
  e
}

# Every case the consolidation contract requires, plus the adversarial surname
# pairs that must NOT be treated as compatible.
CASES <- list(
  # --- surname adversarials: near-miss pairs that must stay distinct --------
  list(id = "surname_anderson_sanderson",  fn = "names_have_compatible_surname", args = list("ANDERSON", "SANDERSON")),
  list(id = "surname_williams_williamson", fn = "names_have_compatible_surname", args = list("WILLIAMS", "WILLIAMSON")),
  list(id = "surname_martin_martinez",     fn = "names_have_compatible_surname", args = list("MARTIN", "MARTINEZ")),
  list(id = "surname_oconnor_apostrophe",  fn = "names_have_compatible_surname", args = list("O'CONNOR", "OCONNOR")),
  list(id = "surname_nelson_hyphen",       fn = "names_have_compatible_surname", args = list("NELSON", "NELSON-BECKER")),
  list(id = "surname_abu_ghazaleh",        fn = "names_have_compatible_surname", args = list("ABU-GHAZALEH", "ABUGHAZALEH")),
  list(id = "surname_identical",           fn = "names_have_compatible_surname", args = list("SMITH", "SMITH")),
  list(id = "surname_particle_only",       fn = "names_have_compatible_surname", args = list("VAN", "VAN DYKE")),
  # --- surname match TYPE ---------------------------------------------------
  list(id = "type_anderson_sanderson",     fn = "name_surname_match_type", args = list("ANDERSON", "SANDERSON")),
  list(id = "type_nelson_hyphen",          fn = "name_surname_match_type", args = list("NELSON", "NELSON-BECKER")),
  list(id = "type_concatenated",           fn = "name_surname_match_type", args = list("ABU-GHAZALEH", "ABUGHAZALEH")),
  list(id = "type_identical",              fn = "name_surname_match_type", args = list("SMITH", "SMITH")),
  # --- surname components ---------------------------------------------------
  list(id = "components_hyphenated",       fn = "name_surname_components", args = list("NELSON-BECKER")),
  list(id = "components_apostrophe",       fn = "name_surname_components", args = list("O'CONNOR")),
  list(id = "components_particle",         fn = "name_surname_components", args = list("VAN DER BERG")),
  list(id = "components_blank",            fn = "name_surname_components", args = list("")),
  list(id = "components_na",               fn = "name_surname_components", args = list(NA_character_)),
  # --- given tokens and leading given --------------------------------------
  list(id = "given_tokens_simple",         fn = "name_given_tokens", args = list("MARY", "JANE")),
  list(id = "given_tokens_no_middle",      fn = "name_given_tokens", args = list("MARY", NULL)),
  list(id = "given_tokens_initial",        fn = "name_given_tokens", args = list("M", "J")),
  list(id = "given_tokens_blank",          fn = "name_given_tokens", args = list("", "")),
  list(id = "given_tokens_na",             fn = "name_given_tokens", args = list(NA_character_, NA_character_)),
  list(id = "leading_given_full",          fn = "name_leading_given", args = list("MARY JANE")),
  list(id = "leading_given_initial",       fn = "name_leading_given", args = list("M")),
  # --- given match POSITION --------------------------------------------------
  list(id = "pos_same_leading",            fn = "name_given_match_position", args = list("MARY", "MARY")),
  list(id = "pos_middle_token",            fn = "name_given_match_position", args = list("MARY", "JANE", "JANE", "MARY")),
  list(id = "pos_initial_vs_full",         fn = "name_given_match_position", args = list("M", "MARY")),
  list(id = "pos_two_initials",            fn = "name_given_match_position", args = list("M", "M")),
  list(id = "pos_disjoint",                fn = "name_given_match_position", args = list("MARY", "SUSAN")),
  # --- compatible given, BOTH modes ------------------------------------------
  list(id = "given_positional_same",       fn = "names_have_compatible_given", args = list("MARY", "MARY"), mode = "positional_ie"),
  list(id = "given_positional_initial",    fn = "names_have_compatible_given", args = list("M", "MARY"), mode = "positional_ie"),
  list(id = "given_positional_two_init",   fn = "names_have_compatible_given", args = list("M", "M"), mode = "positional_ie"),
  list(id = "given_anytoken_same",         fn = "names_have_compatible_given", args = list("MARY", "MARY"), mode = "any_token"),
  list(id = "given_anytoken_middle",       fn = "names_have_compatible_given", args = list("MARY", "JANE", "JANE", "MARY"), mode = "any_token"),
  list(id = "given_anytoken_disjoint",     fn = "names_have_compatible_given", args = list("MARY", "SUSAN"), mode = "any_token"),
  list(id = "given_blank",                 fn = "names_have_compatible_given", args = list("", ""), mode = "any_token"),
  list(id = "given_na",                    fn = "names_have_compatible_given", args = list(NA_character_, NA_character_), mode = "any_token"),
  # --- vectorisation contract ------------------------------------------------
  list(id = "vec_scalar_broadcast",        fn = "names_have_compatible_surname", args = list("SMITH", c("SMITH", "JONES"))),
  list(id = "vec_equal_length",            fn = "names_have_compatible_surname", args = list(c("SMITH", "JONES"), c("SMITH", "JONES"))),
  list(id = "vec_illegal_unequal",         fn = "names_have_compatible_surname", args = list(c("A", "B", "C"), c("A", "B")))
)

run_case <- function(env, case) {
  fn <- get0(case$fn, envir = env, inherits = FALSE)
  if (is.null(fn)) return(list(ok = FALSE, value = "FUNCTION_ABSENT"))
  args <- case$args
  if (!is.null(case$mode)) args <- c(args, list(mode = case$mode))
  out <- tryCatch(list(ok = TRUE, value = do.call(fn, args)),
                  error = function(e) list(ok = FALSE, value = paste0("ERROR: ", conditionMessage(e))))
  out
}

render <- function(r) {
  if (!isTRUE(r$ok)) return(as.character(r$value))
  v <- r$value
  if (is.list(v)) return(paste(vapply(v, function(x) paste(as.character(x), collapse = "|"), character(1)), collapse = " ;; "))
  paste(as.character(v), collapse = "|")
}

iso <- load_impl(ISO, ISO_HELPERS)
mnp <- load_impl(MNP)

rows <- lapply(CASES, function(cs) {
  a <- run_case(iso, cs); b <- run_case(mnp, cs)
  ra <- render(a); rb <- render(b)
  same <- identical(ra, rb)
  cls <- if (same) "NO_CHANGE" else "NEEDS_REVIEW"
  data.frame(case_id = cs$id, `function` = cs$fn,
             inputs = paste(vapply(cs$args, function(x) paste(as.character(x), collapse = ","), character(1)), collapse = " / "),
             mode = if (is.null(cs$mode)) NA_character_ else cs$mode,
             isochrones_result = ra, mysterynpi_result = rb,
             same = same, classification = cls,
             reason = if (same) "identical output" else "DIFFERENCE: requires explicit classification",
             check.names = FALSE, stringsAsFactors = FALSE)
})
out <- do.call(rbind, rows)
utils::write.csv(out, "tests/fixtures/name_primitive_differential.csv", row.names = FALSE, na = "")
cat("cases:", nrow(out), "\n")
print(table(out$classification))
diffs <- out[!out$same, ]
if (nrow(diffs)) { cat("\nDIFFERENCES:\n"); print(diffs[, c("case_id", "isochrones_result", "mysterynpi_result")]) }
