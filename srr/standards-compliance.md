# mysterynpi and the rOpenSci statistical software standards

Second assessment, 2026-11-22. The first assessment in this file was made
before any standards work existed in the package; this one is made after it,
and it reaches a different set of numbers for a reason worth stating up front
(see "What changed, and why the numbers moved"). The first version is in git
history if you want to compare.

**The package.** `mysterynpi` resolves whether a roster name and a National
Provider Identifier record describe the same person. It is a rules engine, not
a model: each comparable attribute (surname, given name, middle name, suffix,
gender, licence, graduation year, nickname) produces one of three verdicts,
`corroborates`, `conflicts` or `uninformative`, and the decision is composed
from those verdicts rather than from a score. There is no fitted model, no
probability, no threshold to tune, and this is deliberate: the package exists
because a probabilistic matcher once resolved identity on evidence nobody had
recorded.

**Categories assessed.** Exploratory Data Analysis, Regression and Supervised
Learning, and Time Series, each combined with the General standards, which
apply regardless of category.

## What changed, and why the numbers moved

Three things, and only the third is an improvement in the package.

**1. The counting granularity was wrong the first time.** The first assessment
counted the 145 top-level items in `srr-standards.md`. But many of those items
carry sub-lettered identifiers (`G2.4a` through `G2.4e`, `TS4.6c`, `RE4.17`),
each of which is a separate standard with its own requirement, and the skill
asks for a verdict on every individual identifier. At that granularity there
are **205** standards, not 145: General 68, Exploratory Data Analysis 34,
Regression 48, Time Series 55. The instruction's own expectation of "roughly 70
General standards" matches 68 and not 40, which is the clue that 145 was the
wrong denominator. Every proportion below is therefore computed over a larger
and more demanding denominator than the first assessment used.

**2. The `srr` tooling is now the source of the verdicts, not my reading.**
Every verdict below is derived mechanically from the tags in the package source
rather than transcribed from a judgement I made in prose. The cross-check:

```
identifiers in srr-standards.md                 205
identifiers carrying an @srrstats or @srrstatsNA tag   205
tagged but not a real standard                    0
a real standard with no tag                       0
```

`srr::srr_stats_pre_submit()` agrees: "All applicable standards [v0.3.0] have
been documented in this package (103 complied with; 104 N/A standards)". Its
103 counts tag occurrences, two identifiers being tagged in two files; the
unique count is 101.

**3. The work itself.** The first assessment found 67 standards achievable of
which 36 were already done, the other 31 being "feasible, not yet
implemented". All 31 were then implemented. That column is now empty, which is
the one change here that reflects the package getting better rather than the
assessment getting more careful.

## How to read the verdicts

- **Y** means a tagged `@srrstats` claim backed by code in this package. There
  are no "feasible but not yet done" Y verdicts left, so unlike the first
  assessment, Y here means done.
- **N** means possible in principle but outside what this package is. Ten
  standards. They are tagged `@srrstatsNA` in the source because `srr` offers
  no other tag, and the distinction matters to a reader, so they are counted
  separately here. See the caveat in "A disagreement between the tags and this
  table" below.
- **NA** means the concept has no referent in a package with no model, no
  series, and no graphical output. Ninety-four standards. Every one carries a
  justification on its own line, which the test suite enforces: a bare
  `@srrstatsNA {ID}` with no reason fails
  `tests/testthat/test-srr-standards-tags.R`.

**The denominator.** The instruction asks for `Y / (Y + N + NA)`, counting
not-applicable standards against the package, and its stated reason is that "at
this early, pre-implementation stage NA calls are estimates rather than
developer-asserted `@srrstatsNA` tags". That reason has now expired: the NA
calls in this package are exactly developer-asserted `@srrstatsNA` tags, each
justified and validated by `srr_stats_pre_submit()`. Both numbers are therefore
reported throughout, the conservative one first because that is what was asked:

| convention | formula | result |
|---|---|---|
| this assessment, as instructed | Y / (Y + N + NA) | 101 / 205 = **49.3%** |
| rOpenSci's own applicable-standards convention | Y / (Y + N) | 101 / 111 = **91.0%** |

Neither number is the interesting one on its own. The instruction's scope
question is asked per category combined with General, and all three clear the
bar; the per-category spread is what actually decides the submission.

