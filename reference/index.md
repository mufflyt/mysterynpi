# Package index

## Join keys

Keys where absence is never read as a value.

- [`name_key()`](https://mufflyt.github.io/mysterynpi/reference/name_key.md)
  : Canonical name join key: transliterated, upper-cased,
  whitespace-collapsed.
- [`blank_na()`](https://mufflyt.github.io/mysterynpi/reference/blank_na.md)
  : Normalised key with absence rendered as \`""\`, for use as a join
  key.
- [`has_name_information()`](https://mufflyt.github.io/mysterynpi/reference/has_name_information.md)
  : Does this field carry identity information?
- [`first_initial()`](https://mufflyt.github.io/mysterynpi/reference/first_initial.md)
  : First initial of a normalised name, or \`NA\` when there is no name.
- [`strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/strip_parenthetical.md)
  : Strip parenthesised alternate names, keeping word-internal brackets.
- [`split_given()`](https://mufflyt.github.io/mysterynpi/reference/split_given.md)
  : Split a fused given-name field into given name and trailing middle
  tokens.

## The normalisation surface

Drop-in replacements for the pipelines this was extracted from.

- [`normalize_string()`](https://mufflyt.github.io/mysterynpi/reference/normalize_string.md)
  : Normalise a string: transliterate, upper-case, trim
- [`normalize_name_columns()`](https://mufflyt.github.io/mysterynpi/reference/normalize_name_columns.md)
  : Add normalised copies of named columns to a data frame
- [`normalize_physician_names()`](https://mufflyt.github.io/mysterynpi/reference/normalize_physician_names.md)
  : Normalise the first/middle/last columns of a provider table
- [`sql_npi_name()`](https://mufflyt.github.io/mysterynpi/reference/sql_npi_name.md)
  : SQL expression normalising a name column the same way R does
- [`needs_normalization()`](https://mufflyt.github.io/mysterynpi/reference/needs_normalization.md)
  : Would normalising this vector change it?
- [`extract_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/extract_first_initial.md)
  : First initial of a name, punctuation and accents removed
- [`strip_name_noise()`](https://mufflyt.github.io/mysterynpi/reference/strip_name_noise.md)
  : Strip credential and title TOKENS from a personal-name string
- [`NAME_NOISE`](https://mufflyt.github.io/mysterynpi/reference/NAME_NOISE.md)
  : Credential and title tokens seen in provider directories.

## Parsing and tokens

- [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)
  : Parse a free-text person name into given, middle and surname
- [`middle_tokens()`](https://mufflyt.github.io/mysterynpi/reference/middle_tokens.md)
  : Middle-name tokens, initials INCLUDED.
- [`given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/given_tokens.md)
  : Given-name tokens of length \>= 2, initials EXCLUDED.
- [`surname_tokens()`](https://mufflyt.github.io/mysterynpi/reference/surname_tokens.md)
  : Split a normalised surname into its components.
- [`surname_token_table()`](https://mufflyt.github.io/mysterynpi/reference/surname_token_table.md)
  : Surname components as a long (id, token) data frame
- [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
  : Pull the generational suffix out of a raw name string, keeping both
  parts
- [`SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/SURNAME_PARTICLES.md)
  : Surname particles that are naming convention, not identity.
- [`MIN_SURNAME_TOKEN`](https://mufflyt.github.io/mysterynpi/reference/MIN_SURNAME_TOKEN.md)
  : Minimum surname token length.

## Agreement rules

Three verdicts; “uninformative” is load-bearing and is not agreement.

- [`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md)
  : Compare two middle names as TOKEN SETS, never by position.
- [`person_matches()`](https://mufflyt.github.io/mysterynpi/reference/person_matches.md)
  : Do two parsed people share a surname AND at least one full
  given-name token?
- [`gender_agreement()`](https://mufflyt.github.io/mysterynpi/reference/gender_agreement.md)
  : Do two recorded genders agree, disagree, or decide nothing?
- [`normalize_gender()`](https://mufflyt.github.io/mysterynpi/reference/normalize_gender.md)
  : Normalise recorded gender codes to \`"M"\`, \`"F"\`, or \`NA\`
- [`nickname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/nickname_agreement.md)
  : Do two given-name tokens agree once recorded nicknames are admitted?
- [`NICKNAME_EDGES`](https://mufflyt.github.io/mysterynpi/reference/NICKNAME_EDGES.md)
  : Formal-name / nickname edges, vendored from
  carltonnorthern/nicknames
- [`suffix_agreement()`](https://mufflyt.github.io/mysterynpi/reference/suffix_agreement.md)
  : Do two recorded generational suffixes agree, disagree, or decide
  nothing?
- [`normalize_suffix()`](https://mufflyt.github.io/mysterynpi/reference/normalize_suffix.md)
  : Normalise a recorded generational suffix to
  \`JR\`/\`SR\`/\`II\`/\`III\`/\`IV\`, or \`NA\`
- [`license_agreement()`](https://mufflyt.github.io/mysterynpi/reference/license_agreement.md)
  : Do two recorded licenses corroborate? (This rule cannot veto.)
- [`normalize_license()`](https://mufflyt.github.io/mysterynpi/reference/normalize_license.md)
  : Normalise a recorded license number for comparison

## Clerical review

A blinded, class-stratified sample, and the precision it buys.

- [`clerical_sample()`](https://mufflyt.github.io/mysterynpi/reference/clerical_sample.md)
  : Draw a blinded, class-stratified sample of candidate pairs for
  review
- [`clerical_precision()`](https://mufflyt.github.io/mysterynpi/reference/clerical_precision.md)
  : Per-class precision from a completed clerical review

## Ordered classes and the one-to-one constraint

- [`collapse_candidates()`](https://mufflyt.github.io/mysterynpi/reference/collapse_candidates.md)
  : Collapse candidates to one row per (id, candidate), keeping the
  strongest class
- [`pool_stats()`](https://mufflyt.github.io/mysterynpi/reference/pool_stats.md)
  : Per-person pool statistics
- [`resolve_best_class()`](https://mufflyt.github.io/mysterynpi/reference/resolve_best_class.md)
  : Resolve people whose strongest class holds exactly one candidate
- [`resolve_ordered_classes()`](https://mufflyt.github.io/mysterynpi/reference/resolve_ordered_classes.md)
  : Ordered-class resolution end to end
- [`count_rivals()`](https://mufflyt.github.io/mysterynpi/reference/count_rivals.md)
  : Count RIVAL ids: alternative claimants who are a different PERSON
- [`award_contested()`](https://mufflyt.github.io/mysterynpi/reference/award_contested.md)
  : Award a contested candidate, or refuse to

## NPI

- [`npi_luhn_ok()`](https://mufflyt.github.io/mysterynpi/reference/npi_luhn_ok.md)
  : Is this a structurally valid NPI?

## Contracts

Assertions a caller runs in its own suite.

- [`assert_middle_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_middle_agreement_contract.md)
  : Assert that middle-name agreement still behaves as this caller
  relies on.
- [`assert_gender_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_gender_agreement_contract.md)
  : Assert that gender blocking still behaves as this caller relies on.
- [`assert_nickname_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_nickname_agreement_contract.md)
  : Assert that nickname agreement still behaves as this caller relies
  on.
- [`assert_suffix_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_suffix_agreement_contract.md)
  : Assert that suffix agreement still behaves as this caller relies on.
- [`assert_license_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_license_agreement_contract.md)
  : Assert that license agreement still behaves as this caller relies
  on.
