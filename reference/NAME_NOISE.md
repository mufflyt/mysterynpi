# Credential and title tokens seen in provider directories.

Stripped BEFORE parsing: a name parser has no way to know \`CRNP\` is
not a middle name.

## Usage

``` r
NAME_NOISE
```

## Details

The vocabulary began nursing/midwifery-centric. The final block was
added from an all-provider-type source (the 2026-09-13 OpenSanctions
Medicaid exclusion linkage, 8,450 sanctioned individuals): the NPPES
credential column there showed DC on 314 providers, DDS 248, LPN 130,
DPM 114, DMD 101, PA 73, with OD, PSYD, PHARMD, RPH, LVN, LCSW and DPT
at lower counts – none of which were in the vocabulary, so any of them
appearing in a name string sailed through \[strip_name_noise()\] into a
parsed name slot. Short ambiguous tokens (PA, OD, DC) follow the
precedent already set by MS, MA, DO and LM: in a PROVIDER-DIRECTORY name
string the credential reading is overwhelmingly the correct one.

THAT "MA" PRECEDENT WAS WRONG. \`"Ma"\` is a top-20 Chinese surname
(Yo-Yo Ma, Jack Ma) with the same shape as the \`"Do"\` collision below
– a single token that is BOTH a real NAME_NOISE credential (Master of
Arts) AND a common real surname – and it was carrying none of \`"Do"\`'s
protection: \`strip_name_noise("John Ma")\` silently returned
\`"John"\`, and since \[parse_person()\] threads its result through
\[has_name_information()\], that record read as unqueryable and would be
silently dropped exactly like the pre-fix \`"Do"\` case (see
\[strip_name_noise()\]'s "THE DO CARVE-OUT" docs for the DEA-action
provenance of that original defect). Found 2026-09-18; given the SAME
carve-out \`"Do"\` already has, via \[SURNAME_CREDENTIAL_COLLISIONS\].
The other short, ambiguous tokens named above (PA, OD, DC, MS, LM, BA)
are NOT known common surnames the way "Do" and "Ma" are – protecting
them would invent a fake surname for a genuinely credential-only input
rather than recover a real one, so they are deliberately left stripped
unconditionally. This is a claim about which token spellings are real
surnames, not a general policy reversal for the vocabulary.
