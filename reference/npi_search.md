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
  limit = 10L
)
```

## Arguments

- first_name, last_name, state, postal_code, npi:

  search criteria; any may be omitted, but the API requires something.
  NPPES treats \`first_name\` and \`last_name\` as case-insensitive and
  supports a trailing \`\*\` wildcard on names of two or more
  characters.

- limit:

  maximum results, 1 to 200.

## Value

see \[parse_npi_search()\].

## Details

This function performs a NETWORK call to the public NPPES API
(\`npiregistry.cms.hhs.gov\`) and belongs in interactive exploration and
pipeline candidate generation – never inside a test suite, which is why
the parser is a separate, fixture-testable function.
