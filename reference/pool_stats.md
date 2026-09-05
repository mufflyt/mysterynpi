# Per-person pool statistics

\`n_at_best\` is the number that decides everything downstream: one
candidate at the strongest class resolves, more than one is ambiguous.

## Usage

``` r
pool_stats(per_candidate, id = "id", class = "evidence_class", facet = NULL)
```

## Arguments

- per_candidate:

  output of \[collapse_candidates()\].

- id, class:

  column names.

- facet:

  optional column (e.g. a taxonomy axis) counted per class-best pool.
  Counted, never used to break a tie – see \[resolve_best_class()\].

## Value

one row per id.
