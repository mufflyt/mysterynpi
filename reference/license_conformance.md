# Does each license fit the shape its state's board actually issues?

THE FORMAT TABLE IS LEARNED FROM THE COLUMN, NOT VENDORED. A
hand-curated fifty-state table of board formats would rot the day a
board changed its numbering, and this package would have no way to
notice. What a board file itself knows is better evidence: within one
state, the overwhelming majority of rows carry the board's real format,
and a row shaped like nothing else in its state – a stray \`MD\` prefix,
a trailing \`A\`, a pasted-in NPI – is exactly the row that will corrupt
a blocking key.

## Usage

``` r
license_conformance(license, state, min_share = 0.01)
```

## Arguments

- license, state:

  character vectors of the same length: the recorded number and its
  issuing state.

- min_share:

  shapes rarer than this within their state, other than the modal shape,
  are flagged. Default 0.01.

## Value

data.frame: the \[license_anatomy()\] columns plus \`state\`,
\`shape_share\`, \`state_modal_shape\`, \`flagged\`.

## Details

For each row this reports its \[license_anatomy()\] shape, the share of
its state's rows carrying that shape, the state's modal shape, and a
flag: \`flagged\` when the shape is not the modal one AND its share
falls below \`min_share\`. A state can legitimately issue several
formats (numbering eras); those survive because their shapes are common,
not because anyone listed them. The flag marks rows for REVIEW before
blocking – it never silently rewrites a number, because whether \`MD\`
was meaning or junk is a decision that belongs in reviewed code, not
inside a cleaner.

Rows with no usable license or state get \`NA\` throughout and are
counted in no denominator.
