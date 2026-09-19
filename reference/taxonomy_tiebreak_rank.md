# Tie-break rank from a three-valued consistency verdict

\`0\` consistent, \`1\` unknown, \`2\` inconsistent – so a sort
ascending on this rank prefers consistent over unknown over
inconsistent. Position the rank AFTER every stronger ordering criterion
(recency, confidence tier): it exists to resolve ties, never to override
stronger evidence. Measured origin: the isochrones dedup broke ties by
lowest NPI, blind to identity quality, and the 2026-09-19 production
promotion audit showed the rank changing 360 of 22,002 selections, every
one tied on recency and confidence, zero rank regressions.

## Usage

``` r
taxonomy_tiebreak_rank(consistent)
```

## Arguments

- consistent:

  logical vector from \[taxonomy_consistent()\].

## Value

integer vector of 0/1/2.

## See also

Other taxonomy-agreement:
[`TAXONOMY_FAMILY_PATTERNS`](https://mufflyt.github.io/mysterynpi/reference/TAXONOMY_FAMILY_PATTERNS.md),
[`taxonomy_consistent()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_consistent.md),
[`taxonomy_family_pattern()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_family_pattern.md)
