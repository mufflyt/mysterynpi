# Numeric middle-name similarity, missing-aware and vectorized

Same engine and contract as \[surname_similarity()\], on compact keys.
NOTE ON INITIALS: an initial against a full name (\`"R"\` vs
\`"ROBERT"\`) produces a mechanically low score that MEANS NOTHING about
the person - most registry rows record only an initial. That comparison
belongs to \[middle_agreement()\], whose initial rules are categorical;
use this only when both sides carry full middle names, or feed the
decision layer, which is missing-aware and initial-aware by
configuration.

## Usage

``` r
middle_name_similarity(a, b, method = c("jw", "lv"))
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

## See also

Other similarity:
[`JW_PREFIX_WEIGHT`](https://mufflyt.github.io/mysterynpi/reference/JW_PREFIX_WEIGHT.md),
[`NICKNAME_SIMILARITY`](https://mufflyt.github.io/mysterynpi/reference/NICKNAME_SIMILARITY.md),
[`assert_similarity_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_similarity_contract.md),
[`given_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/given_name_similarity.md),
[`surname_similarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_similarity.md)
