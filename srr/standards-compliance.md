# mysterynpi against the rOpenSci statistical software standards

**Assessed 2026-11-22 at `edaae4b` (0.9.1); every feasible standard then
implemented on `feat/srr-feasible-standards`.** Every one of the 145 standard
IDs in [`srr-standards.md`](srr-standards.md) carries an individual verdict,
and the tables below are counted from those verdicts rather than estimated
from subsection headings.

**What changed between the assessment and this version of the document.** The
first assessment found 67 `Y` verdicts of which only 36 were implemented; the
other 31 were "feasible, not yet implemented". All 31 are now implemented, so
every `Y` in the tables below is already-done and the "Y (feasible)" column is
zero everywhere. The proportions are unchanged, because potential compliance
was what they always measured -- what changed is that they are now actual.

`srr::srr_stats_pre_submit()` reports **"All applicable standards [v0.3.0]
have been documented in this package (104 complied with; 104 N/A standards)"**,
with zero undocumented. srr counts sub-lettered IDs (`G2.4a`, `TS4.6c`) that
the 145-item checklist collapses, which is why its totals are larger; 104 of
208 is exactly srr's own 50% bar.

## What the package is

`mysterynpi` is record-linkage machinery: one definition of the name handling
a provider linkage needs. It transliterates join keys, tokenises
given/middle/surnames, and decides whether two records name the same person.
It is deliberately deterministic — `middle_agreement()` returns
`"corroborates"`, `"conflicts"` or `"uninformative"`, with no edit-distance
tolerance and no score — and its `DESCRIPTION` draws an explicit scope
boundary: it "stops short of dataset-specific candidate-generation policy and
blended scoring", because "which blocking plans to deploy and what a study
claims from the resulting evidence are pipeline science, not shared
machinery."

Measured surface: 7,539 lines across 39 files in `R/`, 108 exports, 115 `.Rd`
pages, 58 test files carrying 1,654 expectations, 5 vignettes, 4 exported
datasets (`WINKLER_CENSUS`, `ROSTER_BENCHMARK`, `SURNAME_FREQUENCIES`,
`NICKNAME_EDGES`), and 6 GitHub workflows including `R-CMD-check`,
`test-coverage` and `pkgdown`. Imports are `stringi` and `stats` only.

## Categories assessed

General (mandatory), plus **EDA**, **Regression and Supervised Learning**, and
**Time Series**, as requested. Full standards texts are in
[`general.Rmd`](general.Rmd), [`eda.Rmd`](eda.Rmd),
[`regression.Rmd`](regression.Rmd) and [`time-series.Rmd`](time-series.Rmd).

## Reading the verdicts

- **Y** — satisfied, or achievable with ordinary engineering given the current
  architecture. The tables split these into **Y (done)** and **Y (feasible)**
  because the distinction matters to a maintainer even though both count the
  same: *feasible* is exactly where follow-up work would go.
- **N** — would need a capability that conflicts with the package's scope.
- **NA** — the concept is absent from the package. **NA counts in the
  denominator.** A category that mostly does not apply scores low, which is
  the point.

Proportion reported throughout is **Y / (Y + N + NA)**, over every standard in
the set.


## General Standards

### General — verdict table

| Subsection | Y (done) | Y (feasible) | N | NA | total |
|---|---:|---:|---:|---:|---:|
| Documentation | 7 | 0 | 0 | 0 | 7 |
| Input Structures | 16 | 0 | 0 | 1 | 17 |
| Algorithms | 1 | 0 | 0 | 1 | 2 |
| Output Structures | 0 | 0 | 0 | 1 | 1 |
| Testing | 12 | 0 | 0 | 1 | 13 |
| **total** | **36** | **0** | **0** | **4** | **40** |

**Proportion Y / (Y + N + NA) = 36 / 40 = 90.0%**, all of it implemented.

### General — key evidence and gaps

**Already satisfied, and strongly.** `G1.4` is beyond argument: roxygen2
throughout, 115 `.Rd` files, a published pkgdown site. `G1.3` is unusually well
served — the three agreement classes, the evidence classes, the veto and
quarantine vocabulary are each defined in roxygen *and* narrated in
`vignettes/vetoes-and-quarantine.Rmd`. `G1.0` is met in substance: Winkler and
Jaro are cited in `R/surname.R` and `R/name_matching.R`, and
`data/WINKLER_CENSUS.rda` ships the reference surname frequency table, so the
literature is in the package rather than only in the prose.

