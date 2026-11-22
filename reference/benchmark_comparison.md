# Evaluate the agreement rules against the shipped benchmark

Runs the benchmark evaluation and returns the confusion table beside the
three properties the vignette claims for it, each with an explicit pass
column: every accept is a true match, every reject a true nonmatch, and
every reviewed pair is a true match (the stale-gender family routed to a
person rather than deleted).

## Usage

``` r
benchmark_comparison(data = mysterynpi::ROSTER_BENCHMARK, digits = 3L)
```

## Arguments

- data:

  \[data.frame\] shaped like \[ROSTER_BENCHMARK\], with a \`truth\`
  column of \`"match"\` / \`"nonmatch"\`.

- digits:

  \[integer(1)\] precision for the reported rates (srr EA4.1).

## Value

a list with \`table\` (decision by truth), \`properties\` (one row per
claimed property, with \`pass\`), and \`rates\` (accept/review/reject
shares and precision among accepts). Attribute \`"all_pass"\` is
\`TRUE\` when every property holds.

## See also

\`vignette("roster-benchmark", package = "mysterynpi")\` for the
construction of the corpus and the caveats on what it can show.

## Examples

``` r
b <- benchmark_comparison()
b$properties
#>                              property violations pass
#> 1        every accept is a true match          0 TRUE
#> 2     every reject is a true nonmatch          0 TRUE
#> 3 every reviewed pair is a true match          0 TRUE
```
