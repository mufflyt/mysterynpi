# Join with the cardinality declared, verified, and ledgered

A join whose row count cannot silently surprise you.

## Usage

``` r
ledgered_join(
  x,
  y,
  by,
  kind,
  relationship,
  unmatched = c("ledger", "error"),
  min_match_rate = 0,
  step = "join"
)
```

## Arguments

- x, y:

  data.frames.

- by:

  character: shared key columns, or a named vector mapping x columns to
  y columns.

- kind:

  \`"left"\`, \`"inner"\`, \`"full"\`, or \`"right"\`.

- relationship:

  required; verified, never assumed.

- unmatched:

  \`"ledger"\` (record) or \`"error"\` (stop when the join would drop
  unmatched rows).

- min_match_rate:

  stop when \`match_rate_x\` falls below this. 0 – the default – checks
  nothing, deliberately visibly.

- step:

  ledger label.

## Value

list of \`result\` (deterministically sorted by key) and \`ledger\` (one
row). \`rbind()\` the ledgers across a pipeline.

## Details

\* \*\*The relationship is DECLARED and VERIFIED\*\* – dplyr 1.1's
values, verbatim: \`"one-to-one"\`, \`"one-to-many"\`,
\`"many-to-one"\`, \`"many-to-many"\`. A duplicate key on a side
declared unique stops the run and names the offending keys. There is
deliberately no default: declaring what the join may do to the row count
is the point, and a guessed cardinality is how fan-out ships. \*
\*\*\`unmatched = "error"\`\*\* (dplyr's semantics): stop if the join
DROPS unmatched rows – both sides for \`"inner"\`, the y side for
\`"left"\`, the x side for \`"right"\`, nothing for \`"full"\` (it drops
nothing). The default \`"ledger"\` records the counts and lets policy
live with the caller. \* \*\*\`min_match_rate\`\*\*: the share of x rows
that must match, for joins where silent loss is the risk. The default 0
is NOT a check – that is the lesson of the deprecated isochrones
safe_join, whose \`expected_min = 0\` let 100 join in a pipeline should
always declare one. \* \*\*NA keys never match\*\* (see the file
header); by join kind they are kept as unmatched rows or dropped, and
either way the ledger counts them.

The result returns with its \[join_ledger_entry()\], and the entry's
\`conserved\` flag is additionally ASSERTED here – a ledgered join that
fails its own arithmetic is a bug in this package, and stops.
