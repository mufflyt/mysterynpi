# Appendix: missing values, input shapes, and the result object

Version 0.10.0 added three things that change what callers can do
without changing what any existing call returns: a selectable
missing-data policy, an input layer that accepts more shapes and says
what each conversion costs, and a result object with methods. Each
exists because a standard asked for it (this is the appendix the
rOpenSci statistical standards work produced, assessed in
`srr/standards-compliance.md`), but each is useful on its own terms, and
none of them was documented for users until now.

## 1. Missing values: absence is not disagreement

Every agreement rule takes `na_action`.

``` r

surname_agreement("SMITH", NA)
#> [1] "uninformative"
```

The default scores a missing value `"uninformative"`: absence of
evidence, not evidence of difference. This is the behaviour of every
release before 0.10.0 and it is the whole reason the package exists, so
it is the default and the contract asserters run against it.

What is new is that you can ask for something louder.

``` r

withCallingHandlers(
  surname_agreement("SMITH", NA, na_action = "warn"),
  warning = function(w) { message("warned: ", conditionMessage(w)); invokeRestart("muffleWarning") }
)
#> warned: 1 missing surname value(s) scored as "uninformative": absent evidence, not conflicting evidence.
#> [1] "uninformative"
```

``` r

surname_agreement("SMITH", NA, na_action = "error")
#> Error:
#> ! 1 missing surname value(s); na_action = "error" refuses to compare. Pass na_action = "uninformative" to score them as deciding nothing, or "warn" to do that loudly.
```

