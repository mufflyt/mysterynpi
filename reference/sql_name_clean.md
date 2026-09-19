# SQL: normalise a name column for matching (UDF-free, DuckDB/RE2)

Upper-cases and trims, strips TRAILING credential and generation
suffixes (\`MD\`, \`M.D.\`, \`DO\`, \`D.O.\`, \`JR\`, \`SR\`, \`II\`,
\`III\`, \`IV\`, \`PH.D.\`, iterated so \`"SMITH JR MD"\` fully
unwinds), then replaces every remaining non-letter with a space and
trims again.

## Usage

``` r
sql_name_clean(col)
```

## Arguments

- col:

  character(1): a SQL column expression.

## Value

character(1) SQL expression.

## See also

Other sql-join-keys:
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md)
