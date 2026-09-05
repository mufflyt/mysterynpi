# Changelog

## mysterynpi (development version)

- [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  and
  [`parse_npi_search()`](https://mufflyt.github.io/mysterynpi/reference/parse_npi_search.md)
  — query the public NPPES registry for the fields a linkage wants:
  names, honorific, suffix, credential, gender (normalised, raw code
  kept), practice ZIP and state, enumeration date with
  `years_enumerated` (a lower bound on years in practice — NPI
  enumeration began in 2005), and vintage as `last_updated` plus
  `retrieved`. NPPES’s three spellings of absence (missing key, empty,
  `"--"`) all become `NA`, so a sentinel can never fake a suffix veto.
  There is deliberately no birth-year column: NPPES does not publish
  one. The parser is pure and fixture-tested; only
  [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  touches the network, and no test does.
- [`license_anatomy()`](https://mufflyt.github.io/mysterynpi/reference/license_anatomy.md),
  [`license_conformance()`](https://mufflyt.github.io/mysterynpi/reference/license_conformance.md)
  — for state medical board files, where the license number is about to
  become a blocking variable: decompose each number into prefix / digits
  / suffix and a `#`-shape, then flag rows whose shape fits nothing else
  their state’s board issues. The format table is learned from the
  column, never vendored, so a board whose real format carries a prefix
  keeps it and a stray `MD` on a bare-number board gets flagged for
  review — flagged, not rewritten.

## mysterynpi 0.2.0

- [`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md),
  [`assert_surname_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_surname_agreement_contract.md)
  — the axis that only had exact equality gets its three-verdict rule:
  exact key equality corroborates even below the token floor
  (`LEE`/`LEE`), shared components span hyphenation and dropped parts,
  apostrophes are folded (`O'BRIEN`/`OBRIEN`), particles never count,
  and the maiden-as-middle rescue corroborates a changed surname
  surviving in the other record’s middle slot. Conflicts deserve
  quarantine discipline in marriage-plausible cohorts — see the new
  vignette.

- **Verdict change** (the contracts call this a major-bump class of
  change, absorbed into 0.2.0):
  [`nickname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/nickname_agreement.md)
  now treats a single letter as an initial, not a nickname — `"J"` vs
  `"JAMES"` moves from `"conflicts"` to `"corroborates"` (compatibility,
  never identity), `"J"` vs `"ROBERT"` still conflicts. Mirrors
  [`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md)’s
  initial semantics; closes the initials residual from issue
  [\#3](https://github.com/mufflyt/mysterynpi/issues/3). The verdict
  snapshot was regenerated and the diff reviewed.

- New vignette `vetoes-and-quarantine`: the deterministic policy for
  error-prone-field conflicts — veto in weaker evidence classes,
  quarantine at the strongest, record every veto.

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
