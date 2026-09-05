# Assert that license agreement still behaves as this caller relies on.

Pins the two-verdict design: same state and same normalised number
corroborates; everything else – including a same-state mismatch, which a
quarter of multi-licensed NPIs make ordinary – is uninformative, and no
input can produce a conflict.

## Usage

``` r
assert_license_agreement_contract(fn = license_agreement)
```

## Arguments

- fn:

  the function to test; defaults to \[license_agreement()\].

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
