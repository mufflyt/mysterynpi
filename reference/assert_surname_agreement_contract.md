# Assert that surname agreement still behaves as this caller relies on.

Pins the component logic, the sub-floor exact match, the apostrophe
fold, the particle refusal, and the maiden-as-middle rescue – each a
measured failure mode of exact-equality surname comparison.

## Usage

``` r
assert_surname_agreement_contract(fn = surname_agreement)
```

## Arguments

- fn:

  the function to test; defaults to \[surname_agreement()\].

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
