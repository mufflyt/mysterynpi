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
  name_expansion = c("none", "curated_one_hop"),
  max_expansion = 25L
)
```

## Arguments

- first_name, last_name, state, postal_code, npi:

  search criteria; any may be omitted, but the API requires something.
  NPPES treats \`first_name\` and \`last_name\` as case-insensitive and
  supports a trailing \`\*\` wildcard on names of two or more
  characters.

- limit:

  maximum results per query, 1 to 200.

- licenses:

  when \`TRUE\`, the same fetches also return the license frame as
  \`list(providers, licenses)\` – the licenses via
  \[parse_npi_licenses()\], ready for \[license_agreement()\]. Default
  \`FALSE\` keeps the plain provider frame.

- name_expansion:

  \`"none"\` (default: query exactly the name given) or
  \`"curated_one_hop"\` (execute the \[nickname_variants()\] plan).
  Anything else is an error – deliberately an enum, not a Boolean, so a
  third behavior can never sneak in as a truthy value.

- max_expansion:

  passed to \[nickname_variants()\]; the hard ceiling on fan-out.

## Value

see \[parse_npi_search()\], plus the four provenance columns; results
are deduplicated by NPI (the plan's order – input first, then sorted –
makes the retained provenance deterministic). With \`licenses = TRUE\`,
a list of two data.frames, \`providers\` and \`licenses\`.

## Details

This function performs a NETWORK call to the public NPPES API
(\`npiregistry.cms.hhs.gov\`) and belongs in interactive exploration and
pipeline candidate generation – never inside a test suite, which is why
the parser is a separate, fixture-testable function.

NPPES ALIAS MATCHING IS ALWAYS OFF. The API silently expands first names
against an internal alias list by default – measured live: searching
\`bill\` returned five providers all legally named WILLIAM. Every query
this function sends carries \`use_first_name_alias=False\`; there is no
argument to turn that back on. Nickname recall is recovered in daylight
instead, through exactly one route: \`name_expansion =
"curated_one_hop"\` executes the \[nickname_variants()\] plan (one fetch
per plan row), and every returned row carries the plan's provenance.

PROVENANCE COLUMNS, always present on the provider frame:
\`input_first_name\` (the name you asked for), \`queried_first_name\`
(the spelling that found this row), \`alias_edge_id\` (the
\[NICKNAME_EDGES\] row that licensed the fan-out, \`NA\` when the row
came from the input name itself), and \`alias_dictionary_version\`. All
\`NA\` when no first name was given.