Note that the rules differ in what they take.
[`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md)
compares name strings, while
[`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md)
compares **token lists** from
[`middle_tokens()`](https://mufflyt.github.io/mysterynpi/reference/middle_tokens.md)
and
[`license_agreement()`](https://mufflyt.github.io/mysterynpi/reference/license_agreement.md)
takes a number and a state for each side.
[`middle_tokens()`](https://mufflyt.github.io/mysterynpi/reference/middle_tokens.md)
absorbs both a logical `NA` and an `NA_character_`, so either reaches
the rule as an empty token list and scores `"uninformative"`:

``` r

middle_agreement(middle_tokens("ANNE"), middle_tokens(NA_character_))
#> [1] "uninformative"
license_agreement("12345", "CO", NA_character_, "CO")
#> [1] "uninformative"
```

`"warn"` reports once per call rather than once per row, so a 50,000-row
comparison gives you one warning with a count instead of a scroll.
`"error"` refuses before any comparison is made. Use `"error"` when a
missing name in your input means an upstream extraction failed and you
would rather stop than quietly score the pair as uninformative.

The same parameter is on all eight rules:
[`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md),
[`given_name_agreement()`](https://mufflyt.github.io/mysterynpi/reference/given_name_agreement.md),
[`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md),
[`suffix_agreement()`](https://mufflyt.github.io/mysterynpi/reference/suffix_agreement.md),
[`gender_agreement()`](https://mufflyt.github.io/mysterynpi/reference/gender_agreement.md),
[`license_agreement()`](https://mufflyt.github.io/mysterynpi/reference/license_agreement.md),
[`nickname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/nickname_agreement.md)
and
[`graduation_year_agreement()`](https://mufflyt.github.io/mysterynpi/reference/graduation_year_agreement.md).

### Imputation is not offered, and that is deliberate

The statistical standards ask for an imputation option (`G2.14c`). This
package refuses it. An imputed name is a fabricated identity claim. The
package exists because absence of evidence was once read as evidence of
difference; reading it as evidence of *sameness* is worse, because it
resolves a match on a name nobody recorded. It is refused on the numeric
graduation-year scale too, where it would at least be well defined,
because imputing a year manufactures the very compatibility
[`graduation_year_agreement()`](https://mufflyt.github.io/mysterynpi/reference/graduation_year_agreement.md)
is asked to judge.

### Undefined is not missing

`NaN` and the infinities are arithmetic that went wrong upstream, not a
value nobody recorded, so they are handled separately.

``` r

is_undefined_number(c(1, NA, NaN, Inf, -Inf))
#> [1] FALSE FALSE  TRUE  TRUE  TRUE
finite_or_na(c(1, NaN, Inf))
#> [1]  1 NA NA
```

[`graduation_year_agreement()`](https://mufflyt.github.io/mysterynpi/reference/graduation_year_agreement.md)
takes its own `undefined` parameter for the same reason: a year of `Inf`
is a bug in whatever produced it, and you may want to hear about it even
when you are content for a missing year to be silent.

## 2. Input shapes: converted once, at the boundary, out loud

[`match_npi()`](https://mufflyt.github.io/mysterynpi/reference/match_npi.md)
now coerces its inputs through one layer rather than letting each rule
meet whatever it is handed.

``` r

as_linkage_table(matrix(c("A", "B"), nrow = 1, dimnames = list(NULL, c("x", "y"))))
#> input converted from matrix to data.frame: every column becomes character, because a matrix has one type
#>   x y
#> 1 A B
```

Accepted: `data.frame`, `tbl_df`, `data.table`, and a matrix with column
names. A matrix without column names is refused, because “you name the
columns, we never guess” is the package’s input contract and an unnamed
matrix has nothing to name.

The conversions report what they cost, which is the point rather than
noise:

``` r

x <- read_name_column(factor(c("SMITH", "JONES")), nm = "last_name")
#> column last_name converted from factor to character (labels, not codes); level order is discarded
x
#> [1] "SMITH" "JONES"
```

``` r

y <- tryCatch(read_name_column(c(1234567890, 1234567891), nm = "npi"),
              warning = function(w) { message("warned: ", conditionMessage(w)); NULL })
#> warned: column npi converted from double to character; a numeric identifier loses leading zeros and can round. Read it as character upstream.
```

That warning is the one worth reading. A numeric identifier loses
leading zeros and can round, and `as.character(1234567890)` on a larger
value yields `"1.23e+09"`, which then matches nothing. Read identifiers
as character upstream; the package warns rather than silently producing
a column that cannot match.

Two more refusals, both deliberate:

``` r

reject_list_columns(data.frame(id = 1, nm = I(list(c("A", "B")))))
#> Error:
#> ! input has list column(s): nm. A list column stringifies silently in a name comparison, so it is refused rather than coerced; unnest or drop it.
```

``` r

check_scalar(c(1, 2), "seed")
#> Error:
#> ! seed must be a single value, not length 2. A multi-valued seed would be silently truncated to its first element.
```

A list column would stringify into a comparison as the literal text
`c("A", "B")` and conflict with every real name. A multi-valued `seed`
or `entity_filter` used to be silently truncated to its first element.

## 3. The result object

[`match_npi()`](https://mufflyt.github.io/mysterynpi/reference/match_npi.md)
returns an `npi_match_result`. **The class is additive**: the same five
elements under the same names as before, so every existing caller keeps
working, and `result$matches` is still a data frame.

What is new is that printing one is readable, and that the summary is a
value rather than text you have to parse:

``` r

res <- match_npi(roster, table = "nppes")

res                      # six lines of summary, not every matched row
nobs(res)                # roster rows submitted
s <- summary(res)
s$statistics             # statistic / value / denominator
s$columns                # class, storage mode and missing count per column
```

[`summary()`](https://rdrr.io/r/base/summary.html) takes `digits`
(default 3) and so do [`print()`](https://rdrr.io/r/base/print.html) and
[`format()`](https://rdrr.io/r/base/format.html), so screen output does
not change with your `options(digits)`. `s$statistics` carries a
`denominator` column, which names what each share was computed over: a
share without its denominator is the kind of number that gets quoted out
of context.

**There is no [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
method, on purpose.** A plot of a three-valued verdict table is a bar
chart of counts that [`summary()`](https://rdrr.io/r/base/summary.html)
already reports more precisely, and the one genuinely visual question
here, which pairs a human should look at, is answered by
[`clerical_sample()`](https://mufflyt.github.io/mysterynpi/reference/clerical_sample.md)
rather than by a chart.

## What to read next

- [`vignette("resolving-a-roster")`](https://mufflyt.github.io/mysterynpi/articles/resolving-a-roster.md)
  for the end-to-end workflow.
- [`vignette("roster-benchmark")`](https://mufflyt.github.io/mysterynpi/articles/roster-benchmark.md)
  for how the decision rules are evaluated.
- [`vignette("comparison-with-alternatives")`](https://mufflyt.github.io/mysterynpi/articles/comparison-with-alternatives.md)
  for the measured comparison against an edit-distance baseline.
- `srr/standards-compliance.md` and `srr/verdict-ledger.csv` for the
  standards assessment and a verdict per individual standard.
