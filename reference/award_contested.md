# Award a contested candidate, or refuse to

A \*\*contested\*\* candidate is one that two or more people each
resolved to independently. It is not a matching error; it is two people
whose evidence points at the same record, and the count is a
data-quality signal in itself.

## Usage

``` r
award_contested(
  contested,
  policy = "strict_dominance",
  id = "id",
  candidate = "candidate",
  key = "rank"
)
```

## Arguments

- contested:

  data.frame of claimants on contested candidates.

- policy:

  "strict_dominance", "quarantine_all", or "greedy".

- id, candidate:

  column names.

- key:

  character: ranking columns in precedence order. Ties on ALL of them
  are what "not separable" means. Numeric columns are compared
  ascending; wrap in \`-x\` upstream if larger is better.

## Value

the rows to add back; zero rows if none qualify.

## Details

Three policies, and the difference between them is not a matter of
taste. Measured on one real cohort with 93 contested candidates:

|                      |           |                                  |
|----------------------|-----------|----------------------------------|
| policy               | recovered | identities decided by SORT ORDER |
| \`quarantine_all\`   | 0         | 0                                |
| \`strict_dominance\` | 56        | 0                                |
| \`greedy\`           | 93        | \*\*37\*\*                       |

The 37 tie on every ranking key – 10 of them at the strongest class,
meaning two people whose full names AND middle names both match one
record. Handing that to whoever sorts first is not a linkage result.
\`strict_dominance\` takes every record the evidence justifies and none
that it does not.

\`greedy\` exists because reproducing a cohort frozen before this
distinction was drawn requires it, and a published number nobody can
regenerate is worse than one whose weakness is written down. It is not
the default.
