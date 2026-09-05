# Normalise a string: transliterate, upper-case, trim

Transliteration is the point. A hand-rolled \`toupper(trimws(...))\`
does not delete accented characters – it PRESERVES them, so an accented
name can never reach its unaccented spelling by any exact or
initial-based route.

## Usage

``` r
normalize_string(x, remove_apostrophes = FALSE, remove_internal_spaces = FALSE)
```

## Arguments

- x:

  character vector.

- remove_apostrophes:

  logical: drop \`'\` (so \`O'BRIEN\` becomes \`OBRIEN\`).

- remove_internal_spaces:

  logical: drop all whitespace.

## Value

character vector, \`NA\` preserved.

## Details

Internal whitespace is deliberately left alone: some callers need \`"VAN
DER BERG"\` preserved. \[name_key()\] collapses it, because a join key
needs the opposite.
