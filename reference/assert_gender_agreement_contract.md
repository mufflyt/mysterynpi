# Assert that gender blocking still behaves as this caller relies on.

Call from your own test suite. The properties pinned here are the ones a
blocking caller silently depends on: encoding differences must not
manufacture a veto, absence must never be read as a conflict, and
numeric codes must not be guessed at.

## Usage

``` r
assert_gender_agreement_contract(fn = gender_agreement)
```

## Arguments

- fn:

  the function to test; defaults to \[gender_agreement()\] so a caller
  can also run it against a stand-in to prove the assertion can fail.

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
