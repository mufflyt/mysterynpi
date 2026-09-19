# Surname particles

Components that are grammatical connectives rather than family names. A
particle ALONE is not identity evidence: "Van" against "van Erven" and
"La" against "de la Cruz" would otherwise be compatible on component
subset, recreating a candidate-collision mechanism inside the canonical
layer.

## Usage

``` r
NAME_SURNAME_PARTICLES
```

## Details

No existing particle list was found in this repository (only prose
mentions in the parser pipelines), so this is the definition.
Deliberately conservative: adding a real surname here would silently
weaken matching.

KNOWN LIMITATION: \`"DO"\` IS BOTH A PARTICLE AND A STANDALONE SURNAME.
\`"do"\` is a genuine Portuguese/Lusophone particle ("of the", as in
surnames built like "do Carmo"), which is why it is listed here – but it
is ALSO, unrelatedly, a common standalone Vietnamese surname (the same
collision \[strip_name_noise()\]'s DO carve-out and
\`SURNAME_CREDENTIAL_COLLISIONS\` exist for, and the same collision
documented on \[SURNAME_PARTICLES\] in \`tokens.R\`, in a different
function each time). The particle guard here means a standalone
Vietnamese "Do" cannot be recognised as the shared surname of a compound
like "Do Nguyen": \`name_surname_match_type("Do", "Do Nguyen")\` returns
\`"none"\`, not \`"component_subset"\`, because the guard specifically
excludes a component set of the particle alone from counting as identity
evidence – yet removing \`"DO"\` from this list would reopen the exact
false-positive this guard exists to prevent for the Portuguese case: two
unrelated people named "Do Carmo" and "Do Silva" would then wrongly nest
as \`"component_subset"\` via the shared particle alone, the same shape
as "Van Dyke"/"Van Buren" this guard is built to reject. Both are real
populations in a US provider directory and this package has no evidence
either is rarer than the other, so – matching the precedent already set
for the identical shape in \`tokens.R\`'s \`SURNAME_PARTICLES\` – this
is documented rather than resolved with an unproven directional guess.
Found 2026-09-18.

## See also

Other name-matching:
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)