The input-validation standards land well because validation is this package's
subject. `R/contracts.R` alone carries 28 `stop()` calls;
`.match_npi_inputs()` (`R/match_npi.R:221`) checks class, backend consistency
and the table/connection pairing with `call. = FALSE` messages that name the
offending argument. `G2.10` is satisfied by construction: every column is
addressed through a caller-supplied name, never by position or by a default,
and the README explains why — an upstream consolidation moved a resolver's
default identifier column and a caller "died fifteen minutes into a run,
twice", with the silent variant being the dangerous one. `G2.13` and `G2.15`
are the package's origin story: `blank_na()` and `has_name_information()`
exist because `nzchar(NA)` is `TRUE`, which made every absent middle name
agree with every other.

Testing is the other strength. `G5.0` and `G5.1` are both met already, which
is rarer than it sounds: the test data are *exported* datasets, so a user can
re-run any assertion. `G5.2` holds across 30 of the 58 test files, asserting
on message text rather than merely on failure. `G5.5` is enforced at the API
level — `clerical_sample()` refuses to run without a `seed`, with the error
"the draw must be reproducible from the methods section alone". `G5.8` is the
suite's centre of gravity: empty strings, `NA`, single-character given names,
concatenated initials, and — as of `HEAD` — punctuation-only tokens.

**The eighteen that were feasible are now done.** They clustered in three
places, and each cluster became one change:

1. *Two one-paragraph documentation gaps.* `G1.2` has no Life Cycle Statement
   at all, which is conspicuous for a package at 0.9.1 whose `DESCRIPTION`
   already articulates a deliberate scope boundary. `G1.1` never says whether
   these rules re-implement established linkage practice or invent it — the
   README says each rule encodes a shipped defect, which is a different claim.
2. *A missing-data parameter.* `G2.14` wants user-selectable `NA` handling.
   The package has exactly one policy (absence is uninformative, never
   conflicting), it is the right default, and it is tested — but it is not a
   parameter. The same gap is `RE2.1` and `TS2.1` in the category sets, so one
   change closes three standards.
3. *Tabular-form and type-conversion breadth.* `G2.2`, `G2.4`, `G2.6`, `G2.7`,
   `G2.9`, `G2.11`, `G2.12` and `G2.16` are all variations on "accept more
   input shapes, and say something when a conversion loses information". Today
   the API is `data.frame`-only and silent on lossy coercion; an identifier
   read as numeric and compared as character would pass unremarked. These are
   dispatch and diagnostics, not redesign.

The extended-test standards `G5.10`–`G5.12` are now one lane:
`tests/testthat/test-srr-extended.R`, gated on `MYSTERYNPI_EXTENDED_TESTS`,
fetching the NPPES extract rather than shipping it (or reading a local copy
named by `MYSTERYNPI_NPPES_CSV`), with the flag, platform, memory, runtime,
network, asset and artefact conditions stated in a block at the top. `G5.7` is
now asserted rather than narrated: the benchmark properties are checked per
defect family, so a rule that holds only on the mixed corpus fails.

**No `N` verdicts, and I looked for them.** The four `NA`s are
concept-absence, not evasion: `G2.5` (no argument is ever expected to be a
factor), `G3.1` (no covariance calculation exists), `G4.0` (nothing writes a
user-named local file; the DuckDB backend writes into a caller-supplied
connection), and `G5.6` (nothing is estimated, so there is no parameter to
recover). I specifically re-examined `G1.6`, `G2.7` and `G5.6` as `N`
candidates and rejected each: comparing against `fastLink` or `reclin2` needs
a benchmark, not a new inferential framework; tibble acceptance is a dispatch
change; and parameter recovery is genuinely inapplicable to a decision
function with no parameters. The General set is where this package is
strongest, and that is unsurprising — these standards largely encode software
engineering practice, which is what the package is built out of.

## EDA Standards

### EDA — verdict table

| Subsection | Y (done) | Y (feasible) | N | NA | total |
|---|---:|---:|---:|---:|---:|
| Documentation Standards | 4 | 0 | 0 | 0 | 4 |
| Input Data | 6 | 0 | 1 | 0 | 7 |
| Analytic Algorithms | 2 | 0 | 0 | 0 | 2 |
| Return Results / Output Data | 3 | 0 | 0 | 0 | 3 |
| Visualization and Summary Output | 2 | 0 | 0 | 5 | 7 |
| Testing | 1 | 0 | 0 | 1 | 2 |
| **total** | **18** | **0** | **1** | **6** | **25** |

