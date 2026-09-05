# Changelog

## mysterynpi (development version)

- Testing patterns imported from the public name-matching ecosystem,
  each credited in the file that carries it: a golden verdict corpus
  where every row must reproduce exactly and every new hard case joins
  the corpus in the PR that fixes it (datamade/probablepeople, MIT);
  fixture provenance headers enforced by a meta-test, and a declarative
  rule registry whose generic contract battery every agreement rule
  inherits (howardjp/phonics, BSD-2-Clause); a 6,728-verdict frozen
  snapshot that refactors must reproduce bit-for-bit
  (moj-analytical-services/splink, MIT); a vendored-data drift gate
  regenerating `NICKNAME_EDGES` from its pinned commit
  (opensanctions/rigour, MIT; carltonnorthern/nicknames, Apache-2.0)
  plus semantic invariants on the table itself; a vendor-boundary
  fixture pinning the dormant humaniformat’s raw outputs; an always-on
  namespace walk backing the no-fuzzy guard so it cannot green-skip
  under R CMD check (loudness rule from derek73/python-nameparser); and
  workflow refinements – R-devel as advisory, generated docs must diff
  clean (howardjp/phonics).

- `NICKNAME_EDGES`,
  [`nickname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/nickname_agreement.md)
  — the carltonnorthern/nicknames corpus (Apache-2.0, vendored at a
  pinned commit) with a one-hop rule over it: a recorded edge or a
  shared formal name corroborates; a shared nickname never merges two
  formal names; no transitive closure, no edit distance.

- [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md),
  [`normalize_suffix()`](https://mufflyt.github.io/mysterynpi/reference/normalize_suffix.md),
  [`suffix_agreement()`](https://mufflyt.github.io/mysterynpi/reference/suffix_agreement.md)
  — the generational suffix parsed out before the noise strip deletes
  it, and the father/son veto: SR vs JR conflicts, JR vs II corroborates
  (both a second-of-name), absence decides nothing.

- [`normalize_license()`](https://mufflyt.github.io/mysterynpi/reference/normalize_license.md),
  [`license_agreement()`](https://mufflyt.github.io/mysterynpi/reference/license_agreement.md)
  — same state plus same normalised number corroborates; everything else
  is uninformative, and there is deliberately no conflicts verdict (the
  registry’s license field is partial and a quarter of NPIs carry more
  than one license).

- [`clerical_sample()`](https://mufflyt.github.io/mysterynpi/reference/clerical_sample.md),
  [`clerical_precision()`](https://mufflyt.github.io/mysterynpi/reference/clerical_precision.md)
  — a blinded, evidence-class- stratified review sample (seed required,
  class never shown, ids assigned after shuffling) and per-class
  precision with exact binomial intervals.

- The matching gate: a mutation campaign
  (`tools/ci/mutation_campaign.R`, run in CI by `matching-gate.yaml`)
  proves the tests can FAIL – eleven catalogued mutants each reintroduce
  a shipped defect (the token floor lowered, a veto loosened, absence
  read as evidence, blinding lost) and the suite must go red under every
  one. Control-first with an assertion floor, exactly-once anchors,
  byte-for-byte restore. A permutation attack over a deliberately tied
  fixture pins order-invariance of the resolver, and a parse-tree
  capability guard keeps approximate matching from arriving under an
  alias. Patterns imported from the CI of mufflyt/midwifery,
  mufflyt/twostep and mufflyt/mysterymaps.

- Contracts for each new agreement rule:
  [`assert_nickname_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_nickname_agreement_contract.md),
  [`assert_suffix_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_suffix_agreement_contract.md),
  [`assert_license_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_license_agreement_contract.md).

- [`gender_agreement()`](https://mufflyt.github.io/mysterynpi/reference/gender_agreement.md),
  [`normalize_gender()`](https://mufflyt.github.io/mysterynpi/reference/normalize_gender.md),
  [`assert_gender_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_gender_agreement_contract.md)
  — gender as a blocking signal: it may veto a candidate pair, never
  identify one. Same three-verdict contract as
  [`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md);
  absence or an unmapped code is `"uninformative"`, numeric conventions
  are refused rather than guessed, and there is no name-based gender
  inference.

- Continuous integration: `R CMD check` runs on GitHub Actions across
  Linux (devel/release/oldrel), macOS and Windows, on every push and PR
  and weekly on a schedule to catch dependency drift. Test coverage is
  measured with covr and reported to Codecov; the pkgdown site builds on
  every PR (the build is the test) and deploys to
  <https://mufflyt.github.io/mysterynpi/> on push. Dependabot keeps the
  pinned actions current.

## mysterynpi 0.1.0

Initial extraction. Nothing depends on this yet.

- [`name_key()`](https://mufflyt.github.io/mysterynpi/reference/name_key.md),
  [`blank_na()`](https://mufflyt.github.io/mysterynpi/reference/blank_na.md),
  [`has_name_information()`](https://mufflyt.github.io/mysterynpi/reference/has_name_information.md),
  [`first_initial()`](https://mufflyt.github.io/mysterynpi/reference/first_initial.md),
  [`strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/strip_parenthetical.md),
  [`split_given()`](https://mufflyt.github.io/mysterynpi/reference/split_given.md)
  — join keys where absence is never read as a value and accents cannot
  survive into a blocking key.
- [`middle_tokens()`](https://mufflyt.github.io/mysterynpi/reference/middle_tokens.md),
  [`given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/given_tokens.md),
  [`surname_tokens()`](https://mufflyt.github.io/mysterynpi/reference/surname_tokens.md),
  `SURNAME_PARTICLES`, `MIN_SURNAME_TOKEN` — tokenisation, with the
  surname-token floor pinned by value so lowering it fails a test rather
  than quietly widening every pool.
- [`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md),
  [`person_matches()`](https://mufflyt.github.io/mysterynpi/reference/person_matches.md)
  — token-set agreement. Three verdicts; `"uninformative"` is
  load-bearing and is not agreement.
- [`npi_luhn_ok()`](https://mufflyt.github.io/mysterynpi/reference/npi_luhn_ok.md).
- [`assert_middle_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_middle_agreement_contract.md)
  — the contract a caller runs in its own suite, written so it can be
  run against a stand-in and demonstrably fail.
