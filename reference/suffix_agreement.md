# Do two recorded generational suffixes agree, disagree, or decide nothing?

THE VETO COMPARES GENERATIONS, NOT SPELLINGS. \`JR\` and \`II\` are both
a second-of-name and corroborate; \`SR\` vs \`JR\` and \`II\` vs \`III\`
are different people and conflict. Absence is \`"uninformative"\`, never
a conflict: most people carry no suffix, and a roster that omits \`JR\`
has not disagreed with a registry that records it.

## Usage

``` r
suffix_agreement(a, b)
```

## Arguments

- a, b:

  character vectors of recorded suffixes, the same length. Raw spellings
  are fine; \[normalize_suffix()\] is applied internally.

## Value

character: \`"corroborates"\`, \`"conflicts"\`, or \`"uninformative"\`.

## Details

Note the asymmetry that makes this rule worth its keep: agreement is
weak (almost everyone agrees on "no suffix" – which this rule reports as
uninformative, not agreement), but a conflict between two RECORDED
generations is close to the strongest single-field veto a name offers,
because the population it fires on – same surname, same given name, one
generation apart – is exactly the population every other name field
cannot separate.
