# Normalise a recorded generational suffix to \`JR\`/\`SR\`/\`II\`/\`III\`/\`IV\`, or \`NA\`

Case-insensitive, periods and surrounding whitespace ignored (\`"Jr."\`
-\> \`"JR"\`). Everything unrecognised maps to \`NA\` – an encoding this
rule cannot read must degrade to "decides nothing", never to a spurious
veto.

## Usage

``` r
normalize_suffix(x)
```

## Arguments

- x:

  character vector of recorded suffixes.

## Value

character vector of canonical labels, or \`NA_character\_\`.
