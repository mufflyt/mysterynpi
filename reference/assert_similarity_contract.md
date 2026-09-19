# Assert the similarity contract on a similarity function

Executable pin for the properties every consumer builds on: missing +
present is \`NA\` (never 0, never a neutral constant), missing + missing
is \`NA\`, self-similarity of an observed name is 1, symmetry, scalar
broadcasting works, and unequal non-scalar lengths REFUSE to recycle.
Downstream test suites call this against the installed package so a
semantic drift fails their build, not just this package's.

## Usage

``` r
assert_similarity_contract(fn = surname_similarity)
```

## Arguments

- fn:

  a similarity function taking \`(a, b)\`.

## Value

invisible TRUE, or an error naming the violated property.

## See also

Other similarity:
[`JW_PREFIX_WEIGHT`](https://mufflyt.github.io/mysterynpi/reference/JW_PREFIX_WEIGHT.md),
[`NICKNAME_SIMILARITY`](https://mufflyt.github.io/mysterynpi/reference/NICKNAME_SIMILARITY.md),
[`given_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/given_name_similarity.md),
[`middle_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/middle_name_similarity.md),
[`surname_similarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_similarity.md)
