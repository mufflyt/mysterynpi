# SQL: letters-only compact join key (DuckDB/RE2)

The database-side twin of \[compact_name_key()\], UNCONDITIONALLY: same
preprocessing, same supported domain, same output, in BOTH modes -
\`strip_suffixes\` mirrors the R primitive's own argument, so "twin"
never means "the same plus preprocessing a caller must remember". (Until
2026-09-19 this builder silently included the trailing credential strip
the R primitive does not perform, and the parity test had to restrict
itself to a suffix-free domain - evidence of two contracts wearing one
name; retired by owner review.)

## Usage

``` r
sql_name_compact(col, strip_suffixes = FALSE)
```

## Arguments

- col:

  character(1): a SQL column expression.

- strip_suffixes:

  logical(1), default \`FALSE\`: mirror of \[compact_name_key()\]'s
  \`strip_suffixes\` - when \`TRUE\`, trailing credential/generation
  tokens strip first, via the SAME shared pattern
  (\`.TRAILING_CREDENTIAL_RE\`) the R side applies.

## Value

character(1) SQL expression.

## Details

\`"JONES-COX"\`, \`"JONES COX"\` and \`"JONESCOX"\` all reduce to
\`"JONESCOX"\`; \`"Muñoz"\` and \`"Munoz"\` to \`"MUNOZ"\`; \`"Müller"\`
and \`"Mueller"\` to \`"MUELLER"\`; \`"C(arolyn)"\` unwraps to
\`"CAROLYN"\`. An input with no letters is \`NULL\`, never \`”\` -
\[compact_name_key()\] returns \`NA\` there for the same reason: absence
must not join to absence.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md),
[`sql_strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/sql_strip_parenthetical.md)
