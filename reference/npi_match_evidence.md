# Build canonical evidence fields for post-match grading

Compares one roster/candidate pair per row using the package's canonical
rules rather than ad-hoc equality: \[surname_agreement()\] for surnames,
\[given_name_agreement()\] for given names (including its named
\`initial\` rule), and punctuation-insensitive exact phrase keys for
state and city. Missing values are \`uninformative\`, never positive or
negative evidence.

## Usage

``` r
npi_match_evidence(
  roster_given,
  roster_surname,
  candidate_given,
  candidate_surname,
  roster_state = NULL,
  candidate_state = NULL,
  roster_city = NULL,
  candidate_city = NULL
)
```

## Arguments

- roster_given, roster_surname:

  Character vectors of source names.

- candidate_given, candidate_surname:

  Character vectors of candidate names, the same length as the roster
  vectors.

- roster_state, candidate_state, roster_city, candidate_city:

  Optional character vectors of place fields, the same length as the
  name vectors.

## Value

A data frame with surname and given verdicts/reasons plus state and city
verdicts.

## Examples

``` r
npi_match_evidence("John", "Smith", "J", "Smith",
                   roster_state = "CO", candidate_state = "CO")
#>   surname_verdict surname_reason given_verdict given_reason state_verdict
#> 1    corroborates          exact  corroborates      initial  corroborates
#>    city_verdict
#> 1 uninformative
```
