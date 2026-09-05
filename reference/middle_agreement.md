# Compare two middle names as TOKEN SETS, never by position.

THE DEFECT THIS EXISTS TO PREVENT. Comparing \`substr(middle, 1, 1)\` on
each side scores a maiden surname held in a different slot as a
disagreement:

## Usage

``` r
middle_agreement(a_tokens, b_tokens)
```

## Arguments

- a_tokens, b_tokens:

  lists of character vectors from \[middle_tokens()\], the same length.

## Value

character: \`"corroborates"\`, \`"conflicts"\`, or \`"uninformative"\` –
the last when either side records no middle name, which is absence of
evidence and must never be read as evidence of difference.

## Details


      "Katherine A. Reinhard" / "KATHERINE REINHARD RYE"   A vs R
      "Pamela Beth Harvey"    / "PAMELA H. CAPISTA"        B vs H
      "Alyssa Diane Bantz"    / "ALYSSA BANTZ HINDMON"     D vs B

Every one of those shares a token outright. In the pipeline this comes
from, 82 roster rows had their ONLY exact first-and-last-name candidate
deleted this way, 57 of the 88 deleted pairs carrying a matching
credential in the registry, and the row was then published as "no
candidate" – indistinguishable from a person absent from the registry
entirely.

THREE VERDICTS, AND THE MIDDLE ONE IS LOAD-BEARING. \`"uninformative"\`
is not a hedge: it is what absence yields, and it means the middle name
decides nothing here. Callers must not treat it as agreement.

WHAT THIS DELIBERATELY DOES NOT DO:

\* It does not loosen the conflict. Two full middle names sharing no
token still conflict, and an initial still conflicts with a token it
cannot abbreviate. Only POSITION is stopped from manufacturing
disagreement. \* \*\*No edit-distance tolerance.\*\* A one-edit rule was
added and removed the same day: measured, it changed 64 of 30,740
candidate pairs and was worth 22 records, while admitting pairs that are
genuinely different given names (\`JULIA\`/\`JULIE\`, \`LEE\`/\`LEA\`,
\`ANN\`/\`ANNE\`). It is not symmetric with fuzzy SURNAME blocking,
which generates a candidate that is then ranked below exact evidence;
this would have suppressed a veto with no tier recording that it
happened.
