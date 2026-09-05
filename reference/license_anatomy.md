# Decompose a license number into prefix, digits, and suffix

FOR STATE MEDICAL BOARD FILES, where the license number is about to
become a blocking variable and its anatomy decides whether it can be
one. A board file's numbers arrive as \`12345\`, \`MD12345\`,
\`12345A\`, \`MD.0012345\` – and whether \`MD\` is a profession code
(meaning) or decoration (junk) is not decidable from one row. This
function makes the anatomy VISIBLE so \[license_conformance()\] can
decide it from the whole column. (NPPES's license field has known
conventions; this machinery is aimed at the board side, where each state
is its own convention.)

## Usage

``` r
license_anatomy(x)
```

## Arguments

- x:

  character vector of recorded license numbers.

## Value

data.frame with \`license\` (as given), \`key\` (normalised),
\`prefix\`, \`digits\`, \`suffix\`, \`shape\`, \`n_digits\`. All-\`NA\`
rows for absent input; a key with no digit at all keeps everything in
\`prefix\`.

## Details

Decomposition runs on \[normalize_license()\] output (case and
punctuation are already formatting): \`prefix\` is everything before the
first digit, \`suffix\` everything after the last digit, \`digits\` the
span between – which may itself contain letters (\`A12B34\`), and the
\`shape\` says so. \`shape\` is the license with every digit replaced by
\`#\`: \`MD12345A\` has shape \`MD#####A\`. Two numbers with the same
shape are formatted alike; that is the unit \[license_conformance()\]
counts.
