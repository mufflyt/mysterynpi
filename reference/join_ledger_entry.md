# The accounting for one join, from its inputs and its output

Pure arithmetic, engine-agnostic: hand it the two inputs, the result,
and the keys – from \[ledgered_join()\], from a dplyr pipeline, from
anything – and it returns the one-row ledger. The load-bearing column is
\`conserved\`: the row count the join SHOULD have produced is recomputed
from the inputs (matched pairs plus whatever the join kind keeps), and
\`conserved\` says whether the output actually has it. \`FALSE\` means
rows were lost or manufactured somewhere the call site cannot see –
including by an engine that matched NA keys to each other.

## Usage

``` r
join_ledger_entry(x, y, out, by, kind, step = "join")
```

## Arguments

- x, y:

  the join inputs.

- out:

  the join result.

- by:

  character: shared key columns, or a named vector mapping x columns to
  y columns (\`c(npi = "provider_npi")\`).

- kind:

  \`"left"\`, \`"inner"\`, \`"full"\`, or \`"right"\`.

- step:

  a label for the ledger – which join, in which script.

## Value

one-row data.frame: \`step\`, \`kind\`, \`by\`, \`rows_x\`, \`rows_y\`,
\`rows_out\`, \`rows_expected\`, \`matched_pairs\`, \`unmatched_x\`,
\`unmatched_y\`, \`na_key_x\`, \`na_key_y\`, \`match_rate_x\`,
\`max_fanout\`, \`conserved\`. NA-key rows count as unmatched on their
side, never as matched: absence is not evidence of anything, including a
match.

## Details

Accumulate entries with \`rbind()\` across a pipeline and ship the frame
with the study: it is the row-count reconciliation table a reviewer can
read without running anything.
