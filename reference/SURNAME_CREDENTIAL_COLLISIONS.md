# \`NAME_NOISE\` tokens that are ALSO common real surnames.

A single token cannot mean both things in \[NAME_NOISE\]'s flat
vocabulary, so each entry here gets the SAME two-part protection inside
\[strip_name_noise()\]: kept as a surname when it is one of exactly two
tokens in its comma segment, or written in the exact title-case spelling
recorded here (the value), regardless of token count. The name (the
vector's names) is the \`NAME_NOISE\` spelling the protection applies
to.

## Usage

``` r
SURNAME_CREDENTIAL_COLLISIONS
```

## Details

Membership bar: the token must be a WELL-KNOWN, common real surname –
not merely conceivable. \`"DO"\` (Vietnamese, e.g. the DEA-action
records that motivated this file) and \`"MA"\` (Chinese – Yo-Yo Ma, Jack
Ma) both clear that bar. Most other short \`NAME_NOISE\` tokens (\`PA\`,
\`OD\`, \`DC\`, \`MS\`, \`LM\`, \`BA\`) do NOT – protecting one of those
would invent a fake surname for a genuinely credential-only input rather
than recover a real one, so they stay unconditionally stripped. Add a
token here only with the same standard of evidence: a real, common
surname, not a hypothetical one.
