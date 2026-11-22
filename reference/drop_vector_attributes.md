# Strip attributes from one-dimensional input

Objects that behave like vectors but do not inherit from \`vector\` –
those the \`units\` package creates, for instance – reach string
functions with a class that dispatches somewhere unhelpful. This returns
the underlying values with names and other attributes removed, so every
downstream comparison sees the same thing regardless of how the caller
stored it (srr G2.6, EA2.6).

## Usage

``` r
drop_vector_attributes(x)
```

## Arguments

- x:

  one-dimensional input.

## Value

\`x\` with attributes removed.

## Examples

``` r
drop_vector_attributes(structure(c(a = "X", b = "Y"), class = "odd"))
#> [1] "X" "Y"
```
