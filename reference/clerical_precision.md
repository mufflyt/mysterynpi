# Per-class precision from a completed clerical review

Joins the reviewer's verdicts back to the blinding key and reports, per
evidence class: rows sampled, rows reviewed, matches confirmed,
precision, and an exact binomial confidence interval
(\[stats::binom.test()\]). Unreviewed rows are counted and excluded,
never imputed; a class reviewed at zero rows gets \`NA\` precision, not
a flattering blank.

## Usage

``` r
clerical_precision(key, verdicts, class = "evidence_class", conf.level = 0.95)
```

## Arguments

- key:

  the \`key\` frame from \[clerical_sample()\].

- verdicts:

  data.frame with \`review_id\` and \`is_match\` (logical; \`NA\` means
  not reviewed). Unknown review ids error – a verdict that matches no
  sampled row is a transcription failure, not data.

- class:

  column name of the class in \`key\`.

- conf.level:

  confidence level for the interval.

## Value

one row per class: \`n_sampled\`, \`n_reviewed\`, \`n_match\`,
\`precision\`, \`ci_low\`, \`ci_high\`.