---

## General Standards

| subsection | Y | N | NA | total | proportion |
|---|---:|---:|---:|---:|---:|
| Documentation | 8 | 0 | 0 | 8 | 1.00 |
| Input Structures | 27 | 0 | 2 | 29 | 0.93 |
| Algorithms | 1 | 0 | 2 | 3 | 0.33 |
| Output Structures | 0 | 0 | 1 | 1 | 0.00 |
| Testing | 24 | 0 | 3 | 27 | 0.89 |
| **total** | **60** | **0** | **8** | **68** | **0.882** |

### Key evidence and gaps

**Documentation is complete, 8 of 8.** `G1.1` is answered in the README section
"What this re-implements, and what is original": the primitives (blocking keys,
agreement vectors, declared nickname equivalence) are established record
linkage practice, and what is original is the set of refusals. `G1.2` is the
"Life cycle" statement. `G1.3` is the terminology section defining
"corroborates", "conflicts" and "uninformative" as the package uses them.
`G1.4` is complete `roxygen2` documentation across 123 exports and 5 S3 methods. `G1.5` and
`G1.6` are the benchmark and the comparison described below.

**Input Structures is the strongest section, 27 of 29**, and most of it was
built for this assessment. `R/input_structures.R` holds `as_linkage_table()`
(accepting `data.frame`, `tbl_df`, `data.table` and a named matrix, and
reporting what each conversion costs), `reject_list_columns()`,
`read_name_column()`, `drop_vector_attributes()`, `check_scalar()` and
`affirm_unique_index()`. `match_npi()` applies them at the top of the call, so
a numeric identifier no longer reaches a comparison formatted as `1.23e+09`.

`G2.14`, and with it `RE2.1` and `TS2.1`, is `R/missing_policy.R`:
`na_action = c("uninformative", "warn", "error")` on all eight agreement rules.
One parameter closed three standards because they are the same request in three
standard sets. The default reproduces the behaviour of every previous release,
so the contract asserters still run against it unchanged.

`G2.14c` (imputation) is the one General standard refused on principle rather
than for absence of a referent, and the refusal is tagged with its reasoning:
an imputed name is a fabricated identity claim. This package exists because
absence of evidence was once read as evidence of difference; reading it as
evidence of sameness is worse, because it resolves a match on a name nobody
recorded. It is refused on the numeric graduation-year scale too, where it would
at least be well defined, because imputing a year manufactures the very
compatibility `graduation_year_agreement()` is asked to judge.

**Testing is 24 of 27.** The suite is 2,579 passing assertions. What matters for
these standards is what they cover, not that they exist: `G5.2` error and
warning messages are asserted by message text, not merely by condition class;
`G5.3` missingness and undefined values have their own suite
(`test-srr-missing-policy.R`); `G5.5` and `G5.6` seeded tests fix the seed and
assert the recovered value, after a defect where the comparison was between two
`NULL`s and passed trivially; `G5.9` noise susceptibility is covered by the
trivial-noise and seed-independence tests; `G5.10` to `G5.12` extended tests are
`test-srr-extended.R`, gated on `MYSTERYNPI_EXTENDED_TESTS`, documenting its
flag, platform, memory, runtime, network dependency, asset and artefacts, and
fetching a National Plan and Provider Enumeration System extract rather than
shipping one.

**The two Input Structures NAs** are `G2.4d` and `G2.4e` (explicit conversion to
and from factor): the package refuses factors at the boundary rather than
converting them, which is a stronger position than the standard asks for, and
documented as such.

**The three Algorithms and Output Structures NAs are the honest heart of this
assessment.** `G4.0` (outputs written to local files) has no referent:
`match_npi()` returns an object and writes nothing. `G3.0` and `G3.1` concern
floating-point comparison and covariance methods; there is no floating-point
arithmetic in a verdict and no covariance anywhere. A package that composes
three-valued verdicts has very little surface for the General standards about
numeric algorithms, and that is a real limit on how much of this standard set
can ever apply, not an omission.

**No N verdicts in General, and I looked for them twice.** Every General
standard is either satisfied or has no referent.

---

## Exploratory Data Analysis

