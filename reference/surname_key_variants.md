# Both equality-join key variants of a surname

Returns one row per input with two keys:

- key_full:

  the compact key of the WHOLE surname, particles glued: \`"Van
  Houten"\` -\> \`"VANHOUTEN"\`, \`"de la Cruz"\` -\> \`"DELACRUZ"\`.

- key_final:

  the compact key of the FINAL token alone: \`"Van Houten"\` -\>
  \`"HOUTEN"\`, \`"Van Le"\` -\> \`"LE"\`.

They are equal for single-token surnames. A matcher should accept EITHER
against the registry key (one long-format frame row per variant keeps
the database join a hash join; an OR predicate degrades it to a nested
loop).

## Usage

``` r
surname_key_variants(x, strip_alternates = TRUE)
```

## Arguments

- x:

  character vector of surnames (already parsed out of a full name; see
  \[parse_person()\]).

- strip_alternates:

  see \[name_key()\].

## Value

data.frame with columns \`surname\` (the input), \`key_full\`,
\`key_final\`. \`NA\` surname gives \`NA\` keys.

## Details

A TRAILING SINGLE LETTER never enters either key when at least one other
token exists: \`"Goodyear V"\` keys as \`"GOODYEAR"\`. This is a
positional rule about what can be a surname, NOT a claim that the letter
is a generational suffix – the suffix module deliberately refuses to
read \`V\` as a generation (\[normalize_suffix()\]), and both rules
stand: here the V merely must not become the surname key; there it must
not veto a match.

## See also

Other join-keys:
[`compact_name_key()`](https://mufflyt.github.io/mysterynpi/reference/compact_name_key.md)

## Examples

``` r
surname_key_variants(c("Van Houten", "Van Le", "Jones-Cox", "Goodyear V"))
#>      surname  key_full key_final
#> 1 Van Houten VANHOUTEN    HOUTEN
#> 2     Van Le     VANLE        LE
#> 3  Jones-Cox  JONESCOX       COX
#> 4 Goodyear V  GOODYEAR  GOODYEAR
```
