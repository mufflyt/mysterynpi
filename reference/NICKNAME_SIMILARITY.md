# Pinned nickname-equivalence similarity

The score assigned when two given names are one-hop nickname equivalents
under \[NICKNAME_EDGES\] - deliberately just under exact (1.0) and far
above any plausible Jaro-Winkler for unrelated names, so a recorded
BOB/ROBERT edge always outranks a coincidental spelling neighbour. The
historical 0.96/0.94 sub-tiers were consolidated to 0.98 in 2026-09 (see
NEWS).

## Usage

``` r
NICKNAME_SIMILARITY
```

## See also

Other similarity:
[`JW_PREFIX_WEIGHT`](https://mufflyt.github.io/mysterynpi/reference/JW_PREFIX_WEIGHT.md),
[`assert_similarity_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_similarity_contract.md),
[`given_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/given_name_similarity.md),
[`middle_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/middle_name_similarity.md),
[`surname_similarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_similarity.md)
