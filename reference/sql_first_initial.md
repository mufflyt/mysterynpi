# SQL: first initial of a name column (UDF-free, DuckDB/RE2)

The database-side twin of \[extract_first_initial()\]: strips
non-letters BEFORE taking the character, so \`"(Sandra) Theresa"\`
yields \`'S'\` and a punctuation-only or empty value yields \`NULL\` –
never \`”\`, never a punctuation byte. The 2026-09-19 isochrones survey
found candidate queries hand-rolling \`SUBSTR(UPPER(TRIM(col)), 1, 1)\`,
which hands back \`'('\` or \`'-'\` for exactly the inputs above and
then blocks that person against nobody.

## Usage

``` r
sql_first_initial(col)
```

## Arguments

- col:

  character(1): a SQL column expression.

## Value

character(1) SQL expression yielding a single upper-case letter,
\`NULL\` where no ASCII letter is present.

## Details

PARITY DOMAIN IS ASCII, same as \[sql_name_compact()\]: UDF-free SQL
cannot transliterate, so an accented FIRST letter diverges from the R
side (\`"Émile"\`: R gives \`"E"\` via \[normalize_string()\]'s
transliteration; this expression strips the non-ASCII letter and yields
\`'M'\` from \`"MILE"\`). The parity test pins agreement on ASCII AND
pins that divergence explicitly, so it is a documented boundary, not a
surprise. For accented columns use the \[sql_npi_name()\] UDF path.

## See also

Other sql-join-keys:
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md)
