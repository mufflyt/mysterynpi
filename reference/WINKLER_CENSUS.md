# Winkler's synthetic census pairs, via the SecondString project

Two relations of SYNTHETIC person records (A: 449 rows, B: 392) authored
by William Winkler for record-linkage evaluation and distributed with
the SecondString project. Deliberately full of classic name pathology:
typos (\`BENITEZ\`/\`BENETAS\`), truncated and swapped given names
(\`LEARONAD\`/\`LENARD\`), and household confusion. An \`id\` present in
BOTH relations is the same synthetic person – 327 labeled matches.
Eleven ids additionally repeat within a relation; those duplicates are
kept, and \[duplicate_differences()\] is how to look at them. No real
individual is described.

## Usage

``` r
WINKLER_CENSUS
```

## Format

data.frame with columns \`relation\`, \`id\`, \`surname\`, \`given\`,
\`middle\`, \`house\`, \`street\`; 841 rows.

## Source

<https://github.com/TeamCohen/secondstring> (\`data/censusText.txt\`,
pinned commit in \`data-raw/WINKLER_CENSUS.R\`). License: Carnegie
Mellon University, 2003, permissive with notice retention – shipped as
\`system.file("secondstring-LICENSE", package = "mysterynpi")\`.
