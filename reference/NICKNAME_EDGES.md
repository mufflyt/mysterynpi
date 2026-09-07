# Formal-name / nickname edges, vendored from carltonnorthern/nicknames

One row per recorded (formal name, nickname) pair, both sides uppercased
with periods removed. The relation is DIRECTIONAL: \`name\` is the
formal side, \`nickname\` the hypocorism. It is not closed transitively,
and \[nickname_agreement()\] deliberately never closes it (see the file
header: AL must not merge ALBERT with ALEXANDER).

## Usage

``` r
NICKNAME_EDGES
```

## Format

data.frame with columns \`name\`, \`nickname\`, \`edge_id\`; one row per
edge. Attributes: \`version\` (the dictionary version string) and
\`checksum\` (an integrity pin over the edge ids).

## Source

<https://github.com/carltonnorthern/nicknames> (Apache-2.0; the license
text is installed as \`system.file("nicknames-LICENSE", package =
"mysterynpi")\`).

## Details

Vendored at a pinned commit by \`data-raw/NICKNAME_EDGES.R\`; updating
the pin is a code change, reviewed like one, because a row added here
can move a verdict from \`"conflicts"\` to \`"corroborates"\`.

Every row carries a stable \`edge_id\` (\`NAME\>NICKNAME\` –
content-derived, so it survives reordering and insertion), and the table
carries a \`version\` attribute bumped on any edge change;
\[nickname_variants()\] stamps both onto every query it plans, so any
fan-out a search performs is attributable to one versioned row of this
table.
