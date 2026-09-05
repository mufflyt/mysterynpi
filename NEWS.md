# mysterynpi (development version)

* `NICKNAME_EDGES`, `nickname_agreement()` — the carltonnorthern/nicknames
  corpus (Apache-2.0, vendored at a pinned commit) with a one-hop rule over
  it: a recorded edge or a shared formal name corroborates; a shared nickname
  never merges two formal names; no transitive closure, no edit distance.
* `extract_suffix()`, `normalize_suffix()`, `suffix_agreement()` — the
  generational suffix parsed out before the noise strip deletes it, and the
  father/son veto: SR vs JR conflicts, JR vs II corroborates (both a
  second-of-name), absence decides nothing.
* `normalize_license()`, `license_agreement()` — same state plus same
  normalised number corroborates; everything else is uninformative, and there
  is deliberately no conflicts verdict (the registry's license field is
  partial and a quarter of NPIs carry more than one license).
* `clerical_sample()`, `clerical_precision()` — a blinded, evidence-class-
  stratified review sample (seed required, class never shown, ids assigned
  after shuffling) and per-class precision with exact binomial intervals.
* Contracts for each new agreement rule:
  `assert_nickname_agreement_contract()`,
  `assert_suffix_agreement_contract()`,
  `assert_license_agreement_contract()`.

* `gender_agreement()`, `normalize_gender()`,
  `assert_gender_agreement_contract()` — gender as a blocking signal: it may
  veto a candidate pair, never identify one. Same three-verdict contract as
  `middle_agreement()`; absence or an unmapped code is `"uninformative"`,
  numeric conventions are refused rather than guessed, and there is no
  name-based gender inference.
* Continuous integration: `R CMD check` runs on GitHub Actions across Linux
  (devel/release/oldrel), macOS and Windows, on every push and PR and weekly
  on a schedule to catch dependency drift. Test coverage is measured with covr
  and reported to Codecov; the pkgdown site builds on every PR (the build is
  the test) and deploys to <https://mufflyt.github.io/mysterynpi/> on push.
  Dependabot keeps the pinned actions current.

# mysterynpi 0.1.0

Initial extraction. Nothing depends on this yet.

* `name_key()`, `blank_na()`, `has_name_information()`, `first_initial()`,
  `strip_parenthetical()`, `split_given()` — join keys where absence is never
  read as a value and accents cannot survive into a blocking key.
* `middle_tokens()`, `given_tokens()`, `surname_tokens()`, `SURNAME_PARTICLES`,
  `MIN_SURNAME_TOKEN` — tokenisation, with the surname-token floor pinned by
  value so lowering it fails a test rather than quietly widening every pool.
* `middle_agreement()`, `person_matches()` — token-set agreement. Three
  verdicts; `"uninformative"` is load-bearing and is not agreement.
* `npi_luhn_ok()`.
* `assert_middle_agreement_contract()` — the contract a caller runs in its own
  suite, written so it can be run against a stand-in and demonstrably fail.
