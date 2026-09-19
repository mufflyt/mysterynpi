# SQL: first initial of a name column (DuckDB/RE2)

The database-side twin of \[extract_first_initial()\], built on the same
transliterating base as every other SQL twin: normalizes exactly as
\[normalize_string()\] does (NFC, German digraphs, Latin special
letters, accent strip), strips non-letters BEFORE taking the character,
so \`"(Sandra) Theresa"\` yields \`'S'\`, \`"Émile"\` yields \`'E'\`
(the same initial the R side produces - a blocking primitive whose two
sides disagree puts the same person in two different blocks), and a
punctuation-only or empty value yields \`NULL\` – never \`”\`, never a
punctuation byte. The 2026-09-19 isochrones survey found candidate
queries hand-rolling \`SUBSTR(UPPER(TRIM(col)), 1, 1)\`, which hands
back \`'('\` or \`'-'\` for exactly the inputs above and then blocks
that person against nobody.

## Usage

``` r
sql_first_initial(col)
```

## Arguments

- col:

  character(1): a SQL column expression.

## Value

character(1) SQL expression yielding a single upper-case letter,
\`NULL\` where no letter survives normalization.

## Details

Parity with \[extract_first_initial()\] is proven BY EXECUTION on a
Unicode corpus (acute accents, umlauts, tilde, cedilla, Latin special
letters, decomposed combining marks, punctuation-led and parenthesised
names) in \`test-sql-r-parity-contract.R\`.

## See also

Other sql-join-keys:
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md),
[`sql_strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/sql_strip_parenthetical.md)
