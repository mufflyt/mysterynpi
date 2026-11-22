# Count the missing values in a character or list input

One definition of "missing" for the agreement rules, so that the policy
is applied to the same thing everywhere. A character value is missing
when it is \`NA\` or empty after trimming – which is what
\[has_name_information()\] decides, reused here rather than re-derived.
A token list element is missing when it holds no tokens.

## Usage

``` r
count_missing_values(x)
```

## Arguments

- x:

  \[character\] or \[list\] as passed to an agreement rule.

## Value

\[integer(1)\] the number of missing elements.

## Examples

``` r
count_missing_values(c("SMITH", NA, ""))
#> [1] 2
count_missing_values(list(c("A"), character(0)))
#> [1] 1
```
