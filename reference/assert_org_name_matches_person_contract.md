# Assert that the person/organization name bridge still behaves as relied on.

Pins the professional-corporation pattern (all 14 name "mismatches" in
the 2026-09-13 Medicaid exclusion linkage were this, not wrong people),
the corporate-form/credential noise floor, hyphen folding, and the
DO-surname collision fix – a practice literally named after the
physician's own surname, where that surname collides with a NAME_NOISE
credential token (the Vietnamese surname "Do" vs. the DO credential),
used to lose its only shared identity token and report no match.

## Usage

``` r
assert_org_name_matches_person_contract(fn = org_name_matches_person)
```

## Arguments

- fn:

  the function to test; defaults to \[org_name_matches_person()\].

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
