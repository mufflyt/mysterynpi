# The institution in a CMS medical-school name

CMS maps every clinician's education through a MEDICAL-school code list,
so a nurse-midwife, nurse practitioner or physician assistant trained at
a university's nursing or health-professions school arrives as
"\<University\> SCHOOL OF MEDICINE". Read verbatim, that says the
clinician holds an MD. Other directories built on the same CMS field
(commercial provider directories among them) carry the identical
strings. This returns the institution and drops the medical unit.

## Usage

``` r
strip_med_suffix(x)
```

## Arguments

- x:

  character vector of school names (a factor is read as its labels; an
  all-\`NA\` vector of any type is allowed).

## Value

character vector the same length as \`x\`: the institution, the input
unchanged when no rule applies, and \`NA\` where \`x\` is \`NA\`.

## Details

Three rules, each written for a string that came out wrong before it:

1\. \*\*A trailing unit is removed\*\*: "GEORGETOWN UNIVERSITY SCHOOL OF
MEDICINE" gives "GEORGETOWN UNIVERSITY". Phrases are tried longest first
(\[MEDICAL_UNIT_PATTERNS\]). At least one character must precede the
unit, so a phrase that opens the name is never taken for a suffix. 2.
\*\*A named school of a university gives the university\*\*: when the
unit is followed by "at", "of" or a comma and then a university, the
words before the unit are the school's own name. "BRODY SCHOOL OF
MEDICINE AT EAST CAROLINA UNIVERSITY" gives "EAST CAROLINA UNIVERSITY",
not "BRODY". 3. \*\*A strip that leaves no institution is refused\*\*:
when what would remain contains no institution word (university,
college, institute), the medical phrase is the institution's name and
that step is skipped. "BAYLOR COLLEGE OF MEDICINE", "OHIO MEDICAL
UNIVERSITY" and "PHILADELPHIA COLLEGE OF OSTEOPATHIC MEDICINE" come back
whole, not as "BAYLOR", "OHIO" and "PHILADELPHIA". Refusing one step
does not refuse the rest: "MEHARRY MEDICAL COLLEGE SCHOOL OF MEDICINE"
gives "MEHARRY MEDICAL COLLEGE".

Matching ignores case and the result keeps the input's case, so it can
be applied to raw strings either way. It names an institution, not a
programme: it cannot tell a nursing school from the medical school of
the same university, and a school that has no medical school (Frontier
Nursing University) never appears in the CMS field to begin with.

## Examples

``` r
strip_med_suffix(c(
  "GEORGETOWN UNIVERSITY SCHOOL OF MEDICINE",
  "Perelman School of Med at the University of Pennsylvania",
  "BAYLOR COLLEGE OF MEDICINE",
  "MEDICAL UNIVERSITY OF SOUTH CAROLINA COLLEGE OF MEDICINE",
  NA))
#> [1] "GEORGETOWN UNIVERSITY"               
#> [2] "University of Pennsylvania"          
#> [3] "BAYLOR COLLEGE OF MEDICINE"          
#> [4] "MEDICAL UNIVERSITY OF SOUTH CAROLINA"
#> [5] NA                                    
```
