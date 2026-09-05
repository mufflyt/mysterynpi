# Do two surnames agree, disagree, or decide nothing?

THE GAP THIS CLOSES. Until this rule existed the package compared
surnames only by exact equality inside \[person_matches()\], while every
other axis had a three-verdict rule. Surnames are the axis where that
hurts most: hyphenated surnames ran 27.1 one measured crosswalk, and
marriage moves a surname wholesale.

## Usage

``` r
surname_agreement(a, b, middle_a = NULL, middle_b = NULL)
```

## Arguments

- a, b:

  character vectors of surnames, the same length. Raw strings are fine;
  \[name_key()\] normalisation is applied internally.

- middle_a, middle_b:

  optional character vectors of the SAME record's raw middle-name
  strings, enabling the cross-slot rescue: \`middle_a\` belongs with
  \`a\`, and is searched for \`b\`'s surname components (and vice
  versa). \`NULL\` skips the rescue. Apostrophes are erased before every
  comparison this rule makes: \`O'BRIEN\` vs \`OBRIEN\` is one surname
  written two ways, and a formatting difference must not become a veto.
  \[name_key()\] itself keeps the apostrophe – it is a join key with its
  own parity contract – so the erasure is local to this rule.

## Value

character: \`"corroborates"\`, \`"conflicts"\`, or \`"uninformative"\`
(either surname absent or reduced to nothing by normalisation).

## Details

FOUR STEPS, EACH ONE EARNING ITS PLACE:

1\. Exact \[name_key()\] equality corroborates. This runs FIRST so that
surnames below the token floor still compare: \`LEE\` vs \`LEE\` is real
agreement even though \`LEE\` is too short to be a blocking token. 2. A
shared component from \[surname_tokens()\] corroborates:
\`MCCARTHY-DERVIN\` shares \`MCCARTHY\` with \`MCCARTHY\`. Particles
never count – \`DE LA CRUZ\` and \`DE LEON\` share only convention. 3.
THE MAIDEN-AS-MIDDLE RESCUE. A changed surname often survives in the
OTHER record's middle slot: \`KATHERINE REINHARD RYE\` against
\`KATHERINE A. REINHARD\` holds the surname \`REINHARD\` as a middle
token. When the surnames themselves share nothing, a full surname
component (\>= \[MIN_SURNAME_TOKEN\]) found among the other side's
middle tokens corroborates. Pass the raw middle strings via
\`middle_a\`/\`middle_b\`; without them this step is skipped, never
guessed. 4. Otherwise, two recorded surnames that share nothing
conflict.

USE THE CONFLICT WITH THE SAME DISCIPLINE AS THE GENDER VETO. In a
cohort where marriage-related change is plausible – most physician
cohorts – total surname disagreement alongside top-class agreement on
everything else is a case for quarantine and review, not silent
deletion. See \`vignette("vetoes-and-quarantine")\`.
