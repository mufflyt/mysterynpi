# Do two recorded licenses corroborate? (This rule cannot veto.)

A license number is only a number WITHIN its issuing state, so the state
rides along: \`"12345"\` in Colorado and \`"12345"\` in Texas is a
numbering coincidence, not evidence.

## Usage

``` r
license_agreement(a, state_a, b, state_b, na_action = NA_ACTIONS)
```

## Arguments

- a, b:

  character vectors of recorded license numbers, the same length. Raw
  formatting is fine; \[normalize_license()\] is applied internally.

- state_a, state_b:

  character vectors of issuing-state codes. Compared after uppercasing
  and trimming; a missing state makes the pair uninformative, because a
  number without its state is not yet a license.

- na_action:

  \[character(1)\] how to treat a missing value on either side: one of
  \[NA_ACTIONS\]. The default \`"uninformative"\` is the behaviour of
  every release before 0.10.0 – absence decides nothing. \`"warn"\` does
  the same and says so once per call; \`"error"\` refuses to compare.
  Imputation is deliberately absent: an imputed name is a fabricated
  identity claim (srr G2.14a, G2.14b; G2.14c refused with reason in
  \`R/missing_policy.R\`).

## Value

character: \`"corroborates"\` or \`"uninformative"\`.

## Details

TWO VERDICTS, NOT THREE, AND THE MISSING ONE IS THE DESIGN. Same state
and same normalised number is \`"corroborates"\` – after the NPI itself,
the strongest deterministic evidence a candidate pair can carry.
EVERYTHING else is \`"uninformative"\`; there is no \`"conflicts"\` and
no code path that could produce one:

\* The registry's license field is PARTIAL (the NBER NPI-license
crosswalk is built from it and is far from fully populated), so absence
is ordinary, not evidence. \* Roughly a quarter of NPIs carry MORE THAN
ONE license. A roster's Colorado number against a registry row's Texas
number – or against a different Colorado number from an earlier
licensure – is two glimpses of one career, not a disagreement. \* A
formatting difference \[normalize_license()\] declines to erase
(padding, a profession prefix) must not become a veto.

A rule that can only add evidence can be ranked as high as its agreement
deserves without ever deleting a candidate it does not understand.
Callers holding several registry licenses per candidate should compare
against each and keep the best verdict – one \`"corroborates"\`
outweighs any number of \`"uninformative"\`.
