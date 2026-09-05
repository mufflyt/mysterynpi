# Normalise recorded gender codes to \`"M"\`, \`"F"\`, or \`NA\`

Accepts the encodings that actually occur in rosters and in NPPES
(\`Provider Sex Code\` is \`M\`/\`F\`): case-insensitive \`M\`/\`MALE\`
and \`F\`/\`FEMALE\`, with surrounding whitespace ignored. EVERYTHING
ELSE MAPS TO \`NA\`, and that direction is the point of the function:

## Usage

``` r
normalize_gender(x)
```

## Arguments

- x:

  character vector of recorded gender codes.

## Value

character vector of \`"M"\`, \`"F"\`, or \`NA_character\_\`.

## Details

\* An unmapped encoding must degrade to "decides nothing", never to a
spurious veto. Passed through raw, \`"FEMALE"\` vs \`"F"\` fails \`==\`
and a naive comparison deletes a candidate over a formatting difference.
\* \`U\`, \`UNKNOWN\`, \`X\`, blank and \`NA\` all mean the source did
not commit to a code this rule can compare against a registry that
records only \`M\`/\`F\`. They are absence, and absence is handled by
\[gender_agreement()\] returning \`"uninformative"\`. \* \*\*Numeric
codes are deliberately not mapped.\*\* ISO/IEC 5218 says 1=male,
2=female; other systems ship the opposite. Guessing the convention flips
gender wholesale across a source, and a wholesale flip turns the veto
into a true-match shredder. Recode numerics upstream, where you know
which convention the source uses.
