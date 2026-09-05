# Do two parsed people share a surname AND at least one full given-name token?

Comparison is on token SETS, not position. \`"Williams, W. Jon"\` and
\`"Jon W Williams"\` are the same person and their given-name token sets
share \`JON\`; a positional first-token rule scores them as different. A
shared FULL token (\>= 2 characters) is required – initials may
corroborate but never identify, since \`"W."\` matches every W.

## Usage

``` r
person_matches(last_a, given_a, last_b, given_b)
```

## Arguments

- last_a, last_b:

  character vectors of normalised surnames.

- given_a, given_b:

  lists from \[given_tokens()\].

## Value

logical vector.

## Details

THIS IS THE EXACT TIER, DELIBERATELY. \`BOB\` does not match \`ROBERT\`
here, and the logical return collapses "no given name" with "different
given name" – both acceptable only because this rule's job is the
strictest pass. The nickname tier, with the three-verdict contract that
keeps absence uninformative, is \[nickname_agreement()\]; a pipeline's
weaker blocking passes should rank on its verdicts rather than loosen
this one.
