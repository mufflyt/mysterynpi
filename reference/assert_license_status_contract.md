# Assert that license-status normalisation still refuses the 4x inflation.

Pins the landmines by name: death is not retirement, discipline is not
retirement, a lapse is not retirement, and an unmapped status decides
nothing. A change that lets any of these drift into "retired" multiplies
a retirement signal roughly fourfold and is a breaking change.

## Usage

``` r
assert_license_status_contract(fn = normalize_license_status)
```

## Arguments

- fn:

  the function to test; defaults to \[normalize_license_status()\].

## Value

\`TRUE\` invisibly, or \`stop()\` naming the property that failed.