**Proportion Y / (Y + N + NA) = 18 / 25 = 72.0%**, all of it implemented.

N verdicts: `EA2.4`

### EDA — key evidence and gaps

**This is the category the package actually resembles**, and the reason is
`EA2`. The Input Data subsection is about index columns and joins, and
`mysterynpi` is a join engine: `R/blocking.R`, `R/match_npi_memory.R` and
`R/match_npi_duckdb.R` are table filter and join operations over named
columns. `EA2.1` is satisfied by `resolve_one_to_one()` and `R/bijection.R`,
which *affirm* identifier uniqueness rather than assuming it, and
`count_rivals()` quantifies the violations instead of discarding them.
`EA2.2` and `EA2.3` are met emphatically: index columns are required
arguments (`id`, `npi`), and no join anywhere uses an assumed column name —
again, because a moved default column is the defect that motivated the
package.

`EA1.0`–`EA1.3` are all already met from the README and the per-function
roxygen: the audience (pipelines linking person rosters to NPI), the data
kinds (character name fields on a roster and an NPPES-shaped reference), the
questions (do these two records name the same person; which candidate wins
one-to-one), and the per-function input types.

**The eight that were feasible are now done.** `EA3.0` and `EA3.1` were
close enough to be annoying -- `pool_stats()` and `clerical_precision()`
already computed statistics, and `ROSTER_BENCHMARK` plus
`roster-benchmark.Rmd` already constituted a reference comparison -- and are
now `summary.npi_match_result()` and `benchmark_comparison()`, both callable
and both tested. `EA4.1`, `EA5.2` and `EA5.3` were the same omission three
times and are closed by the one `npi_match_result` class: `digits` on
`summary()`/`format()`/`print()`, every number formatted rather than
default-printed, and a `summary()$columns` frame reporting class, storage mode
and missing count per column. `EA2.5` and `EA2.6` are
`affirm_unique_index()` and `drop_vector_attributes()`.

**The one `N`.** `EA2.4` asks for an explicit relational class system (the
standard names `dm`). Adopting one across a 108-function API whose contract is
"you name the columns, we never guess" would be a different package, not an
increment on this one.

**The whole Visualization subsection is `NA` except two standards, and that is
what caps this category at 72%.** The package draws nothing: there are no
`plot`, `print`, `summary` or `format` methods anywhere in `R/`, and the only
plots in the repository are two base `barplot()` calls inside
`vignettes/end-to-end-nppes-matching.Rmd`. So `EA5.0`, `EA5.1`, `EA5.4`,
`EA5.5`, `EA5.6` and `EA6.1` have nothing to apply to. Under the stated
denominator rule that is a real cost, correctly applied: a package with no
graphical output is a weaker EDA package, not a neutral one.

## Regression and Supervised Learning Standards

### Regression — verdict table

| Subsection | Y (done) | Y (feasible) | N | NA | total |
|---|---:|---:|---:|---:|---:|
| Input data structures and validation | 1 | 0 | 2 | 2 | 5 |
| Pre-processing and Variable Transformation | 2 | 0 | 0 | 3 | 5 |
| Algorithms | 0 | 0 | 0 | 4 | 4 |
| Return Results | 2 | 0 | 3 | 14 | 19 |
| Documentation | 1 | 0 | 0 | 0 | 1 |
| Visualization | 0 | 0 | 1 | 3 | 4 |
| Testing | 3 | 0 | 0 | 2 | 5 |
| **total** | **9** | **0** | **6** | **28** | **43** |

**Proportion Y / (Y + N + NA) = 9 / 43 = 20.9%**, all of it implemented.

N verdicts: `RE1.0`, `RE1.1`, `RE4.0`, `RE4.17`, `RE4.18`, `RE6.0`

### Regression and Supervised Learning — key evidence and gaps

**20.9%, and the shape of the failure is more informative than the number.**
There is no model. `middle_agreement()` is a decision function over two token
sets; nothing is fitted, nothing iterates to convergence, nothing has
coefficients. Consequently the entire `RE3` Algorithms subsection (4
standards) is `NA` — no convergence to warn about, no thresholds to set — and
14 of the 19 `RE4` Return Results standards are `NA` for the same reason:
`coef()`, `confint()`, `vcov()`, residuals, modelled values, forecast errors
and categorical-group subsetting have no referent here.

