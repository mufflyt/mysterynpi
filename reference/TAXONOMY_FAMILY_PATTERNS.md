# NUCC family patterns for board specialties (identity screen only)

Named character vector: board-specialty label -\> pipe-separated NUCC
code prefixes a genuinely-that-specialty clinician's record may carry.
Absence from this table means "no expectation defined", which
\[taxonomy_consistent()\] reports as \`NA\`, never as a pass or a fail.
Deliberately coarse: prefixes name profession-level families, not
subspecialty codes, because subspecialty is board data's to decide.

## Usage

``` r
TAXONOMY_FAMILY_PATTERNS
```

## See also

Other taxonomy-agreement:
[`taxonomy_consistent()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_consistent.md),
[`taxonomy_family_pattern()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_family_pattern.md),
[`taxonomy_tiebreak_rank()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_tiebreak_rank.md)
