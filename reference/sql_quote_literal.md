# SQL: a character value as a SQL string literal

Doubles embedded single quotes and wraps in quotes; \`NA\` becomes the
SQL keyword \`NULL\`. The defect class is a CORRECTNESS one measured in
this data, not a security posture: physician rosters are full of
\`O'Brien\` and \`D'Angelo\`, and an extractor that pastes a name into
SQL with \`sprintf("... = ' patched with a one-off \`gsub\` that the
next call site forgets. One governed literal-builder, tested by
ROUND-TRIP (the value comes back out of a real DuckDB byte-identical),
replaces the per-site patches.

## Usage

``` r
sql_quote_literal(x)
```

## Arguments

- x:

  character vector of values (NOT column expressions).

## Value

character vector of SQL literals; \`"NULL"\` where \`x\` is \`NA\`.

## Details

Vectorised: a character vector in, one literal per element out.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md)
