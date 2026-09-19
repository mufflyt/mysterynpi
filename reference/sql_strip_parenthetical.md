# SQL: strip parenthesised alternate names (DuckDB/RE2)

The database-side twin of \[strip_parenthetical()\], transformation for
transformation, in the same order - because the R rule is NOT "delete
everything in brackets". Two conventions appear in rosters and they mean
OPPOSITE things, and a single delete-the-group regex collapses them:

## Usage

``` r
sql_strip_parenthetical(col)
```

## Arguments

- col:

  character(1): a SQL column expression.

## Value

character(1) SQL expression.

## Details


      "Cynthia (Cindi) A."   separate token  -> an alternate name, DROPPED
      "C(arolyn) Diane"      inside a token  -> optional letters, UNWRAPPED
                                                ("CAROLYN DIANE", never "C DIANE")

The four ordered rules, each mirrored one-for-one from the R body:
word-internal groups unwrap (backreferences \`\1\2\` - executed against
DuckDB to confirm RE2's replacement syntax); standalone groups become a
space; an UNCLOSED group runs to end-of-string and becomes a space; any
residual stray bracket becomes a space. Every branch carries an executed
parity fixture in \`test-sql-r-parity-contract.R\`, derived by calling
the real R primitive.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md)
