# Deprecated: use \[given_name_similarity()\]

Superseded 2026-09-19 when similarity became a first-class governed
primitive (owner ruling: the defect was hand-rolled fuzz, not fuzz). The
replacement differs in exactly one semantic: MISSING input returns
\`NA_real\_\`, never this function's \`0.5\` neutral scalar - a neutral
constant for absence is the absence-into-evidence conversion the package
forbids everywhere else. This wrapper preserves the old single-pair
contract (including the 0.5) so a deprecation period cannot silently
change scores; migrate to \[given_name_similarity()\] and handle \`NA\`.
The \`options(mysterynpi.enable_similarity_scoring)\` opt-in fence is
retired with the same ruling.

## Usage

``` r
calculate_enhanced_first_name_similarity(name1, name2, nickname_dict = NULL)
```

## Arguments

- name1, name2:

  names to compare.

- nickname_dict:

  ignored (the consolidated corpus is always used); accepted for
  signature compatibility.

## Value

numeric in \`\[0, 1\]\`; \`0.5\` for missing input (old contract).
