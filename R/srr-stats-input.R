#' srr input and algorithm standards satisfied by the matcher itself
#'
#' @description
#' The standards that live in `match_npi()` and the functions it composes,
#' rather than in the helpers added for them.
#'
#' @srrstats {G2.0} Length assertions throughout: `R/contracts.R` carries 28
#'   `stop()` calls, and `.match_npi_inputs()` checks arity before any join.
#' @srrstats {G2.1} Type assertions: `is.data.frame()`, `inherits(nppes,
#'   "DBIConnection")`, `match.arg()` on `backend`.
#' @srrstats {G2.3} `match.arg()` on every character parameter with a fixed
#'   set; `normalize_string()` and `name_key()` fold case before comparison.
#' @srrstats {G2.3a} `match.arg()` is used for `backend`, `na_action`,
#'   `undefined` and `action`.
#' @srrstats {G2.3b} Case is folded by `normalize_string()`; the README and
#'   every key function document that comparison is case-insensitive.
#' @srrstats {G2.8} `.match_npi_inputs()` normalises both backends to one
#'   internal shape, so every sub-function receives the same types.
#' @srrstats {G2.10} Every column is addressed by a caller-supplied name
#'   through `[[`, never by position and never by a default name.
#' @srrstats {G2.13} `blank_na()` and `has_name_information()` check for
#'   missingness before any agreement rule runs; they exist because
#'   `nzchar(NA)` is `TRUE`.
#' @srrstats {G2.15} No base call relies on a default `na.rm = FALSE`; the
#'   missing-data policy is explicit and tested.
#' @srrstats {G3.0} No floating-point equality comparison exists: agreement is
#'   decided on strings and integer year bands.
#'
#' @srrstats {EA2.0} The package is a join engine: `R/blocking.R`,
#'   `R/match_npi_memory.R` and `R/match_npi_duckdb.R` are table filter and
#'   join operations over named columns.
#' @srrstats {EA2.1} `resolve_one_to_one()` and `R/bijection.R` affirm
#'   identifier uniqueness rather than assuming it; `count_rivals()` quantifies
#'   violations instead of discarding them.
#' @srrstats {EA2.2} Index columns are required arguments (`id`, `npi`), never
#'   defaults.
#' @srrstats {EA2.3} No join uses an assumed column name. The package exists
#'   because an upstream default identifier column moved.
#'
#' @srrstats {RE1.3} The output frame retains the caller's roster columns and
#'   appends `source_id`, `npi` and `reason` through `make.unique()`, so input
#'   structure survives onto output without silent collisions.
#' @srrstats {RE2.0} Every transformation is documented with the defect it
#'   prevents: `normalize_string()`, `name_key()`, `strip_parenthetical()`,
#'   `strip_med_suffix()`.
#'
#' @srrstats {TS1.1} The one time-like input, a graduation year, has its type
#'   and accepted range documented on `graduation_year_band()` and
#'   `graduation_year_agreement()`.
#' @srrstats {TS1.8} `GRADUATION_YEAR_BANDS` has a section stating that the
#'   unit is a whole calendar year and why no argument accepts a month.
#' @srrstats {TS4.2} The type and class of every return value is documented in
#'   roxygen.
#'
#' @srrstats {G1.4a} Every function and dataset has a documented return value and documented parameters; `roxygen2::roxygenise()` runs clean.
#' @srrstats {G2.0a} Expectations on input length are documented per argument: the vectorised rules state that their inputs must be the same length and `stop()` when they are not.
#' @srrstats {G2.1a} Expectations on input types are documented per argument, and `read_name_column()` states what each conversion does.
#' @srrstats {G2.4d} `as.factor()` is never used on input, and the reason is documented in the NA_standards block for G2.5: a factor name key would make comparison depend on level order.
#' @srrstats {G2.4e} Explicit conversion from factor happens through `as.character()` on labels in `read_name_column()`, never `as.integer()` on codes.
#' @srrstats {G5.4a} The rules are a new implementation of established linkage practice, so correctness is tested against hand-computed expectations and the 190-pair benchmark rather than against a previous implementation.
#' @srrstats {G5.4b} `vignette("comparison-with-alternatives")` compares the
#'   rules against an alternative implementation -- a base-R edit-distance
#'   baseline -- on the same corpus, with precision and recall for each.
#' @srrstats {G5.4c} Exact deterministic verdicts are asserted with `expect_equal()`; nothing in the package is stochastic except `clerical_sample()`, whose draw is asserted under a fixed seed.
#' @srrstats {RE1.3a} `make.unique()` is used so that appending result columns cannot silently overwrite a roster column of the same name; tested in test-match-npi.
#' @srrstats {RE7.0a} Exact relationships are tested: identical names corroborate on every axis.
#' @srrstats {RE7.1a} The verdict is asserted against exact inputs for each documented defect family.
#' @srrstats {EA2.2a} Index columns are identified by required arguments (`id`, `npi`) rather than by a default name.
#' @srrstats {EA2.2b} `affirm_unique_index()` affirms index uniqueness explicitly, and `resolve_one_to_one()` enforces it.
#'
#' @name srr-stats-input
#' @keywords internal
NULL
