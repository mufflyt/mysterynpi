# Given-name tokens of length \>= 2, initials EXCLUDED.

Initials are dropped for matching because \`"W."\` is compatible with
every W; they remain available in the parsed columns for reporting.

## Usage

``` r
given_tokens(given, middle = NULL, strip_alternates = TRUE)
```

## Arguments

- given, middle:

  character vectors.

- strip_alternates:

  see \[name_key()\].

## Value

list of character vectors.
