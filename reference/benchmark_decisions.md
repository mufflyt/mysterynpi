# The accept / review / reject decision for benchmark pairs

The decision rule the benchmark vignette argues for: any conflicting
axis rejects (middle-name conflicts excepted when excused), a pair
without both surname and given corroboration goes to review, a gender
conflict goes to review rather than to deletion, and everything else is
accepted.

## Usage

``` r
benchmark_decisions(data = mysterynpi::ROSTER_BENCHMARK, axes = NULL)
```

## Arguments

- data:

  \[data.frame\] shaped like \[ROSTER_BENCHMARK\].

- axes:

  \[data.frame\] from \[benchmark_axes()\]; computed if not supplied.

## Value

\[character\] \`"accept"\`, \`"review"\` or \`"reject"\` per row.

## Examples

``` r
table(benchmark_decisions(ROSTER_BENCHMARK))
#> 
#> accept reject review 
#>    126     58      6 
```