| subsection | Y | N | NA | total | proportion |
|---|---:|---:|---:|---:|---:|
| Documentation Standards | 4 | 0 | 0 | 4 | 1.00 |
| Input Data | 8 | 1 | 0 | 9 | 0.89 |
| Analytic Algorithms | 2 | 0 | 0 | 2 | 1.00 |
| Return Results / Output Data | 3 | 0 | 0 | 3 | 1.00 |
| Visualization and Summary Output | 2 | 0 | 7 | 9 | 0.22 |
| Testing | 6 | 0 | 1 | 7 | 0.86 |
| **total** | **25** | **1** | **8** | **34** | **0.735** |

### Key evidence and gaps

Four of the six subsections are complete. This is the only category in which
that is true, and it is the reason the recommendation at the end is what it is.

**`EA1.x` fits without strain.** The standards ask the software to state its
target audience, the kinds of question it answers and the data it expects, and
`DESCRIPTION`, the README and `vignette("resolving-a-roster")` already did.
This category's premise, software whose purpose is to help a user understand a
dataset rather than to fit a model to it, is a fair description of what this
package does: it tells you which roster rows it can resolve, which it refuses,
and why for each one.

**Return results, 3 of 3, is new work.** `R/match_result_class.R` adds the
`npi_match_result` class with `print()`, `format()`, `summary()` and `nobs()`.
`summary()$columns` reports the class, storage mode and missing count of each
column, which is `EA4.1` and `EA4.2` (precision and the general tabular
summary). The class is additive: the same five elements under the same names, so
every existing caller keeps working, while printing a result now gives six lines
of summary instead of every matched row.

**`EA2.4`, a relational data class, is the one N in this set.** The standard
asks for explicit relational structure, naming the `dm` package. The package's
whole input contract is "you name the columns, we never guess", across a
123-export surface. Adopting a relational class system would be a different
package rather than an increment on this one, which is what an N verdict is
for.

**The whole Visualization subsection except two standards is NA, and that is
the ceiling on this category.** `EA5.0` through `EA5.6` concern colour
perception, contrast, scaling, axis labelling and graphical output formats.
There is no graphical output: no plot method exists, and
`R/match_result_class.R` records why in a comment rather than leaving the
absence to be inferred. A plot of a three-valued verdict table would be a bar
chart of counts that `summary()` already prints more precisely. The two Y
verdicts here are the summary-output standards, `EA5.4` on the number of
digits reported (`summary.npi_match_result(digits = 3L)`) and the printed
general summary.

---

## Regression and Supervised Learning

| subsection | Y | N | NA | total | proportion |
|---|---:|---:|---:|---:|---:|
| Input data structures and validation | 2 | 2 | 2 | 6 | 0.33 |
| Pre-processing and Variable Transformation | 2 | 0 | 5 | 7 | 0.29 |
| Algorithms | 0 | 0 | 4 | 4 | 0.00 |
| Return Results | 2 | 3 | 14 | 19 | 0.11 |
| Documentation | 1 | 0 | 0 | 1 | 1.00 |
| Visualization | 0 | 1 | 3 | 4 | 0.00 |
| Testing | 5 | 0 | 2 | 7 | 0.71 |
| **total** | **12** | **6** | **30** | **48** | **0.250** |

### Key evidence and gaps

**One quarter, and the shape of the gap is more informative than the number.**
Two subsections score zero and a third scores 0.11. What the package can satisfy
here is almost entirely what it already satisfies for General: input validation
(`RE1.4`), the missing-data parameter (`RE2.1`, the same one as `G2.14`),
testing discipline, and the return-value standards that happen to coincide with
having a result class (`RE4.5` on the number of observations, `RE4.11` on
goodness of fit, answered by the benchmark).

**Six N verdicts, and they are the honest ones.** `RE1.0` and `RE1.1` ask for a
formula interface and for documentation of how a formula becomes a model
matrix. A formula interface over a function that takes two character vectors
would tell a reader the package fits something it does not. `RE4.0` asks the
return object to be a model object; it is a match result, which is a different
thing. `RE4.17` and `RE4.18` ask for prediction intervals and for a `predict()`
method on new data: there is nothing fitted to predict with, and a `predict()`
method that re-ran the rules would be `match_npi()` with a misleading name.
`RE6.0` asks for a default plot method showing fitted values against residuals,
and there are no fitted values and no residuals.

