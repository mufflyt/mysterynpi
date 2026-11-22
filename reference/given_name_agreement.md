# Categorical given-name agreement: verdict plus named reason

Deterministic rules only - no edit distance, no thresholds, no number of
any kind. Returns one row per pair with two columns:

## Usage

``` r
given_name_agreement(a, b, na_action = NA_ACTIONS)
```

## Arguments

- a, b:

  character vectors of given names.

- na_action:

  \[character(1)\] how to treat a missing value on either side: one of
  \[NA_ACTIONS\]. The default \`"uninformative"\` is the behaviour of
  every release before 0.10.0 – absence decides nothing. \`"warn"\` does
  the same and says so once per call; \`"error"\` refuses to compare.
  Imputation is deliberately absent: an imputed name is a fabricated
  identity claim (srr G2.14a, G2.14b; G2.14c refused with reason in
  \`R/missing_policy.R\`).

## Value

data.frame with columns \`verdict\` and \`reason\`, one row per pair.

## Details

- \`verdict\`:

  \`"corroborates"\` / \`"conflicts"\` / \`"uninformative"\` - the same
  three-valued vocabulary as every other \`\*\_agreement()\` rule.
  \`uninformative\` means either side is missing or empty of letters;
  absence is never evidence of difference.

- \`reason\`:

  the NAMED deterministic rule behind a \`corroborates\`:

  - \`"exact"\` - compact keys equal after \[name_key()\] normalisation,
    so case, punctuation, spacing and accents can never read as
    difference;

  - \`"nickname"\` - a RECORDED one-hop \[NICKNAME_EDGES\] relation (a
    recorded edge or a shared formal root, the same relation
    \[nickname_agreement()\] corroborates on, never transitive closure).
    Declared equivalence, not spelling similarity: JULIA/JULIE
    corroborates because the corpus records the edge, while LEE/LEA -
    one edit apart, no edge - conflicts;

  - \`"initial"\` - exactly one side is a single letter and it equals
    the other side's first letter. An explicit rule about initials, and
    deliberately WEAK evidence (an initial matches many people): callers
    must treat it as countable, never rankable, which is why the reason
    travels with the verdict.

  \`NA_character\_\` for \`conflicts\` and \`uninformative\`.

Length discipline: equal lengths or scalar broadcast; anything else
refuses to recycle (comparing person 1 against person 3 and reporting
the result as though it had been asked for is how identity vectors get
silently mispaired).

## See also

Other agreement rules:
[`assert_given_name_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_given_name_agreement_contract.md)
