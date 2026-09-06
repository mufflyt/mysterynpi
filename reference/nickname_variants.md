# One-hop name variants, for auditable search expansion

The set a nickname-aware search should fan out over: the name itself,
every recorded nickname of it, and every formal name it is recorded as a
nickname of – one hop over \[NICKNAME_EDGES\], both directions, never
transitive closure. \`nickname_variants("BILL")\` includes \`WILLIAM\`;
\`nickname_variants("ALBERT")\` includes \`AL\` but never \`ALEXANDER\`.

## Usage

``` r
nickname_variants(x, edges = mysterynpi::NICKNAME_EDGES)
```

## Arguments

- x:

  a single name token.

- edges:

  the corpus; defaults to \[NICKNAME_EDGES\].

## Value

character vector of variants, the (normalised) input first, the rest
sorted – a stable, auditable query plan.

## Details

This exists because NPPES's API does its own first-name alias expansion
BY DEFAULT, against a list nobody outside CMS can read, cite or test –
searching \`bill\` returns providers legally named WILLIAM with nothing
in the response saying why. \[npi_search()\] turns that off
unconditionally and offers this corpus as the daylight replacement:
every expansion is a reviewable edge in a pinned, weld-audited table.