**The fourteen NAs in Return Results** are the model-object accessors:
coefficients, standard errors, degrees of freedom, the variance-covariance
matrix, the model call, convergence diagnostics. None has a referent in a rules
engine. This is the subsection that decides the category: a standard set in
which the largest section is mostly about describing a fitted model is a poor
description of software that never fits one.

---

## Time Series

| subsection | Y | N | NA | total | proportion |
|---|---:|---:|---:|---:|---:|
| Input data structures and validation | 2 | 2 | 5 | 9 | 0.22 |
| Pre-processing and Variable Transformation | 1 | 0 | 11 | 12 | 0.08 |
| Analytic Algorithms | 0 | 0 | 6 | 6 | 0.00 |
| Return Results | 1 | 0 | 18 | 19 | 0.05 |
| Visualization | 0 | 1 | 8 | 9 | 0.00 |
| **total** | **4** | **3** | **48** | **55** | **0.073** |

### Key evidence and gaps

**Seven per cent. This category does not apply, and the assessment should say so
without softening it.** Three of five subsections score zero or near it, and
forty-eight of fifty-five standards have no referent at all.

The four Y verdicts are real but incidental: `TS2.1` (the missing-data
parameter, the same `na_action` as `G2.14`), `TS1.8` (the unit of time is
stated, which `GRADUATION_YEAR_BANDS` now documents as a whole calendar year
with band boundaries that are not date boundaries), and two input-validation
standards that coincide with the General ones.

**Three N verdicts.** `TS1.0` and `TS1.2` ask the software to accept and
validate time-series classes (`ts`, `xts`, `tsibble`). Adopting them would
require inventing a temporal dimension the data does not have. `TS5.0` asks for
a default plot method with time on the horizontal axis, and there is no time
axis.

**Forty-eight NAs, covering stationarity, differencing, seasonality, lag
selection, autocorrelation, forecast horizons and prediction intervals.** The
package has one date-like field, a graduation year, and it is used as a
compatibility band rather than as a position in a series. Two records are
compared to each other, never a record to its own past. There is no series
anywhere in the package.

A category in which the best available verdict for forty-eight of fifty-five
standards is "the concept has no referent here" is not a category this package
belongs in, whatever the combined proportion with General works out to.

---

## A disagreement between the tags and this table

Worth flagging for anyone reading both. The source tags ten standards
`@srrstatsNA` that this assessment counts as **N**: `EA2.4`, `RE1.0`, `RE1.1`,
`RE4.0`, `RE4.17`, `RE4.18`, `RE6.0`, `TS1.0`, `TS1.2`, `TS5.0`. This is not a
contradiction and not a fudge. `srr` has exactly two tags, complied and not
applicable, with no slot for "possible, but it would make this a different
package", which is what the N verdict means here. In `srr`'s own taxonomy these
really are not applicable: there is no formula interface, so there is nothing to
document about one. The distinction only exists in this assessment's taxonomy,
so it is reported in this assessment's tables and the justification text on each
tag says which of the two situations it is.

---

## Task 3: scope and category fit

### Is the package in scope?

Per category combined with General, which is how the question is posed:

| standards set | Y | total | Y / (Y + N + NA) | clears 50% |
|---|---:|---:|---:|:---:|
| General + Exploratory Data Analysis | 85 | 102 | **83.3%** | yes |
| General + Regression | 72 | 116 | **62.1%** | yes |
| General + Time Series | 64 | 123 | **52.0%** | yes |

All three clear the bar on the conservative denominator, and the applicable
standards convention puts the package at 91.0% overall. **The package is in
scope.**

Two honest qualifications. The Time Series figure clears 50% only because the
General standards carry it: the category itself is at 7.3%, so that row should
be read as evidence about the General standards, not about Time Series. And the
all-standards figure of 49.3% falls just under half, which is a fact about
assessing a rules engine against three model-shaped standard sets at once, not a
scope failure against any one of them.

### Which single category fits best?

**Exploratory Data Analysis, at 73.5%, and the reasoning is not only the
number.** The number is nearly three times Regression and ten times Time
Series, but what settles it is which sections are complete. In this category,
Documentation, Input Data, Analytic Algorithms and Return Results are all at or
near 1.00, and those four are the sections that describe what the package
actually does: take a table, validate it carefully, apply deterministic rules,
return a described result. Its only weak section, Visualization, is weak for a
single stated reason, that the package produces no graphics, and that reason is
documented in the source rather than left to be inferred.

