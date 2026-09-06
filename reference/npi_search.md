# Search the NPPES registry for providers

A thin fetch over \[parse_npi_search()\], which documents every column
and every deliberate absence (no birth year – NPPES does not publish
one; \`years_enumerated\` is a lower bound on years in practice,
truncated at the 2005 start of enumeration).

## Usage

``` r
npi_search(
  first_name = NULL,
  last_name = NULL,
  state = NULL,
  postal_code = NULL,
  npi = NULL,
  limit = 10L,
  licenses = FALSE,
  expand_nicknames = FALSE
)
```

## Arguments

- first_name, last_name, state, postal_code, npi:

  search criteria; any may be omitted, but the API requires something.
  NPPES treats \`first_name\` and \`last_name\` as case-insensitive and
  supports a trailing \`\*\` wildcard on names of two or more
  characters.

- limit:

  maximum results, 1 to 200. NPPES ALIAS MATCHING IS ALWAYS OFF. The API
  silently expands first names against an internal alias list by default
  – measured live: searching \`bill\` returned five providers all
  legally named WILLIAM. Every query this function sends carries
  \`use_first_name_alias=False\`, and nickname recall is recovered in
  daylight instead: with \`expand_nicknames = TRUE\`, the first name
  fans out over its \[nickname_variants()\] (one fetch per variant), and
  each returned row carries \`queried_as\` – which spelling found it.
  Every expansion is a reviewable corpus edge, not a registry black box.

- licenses:

  when \`TRUE\`, one fetch returns BOTH frames as \`list(providers,
  licenses)\` – the licenses via \[parse_npi_licenses()\], ready for
  \[license_agreement()\]. Default \`FALSE\` keeps the plain provider
  frame.

- expand_nicknames:

  fan the first name out over its one-hop \[nickname_variants()\];
  results are deduplicated by NPI with a \`queried_as\` provenance
  column.

## Value

see \[parse_npi_search()\]; with \`licenses = TRUE\`, a list of two
data.frames, \`providers\` and \`licenses\`.

## Details

This function performs a NETWORK call to the public NPPES API
(\`npiregistry.cms.hhs.gov\`) and belongs in interactive exploration and
pipeline candidate generation – never inside a test suite, which is why
the parser is a separate, fixture-testable function.
