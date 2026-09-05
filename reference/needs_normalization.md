# Would normalising this vector change it?

A cheap pre-check for mixed case or untrimmed whitespace. It does NOT
detect accents, so \`FALSE\` means "no case or spacing work to do", not
"already a valid join key" – use \[name_key()\] for that.

## Usage

``` r
needs_normalization(x)
```

## Arguments

- x:

  character vector.

## Value

logical(1).
