# Pinned Jaro-Winkler prefix weight

Named so no caller ever re-derives it: stringdist's \`p\` parameter for
the Winkler prefix bonus. 0.1 is the classical Winkler setting; 0
degrades to plain Jaro. Changing this changes every score in every
consumer - it is a versioned package decision, not a call-site knob left
to drift.

## Usage

``` r
JW_PREFIX_WEIGHT
```

## See also

Other similarity:
[`NICKNAME_SIMILARITY`](https://mufflyt.github.io/mysterynpi/reference/NICKNAME_SIMILARITY.md),
[`assert_similarity_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_similarity_contract.md),
[`given_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/given_name_similarity.md),
[`middle_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/middle_name_similarity.md),
[`surname_similarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_similarity.md)
