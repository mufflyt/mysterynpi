# Attributes match_npi() can block or corroborate on

Beyond names, \`match_npi()\` can weigh six optional attributes, each
judged by the package's canonical rule for that field and each reported
in the shared three-verdict vocabulary (\`corroborates\`, \`conflicts\`,
\`uninformative\`). Absence on either side is always uninformative.

## Usage

``` r
MATCH_NPI_ATTRIBUTES
```

## Format

A character vector of the six attribute names.

## Details

- gender:

  \[gender_agreement()\].

- credential:

  \[normalize_credential()\] on both sides; any shared degree
  corroborates, disjoint non-blank degrees (MD against DO) conflict.

- taxonomy:

  \[taxonomy_consistent()\]: the roster value is one or more
  \`\|\`-separated code prefixes, the reference value one or more codes.

- license:

  \[license_agreement()\], which needs the issuing state on both sides
  and can only corroborate, never conflict.

- graduation_year:

  \[graduation_year_agreement()\]: the roster holds the graduation year,
  the reference a credentialing or enumeration year (a date's leading
  four digits are used). Beyond ten years conflicts; that rule's
  documentation asks for the conflict to be a flag, so leave it out of
  \`block\`.

- state:

  Two-letter codes compared after trimming and upper-casing.

A conflicting attribute vetoes a candidate (it goes to \`review\` with
reason \`\<attribute\>\_conflict\`) unless the attribute is named in
\`block\`, in which case the candidate is removed before evidence and
counted in \`counts\$blocked_by_attribute\`. Corroborating attributes
are counted into \`attribute_rank\`, the tie-break applied after
evidence class and middle corroboration inside \[resolve_one_to_one()\].
