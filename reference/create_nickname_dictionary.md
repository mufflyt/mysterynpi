# Build the bidirectional nickname dictionary used by the similarity score

~125 formal first names mapped to their common variants, extracted
verbatim from isochrones' nickname system (quirks pinned – see the file
header). Distinct from \[NICKNAME_EDGES\] on purpose: that corpus feeds
the three-verdict \[nickname_agreement()\] rule; this dictionary feeds a
SIMILARITY SCORE for candidate ranking, and the two must never be
silently merged, because a table change here moves scores while a table
change there moves verdicts.

## Usage

``` r
create_nickname_dictionary(verbose = TRUE)
```

## Arguments

- verbose:

  message the build, as the original did.

## Value

list: \`formal_to_nicknames\`, \`nickname_to_formal\`, \`source\`,
\`created\`, \`formal_count\`, \`nickname_count\`.
