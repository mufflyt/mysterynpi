# Is this value undefined rather than merely missing?

\`NaN\`, \`Inf\` and \`-Inf\` are not missing values: they are the
result of an arithmetic that went wrong upstream, and a year of \`Inf\`
is a different problem from a year nobody recorded. The agreement rules
that take numbers separate the two so a caller can refuse one and
tolerate the other (srr G2.16).

## Usage

``` r
is_undefined_number(x)
```

## Arguments

- x:

  \[numeric\] or anything coercible with \[as.numeric()\]. Non-numeric
  input is never undefined, so character and factor input returns
  \`FALSE\`.

## Value

\[logical\] the same length as \`x\`.

## Examples

``` r
is_undefined_number(c(2015, NA, NaN, Inf, -Inf))
#> [1] FALSE FALSE  TRUE  TRUE  TRUE
```
