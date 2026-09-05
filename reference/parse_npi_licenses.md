# The licenses inside an NPPES response, one row per (NPI, license)

NPPES's \`taxonomies\` array carries STATE LICENSE NUMBERS with their
issuing states – after the NPI itself the strongest deterministic key a
candidate pair can share, and exactly the input \[license_agreement()\]
wants. This is the long companion to \[parse_npi_search()\]: same JSON
text in, one row per recorded (NPI, license) out, taxonomy entries
without a usable license dropped (a taxonomy code alone says what a
record is for, not which licenses its person holds).

## Usage

``` r
parse_npi_licenses(txt)
```

## Arguments

- txt:

  character: the JSON text of an NPPES API v2.1 response.

## Value

data.frame: \`npi\`, \`state\`, \`license\`, \`taxonomy_code\`,
\`taxonomy_desc\`, \`primary\`; zero rows when no result carries one.
NPPES's absence sentinels (missing, empty, \`"–"\`) are dropped rows
here, never \`NA\` rows – a licenseless taxonomy is not a license.

## Details

THE INTENDED USE closes the search-to-agreement loop: a roster license
is compared against EVERY row its candidate NPI carries here, and the
best verdict stands – one \`"corroborates"\` outweighs any number of
\`"uninformative"\`, which is \[license_agreement()\]'s design (a
quarter of NPIs carry more than one license; disagreement between two of
them is two glimpses of one career).


      lic <- parse_npi_licenses(txt)
      v <- license_agreement(rep(roster_num, nrow(lic)),
                             rep(roster_state, nrow(lic)),
                             lic$license, lic$state)
      any(v == "corroborates")
