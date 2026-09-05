# The mapping that was applied, per source, as a document

A normalisation nobody can audit is a normalisation nobody should trust.
For each source (a state, a file, a download date – whatever the caller
names), this records every RAW status the source carried, the class it
was mapped to, and how many rows carried it – including the unmapped
ones, listed first, because an unmapped status is a decision waiting to
be made, not a rounding error. \`FL: Deceased(350) -\> deceased\` is a
line a reviewer can check against the board's own site; "we normalised
statuses" is not.

## Usage

``` r
license_status_audit(status, source, levels = LICENSE_STATUS_LEVELS)
```

## Arguments

- status:

  character vector of recorded license statuses.

- source:

  character vector, the same length: which document each row came from
  (\`"FL"\`, \`"IL-2026-08"\`, a filename).

- levels:

  see \[normalize_license_status()\]; passed through, so the audit
  records the SAME mapping the pipeline applied.

## Value

data.frame, one row per (source, raw status): \`source\`,
\`status_raw\`, \`class\` (\`NA\` when unmapped), \`n\`, \`mapped\`.
Unmapped rows sort first within each source, then by descending count.

## Details

The returned frame IS the methods-appendix table: write it next to the
artifact it describes and ship it with the study. Rerun on refreshed
data, its diff shows exactly which vocabulary the boards changed.
