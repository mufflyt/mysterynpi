# The nickname ablation (2026-09-07): reproducible pieces

Governing evidence of `NICKNAME_POLICY` ("nickname-policy-2026-09-07").
Full appendix: vignette("nickname-policy") and the published artifact
referenced there; raw outputs and the candidate-layer harness live in
`~/Dropbox (Personal)/mysterynpi-nickname-ablation-2026-09-07/`.

- `exp2_verdict_layer.R` — the verdict-layer A/B on ROSTER_BENCHMARK plus
  the ghost negative controls, pre-registration in the header. Rerunnable
  anywhere this package installs: `Rscript tools/ablation/exp2_verdict_layer.R`
  (its counts are pinned in tests/testthat/fixtures/ablation/).
- `per_edge_exp1b.csv` — the per-edge incremental-candidate ledger from the
  candidate-layer experiment (221 human-adjudicated anchors, 40k-row NPPES
  pool): 34 edges fired, one participated in the single rescue.

The candidate-layer experiment itself needs the human-adjudicated anchor
fixtures (isochrones worktree) and is therefore archived in Dropbox rather
than vendored here.
