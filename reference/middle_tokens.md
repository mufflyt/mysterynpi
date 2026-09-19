# Middle-name tokens, initials INCLUDED.

Unlike \[given_tokens()\], single-letter tokens are kept. A recorded
middle initial is the only middle-name evidence most registry rows
carry; dropping it would make every initial-only row uninformative
rather than comparable, and comparability is the whole point of the
middle-name axis.

## Usage

``` r
middle_tokens(x, strip_alternates = TRUE)
```

## Arguments

- x:

  character vector.

- strip_alternates:

  see \[name_key()\].

## Value

list of character vectors, one per input.

## Details

A HYPHEN NEVER SPLITS A TOKEN HERE, for the same reason \[name_key()\]'s
\`fold_hyphens\` must default \`FALSE\` and must never apply before
\[split_given()\]: "Anne-Marie" is ONE compound name, not "Anne" plus an
incidental, droppable "Marie". Splitting it produced a real false
corroboration – \`middle_agreement(middle_tokens("Anne-Marie"),
middle_tokens("Marie"))\` returned \`"corroborates"\` against a middle
name that is a DIFFERENT, unrelated person's, sharing only the second
half of the compound. This is the identical defect class
\[name_key()\]'s \`fold_hyphens\` documentation describes for given
names (three cross-state false identity matches), just not yet applied
to this tokeniser when that policy was set.
