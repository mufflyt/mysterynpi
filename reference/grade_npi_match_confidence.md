# Grade the confidence of an accepted NPI candidate

Grades evidence after the resolver has chosen a candidate; it does not
decide whether the candidate is acceptable. \`high\` requires the
strongest query tier, corroborating state, corroborating surname, and
exact or recorded-initial given-name agreement. \`medium\` requires
exact given-name agreement or corroborating geography. A candidate
without a corroborating surname is \`unmatched\`; tied or contested
candidates are \`ambiguous\` when the caller marks them so (for example,
from \`match_npi()\`'s review reason).

## Usage

``` r
grade_npi_match_confidence(
  evidence,
  query_tier = NA_integer_,
  ambiguous = FALSE,
  matched = TRUE
)
```

## Arguments

- evidence:

  Data frame from \[npi_match_evidence()\].

- query_tier:

  Integer or numeric vector describing the query tier that produced the
  candidate (\`1\` strongest). \`NA\` means no tiered query.

- ambiguous:

  Logical vector: \`TRUE\` when candidate selection ended in a tie or
  otherwise ambiguous disposition.

- matched:

  Logical vector: \`FALSE\` when no candidate was accepted.

## Value

Character vector of labels from \[NPI_MATCH_CONFIDENCE_LEVELS\].

## Details

Given-name handling is canonical: a bare recorded initial corroborates
with reason \`initial\`; two different full names that merely share a
first letter conflict and do not receive initial credit.

## Examples

``` r
ev <- npi_match_evidence("John", "Smith", "John", "Smith",
                         roster_state = "CO", candidate_state = "CO")
grade_npi_match_confidence(ev, query_tier = 1)
#> [1] "high"
```
