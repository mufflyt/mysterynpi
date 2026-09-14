# Medical-school unit phrases, longest first

The trailing academic units \[strip_med_suffix()\] removes from a school
name. Derived from the strings CMS actually uses for non-physician
clinicians in the Doctors and Clinicians file (the dental schools and
"college of physicians and surgeons" are CMS taxonomy noise, and are in
the list for that reason). The order matters: a shorter phrase must
never match first and leave the tail of a longer one ("COLLEGE OF
MEDICINE" before "COLLEGE OF MED", which would otherwise leave "INE").

## Usage

``` r
MEDICAL_UNIT_PATTERNS
```
