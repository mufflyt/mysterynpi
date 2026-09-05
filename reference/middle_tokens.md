# Middle-name tokens, initials INCLUDED.

Unlike \[given_tokens()\], single-letter tokens are kept. A recorded
middle initial is the only middle-name evidence most registry rows
carry; dropping it would make every initial-only row uninformative
rather than comparable, and comparability is the whole point of the
middle-name axis.

## Usage

``` r
middle_tokens(x, strip_alternates = TRUE)
```

## Arguments

- x:

  character vector.

- strip_alternates:

  see \[name_key()\].

## Value

list of character vectors, one per input.
