# First initial of a normalised name, or \`NA\` when there is no name.

Returns \`NA\` rather than \`""\` for missing input so a caller cannot
read absence as a value. Taken AFTER transliteration, so an accented
surname yields the unaccented letter and joins against the registry
spelling.

## Usage

``` r
first_initial(x, strip_alternates = TRUE)
```

## Arguments

- x:

  character vector.

- strip_alternates:

  see \[name_key()\].

## Value

character vector of single letters, or \`NA\`.
