# Number of roster rows a match result was built from

The \`nobs()\` method srr RE4.5 asks for: how many rows were submitted,
which is the denominator of every rate in \[summary.npi_match_result()\]
and is otherwise reachable only by knowing that \`counts\$roster_rows\`
is where it lives.

## Usage

``` r
# S3 method for class 'npi_match_result'
nobs(object, ...)
```

## Arguments

- object:

  an \`npi_match_result\`.

- ...:

  ignored.

## Value

\[integer(1)\] roster rows submitted.
