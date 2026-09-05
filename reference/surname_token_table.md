# Surname components as a long (id, token) data frame

Returned long rather than as a list column because every caller joins on
the token; a list column would have to be unnested at each call site.

## Usage

``` r
surname_token_table(x, id, strip_alternates = TRUE)
```

## Arguments

- x:

  character vector of surnames.

- id:

  vector of identifiers, the same length as \`x\`.

- strip_alternates:

  see \[name_key()\].

## Value

data.frame(id, token), zero rows where a surname yields no component.
