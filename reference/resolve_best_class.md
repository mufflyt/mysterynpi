# Resolve people whose strongest class holds exactly one candidate

TAXONOMY – OR ANY OTHER FACET – MAY NOT BREAK THE TIE. Several
candidates at the strongest class means they are indistinguishable on
the evidence held. A facet like taxonomy says what a candidate record is
\*for\*, not \*which person\* the name refers to. Letting it decide is
how a resolver becomes a plausible-match machine.

## Usage

``` r
resolve_best_class(
  per_candidate,
  stats,
  id = "id",
  class = "evidence_class",
  confidence = NULL
)
```

## Arguments

- per_candidate, stats:

  outputs of \[collapse_candidates()\], \[pool_stats()\].

- id, class:

  column names.

- confidence:

  optional numeric vector indexed by class, attached as \`confidence\`.
  Reporting only; nothing here ranks on it.

## Value

the resolved rows, one per id.
