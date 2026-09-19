# Numeric given-name similarity: nickname-aware, missing-aware, vectorized

The canonical replacement for
\[calculate_enhanced_first_name_similarity()\] (deprecated) and for
every hand-rolled first-name Jaro-Winkler in downstream pipelines. Per
pair:

1.  exact after compact-key normalisation: \`1\`

2.  one-hop nickname equivalents under \[NICKNAME_EDGES\] (the same
    relation \[nickname_agreement()\] corroborates on - a recorded edge
    or a shared formal root, never transitive closure):
    \[NICKNAME_SIMILARITY\]

3.  both observed, otherwise: Jaro-Winkler on compact keys, taking the
    LARGER of the raw score and the umlaut-digraph-simplified score
    (\`AE/OE/UE -\> A/O/U\`), so \`MUELLER\` and \`MULLER\` score as the
    same romanisation family rather than as strangers

4.  either side missing: \`NA_real\_\` - never \`0\`, never a neutral
    constant. (The deprecated function returned \`0.5\` for missing;
    that neutral scalar is exactly the absence-into-evidence conversion
    this contract forbids.)

## Usage

``` r
given_name_similarity(a, b, nickname_aware = TRUE)
```

## Arguments

- a, b:

  character vectors of given names (equal length, or either scalar).

- nickname_aware:

  apply step 2. \`TRUE\` is the default and the reason this function
  exists; \`FALSE\` gives plain governed Jaro-Winkler.

## Value

numeric vector in \`\[0, 1\]\`, \`NA_real\_\` where either side is
missing.

## See also

Other similarity:
[`JW_PREFIX_WEIGHT`](https://mufflyt.github.io/mysterynpi/reference/JW_PREFIX_WEIGHT.md),
[`NICKNAME_SIMILARITY`](https://mufflyt.github.io/mysterynpi/reference/NICKNAME_SIMILARITY.md),
[`assert_similarity_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_similarity_contract.md),
[`middle_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/middle_name_similarity.md),
[`surname_similarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_similarity.md)
