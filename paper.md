# Summary

Health services research routinely needs to answer one deceptively
simple question: does this row of a clinician roster describe the same
person as that row of the National Plan and Provider Enumeration System
(NPPES)? `mysterynpi` is an R package holding one shared definition of
the name-handling that linkage needs: transliterating join keys,
given/middle/surname tokenisation, and a family of **three-verdict
agreement rules** – `"corroborates"`, `"conflicts"`, `"uninformative"` –
covering middle names, given names with a vendored nickname corpus,
surnames with a maiden-as-middle rescue, generational suffixes, recorded
gender, and state license numbers. Absence is always `"uninformative"`,
never evidence of difference; this is the Fellegi–Sunter comparison
vector \[@fellegi1969\] made explicit, deterministic and auditable,
without estimated weights. Ordered evidence classes replace blended
scores, a one-to-one constraint quarantines contested candidates, and a
blinded, class-stratified clerical-review sampler converts the audit
trail into per-class precision estimates with exact intervals.

# Statement of need

Probabilistic linkage tools are mature – `splink` \[@linacre2022\],
`fastLink` \[@enamorado2019\], `reclin2` \[@vanderlaan2022\] – but
studies that must defend every published match in clinical and workforce
contexts often prefer deterministic, named rules whose failure modes are
enumerable. In practice those rules are re-implemented ad hoc in every
pipeline, and the copies drift. Every rule in `mysterynpi` encodes a
defect that already shipped in a real physician linkage (a positional
middle-name comparison silently deleted 82 true candidates; a fuzzy
surname pass admitted `JULIA`/`JULIE`), and each ships with the test
that catches its return plus an `assert_*_contract()` a downstream
pipeline runs in its own suite, so a breaking change fails in the
caller’s CI rather than in its published numbers.

The package also fills an evaluation gap: no public labeled benchmark
for roster-to-NPPES name matching exists, because NPPES describes real
providers \[@bindman2013\]. `ROSTER_BENCHMARK` provides 190 fully
synthetic pairs, truth assigned by construction, organised by defect
family (nickname, maiden-as-middle, generational suffixes, cross-gender
derivative names, stale gender codes, license coincidences), alongside
Winkler’s synthetic census pairs and the public-domain Census surname
frequency file.

# Quality control

Beyond a conventional test suite (650+ assertions, five-platform
continuous integration), correctness is enforced by mechanisms uncommon
in this field: a mutation campaign in which thirteen catalogued mutants
each reintroduce a shipped defect and the suite must fail under every
one; a frozen snapshot of 7,300+ verdicts that refactors must reproduce
bit-for-bit; a golden corpus in which every labeled example is its own
exact-match test; permutation attacks proving resolution is a property
of the data rather than row order; and parse-tree guards that fail the
build if approximate string matching enters the package under any alias.

# Acknowledgements

The nickname corpus is vendored from carltonnorthern/nicknames
(Apache-2.0); the synthetic census pairs from the SecondString project
\[@cohen2003\] (Carnegie Mellon University license); surname frequencies
from the U.S. Census Bureau (public domain).

# References