**Six `N` verdicts, and they are the honest ones.** `RE1.0`/`RE1.1` (a formula
interface and its matrix conversion), `RE4.0`/`RE4.17`/`RE4.18` (a model
object with `print` and `summary` methods) and `RE6.0` (a default plot method
on that object) could all be *built*, but each would be a facade: a formula
interface over a function that takes two character vectors, or a "model"
object that fits nothing, would tell a reader this package does something it
does not. That is the distinction the `N` verdict exists for.

**What genuinely holds.** `RE1.3` is satisfied and worth noting, because it is
the one `RE1` standard that is about data plumbing rather than models: the
output frame retains the caller's roster columns and appends `source_id`,
`npi` and `reason` through `make.unique()`, so input structure survives onto
output without silent collisions. `RE2.0` is fully met — every transformation
(`normalize_string()`, `name_key()`, `strip_parenthetical()`,
`strip_med_suffix()`) is documented together with the defect it prevents.
`RE5.0` is met by `roster-benchmark.Rmd`, which documents how runtime and
candidate counts scale with roster size; that is precisely what the standard
asks and it is already written. And the `RE7` Testing standards are the
package's strong suit: `RE7.0`, `RE7.1` and `RE7.2` are all already satisfied
because exact, noiseless relationships *are* the test suite — identical names
must corroborate, disjoint names must conflict, roster identifiers must
survive onto the output.

**The three that were feasible are now done.** `RE4.5` is
`nobs.npi_match_result()`. `RE4.11` is the precision-among-accepts statistic in
`benchmark_comparison()$rates` plus the precision/recall table in
`vignette("comparison-with-alternatives")`. `RE2.1` is the same missing-data parameter as
`G2.14`, which is the point: one change, three standard sets.

## Time Series Standards

### Time Series — verdict table

| Subsection | Y (done) | Y (feasible) | N | NA | total |
|---|---:|---:|---:|---:|---:|
| Input data structures and validation | 2 | 0 | 2 | 5 | 9 |
| Pre-processing and Variable Transformation | 1 | 0 | 0 | 6 | 7 |
| Analytic Algorithms | 0 | 0 | 0 | 4 | 4 |
| Return Results | 1 | 0 | 0 | 7 | 8 |
| Visualization | 0 | 0 | 1 | 8 | 9 |
| **total** | **4** | **0** | **3** | **30** | **37** |

**Proportion Y / (Y + N + NA) = 4 / 37 = 10.8%**, all of it implemented.

N verdicts: `TS1.0`, `TS1.2`, `TS5.0`

### Time Series — key evidence and gaps

**10.8%, and it should be.** There is no time series anywhere in the package.
30 of 37 standards are `NA` because the concepts are absent outright:
stationarity (`TS2.2`–`TS2.4`), forecasting and forecast-error widening
(`TS3.0`–`TS3.3`, `TS4.4`–`TS4.7`), temporal axes and forecast-interval plots
(`TS5.1`–`TS5.8`), auto-covariance units (`TS2.6`), the `units` package
(`TS1.7`).

The only time-like quantity in the package is a graduation year, used for
plausibility banding: `GRADUATION_YEAR_BANDS`, `graduation_year_band()` and
`graduation_year_agreement()`. A year on a roster row is a scalar attribute
used to decide whether two records can be the same person — not an ordered
index, not a series, and not something with a frequency. That is why `TS1.1`
and `TS4.2` are the only two already-met standards: both are domain-neutral
documentation requirements (document the input types; document the type and
class of return values) that the package's roxygen satisfies incidentally.

**Three `N` verdicts.** `TS1.0` and `TS1.2` ask the software to use and
validate explicit time-series classes (`ts`, `xts`, `tsibble`); accepting them
would mean inventing a temporal dimension the data does not have. `TS5.0` asks
for a default plot method on an implemented class system — there is no class
system, and a plot of a match table is not a time-series plot.

**The two that were feasible are now done.** `TS1.8` is a section on
`GRADUATION_YEAR_BANDS` stating that the unit is a whole calendar year,
that a band boundary is not a date boundary, and why no argument accepts a
month -- passing one would be false precision. `TS2.1` is once more the
`G2.14` missing-data parameter.

A category in which the best available verdict for 30 of 37 standards is "the
concept does not arise" is not a category this package should be submitted
under, and the proportion says so without needing interpretation.

## What was built to close the 31

Each item lists the standards it closed. Everything here is on
`feat/srr-feasible-standards`; the tests that hold it are named.

