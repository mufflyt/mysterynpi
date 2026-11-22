# Resolve and apply a missing-data policy

Validates an \`na_action\` argument and acts on the missingness it is
given. Called at the top of every agreement rule, before any comparison,
so that \`"error"\` fails before work is done and \`"warn"\` reports
once per call rather than once per row.

## Usage

``` r
resolve_na_action(na_action = NA_ACTIONS, n_missing = 0L, what = "value")
```

## Arguments

- na_action:

  \[character(1)\] one of \[NA_ACTIONS\]. Matched with \[match.arg()\],
  so partial matching works and an unknown value is an error naming the
  permitted set (srr G2.3a).

- n_missing:

  \[integer(1)\] how many missing values the caller found.

- what:

  \[character(1)\] what was missing, for the message.

## Value

\[character(1)\] the resolved action, invisibly for \`"uninformative"\`.

## Examples

``` r
resolve_na_action("uninformative", 0L, "middle name")
#> [1] "uninformative"
resolve_na_action("warn", 0L, "middle name")   # silent: nothing was missing
#> [1] "warn"
```
