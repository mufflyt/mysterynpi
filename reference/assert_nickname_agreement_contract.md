# Assert that nickname agreement still behaves as this caller relies on.

Pins the one-hop semantics: a recorded edge admits, a shared formal name
admits, and a shared NICKNAME does not – AL must never merge ALBERT with
ALEXANDER. A table update that flips any of these is a breaking change.

## Usage

``` r
assert_nickname_agreement_contract(fn = nickname_agreement)
```

## Arguments

- fn:

  the function to test; defaults to \[nickname_agreement()\].

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
