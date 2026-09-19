# SQL: normalise a name column for matching (DuckDB/RE2)

Transliterates on the shared base every SQL twin uses (NFC, German
digraphs and Latin special letters mapped as \[normalize_string()\] maps
them, then \`strip_accents(UPPER(TRIM(...)))\` - see the parity contract
note on \[sql_npi_name()\]), strips parenthesised alternate names (the
same \`strip_alternates\` behaviour \[name_key()\] applies, so \`"SMITH
(JONES)"\` cleans to \`"SMITH"\`, never \`"SMITH JONES"\`), strips
TRAILING credential and generation suffixes (\`MD\`, \`M.D.\`, \`DO\`,
\`D.O.\`, \`JR\`, \`SR\`, \`II\`, \`III\`, \`IV\`, \`PH.D.\`, iterated
so \`"SMITH JR MD"\` fully unwinds), then replaces every remaining
non-letter with a space and trims again.

## Usage

``` r
sql_name_clean(col)
```

## Arguments

- col:

  character(1): a SQL column expression.

## Value

character(1) SQL expression.

## Details

\`strip_accents()\` and \`nfc_normalize()\` are DuckDB built-ins; no
user-registered UDF is needed on a bare DuckDB connection.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md),
[`sql_strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/sql_strip_parenthetical.md)
