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

data.frame with columns \`name\`, \`nickname\`; one row per edge.

## Source

<https://github.com/carltonnorthern/nicknames> (Apache-2.0; the license
text is installed as \`system.file("nicknames-LICENSE", package =
"mysterynpi")\`).

## Details

Vendored at a pinned commit by \`data-raw/NICKNAME_EDGES.R\`; updating
the pin is a code change, reviewed like one, because a row added here
can move a verdict from \`"conflicts"\` to \`"corroborates"\`.
