# Calibrated bands for \[graduation_year_agreement()\].

PROVISIONAL. The weights are likelihood ratios measured against a SILVER
standard – high-confidence incumbent links treated as matches, every
other candidate of the same person treated as a non-match – not against
adjudicated pairs. They are shipped as data, like \[NICKNAME_EDGES\], so
a study with its own calibration supplies its own table: a reviewable
data decision rather than a code change. Re-estimate once an adjudicated
truth set exists.

## Usage

``` r
GRADUATION_YEAR_BANDS
```

## Format

data.frame, one row per band, ordered from the strongest evidence for a
link to the strongest against:

- band:

  character label, also what \[graduation_year_band()\] returns

- lo,hi:

  inclusive bounds on \`d\`, in years; \`Inf\`/\`-Inf\` at the ends

- verdict:

  what \[graduation_year_agreement()\] reports for the band

- log2_lr:

  log2 likelihood ratio for a caller that scores; 0 where the band
  decides nothing

## Source

Measured on 8,681 likely matches and 170,827 likely non-matches, AMCB
certificants against a commercial provider directory (snapshot
2026-06-25). Coverage of the graduation year in that directory is about
half of linked clinicians, and it originates in CMS DAC, so it exists
only for Medicare-enrolled clinicians.

## Details

THE BANDS ARE SIGNED, AND THAT IS THE POINT. \`d = graduation -
credentialing\`. Finishing a programme and then credentialing is the
ordinary sequence; credentialing and then graduating is not, and the
measurement says so:


       d    likelihood ratio
       0        43.8
      -1        10.2
      +1         1.8     <- the same |d|, roughly six times weaker

A symmetric "within 1 year" band averages a strong signal with a weak
one. Two independent implementations over the same directory snapshot
reached that conclusion; the second also found the middle bands
NEGATIVE, so a caller that scores \`\|d\|\` of 2 or 3 as evidence FOR a
link has the sign wrong (see \`log2_lr\` below, and the note in
\[graduation_year_agreement()\]).
