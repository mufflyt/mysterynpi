# Replace undefined numbers with NA

The conversion step that lets a numeric agreement rule treat \`NaN\` and
infinities as "no information" rather than as years: they become \`NA\`,
and the missing-data policy then applies to them like any other absence.

## Usage

``` r
finite_or_na(x)
```

## Arguments

- x:

  \[numeric\] input.

## Value

\[numeric\] with \`NaN\`, \`Inf\` and \`-Inf\` replaced by
\`NA_real\_\`.

## Examples

``` r
finite_or_na(c(2015, NaN, Inf))
#> [1] 2015   NA   NA
```
