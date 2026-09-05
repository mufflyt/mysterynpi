# A labeled, fully synthetic roster-to-registry matching benchmark

One row per (roster record, registry candidate) pair: a free-text roster
name with the fields state boards actually hold, against NPPES-shaped
split fields, with \`truth\` (\`"match"\`/\`"nonmatch"\`) assigned BY
CONSTRUCTION and \`family\` naming the defect each pair encodes – from
\`exact\` through \`nickname\`, \`maiden-as-middle\`,
\`suffix-generations\`, \`stale-gender\`, \`spelling-trap\`,
\`cross-gender-derivative\`, \`hub-nickname\`, \`license-anchor\`,
\`stacked-defects\` and \`absence\`. 190 pairs: 132 matches, 58
nonmatches.

## Usage

``` r
ROSTER_BENCHMARK
```

## Format

data.frame, 190 rows: \`pair_id\`, \`family\`, \`truth\`, \`note\`,
\`roster_name\`, \`roster_gender\`, \`roster_state\`,
\`roster_license\`, \`npi_first\`, \`npi_middle\`, \`npi_last\`,
\`npi_suffix\`, \`npi_credential\`, \`npi_gender\`, \`npi_state\`,
\`npi_license\`.

## Source

Authored with this package; MIT like the package itself.

## Details

WHY IT EXISTS. No public benchmark for roster-to-NPPES name matching
exists, because NPPES describes real providers and a labeled gold
standard would name real people. Every pair here is synthetic and
authored in reviewable code (\`data-raw/ROSTER_BENCHMARK.R\`); surnames
come from the public-domain Census frequency file. A pair whose truth a
reviewer could not assign did not go in. The same table ships as plain
CSV for use outside R: \`system.file("extdata", "roster_benchmark.csv",
package = "mysterynpi")\`.

\`vignette("roster-benchmark")\` evaluates the package's own rules
against it and shows the \[clerical_sample()\] /
\[clerical_precision()\] workflow.
