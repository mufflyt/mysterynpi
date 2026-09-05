# Normalise the first/middle/last columns of a provider table

Writes \`first_clean\`, \`last_clean\` and, when the column exists,
\`middle_clean\`. A missing middle name is normal and is not an error; a
missing given or family name is.

## Usage

``` r
normalize_physician_names(
  df,
  first_col = "first_name",
  last_col = "last_name",
  middle_col = "middle_name",
  advanced_norm = FALSE
)
```

## Arguments

- df:

  data frame.

- first_col, last_col, middle_col:

  column names.

- advanced_norm:

  logical: also drop apostrophes and internal spaces.

## Value

\`df\` with the \`\_clean\` columns added.
