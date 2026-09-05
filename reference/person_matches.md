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
