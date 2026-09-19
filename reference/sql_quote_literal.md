# SQL: a character value as a DuckDB SQL string literal

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

SCOPE: this is a DuckDB SQL literal builder for GENERATED SQL text -
deterministic correctness where the query has to be assembled as a
string. It is not a database-independent quoting or sanitization
abstraction; other engines have other literal rules. Where the caller
holds a live connection, prefer DBI parameter binding (\`DBI::dbBind()\`
/ parameterised \`dbGetQuery()\`) over pasting literals at all.

Vectorised: a character vector in, one literal per element out.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
[`sql_strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/sql_strip_parenthetical.md)
