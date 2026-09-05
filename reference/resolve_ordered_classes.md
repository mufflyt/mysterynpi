# Ordered-class resolution end to end

Ordered-class resolution end to end

## Usage

``` r
resolve_ordered_classes(
  candidates,
  id = "id",
  candidate = "candidate",
  class = "evidence_class",
  tiebreak = character(0),
  facet = NULL,
  confidence = NULL
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

- facet, confidence:

  see \[pool_stats()\], \[resolve_best_class()\].

## Value

list(per_candidate, stats, resolved, quarantined).
