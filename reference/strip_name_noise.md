# Strip credential and title TOKENS from a personal-name string

TOKEN-BASED ON PURPOSE. A \`\b\`-delimited regex alternation destroys
accented surnames: in \`"Mróz"\` the \`ó\` is not an ASCII word
character, so \`\bMr\b\` matches INSIDE the name and the parser returns
a surname of \`"OZ"\`. That is the same population transliteration
exists to protect, broken by the cleaner meant to help it. Splitting on
delimiters and dropping whole tokens cannot match a substring, so no
name can be truncated here.

## Usage

``` r
strip_name_noise(x)
```

## Arguments

- x:

  character vector.

## Value

character vector with credential and title tokens removed.
