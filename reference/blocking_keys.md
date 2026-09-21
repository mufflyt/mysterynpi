# Generate several governed blocking keys per record

Produces long-form candidate-generation plumbing: one row per input
record per blocking specification. This is intentionally NOT an identity
verdict and does not count repeated blocks as repeated evidence.
Multiple blocks only widen or partition the candidate set that
downstream agreement rules will evaluate.

## Usage

``` r
blocking_keys(last, first = NULL, specs)
```

## Arguments

- last:

  Character vector of surnames.

- first:

  Character vector of given names. Required if any specification uses
  \`surname_initial\`.

- specs:

  One \[blocking_spec()\] or a non-empty list of them. Labels must be
  unique so persisted ledgers can identify which rule emitted each key.

## Value

Long-form data frame. It adds \`record_id\`, \`spec_id\`, and \`label\`
to the columns returned by \[blocking_key_info()\].

## Details

Output order is specification-major: specifications keep their supplied
order, and records keep their input order within each specification.

## See also

Other blocking:
[`blocking_key()`](https://mufflyt.github.io/mysterynpi/reference/blocking_key.md),
[`blocking_key_info()`](https://mufflyt.github.io/mysterynpi/reference/blocking_key_info.md),
[`blocking_spec()`](https://mufflyt.github.io/mysterynpi/reference/blocking_spec.md)
