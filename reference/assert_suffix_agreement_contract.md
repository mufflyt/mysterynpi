# Assert that suffix agreement still behaves as this caller relies on.

Pins the father/son veto and the generation semantics: SR vs JR
conflicts, JR vs II corroborates (both a second-of-name), absence
decides nothing.

## Usage

``` r
assert_suffix_agreement_contract(fn = suffix_agreement)
```

## Arguments

- fn:

  the function to test; defaults to \[suffix_agreement()\].

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
