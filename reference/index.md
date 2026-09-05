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
- [`license_anatomy()`](https://mufflyt.github.io/mysterynpi/reference/license_anatomy.md)
  : Decompose a license number into prefix, digits, and suffix
- [`license_conformance()`](https://mufflyt.github.io/mysterynpi/reference/license_conformance.md)
  : Does each license fit the shape its state's board actually issues?
- [`normalize_license_status()`](https://mufflyt.github.io/mysterynpi/reference/normalize_license_status.md)
  : Normalise recorded board license statuses to their exit classes
- [`LICENSE_STATUS_LEVELS`](https://mufflyt.github.io/mysterynpi/reference/LICENSE_STATUS_LEVELS.md)
  : The status vocabulary: recorded board spellings and their classes
- [`license_status_audit()`](https://mufflyt.github.io/mysterynpi/reference/license_status_audit.md)
  : The mapping that was applied, per source, as a document
- [`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md)
  : Do two surnames agree, disagree, or decide nothing?
- [`surname_rarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_rarity.md)
  : How common is this surname? Census facts, for ordered-class
  refinement

## Similarity scoring (candidate ranking, never verdicts)

The fenced exception; extracted from isochrones, quirks pinned.

- [`create_nickname_dictionary()`](https://mufflyt.github.io/mysterynpi/reference/create_nickname_dictionary.md)
  : The nickname dictionary, derived from the one corpus
- [`get_nickname_dictionary()`](https://mufflyt.github.io/mysterynpi/reference/get_nickname_dictionary.md)
  : Cached access to the nickname dictionary
- [`get_canonical_name()`](https://mufflyt.github.io/mysterynpi/reference/get_canonical_name.md)
  : Resolve a name, possibly a nickname, to a canonical formal form
- [`are_nickname_equivalents()`](https://mufflyt.github.io/mysterynpi/reference/are_nickname_equivalents.md)
  : Are two names one-hop equivalent under the corpus?
- [`get_nicknames_for_name()`](https://mufflyt.github.io/mysterynpi/reference/get_nicknames_for_name.md)
  : All recorded nicknames for a formal name
- [`calculate_enhanced_first_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/calculate_enhanced_first_name_similarity.md)
  : Nickname-aware first-name similarity SCORE (never a verdict)
- [`create_nickname_aware_similarity()`](https://mufflyt.github.io/mysterynpi/reference/create_nickname_aware_similarity.md)
  : Factory: similarity closure with a bound dictionary

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
- [`duplicate_differences()`](https://mufflyt.github.io/mysterynpi/reference/duplicate_differences.md)
  : Which columns differ between rows that share a key?
- [`ledgered_join()`](https://mufflyt.github.io/mysterynpi/reference/ledgered_join.md)
  : Join with the cardinality declared, verified, and ledgered
- [`join_ledger_entry()`](https://mufflyt.github.io/mysterynpi/reference/join_ledger_entry.md)
  : The accounting for one join, from its inputs and its output

## Evaluation corpora

Vendored and authored data; licenses in inst/COPYRIGHTS.

- [`ROSTER_BENCHMARK`](https://mufflyt.github.io/mysterynpi/reference/ROSTER_BENCHMARK.md)
  : A labeled, fully synthetic roster-to-registry matching benchmark
- [`WINKLER_CENSUS`](https://mufflyt.github.io/mysterynpi/reference/WINKLER_CENSUS.md)
  : Winkler's synthetic census pairs, via the SecondString project
- [`SURNAME_FREQUENCIES`](https://mufflyt.github.io/mysterynpi/reference/SURNAME_FREQUENCIES.md)
  : The 1,000 most frequent U.S. surnames, Census 2010

## NPI

- [`npi_luhn_ok()`](https://mufflyt.github.io/mysterynpi/reference/npi_luhn_ok.md)
  : Is this a structurally valid NPI?
- [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  : Search the NPPES registry for providers
- [`parse_npi_search()`](https://mufflyt.github.io/mysterynpi/reference/parse_npi_search.md)
  : Parse an NPPES API response into one row per provider
- [`parse_npi_licenses()`](https://mufflyt.github.io/mysterynpi/reference/parse_npi_licenses.md)
  : The licenses inside an NPPES response, one row per (NPI, license)

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
- [`assert_surname_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_surname_agreement_contract.md)
  : Assert that surname agreement still behaves as this caller relies
  on.
- [`assert_license_status_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_license_status_contract.md)
  : Assert that license-status normalisation still refuses the 4x
  inflation.
