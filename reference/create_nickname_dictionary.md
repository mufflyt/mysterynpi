# The nickname dictionary, derived from the one corpus

Derived entirely from \[NICKNAME_EDGES\] – the same pinned corpus
\[nickname_agreement()\] reads – so verdicts and scores share ONE truth
about what a name may stand for. \`nickname_to_formal\` is multi-valued:
a hub nickname like \`AL\` carries every formal root the corpus records.

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
