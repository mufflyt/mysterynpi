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