The category's premise fits too. Exploratory Data Analysis standards are
written for software that helps a user understand a dataset. `match_npi()`
returns, for every roster row, a verdict and the reason for it, including the
rows it refuses to resolve and why. That is a description of a dataset's
resolvability, which is what this package is for.

### Is any other category independently viable?

**No, and the recommendation is to submit under one category only.** Regression
at 25.0% is not viable: the formula interface, the model object, `predict()` and
the fitted-versus-residual plot are all N, and they are the centre of that
standard set rather than its periphery. Time Series at 7.3% is further out
still. Listing either as a secondary category would ask reviewers to evaluate
this package against expectations it does not merely fail to meet but has no
analogue for.

### Recommendation

Submit under **Exploratory Data Analysis**, as a single category.

The honest framing for a submission issue is that this is a deterministic rules
engine assessed against a standard set written largely for statistical
estimators, and the most interesting parts of the assessment are the refusals:
imputation (`G2.14c`), a fuzzy-matching comparison function (see the follow-up
list), a formula interface (`RE1.0`), a plot method (`EA5.x`, `RE6.0`, `TS5.0`).
Each is refused in the source with its reason attached, which is the form in
which a reviewer can disagree with the judgement rather than merely notice the
absence.

---

## Ranked follow-up work, cheapest first

1. **Twenty-nine of the 101 complied tags carry a generated justification
   rather than a specific one.** They read "implemented in this file; see the
   function documentation and the file header for the defect it prevents",
   which tells a reviewer nothing beyond which file to open. The code behind
   them is real and tested; the tag text is not evidence. The identifiers:
   `EA2.5`, `EA2.6`, `EA3.0`, `EA3.1`, `EA4.0`, `EA4.1`, `EA4.2`, `EA5.2`,
   `EA5.3`, `G1.5`, `G2.2`, `G2.4`, `G2.4a`, `G2.4b`, `G2.4c`, `G2.6`, `G2.7`,
   `G2.9`, `G2.11`, `G2.12`, `G2.14`, `G2.14a`, `G2.14b`, `G2.16`, `G5.7`,
   `RE2.1`, `RE4.5`, `RE4.11`, `TS2.1`. This is the largest remaining gap
   between what the package does and what a reviewer reading its tags would
   learn, and it is a writing task rather than an engineering one.

2. **No `srr` badge grade has been pursued.** The standards offer graded badges
   and this assessment does not estimate which grade the current coverage would
   earn.

3. **`autotest` has not been run.** rOpenSci's statistical review uses it
   alongside `srr`, and it tests input-handling assumptions automatically. The
   input-structure work in `R/input_structures.R` is exactly what it probes, so
   it is likely to find something.

4. **The benchmark corpus is self-built.** `ROSTER_BENCHMARK` is constructed
   from this package's own defect taxonomy, so the clean separation it shows is
   consistency rather than proof of generality, as `vignette("roster-benchmark")`
   already states. An external roster with known truth would make `G5.4` and
   `G1.5` substantially stronger. This is the most valuable item on the list and
   also the most expensive, since it needs data the package cannot generate.

## Appendix: how to reproduce these counts

```sh
# every identifier in the canonical checklist, including sub-lettered ones
python3 - <<'PY'
import re
cur = None
for ln in open("srr/srr-standards.md"):
    if ln.startswith("### "): cur = ln[4:].strip()
    elif ln.lstrip().startswith("- ["):
        m = re.search(r"\*\*(G|EA|RE|TS)([0-9.]+[a-z]?)\*\*", ln)
        if m: print(cur, m.group(1) + m.group(2))
PY

# every identifier carrying a tag, and of which kind
grep -rhoE "@srrstats \{[^}]+\}" R/ tests/ | sed -E 's/.*\{|\}//g' | tr ',' '\n'
grep -rhoE "@srrstatsNA \{[^}]+\}" R/ tests/ | sed -E 's/.*\{|\}//g' | tr ',' '\n'

# the tooling's own verdict
Rscript -e 'srr::srr_stats_pre_submit()'
```
