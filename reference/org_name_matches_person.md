# Does an organization name carry a person's identity?

Provider data constantly crosses the person/organization NPI boundary: a
sanctioned physician's identifier resolves to their own professional
corporation ("Nadine H. Yassa" against "NADINE H. YASSA, M.D., INC."),
or to the practice they run ("Francis Peter Lagattuta" against "LAGS
SPINE & SPORTSCARE MEDICAL CENTERS INC"). A person-name comparison sees
only a mismatch there. Measured in the 2026-09-13 Medicaid exclusion
linkage, all 14 of the name "mismatches" among NPPES-corroborated NPIs
were this pattern, not wrong people.

## Usage

``` r
org_name_matches_person(org, person)
```

## Arguments

- org:

  character vector of organization names.

- person:

  character vector of person names, the same length.

## Value

logical vector: \`TRUE\` when an identity token is shared, \`FALSE\`
when both sides carry identity tokens and share none, \`NA\` when either
side has no identity tokens left after noise removal (nothing to
compare).

## Details

The rule: after \[name_key()\] normalisation, drop corporate-form tokens
(\[ORG_NOISE\]) and credentials (\[NAME_NOISE\]) from both sides; the
names match when any identity token remains shared. Hyphens are folded
so "ABBAS-RODRIGUEZ MEDICAL GROUP" meets "Abbas Rodriguez" – this is a
surname-style comparison, where folding is the documented correct
setting.

A shared identity token is DELIBERATELY weak evidence – "SMITH" ties
"John Smith" to "SMITH MEDICAL GROUP" – so treat a \`TRUE\` as
corroboration to weigh, never as an identity match on its own; pair it
with an identifier the way \[npi_corroborate()\] does.
