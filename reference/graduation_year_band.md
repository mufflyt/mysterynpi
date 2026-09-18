# Which band does a graduation year fall in, relative to a credentialing year?

The mechanics behind \[graduation_year_agreement()\], reported as a band
label rather than collapsed to a verdict, so a caller can weight the
bands (\`GRADUATION_YEAR_BANDS\$log2_lr\`) instead of taking the
three-verdict summary. This is the same split
\[name_surname_match_type()\] makes against
\[names_have_compatible_surname()\].

## Usage

``` r
graduation_year_band(
  credentialing_year,
  graduation_year,
  bands = GRADUATION_YEAR_BANDS
)
```

## Arguments

- credentialing_year, graduation_year:

  integer-ish vectors, the same length or one of length 1. Order
  matters: the difference is \`graduation_year - credentialing_year\`,
  so a NEGATIVE band means the person graduated BEFORE they
  credentialed.

- bands:

  the band table; defaults to \[GRADUATION_YEAR_BANDS\].

## Value

character: a \`band\` value, or \`"unknown"\` when either year is absent
or unparseable.

## Examples

``` r
graduation_year_band(2015, 2014)   # "one_before"
#> [1] "one_before"
graduation_year_band(2015, 2016)   # "one_after"
#> [1] "one_after"
graduation_year_band(2015, NA)     # "unknown"
#> [1] "unknown"
```
