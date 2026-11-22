# Read one column as character, announcing any loss

The explicit conversion srr G2.4c asks for, with the diagnostic G2.9
asks for. A factor becomes its labels (never its integer codes, which is
the classic silent corruption); a numeric identifier becomes character
with a warning, because \`1e+05\` is not the identifier \`100000\`; a
column with a non-standard class (\`units\`, \`difftime\`, \`POSIXct\`)
is stripped to its underlying vector and said so (srr G2.4, G2.9,
G2.11).

## Usage

``` r
read_name_column(x, nm = "column", quiet = FALSE)
```

## Arguments

- x:

  a column from a tabular input.

- nm:

  \[character(1)\] the column name, for messages.

- quiet:

  \[logical(1)\] suppress messages.

## Value

\[character\] the column as character.

## Examples

``` r
read_name_column(factor(c("SMITH", "JONES")), "surname")
#> column surname converted from factor to character (labels, not codes); level order is discarded
#> [1] "SMITH" "JONES"
read_name_column(c(1001, 1002), "npi")
#> Warning: column npi converted from double to character; a numeric identifier loses leading zeros and can round. Read it as character upstream.
#> [1] "1001" "1002"
```
