# Fail closed: no nickname-only candidate may be auto-accepted

The acceptance-side guard of \[NICKNAME_POLICY\]. Give it the frame of
candidates an automated step is about to accept; it errors – naming the
offending NPIs and the edges that produced them – if any row is
\`review_only\`, i.e. reachable ONLY through nickname expansion. Rows a
human reviewer has since verified belong in a separate, adjudicated
acceptance path, not in the automated one this guard protects.

## Usage

``` r
assert_nickname_policy(accepted)
```

## Arguments

- accepted:

  a data.frame produced by \[npi_search()\] (it must carry the
  \`review_only\` lineage column) holding the rows about to be
  auto-accepted.

## Value

\`accepted\`, invisibly, when the policy holds.