| Change | Standards closed |
|---|---|
| `R/missing_policy.R` — `na_action = c("uninformative", "warn", "error")` on all eight agreement rules, default unchanged; `is_undefined_number()` / `finite_or_na()`; `graduation_year_agreement(undefined=)` | `G2.14`, `G2.16`, `RE2.1`, `TS2.1` |
| `R/input_structures.R` — `as_linkage_table()`, `read_name_column()`, `reject_list_columns()`, `drop_vector_attributes()`, `check_scalar()`, `affirm_unique_index()`, wired into `match_npi()` | `G2.2`, `G2.4`, `G2.6`, `G2.7`, `G2.9`, `G2.11`, `G2.12`, `EA2.5`, `EA2.6` |
| `R/match_result_class.R` — `npi_match_result` class with `print()`, `format()`, `summary()`, `nobs()` | `EA3.0`, `EA4.1`, `EA4.2`, `EA5.2`, `EA5.3`, `RE4.5` |
| `R/benchmark.R` — `benchmark_axes()`, `benchmark_decisions()`, `benchmark_comparison()` | `EA3.1`, `RE4.11`, `G1.5`, `G5.7` |
| `vignettes/comparison-with-alternatives.Rmd` — the head-to-head against an edit-distance baseline | `G1.6` |
| README sections "What this re-implements", "Compared with an edit-distance matcher", "Life cycle"; calendar-convention section on `GRADUATION_YEAR_BANDS` | `G1.1`, `G1.2`, `G1.6`, `TS1.8` |
| `tests/testthat/test-srr-missing-policy.R`, `-input-structures.R`, `-result-and-benchmark.R`, `-extended.R` | `G5.3`, `G5.7`, `G5.9`, `G5.10`, `G5.11`, `G5.12` |

Three of these are worth reading rather than counting.

**The missing-data parameter closed three standards with one change**, which is
what the assessment predicted: `G2.14`, `RE2.1` and `TS2.1` are the same
request in three standard sets. The default is unchanged and the contract
asserters still run against it, so no existing caller moves. What is new is
that a pipeline which would rather fail than carry an uninformative row can
say so. **`G2.14c` — imputation — is refused**, and the refusal is the
interesting part: an imputed name is a fabricated identity claim, and this
package exists because absence of evidence was once read as evidence of
difference. Reading it as evidence of *sameness* is worse. Imputation is not
offered on the numeric year scale either, where it would at least be defined,
because imputing a year manufactures the compatibility the function is asked
to judge.

**`G1.6` turned an assertion into a measurement.** The claim that a one-edit
tolerance on names costs more than it buys was prose in `R/agreement.R`;
`vignette("comparison-with-alternatives")` now runs it on the 190-pair
benchmark against a base-R edit-distance baseline:

| approach | accepted | precision | recall | false accepts |
|---|---:|---:|---:|---:|
| mysterynpi rules | 126 | 1.000 | 0.955 | 0 |
| edit distance <= 1 | 41 | 0.854 | 0.265 | 6 |

The six false accepts land in the `spelling-trap` family, which is exactly the
`JULIA`/`JULIE` case the comment described. No new dependency: edit distance
is the alternative these rules reject, and base R ships it.

**And the package refused to let it be a function.** The comparison was
written first as an exported `compare_with_edit_distance()`, and
`tests/testthat/test-no-fuzzy.R` rejected it: that guard admits no
approximate-matching call anywhere in `R/` -- source scan, parse-tree scan and
namespace reachability, with no exempt module -- and it does not care that the
call exists to argue against approximate matching. It is right not to care. A
package whose position is that spelling similarity has no place in identity
resolution should not ship fuzzy machinery reachable from its own namespace.
The comparison moved to a vignette, which is runnable code outside the
namespace, and the rule stayed absolute. This is the second time in this piece
of work that an existing gate caught the new code rather than the reverse.

**One finding came out of the implementation rather than the assessment.**
`read_name_column()` checked `is.character()` before inspecting the class, so a
character vector carrying a `units`-like class and its attributes passed
through untouched -- which is the exact input `G2.6` and `G2.11` are about. The
test caught it; the class check now runs first, and the reason is in the
function.

## Task 3 — scope and category fit

### Does it clear half the standards?

| Set | Y | total | proportion |
|---|---:|---:|---:|
| General | 36 | 40 | **90.0%** |
| EDA | 18 | 25 | **72.0%** |
| Regression and Supervised Learning | 9 | 43 | **20.9%** |
| Time Series | 4 | 37 | **10.8%** |

Combined with the mandatory General set, which is how a submission is actually
judged:

