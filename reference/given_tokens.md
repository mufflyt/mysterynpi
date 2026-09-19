# Given-name tokens of length \>= 2, initials EXCLUDED.

Initials are dropped for matching because \`"W."\` is compatible with
every W; they remain available in the parsed columns for reporting.

## Usage

``` r
given_tokens(given, middle = NULL, strip_alternates = TRUE)
```

## Arguments

- given, middle:

  character vectors.

- strip_alternates:

  see \[name_key()\].

## Value

list of character vectors.

## Details

A HYPHEN NEVER SPLITS A TOKEN HERE. "Mary-Jane" is ONE given name;
splitting it into \`"MARY"\`/\`"JANE"\` let it satisfy
\[person_matches()\]'s shared-token requirement against an unrelated
"Jane" who shares nothing but the second half of the compound –
\`person_matches("SMITH", given_tokens("Mary-Jane"), "SMITH",
given_tokens("Jane"))\` returned \`TRUE\` before this fix. Consistent
with \[split_given()\], which already never folds a given-name hyphen
for exactly this reason.
