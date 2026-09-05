# Normalise a recorded license number for comparison

Uppercase; spaces, periods and hyphens removed; blank to \`NA\`. THAT IS
ALL, and the restraint is the point:

## Usage

``` r
normalize_license(x)
```

## Arguments

- x:

  character vector of recorded license numbers.

## Value

character vector, or \`NA_character\_\` where nothing was recorded.

## Details

\* \*\*Leading zeros stay.\*\* Some boards number with fixed-width zero
padding and some do not; stripping zeros corroborates \`"052"\` with
\`"52"\` at the price of corroborating \`"520"\`-style truncations too.
A caller who has verified its two sources share a padding convention can
strip upstream. \* \*\*Alpha prefixes stay.\*\* In states that prefix by
profession, \`MD12345\` and \`PA12345\` are two different people's
licenses; a prefix strip would merge them.
