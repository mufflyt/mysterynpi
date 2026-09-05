# Collapse candidates to one row per (id, candidate), keeping the strongest class

DETERMINISTIC TIEBREAK. Picking with \`which.min()\` returns the FIRST
minimum, so when one person has two rows for the same candidate tied at
the same class, the retained row depends on input order. A permutation
suite measured this: the recorded name variant changed in \*\*231 of 300
orderings\*\* while the accepted identity never moved once. Identity was
never at risk, but the recorded variant is what a human reads when
judging whether a weak match is real, and two reviewers running on
different days must not see different evidence for the same person.
Sorting first makes the retained row a property of the data rather than
of row order.

## Usage

``` r
collapse_candidates(
  candidates,
  id = "id",
  candidate = "candidate",
  class = "evidence_class",
  tiebreak = character(0)
)
```

## Arguments

- candidates:

  data.frame of candidate pairs.

- id, candidate, class:

  column names.

- tiebreak:

  character: additional columns, in order, that make the retained
  representative deterministic. Strongly recommended.

## Value

one row per (id, candidate), carrying the minimum class.
