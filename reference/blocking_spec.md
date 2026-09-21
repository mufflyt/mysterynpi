# Define one governed blocking specification

A specification records HOW a block is constructed, separately from the
records it will be applied to. This makes multi-key candidate generation
auditable: a caller can persist the exact blocking plan rather than only
the resulting strings.

## Usage

``` r
blocking_spec(mode, n = NULL, label = NULL)
```

## Arguments

- mode:

  One blocking mode accepted by \[blocking_key()\].

- n:

  Prefix width for \`prefix_n\`; forbidden for other modes.

- label:

  Optional human-readable identifier. Defaults to the mode, or
  \`prefix\_\<n\>\` for \`prefix_n\`.

## Value

An object of class \`mysterynpi_blocking_spec\`.

## See also

Other blocking:
[`blocking_key()`](https://mufflyt.github.io/mysterynpi/reference/blocking_key.md),
[`blocking_key_info()`](https://mufflyt.github.io/mysterynpi/reference/blocking_key_info.md),
[`blocking_keys()`](https://mufflyt.github.io/mysterynpi/reference/blocking_keys.md)