| Submission | Y | total | proportion | clears 50%? |
|---|---:|---:|---:|---|
| General + **EDA** | 54 | 65 | **83.1%** | yes, comfortably |
| General + Regression | 45 | 83 | **54.2%** | yes, but only because General carries it |
| General + Time Series | 40 | 77 | **51.9%** | yes, but only because General carries it |

All three combinations clear the 50% bar, and two of the three do so
dishonestly: strip General out and Regression is at 20.9%, Time Series at
10.8%. **The 50% test is passed on the strength of the engineering standards,
not on statistical fit.** A reader of this assessment should not take "clears
50% under three categories" as meaning the package has three plausible
submission categories. It has one.

### Which single category fits

**EDA, at 72.0%, and the fit is architectural rather than arithmetic.** The
EDA standards' centre of gravity is `EA2` Input Data: index columns, their
uniqueness, and joins that do not guess column names. That is a description of
`mysterynpi`'s whole API. `resolve_one_to_one()` affirms uniqueness instead of
assuming it; `count_rivals()` counts the violations; every join takes
caller-supplied column names because the package exists in response to a moved
default column. Four of the seven `EA2` standards are already met and a fifth
and sixth are small additions.

What holds it back is equally structural and worth stating plainly: the
Visualization subsection is almost entirely `NA` (5 of 7, plus `EA6.1`),
because the package draws nothing — no `plot`, `print`, `summary` or `format`
methods exist anywhere in `R/`. Under the stated denominator that is a genuine
cost, and it is the difference between 72% and a figure in the high eighties.
The cheapest real improvement available is therefore not more validation but a
small result class with `print`/`format` methods, which would move `EA4.1`,
`EA4.2`, `EA5.2` and `EA5.3` from feasible to done.

### Is any second category independently viable?

**No.** Neither Regression nor Time Series is viable as a secondary category,
and the reason is the same in both: the `N` verdicts are not gaps, they are
misrepresentations waiting to happen.

- **Regression (20.9%)** would require a model object (`RE4.0`) with `print`
  (`RE4.17`), `summary` (`RE4.18`) and `plot` (`RE6.0`) methods, reached
  through a formula interface (`RE1.0`, `RE1.1`). Each is buildable and each
  would be a facade over a deterministic decision function that fits nothing.
  14 of the 19 Return Results standards are `NA` because coefficients,
  residuals, fitted values and forecast errors have no referent here.
- **Time Series (10.8%)** has no series at all. The only temporal quantity is
  a graduation year used as a plausibility attribute on a roster row. 30 of 37
  standards are `NA` on concept absence.

### Recommendation

**Submit under EDA, or do not submit yet.**

The honest framing for a submission is that `mysterynpi` is *data-linkage
infrastructure with a statistical consumer*, not statistical software that
estimates anything. Its General compliance at 90% is genuinely strong and
would survive review; its category compliance rests entirely on the
join-and-index half of the EDA standards.

Before submitting, the follow-up work that moves the most standards for the
least change, in order:

1. **A result class with `print`/`format` methods** — closes `EA4.1`, `EA4.2`,
   `EA5.2`, `EA5.3`, and is the only change that lifts the EDA proportion
   materially.
2. **A missing-data parameter** on the agreement functions — closes `G2.14`,
   `RE2.1` and `TS2.1` at once, and the current single policy becomes the
   documented default rather than the only behaviour.
3. **Two paragraphs of documentation** — a Life Cycle Statement (`G1.2`) and a
   statement of whether these rules re-implement established practice
   (`G1.1`).
4. **Assertions on the benchmark** — `roster-benchmark.Rmd` already measures
   scaling; turning its trend into a test closes `G5.7` and strengthens
   `RE5.0`, which is already met.
5. **An extended-test lane** behind `MYSTERYNPI_EXTENDED_TESTS` over a
   fetched NPPES extract — closes `G5.10`, `G5.11`, `G5.12` together.

One caveat on this document's own authority, now narrower than it was. The
methodology asks for *potential* compliance, and the first version of this
assessment recorded 31 of the 67 `Y`s as "feasible, not yet implemented" --
noting that a reviewer counting only shipped code would have scored General at
18/40 and EDA at 10/25. Those 31 are implemented, so the two numbers now
coincide: 36/40 and 18/25 are both the potential and the actual. What remains
a judgement rather than a fact is the `N`/`NA` split itself -- srr has no `N`
tag, so the ten standards this document calls `N` are tagged `@srrstatsNA`
with the same justification, and a reviewer who disagrees that a formula
interface over a decision function would be a facade is disagreeing with a
design position, not with a measurement.
