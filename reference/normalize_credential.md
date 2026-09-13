# Normalise a provider credential string

Credential columns write the same credential many ways: NPPES "Provider
Credential Text" alone holds \`"M.D."\`, \`"MD"\`, \`"M.D., PH.D."\`,
\`"R.N., B.S.N."\`. Joining or grouping on the raw string splits one
credential population into several.

## Usage

``` r
normalize_credential(x)
```

## Arguments

- x:

  character vector of credential strings.

## Value

character vector, \`""\` for \`NA\` or empty input, never \`NA\`.

## Details

PERIODS ARE JOINERS, NOT SEPARATORS: \`"M.D."\` is one token, so periods
are removed before tokenising – the naive split on punctuation turns
\`"M.D."\` into \`"M, D"\`, which is how this function came to exist
(observed while cleaning the 2026-09-13 OpenSanctions Medicaid exclusion
linkage, where the naive approach produced \`"M, D"\` for 1,782
physicians). Commas, spaces, slashes and semicolons separate tokens.
Hyphens are kept: \`"NP-C"\` is one credential. Tokens are upper-cased,
de-duplicated in order of first appearance, and joined with \`", "\`.

This normalises FORM, not vocabulary: unknown credentials pass through
upper-cased rather than being dropped, so a rare credential is never
silently erased. See \[NAME_NOISE\] for the token vocabulary used when
credentials must be REMOVED from a name string instead.
