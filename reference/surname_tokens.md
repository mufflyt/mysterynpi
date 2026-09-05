# Split a normalised surname into its components.

Sources disagree about how a compound surname is recorded: one holds
\`"MCCARTHY-DERVIN"\` where another holds \`"MCCARTHY"\`, or one splits
\`"HARVEY CAPISTA"\` across its middle and last fields where the other
keeps it whole. No exact or edit-distance strategy can span a DROPPED
component – an edit distance of 2 cannot cross seven missing characters
– so these fail silently as "no candidate". Measured in one crosswalk:
hyphenated surnames ran 27.1

## Usage

``` r
surname_tokens(x, strip_alternates = TRUE)
```

## Arguments

- x:

  a single surname string.

- strip_alternates:

  see \[name_key()\].

## Value

character vector of components; \`character(0)\` when nothing survives.
