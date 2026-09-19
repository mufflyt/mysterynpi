# SQL: letters-only compact join key (UDF-free, DuckDB/RE2)

\[sql_name_clean()\] with every non-letter removed instead of spaced:
the database-side twin of \[compact_name_key()\]. \`"JONES-COX"\`,
\`"JONES COX"\` and \`"JONESCOX"\` all reduce to \`"JONESCOX"\`; \`"VAN
HOUTEN"\` and \`"VANHOUTEN"\` both reduce to \`"VANHOUTEN"\`.

## Usage

``` r
sql_name_compact(col)
```

## Arguments

- col:

  character(1): a SQL column expression.

## Value

character(1) SQL expression.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md)
