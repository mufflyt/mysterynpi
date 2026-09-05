# Count RIVAL ids: alternative claimants who are a different PERSON

THE DEFECT THIS PREVENTS, which cost two false demotions before it was
understood. A temporal registry's unit is (candidate x snapshot x name
variant), NOT candidate. One person recorded with a middle initial in
one snapshot and without it in another supplies BOTH a conflicting and a
non-conflicting row – so a naive \`n_distinct(candidate\[conflict\])\`
counts a person as evidence AGAINST the match that belongs to them. Two
real NPIs were vetoed by themselves this way.

## Usage

``` r
count_rivals(vetoed, won, id = "id")
```

## Arguments

- vetoed:

  data.frame with \`id\` and \`vetoed\` columns: candidates removed by
  some veto, recorded BEFORE the veto was applied.

- won:

  data.frame with \`id\` and \`candidate\`: what actually won, one row
  per id. \`NA\` candidate means the person matched nothing, so every
  vetoed alternative is a genuine rival.

- id:

  the identifier column name in both frames.

## Value

data.frame(id, n_rivals).

## Details

Anything that counts "alternative candidates" must exclude the one that
won.
