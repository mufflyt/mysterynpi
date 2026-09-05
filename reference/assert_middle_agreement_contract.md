# Assert that middle-name agreement still behaves as this caller relies on.

Call from your own test suite. Each assertion below is a defect that has
shipped; a change to this package that flips any of them is a breaking
change and must be a major version bump.

## Usage

``` r
assert_middle_agreement_contract(fn = middle_agreement, tokens = middle_tokens)
```

## Arguments

- fn:

  the function to test; defaults to \[middle_agreement()\] so a caller
  can also run it against a stand-in to prove the assertion can fail.

- tokens:

  tokeniser to pair with \`fn\`.

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
