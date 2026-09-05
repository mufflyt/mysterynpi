# Add normalised copies of named columns to a data frame

Originals are preserved. A crosswalk showing only the normalised form
cannot be audited: a reviewer has no way to see that \`"ALVAREZ"\` came
from \`"Álvarez"\`.

## Usage

``` r
normalize_name_columns(
  df,
  cols,
  remove_apostrophes = FALSE,
  remove_internal_spaces = FALSE,
  suffix = "_norm"
)
```

## Arguments

- df:

  data frame.

- cols:

  character: columns to normalise.

- remove_apostrophes, remove_internal_spaces:

  passed to \[normalize_string()\].

- suffix:

  appended to each new column name.

## Value

\`df\` with one added column per entry in \`cols\`.
