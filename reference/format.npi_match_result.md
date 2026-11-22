# Format a match result for printing

The formatted lines \`print()\` emits. Numbers are formatted here, at a
stated precision, rather than left to default numeric printing (srr
EA5.2, EA4.1).

## Usage

``` r
# S3 method for class 'npi_match_result'
format(x, digits = 3L, ...)
```

## Arguments

- x:

  an \`npi_match_result\`.

- digits:

  \[integer(1)\] precision for proportions.

- ...:

  ignored.

## Value

\[character\] one element per line.
