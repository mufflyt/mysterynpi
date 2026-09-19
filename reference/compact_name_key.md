# Letters-only compact key for equality joins

Collapses a name to its A-Z content after \[name_key()\] normalisation:
\`"JONES-COX"\`, \`"JONES COX"\` and \`"JonesCox"\` all become
\`"JONESCOX"\`; \`"O'Brien"\` becomes \`"OBRIEN"\`. This is deliberately
MORE destructive than \[name_key()\]: apostrophes, hyphens and spaces
are exactly the bytes two sources disagree about, so a key that keeps
them fails the join whenever conventions differ. Measured origin: the
isochrones ABMS matcher compared an R side that KEPT punctuation against
a SQL side that spaced it out, so \`"JONES-COX" = "JONES COX"\` could
never be true (2026-09-18 QA).

## Usage

``` r
compact_name_key(x, strip_alternates = TRUE, strip_suffixes = FALSE)
```

## Arguments

- x:

  character vector of names or name fragments.

- strip_alternates:

  see \[name_key()\].

- strip_suffixes:

  logical(1): also strip TRAILING credential and generation tokens
  (\`MD\`, \`M.D.\`, \`DO\`, \`D.O.\`, \`JR\`, \`SR\`, \`II\`, \`III\`,
  \`IV\`, \`PH.D.\`, dotted or bare, iterated) before compacting.
  Default \`FALSE\` - the historical behaviour, and what
  \[blocking_key()\] uses. The flag exists so the R primitive and its
  SQL twin \[sql_name_compact()\] have IDENTICAL contracts in both
  modes: "twins" means the same function on the other execution engine,
  never "the same plus preprocessing a caller must remember". One
  pattern serves both engines (\`.TRAILING_CREDENTIAL_RE\`), and the
  parity tests execute both sides.

## Value

character vector of A-Z-only keys, \`NA\` where no letters survive.

## Details

Use for building candidate sets by equality. Do NOT use as proof of
identity: compaction merges \`"ANN E"\` and \`"ANNE"\`, which is what
the downstream agreement axes (middle initial, suffix, license,
taxonomy) are for.

\`NA\` in, \`NA\` out; a name with no letters is also \`NA\`, never
\`""\`, so absence cannot join to absence.

## See also

Other join-keys:
[`surname_key_variants()`](https://mufflyt.github.io/mysterynpi/reference/surname_key_variants.md)

## Examples

``` r
compact_name_key(c("Jones-Cox", "O'Brien", "van de Ven"))
#> [1] "JONESCOX" "OBRIEN"   "VANDEVEN"
# "JONESCOX" "OBRIEN" "VANDEVEN"
compact_name_key("Smith Jr. MD", strip_suffixes = TRUE)  # "SMITH"
#> [1] "SMITH"
```
