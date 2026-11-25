# Phrase join key: fold, apostrophes closed, punctuation demoted to separator

\[normalize_string()\] is a FOLD, not a key: it keeps punctuation, so
\`"ST. MARY"\` and \`"MARY-JO"\` survive intact. \[name_key()\] keeps
punctuation too, and additionally drops parenthesised alternate names.
\[compact_name_key()\] deletes every non-letter, gluing word boundaries
back together (\`"VAN DER BERG"\` -\> \`"VANDERBERG"\`). None of the
three is the contract a phrase-equality join needs: upper-case ASCII
words separated by single spaces, punctuation demoted to a separator
rather than kept or deleted.

## Usage

``` r
phrase_key(x, remove_apostrophes = TRUE)
```

## Arguments

- x:

  character vector of phrases as recorded.

- remove_apostrophes:

  logical: delete apostrophes before the punctuation pass (the
  join-key-safe default). \`FALSE\` lets the punctuation pass space
  them, splitting \`"O'BRIEN"\` into \`"O BRIEN"\`.

## Value

character vector of \`A-Z0-9\` words separated by single spaces, \`NA\`
where nothing keyable survives.

## Details

Apostrophes are DELETED before the punctuation pass, not spaced. Spacing
them splits one token into two, so \`"O'BRIEN"\` and \`"OBRIEN"\` – one
surname recorded two ways – key as \`"O BRIEN"\` and \`"OBRIEN"\` and
count as a disagreement. The fold maps the curly, modifier and okina
forms onto the straight apostrophe before the delete runs, so all four
codepoints close the token. Pass \`remove_apostrophes = FALSE\` only
when the split is genuinely wanted; for a join key it never is.

Parenthesised text is NOT stripped – unlike \[name_key()\], every
bracket is data here, because this key serves phrases (cities,
organisations, addresses) where \`"Michigan Otolaryngology (MOSA)"\` is
one value, not a name carrying an alternate. For person names under the
alternate-name convention, use \[name_key()\] instead.

\`NA\` in, \`NA\` out; a phrase with no keyable characters is \`NA\`,
never \`""\`, so absence cannot join to absence.

## Examples

``` r
phrase_key(c("O'Brien", "OBrien", "St. Mary", "VAN  DER BERG", ""))
#> [1] "OBRIEN"       "OBRIEN"       "ST MARY"      "VAN DER BERG" NA            
# "OBRIEN" "OBRIEN" "ST MARY" "VAN DER BERG" NA
```
