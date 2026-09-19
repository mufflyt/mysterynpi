# Surname particles that are naming convention, not identity.

A token match on \`"DE"\`, \`"VAN"\` or \`"ST"\` is evidence of a naming
convention, not of identity; admitting them joins every \`DE LA CRUZ\`
to every \`DE LEON\` sharing a given name.

## Usage

``` r
SURNAME_PARTICLES
```

## Details

KNOWN LIMITATION: \`"DO"\` IS BOTH A PARTICLE AND A STANDALONE SURNAME.
\`"do"\` is a genuine Portuguese/Lusophone particle ("of the", as in
surnames built like \`"do Carmo"\`), which is why it is listed here –
but it is ALSO, unrelatedly, a common standalone Vietnamese surname (the
same collision \[strip_name_noise()\]'s DO carve-out and
\[SURNAME_CREDENTIAL_COLLISIONS\] exist for, in a different function).
\[parse_person()\]'s \`format = "surname_first"\` particle walk cannot
tell these apart: \`parse_person("Do Nguyen Van", format =
"surname_first")\` reads leading \`"Do"\` as a particle and walks one
token further to capture what it assumes is the surname root, corrupting
a real Vietnamese surname ("Do") into a false compound ("Do Nguyen")
while losing the real given name ("Van") – yet removing \`"DO"\` from
this list would equally break the genuine Portuguese case (\`"Do Carmo
Silva Maria"\` would then read as surname \`"Do"\` alone, losing
\`"Carmo"\`). Both are real populations in a US provider directory and
this package has no evidence either is rarer than the other, so –
matching the precedent already set for the identical shape elsewhere in
this package – this is documented rather than resolved with an unproven
directional guess. Found 2026-09-18. A caller who knows their source
data's naming convention should resolve the ambiguity before calling in
(e.g. skip \`format = "surname_first"\` for a source known to be
Vietnamese-surname-first with no particles).
