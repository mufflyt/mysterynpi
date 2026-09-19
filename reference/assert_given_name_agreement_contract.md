# Assert the given-name agreement contract

Executable pin, runnable in downstream suites so a semantic drift fails
their CI: the canonical missingness table (SMITH/SMITH corroborates,
SMITH/JONES conflicts, NA/SMITH uninformative, NA/NA uninformative), the
named reasons, the declared-alias-versus-spelling distinction
(JULIA/JULIE corroborates via the recorded edge; LEE/LEA conflicts with
nothing to soften it), one-hop-only nickname semantics, and the refusal
to recycle.

## Usage

``` r
assert_given_name_agreement_contract(fn = given_name_agreement)
```

## Arguments

- fn:

  implementation to check; defaults to \[given_name_agreement()\].
  Accepting a stand-in keeps the assertion falsifiable - an assertion
  only the real implementation can pass is indistinguishable from one
  that always passes.

## Value

invisible TRUE, or an error naming the violated property.

## See also

Other agreement rules:
[`given_name_agreement()`](https://mufflyt.github.io/mysterynpi/reference/given_name_agreement.md)
