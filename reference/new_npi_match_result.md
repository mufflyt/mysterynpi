# Give a match result its class

Wraps the list \[match_npi()\] builds so it can be printed, formatted
and summarised. Called by \`match_npi()\`; exported so a caller
assembling a result from parts can label it the same way.

## Usage

``` r
new_npi_match_result(x)
```

## Arguments

- x:

  \[list\] with elements \`matches\`, \`review\`, \`unmatched\`,
  \`counts\` and \`run_manifest\`.

## Value

\`x\` with class \`"npi_match_result"\`.
