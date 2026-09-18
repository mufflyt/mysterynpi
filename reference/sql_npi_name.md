# SQL expression normalising a name column the same way R does

The join key must be built identically on both sides or the database
half of a pipeline quietly disagrees with the R half about who matched
whom. Requires a \`strip_accents\` UDF registered on the connection
(DuckDB ships one built in).

## Usage

``` r
sql_npi_name(col)
```

## Arguments

- col:

  character(1): a column expression.

## Value

character(1) SQL.

## Details

GERMAN DIGRAPHS, BEFORE \`strip_accents()\`, FOR THE SAME REASON
\[normalize_string()\] ORDERS ITS OWN SUBSTITUTION FIRST.
\`strip_accents()\` only knows how to drop a diacritic: \`"Müller"\`
becomes \`"MULLER"\`, losing the letter the umlaut stood in for. German
romanises umlauts as a digraph, not a bare vowel – \`"Müller"\` is
\`"MUELLER"\` – and once \`strip_accents()\` has already dropped the
dots there is no way to recover that. So the digraph substitution runs
on the RAW column expression, before
\`TRIM\`/\`UPPER\`/\`strip_accents()\` ever see it, mirroring
\[normalize_string()\]'s own ordering exactly. Confirmed against a live
DuckDB connection: pre-fix, \`sql_npi_name()\` emitted \`"MULLER"\` /
\`"SCHON"\` for \`"Müller"\` / \`"Schön"\` while \`normalize_string()\`
gave \`"MUELLER"\` / \`"SCHOEN"\` – the exact silent R/SQL parity break
this function exists to prevent, caught by the isochrones downstream
parity test this function's contract is written for.
