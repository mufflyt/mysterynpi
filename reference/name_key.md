# Canonical name join key: transliterated, upper-cased, whitespace-collapsed.

THE DEFECT THIS EXISTS TO PREVENT. Hand-rolled normalisers are
\`toupper(trimws(...))\` and nothing more, so they do not delete
accented characters – they PRESERVE them:

## Usage

``` r
name_key(x, strip_alternates = TRUE, fold_hyphens = FALSE)
```

## Arguments

- x:

  character vector.

- strip_alternates:

  logical: remove parenthesised alternate names. \`TRUE\` is correct for
  person names and is the default. \`FALSE\` reproduces a normaliser
  that does not handle the convention – use it to prove a swap, not to
  ship.

- fold_hyphens:

  logical: treat a hyphen as equivalent to a space. \`FALSE\` (the
  default) treats a hyphen as a literal character, which is correct for
  \[split_given()\] and any given/middle-name comparison. Pass \`TRUE\`
  only when comparing SURNAMES, where a compound name written with a
  hyphen by one source and a space by another must join as the same
  person – see the defect note above for what goes wrong if this is
  applied to a given name instead.

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

WHAT \`fold_hyphens\` IS FOR, AND WHY IT DOES NOT DEFAULT ON
(2026-09-11). A compound SURNAME is recorded with a hyphen by one source
and a space by another – "ABBAS-RODRIGUEZ" against "Abbas Rodriguez" –
and by default that is TWO DIFFERENT KEYS: no transliteration or
case-folding touches a hyphen. A caller comparing surnames can pass
\`fold_hyphens = TRUE\` to equate them; measured in the linkage this was
found in, 57 of 87 roster-wide fuzzy-surname matches (66 surname
difference, not a genuine spelling discrepancy.

THIS MUST NOT BE THE DEFAULT, AND MUST NOT BE APPLIED TO GIVEN/MIDDLE
NAMES. A first attempt shipped \`fold_hyphens = TRUE\` as the default
for every caller of \[blank_na()\], including \[split_given()\] – which
every given-name split in this package's consumers goes through. A
genuinely compound GIVEN name ("Samantha-Rose", "Bonnie-Dee",
"Mary-Louise") is ONE name, not a given name plus an incidental middle
name; folding its hyphen to a space made \[split_given()\] treat
"Rose"/"Dee"/"Louise" as a separate, droppable middle token, which then
matched a DIFFERENT real person sharing only the shortened given name
and surname – three cross-state false identity matches were found this
way before the default was reverted here. Fold hyphens where a SURNAME
is being compared. Never fold them before splitting a given name.

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
to be looked at on its own. \`fold_hyphens\` is a separate, opt-in,
per-call decision – see above – not part of this migration.
