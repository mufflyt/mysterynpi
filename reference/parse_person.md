# Parse a free-text person name into given, middle and surname

THE ORDER IS THE POINT. humaniformat decides which token is which; it
does not clean, and it does not judge content. Handed a raw directory
string it returns, verbatim:

## Usage

``` r
parse_person(x, format = c("given_first", "surname_first"))
```

## Arguments

- x:

  character vector of free-text names.

- format:

  \`"given_first"\` (the default: current behaviour, with \`"Last,
  First"\` handled via the comma) or \`"surname_first"\` for rosters
  that publish the surname first WITHOUT a comma.

## Value

data.frame with \`first\`, \`middle\`, \`last\`, normalised via
\[name_key()\]. Absent parts are \`""\`, never \`NA\`, so
\[has_name_information()\] is the only test a caller needs.

## Details


      "Ann M. Barbaccia (Pollack)"  ->  last = "(Pollack)"
      "Samuel (NMN) Anaya"          ->  middle = "(NMN)"
      "Álvarez"                     ->  first = "Álvarez"   (not transliterated)

A maiden name becomes the SURNAME, \`(NMN)\` – which means "no middle
name" – becomes a middle name, and the accent survives into a join key
that can never match its unaccented registry spelling. Each of those
looks like a clean parse downstream, which is what makes them dangerous.

So the sequence below is not stylistic:

1.  strip credential and title tokens

2.  decide "Last, First" by asking whether a comma separates two
    stretches that BOTH still hold a name once credentials are gone –
    the comma in \`", M.D."\` does not

3.  remove parenthesised alternates BEFORE parsing, so the parser never
    sees a bracket to assign to a slot

4.  parse

5.  normalise each part

Steps 2 and 3 are each a defect observed in a working pipeline, not a
precaution: testing the raw string for a comma turned \`"Ann M.
Barbaccia (Pollack), M.D."\` into first \`"M"\`, middle \`"BARBACCIA"\`,
surname \`"ANN"\`.

SURNAME-FIRST WITHOUT A COMMA CANNOT BE DETECTED, ONLY DECLARED. The
comma logic above covers \`"Smith, John"\`; some rosters publish
\`"FINCH SHANNON"\` – surname first, no comma – and NOTHING in that
string distinguishes it from a given-first "Finch Shannon" (Finch is a
plausible given name). The caller knows the source's convention;
\`format = "surname_first"\` declares it. Implementation: a comma is
inserted after the surname span, and the string then flows through the
SAME credential-aware reversal as an explicit \`"Last, First"\` – one
reversal path, not two. The surname span is the first token plus any
leading \[SURNAME_PARTICLES\] run, so \`"DE LA CRUZ JUAN"\` reverses to
\`"JUAN DE LA CRUZ"\`. Strings already carrying a comma are left to the
comma logic. Limitation: an unhyphenated compound surname with no
particle (\`"SMITH JONES MARY"\`) reads as surname \`SMITH\` – there is
no signal to do better without a recorded surname to check against.
