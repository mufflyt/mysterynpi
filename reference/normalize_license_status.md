# Normalise recorded board license statuses to their exit classes

Case, surrounding whitespace and punctuation are formatting; the WORDS
are the evidence. Everything the table cannot read maps to \`NA\` – and
that direction is the point, exactly as in \[normalize_gender()\]: an
unmapped status must decide nothing, because a default into any exit
class – least of all \`"retired"\` – is how a board's whole vocabulary
quietly becomes a retirement signal. Florida's \`Deceased\` is death.
OPMC's \`Surrendered\` is discipline. Colorado's \`Expired\` is a lapse
of unknown cause. None of them is retirement, and after this function
none of them can be counted as one by accident.

## Usage

``` r
normalize_license_status(x, levels = LICENSE_STATUS_LEVELS)
```

## Arguments

- x:

  character vector of recorded license statuses.

- levels:

  the vocabulary; defaults to \[LICENSE_STATUS_LEVELS\]. A
  board-specific supplement is rbind()ed by the caller and reviewed like
  data, because it is data.

## Value

character vector of \`"active"\`, \`"restricted"\`, \`"retired"\`,
\`"deceased"\`, \`"disciplinary"\`, \`"lapsed"\`, or \`NA_character\_\`.
