# Numeric surname similarity, missing-aware and vectorized

Similarity in \`\[0, 1\]\` between surnames compared on their
letters-only compact keys (\[compact_name_key()\]), so hyphenation,
apostrophes, spacing and case can never masquerade as distance:
\`"Jones-Cox"\` vs \`"JONES COX"\` is exactly 1. \`NA_real\_\` unless
BOTH sides are observed. Deterministic: same inputs, same version, same
numbers.

## Usage

``` r
surname_similarity(a, b, method = c("jw", "lv"))
```

## Arguments

- a, b:

  character vectors of surnames (equal length, or either scalar).

- method:

  \`"jw"\` (Jaro-Winkler, prefix weight \[JW_PREFIX_WEIGHT\]) or
  \`"lv"\` (normalised Levenshtein similarity, \`1 - dist /
  max(length)\`).

## Value

numeric vector in \`\[0, 1\]\`, \`NA_real\_\` where either side is
missing or empty of letters.

## Details

This is a SCORE for the decision layer, not a verdict:
\[surname_agreement()\] stays categorical and similarity-free. A caller
who converts this number to accept/reject with a local literal has
recreated the private-threshold defect; thresholds belong in a named,
versioned decision configuration.

## See also

Other similarity:
[`JW_PREFIX_WEIGHT`](https://mufflyt.github.io/mysterynpi/reference/JW_PREFIX_WEIGHT.md),
[`NICKNAME_SIMILARITY`](https://mufflyt.github.io/mysterynpi/reference/NICKNAME_SIMILARITY.md),
[`assert_similarity_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_similarity_contract.md),
[`given_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/given_name_similarity.md),
[`middle_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/middle_name_similarity.md)
