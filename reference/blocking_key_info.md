# Canonical blocking key with auditable metadata

The \`key\` column is byte-identical to \[blocking_key()\] on the same
inputs. The remaining columns explain how that key was built and why a
row is or is not informative. Metadata never upgrades a blocking key
into identity evidence: blocking chooses candidates to compare;
agreement rules decide what those candidates mean.

## Usage

``` r
blocking_key_info(
  last,
  first = NULL,
  mode = c("surname_initial", "prefix_n", "compact"),
  n = NULL
)
```

## Arguments

- last:

  character vector of surnames. Required by every mode.

- first:

  character vector of given names. Required by \`surname_initial\`;
  ignored by the other modes.

- mode:

  \`"surname_initial"\`, \`"prefix_n"\`, or \`"compact"\`.

- n:

  prefix length: required for \`prefix_n\` (single finite whole number
  \>= 1); an ERROR with any other mode.

## Value

A data frame with columns \`key\`, \`mode\`, \`components_used\`,
\`informative\`, \`reason\`, \`surname_key\`, \`first_initial\`, and
\`prefix_n\`.

## Details

\`components_used\` names the governed recipe, not the observed
evidence. For example, \`surname+first_initial\` remains the recipe when
the first initial is missing and the key is therefore \`NA\`.

## See also

Other blocking:
[`blocking_key()`](https://mufflyt.github.io/mysterynpi/reference/blocking_key.md),
[`blocking_keys()`](https://mufflyt.github.io/mysterynpi/reference/blocking_keys.md),
[`blocking_spec()`](https://mufflyt.github.io/mysterynpi/reference/blocking_spec.md)
