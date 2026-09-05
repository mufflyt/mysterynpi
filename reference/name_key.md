# Canonical name join key: transliterated, upper-cased, whitespace-collapsed.

THE DEFECT THIS EXISTS TO PREVENT. Hand-rolled normalisers are
\`toupper(trimws(...))\` and nothing more, so they do not delete
accented characters – they PRESERVE them:

## Usage

``` r
name_key(x, strip_alternates = TRUE)
```

## Arguments

- x:

  character vector.

- strip_alternates:

  logical: remove parenthesised alternate names. \`TRUE\` is correct for
  person names and is the default. \`FALSE\` reproduces a normaliser
  that does not handle the convention – use it to prove a swap, not to
  ship.

## Value

character vector.

## Details


      toupper("Alvarez" with an accent)  -> accented, not "ALVAREZ"
      first_initial(that)                -> the accented letter, never "A"

Every blocking strategy joins on an exact name or an exact first
initial, so an accented roster name cannot reach its unaccented registry
spelling by any route. Measured in one frozen linkage: of the 27 roster
rows carrying non-ASCII name characters, the weakest evidence tier ran
26 cohort-wide, and the unmatched rate ran 30

\`NA\` in, \`NA\` out. Callers needing \`""\` for a join must say so via
\[blank_na()\], so absence is never converted to a value by accident.

## Migrating from an existing normaliser

\`strip_alternates\` exists so a swap can be PROVEN rather than assumed.
The incumbent normaliser this was extracted alongside does not remove
parenthesised alternate names; this one does, and that is a deliberate
fix, not an accident of reimplementation – every roster row whose
derived middle initial came out as \`"("\` failed to resolve, 9 of 9.

So the migration is two reviewable steps, not one leap:


      name_key(x, strip_alternates = FALSE)   # byte-identical to the incumbent
      name_key(x)                             # then flip, as its own diff

Step one should change nothing and can be merged on that evidence. Step
two changes keys for exactly the rows carrying a bracket, and deserves
to be looked at on its own.
