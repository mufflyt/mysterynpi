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

data.frame with \`first\`, \`middle\`, \`last\`, \`suffix\` (canonical
\`JR\`/\`SR\`/\`II\`/\`III\`/\`IV\` label, from \[extract_suffix()\]),
normalised via \[name_key()\]. Absent parts are \`""\`, never \`NA\`, so
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

1.  extract the generational suffix (JR/SR/II/III/IV), BEFORE anything
    else touches the string

2.  (if \`format = "surname_first"\`) insert a comma after the surname
    span, so the string flows through the SAME reversal logic as an
    explicit \`"Last, First"\`

3.  strip credential and title tokens

4.  decide "Last, First" by asking whether a comma separates two
    stretches that BOTH still hold a name once credentials are gone –
    the comma in \`", M.D."\` does not

5.  remove parenthesised alternates BEFORE parsing, so the parser never
    sees a bracket to assign to a slot

6.  parse

7.  normalise each part

Steps 4 and 5 are each a defect observed in a working pipeline, not a
precaution: testing the raw string for a comma turned \`"Ann M.
Barbaccia (Pollack), M.D."\` into first \`"M"\`, middle \`"BARBACCIA"\`,
surname \`"ANN"\`.

STEP 1 IS FIRST FOR A REASON THAT HAS NOTHING TO DO WITH PARSING. Step
3's \[strip_name_noise()\] treats \`JR\`/\`SR\`/\`II\`/\`III\`/\`IV\` as
noise and deletes them – correctly, since a name parser has no way to
know \`JR\` is not a surname. That means a caller who treats "strip
titles" and "suffix handling" as two independently-composable pipeline
stages loses every suffix the moment title-stripping happens to run
first: the generation that survives to distinguish father from son is
silently gone before the "suffix" stage ever sees the string, and
\[suffix_agreement()\]'s father/son veto goes quiet with no error.
\[extract_suffix()\] running first, inside this function, is what makes
that ordering hazard impossible to hit by composing stages in the wrong
order – see \`tests/testthat/test-suffix.R\`, "extract_suffix must run
BEFORE strip_name_noise, which deletes it". It also runs before step 2's
surname-first comma insertion: a trailing \`"... JUAN JR"\` must lose
the \`JR\` before the particle walk decides where the surname span ends,
or the suffix is read as part of the given name.

SURNAME-FIRST WITHOUT A COMMA CANNOT BE DETECTED, ONLY DECLARED. The
comma logic in step 4 covers \`"Smith, John"\`; some rosters publish
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
