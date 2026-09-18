# Does a graduation year agree with a credentialing year?

THE GAP THIS CLOSES. Every other rule in this package compares a name. A
name is the axis registries agree on precisely because they copy each
other: in one measured pair of national sources, the directory's first
name matched NPPES for 100 taxonomy 99.75 not two sources agreeing. The
graduation year is the first field measured that is genuinely
independent: it equals the credentialing year for 70.4 true links but
the NPI's own enumeration year for only 39.4 the person's training, not
the registry's paperwork.

## Usage

``` r
graduation_year_agreement(
  credentialing_year,
  graduation_year,
  bands = GRADUATION_YEAR_BANDS
)
```

## Arguments

- credentialing_year, graduation_year:

  integer-ish vectors, the same length or one of length 1. Order
  matters: the difference is \`graduation_year - credentialing_year\`,
  so a NEGATIVE band means the person graduated BEFORE they
  credentialed.

- bands:

  the band table; defaults to \[GRADUATION_YEAR_BANDS\].

## Value

character: \`"corroborates"\`, \`"conflicts"\`, or \`"uninformative"\`.

## Details

THREE VERDICTS, SAME CONTRACT AS \[middle_agreement()\].

\* \`"corroborates"\` – the years are the same, or one year apart.
Strength is NOT symmetric; see \[GRADUATION_YEAR_BANDS\]. \*
\`"uninformative"\` – either year is absent, OR the gap falls in the
middle bands (2 to 10 years either way). Absence is about 47 source
measurement, so a caller that reads \`"uninformative"\` as disagreement
discards half its population. The middle bands are reported as
uninformative rather than as a conflict because no single one of them is
strong enough to veto a link — but be clear about what the verdict costs
a caller that reads only verdicts: among pairs where BOTH years are
known, landing in a middle band is about five times more likely for a
non-match than a match (8.4 evidence, and the three-verdict vocabulary
this package shares across its rules has no way to say "weakly against".
A caller that scores must therefore take the middle bands from
\`log2_lr\`, where the sign is explicit; a caller that scores a
2-to-3-year gap as evidence FOR a link has it backwards. \*
\`"conflicts"\` – beyond ten years either way.

USE THE CONFLICT AS A FLAG, NOT A VETO, with the discipline
\[surname_agreement()\] documents. Beyond ten years has an innocent
reading in both directions: an earlier degree in another discipline, or
a doctorate taken later. In the cohort this was measured on, that band
is 2.5 high-confidence links but 47.6 sensitivity analysis. Quarantine
and review; do not delete.

## See also

\[GRADUATION_YEAR_BANDS\] for the weights and their provenance,
\[graduation_year_band()\] for the band a pair falls in.

## Examples

``` r
graduation_year_agreement(2015, 2015)   # "corroborates"
#> [1] "corroborates"
graduation_year_agreement(2015, 2014)   # "corroborates" (the ordinary order)
#> [1] "corroborates"
graduation_year_agreement(2015, 2017)   # "uninformative" (weakly against)
#> [1] "uninformative"
graduation_year_agreement(2015, 1980)   # "conflicts" -- a flag, not a veto
#> [1] "conflicts"
graduation_year_agreement(2015, NA)     # "uninformative"
#> [1] "uninformative"
```
