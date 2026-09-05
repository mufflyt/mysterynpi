# Parse an NPPES API response into one row per provider

The pure half of \[npi_search()\], split out so it can be tested against
a stored fixture with no network anywhere near the test suite. Give it
the raw JSON text of an NPPES API v2.1 response and the date the
response was RETRIEVED, and it returns the fields a linkage wants, one
row per provider.

## Usage

``` r
parse_npi_search(txt, retrieved)
```

## Arguments

- txt:

  character: the JSON text of an NPPES API v2.1 response (length-one
  string, or lines to be pasted together).

- retrieved:

  the \[Date\] the response was fetched. Explicit, never defaulted, so
  the parse of a stored response is reproducible.

## Value

data.frame with columns \`npi\`, \`first\`, \`middle\`, \`last\`,
\`suffix\`, \`honorific\`, \`credential\`, \`gender\`, \`gender_code\`,
\`zip\`, \`zip_full\`, \`state\`, \`enumeration_date\`,
\`years_enumerated\`, \`last_updated\`, \`retrieved\`; zero rows when
the search matched nothing.

## Details

WHAT THE COLUMNS MEAN, AND WHAT IS MISSING ON PURPOSE:

\* \`honorific\`, \`suffix\`: NPPES \`name_prefix\` / \`name_suffix\`.
The registry writes absence three ways – a missing key, an empty string,
and the literal sentinel \`"–"\` – and all three become \`NA\` here,
because a sentinel that survives into an agreement rule becomes a fake
veto (\`suffix_agreement("–", "JR")\` must be reachable only as
uninformative). \* \`gender\`: \[normalize_gender()\] applied to NPPES
\`sex\`; the raw code is kept in \`gender_code\`. \* \`zip\`: the first
five digits of the practice LOCATION address postal code (\`zip_full\`
keeps all nine); \`state\` rides along because a license number without
its state is not yet a license. \* \`years_enumerated\`: whole years
between \`enumeration_date\` and \`retrieved\`. \*\*This is not years in
practice.\*\* NPI enumeration began in mid-2005, so every career older
than that is truncated to the same ceiling; treat it as a lower bound
and say so in your methods. \* \*\*There is no birth year.\*\* NPPES
does not publish one, and no column here pretends otherwise. A birth
year must come from a licensure board or roster source, where
\[gender_agreement()\]-style absence discipline applies: a source that
lacks it decides nothing. \* \`last_updated\` and \`retrieved\` together
are the vintage: what the registry claimed, and when you asked. Record
both; a match found today against a row last updated in 2019 is a claim
about 2019.
