# Changelog

## mysterynpi (development version)

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
