# Is a record's taxonomy consistent with a board specialty? Three-valued.

Inspects the FULL pipe-concatenated code string, never just the first
code: an NPPES record may retain a residency code (\`390200000X\`) ahead
of \`207V00000X\`, and a first-segment shortcut misreads that clinician
as a non-physician (a real review-tool defect from the 2026-09-19
promotion audit, caught because the audit's full-string screen disagreed
with it).

## Usage

``` r
taxonomy_consistent(taxonomy, expected)
```

## Arguments

- taxonomy:

  character vector of pipe-concatenated NUCC codes (empty segments
  tolerated).

- expected:

  character vector of pipe-separated prefix patterns, e.g. from
  \[taxonomy_family_pattern()\].

## Value

logical vector: \`TRUE\` / \`FALSE\` / \`NA\`.

## Details

Returns \`TRUE\` when any code in the record starts with any expected
prefix, \`FALSE\` when codes exist and none do (a wrong-person signal),
and \`NA\` when the record has no codes OR no expectation is defined –
three-valued on purpose, so unknown can never read as clean.

## See also

Other taxonomy-agreement:
[`TAXONOMY_FAMILY_PATTERNS`](https://mufflyt.github.io/mysterynpi/reference/TAXONOMY_FAMILY_PATTERNS.md),
[`taxonomy_family_pattern()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_family_pattern.md),
[`taxonomy_tiebreak_rank()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_tiebreak_rank.md)
