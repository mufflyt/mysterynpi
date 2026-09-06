# Changelog

## mysterynpi (development version)

- [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  stops letting NPPES fuzzy-match in the dark. Measured live: the API
  alias-expands first names BY DEFAULT against an internal list nobody
  can read – searching `bill` returned five providers all legally named
  WILLIAM, with nothing in the response saying why. Every query now
  carries `use_first_name_alias=False`, and recall is recovered in
  daylight: `expand_nicknames = TRUE` fans the first name out over its
  one-hop
  [`nickname_variants()`](https://mufflyt.github.io/mysterynpi/reference/nickname_variants.md)
  (new, exported, corpus-backed and weld-audited), one fetch per
  variant, results deduplicated by NPI with a `queried_as` column
  recording which spelling found each provider. A twentieth mutant turns
  the alias flag back on and dies.

## mysterynpi 0.3.1

- **Verdict fix (issue
  [\#4](https://github.com/mufflyt/mysterynpi/issues/4))**:
  reverse-direction corpus rows could turn a nickname into a shared root
  and weld two distinct formal names –
  `nickname_agreement("ROBERT", "WILLIAM")` corroborated. Exhaustive
  audit found 15 indirectly welded pairs; the 13 loose rows behind the
  genuinely false six (ROBERT/WILLIAM, HAROLD/HENRY, CAROLINE/CHARLOTTE,
  ADELAIDE/DELILAH, ARABELLA/ISABELLA, HELOISE/LOUISE,
  CATHERINE/CATHLEEN) are dropped in the vendoring script with per-row
  reasons; the defensible spelling-variant welds stay. ROBERT/WILLIAM
  and HAROLD/HENRY are pinned in the golden corpus and the nickname
  contract.
- **Corpus supplement**: 32 adjudicated real nicknames the corpus
  lacked, surfaced by auditing isochrones’ two remaining hand-rolled
  maps (KATE/KATIE/KITTY under CATHERINE, BARB, SUZY, ROBBIE, KIMMY,
  LEXIE, spelling variants STEVEN/STEPHEN and PHILLIP/PHILIP, and more).
  The rejects – AMY-\>AMANDA, EMILY-\>EMMA, NATHAN-\>JONATHAN – are
  recorded in the script as deliberately refused. NICKNAME_EDGES: 2,827
  -\> 2,846 rows; the verdict snapshot regenerated deliberately (7,539
  verdicts).

## mysterynpi 0.3.0

- ONE nickname system, similarity scoring dark by default. The scoring
  API extracted from isochrones
  ([`create_nickname_dictionary()`](https://mufflyt.github.io/mysterynpi/reference/create_nickname_dictionary.md),
  [`get_canonical_name()`](https://mufflyt.github.io/mysterynpi/reference/get_canonical_name.md),
  [`are_nickname_equivalents()`](https://mufflyt.github.io/mysterynpi/reference/are_nickname_equivalents.md),
  [`get_nicknames_for_name()`](https://mufflyt.github.io/mysterynpi/reference/get_nicknames_for_name.md),
  [`calculate_enhanced_first_name_similarity()`](https://mufflyt.github.io/mysterynpi/reference/calculate_enhanced_first_name_similarity.md),
  [`create_nickname_aware_similarity()`](https://mufflyt.github.io/mysterynpi/reference/create_nickname_aware_similarity.md),
  [`get_nickname_dictionary()`](https://mufflyt.github.io/mysterynpi/reference/get_nickname_dictionary.md))
  was first proven byte-identical over 4,000 real ABOG pairs, then
  CONSOLIDATED onto `NICKNAME_EDGES` – the same pinned corpus the
  verdict rule reads – by owner decision: two nickname tables is how two
  layers quietly disagree about what a name may stand for. Consolidation
  is a deliberate score change that repairs the old dictionary’s quirks
  (RICK now resolves to RICHARD; JULIA/JULIE scores 0.98 via its
  recorded edge) and collapses the dead 0.96/0.94 sub-tiers into 0.98;
  equivalence is now the verdict rule’s own one-hop relation, so AL
  pairs with ALBERT and ALEXANDER while ALBERT and ALEXANDER stay
  distinct – in scores exactly as in verdicts. The Jaro-Winkler path is
  OFF BY DEFAULT: `options(mysterynpi.enable_similarity_scoring = TRUE)`
  is the reviewable opt-in, and a mutant that removes the gate is killed
  alongside the one that smuggles the score into a verdict. The no-fuzzy
  guard holds all of it: fuzzy symbols only inside the fenced module,
  nothing outside references it, no verdict can reach it. stringdist in
  Suggests only.

- The join ledger:
  [`ledgered_join()`](https://mufflyt.github.io/mysterynpi/reference/ledgered_join.md)
  and
  [`join_ledger_entry()`](https://mufflyt.github.io/mysterynpi/reference/join_ledger_entry.md)
  — row-count reconciliation as a shipped artifact, one row per join per
  step. The vocabulary is borrowed, not coined: dplyr 1.1’s
  `relationship` values verified rather than assumed (no default —
  declaring what a join may do to the row count is the point), dplyr’s
  `unmatched = "error"` semantics, the ledger fields of midwifery’s Safe
  Join Standard, and a `min_match_rate` contract carrying the lesson of
  the deprecated isochrones safe_join, whose zero lower bound let total
  data loss pass. Absence is not a join key: NA keys never match — base
  merge’s NA-matches- NA default is the nzchar(NA) defect wearing a
  join, and the entry’s `conserved` arithmetic catches engines that do
  it.
  [`resolve_best_class()`](https://mufflyt.github.io/mysterynpi/reference/resolve_best_class.md)
  now refuses caller-supplied stats that would fan its own merge out.
  Two new mutants guard the ledger’s teeth.

- [`parse_npi_licenses()`](https://mufflyt.github.io/mysterynpi/reference/parse_npi_licenses.md)
  and `npi_search(licenses = TRUE)` — NPPES’s taxonomies carry state
  license numbers with their issuing states, the strongest deterministic
  key after the NPI itself; one fetch now returns them long, one row per
  (NPI, license), ready for
  [`license_agreement()`](https://mufflyt.github.io/mysterynpi/reference/license_agreement.md)’s
  best-verdict-across-rows use. Licenseless taxonomy entries are dropped
  rows, never NA rows.

- [`surname_rarity()`](https://mufflyt.github.io/mysterynpi/reference/surname_rarity.md)
  — Census rank and carriers-per-100k for a surname, the deterministic
  analogue of a term-frequency adjustment: it refines which CLASS a pair
  earns, in reviewable policy code, and has no code path into any
  verdict. Absence from the top 1,000 is `NA`: probably rare, possibly
  misspelled, never a value.

- The Winkler evaluation, published and PINNED: over `WINKLER_CENSUS`’s
  327 typo-corrupted true pairs the reference policy accepts 4 (1.2%
  recall) and rejects every one of 582 same-household hard negatives —
  the no-edit-distance trade stated as a measurement. The pinning test
  means recall going UP is how an edit-distance tolerance would announce
  itself.

- [`normalize_license_status()`](https://mufflyt.github.io/mysterynpi/reference/normalize_license_status.md),
  `LICENSE_STATUS_LEVELS`,
  [`assert_license_status_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_license_status_contract.md)
  — state boards do not share a vocabulary for not-practicing, and
  reading theirs naively inflates a retirement signal roughly fourfold.
  Six classes — active, restricted, retired, deceased, disciplinary,
  lapsed — with the landmines pinned by contract: FL/IL `Deceased` is
  death, OPMC’s surrenders and revocations are exits-by-discipline,
  CO/DE/WI’s `Expired` is a lapse of unknown cause, and only the board’s
  own word for retired is retirement. Unmapped statuses map to `NA` and
  decide nothing; a board-specific vocabulary extends via the `levels`
  argument as reviewable data. Two new mutants guard the inflation
  directly.
  [`license_status_audit()`](https://mufflyt.github.io/mysterynpi/reference/license_status_audit.md)
  documents the applied mapping per source – every raw status, its
  class, its count, unmapped first – as the methods-appendix table a
  reviewer can check against the board itself.

- `ROSTER_BENCHMARK` — the labeled roster-to-registry benchmark nobody
  had: 190 fully synthetic pairs, truth by construction, one defect
  family per block, shipped as data and as plain CSV. The reference
  policy in
  [`vignette("roster-benchmark")`](https://mufflyt.github.io/mysterynpi/articles/roster-benchmark.md)
  separates it perfectly (126 accepts and 58 rejects all correct; 6
  stale-gender true matches quarantined for review, as designed).
  Building it caught a real defect:
  [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
  was eating the comma that
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)’s
  “Last, First” reversal needs — fixed and pinned.

- Two evaluation corpora vendored with full attribution
  (`inst/COPYRIGHTS`): `WINKLER_CENSUS` (Winkler’s synthetic census
  pairs via the SecondString project, CMU license, 327 labeled matches
  with the household-duplicate pathology kept) and `SURNAME_FREQUENCIES`
  (Census 2010 top 1,000, public domain, ties kept as Census assigned
  them).

- [`duplicate_differences()`](https://mufflyt.github.io/mysterynpi/reference/duplicate_differences.md)
  — for rows sharing an NPI, license, or id: which columns disagree,
  with differ-by-absence (`JR` vs nothing — one person incompletely
  transcribed) distinguished from differ-by-value (`JR` vs `SR` — two
  people), and fully identical duplicates reported rather than silently
  vanishing.

- A draft JOSS paper (`paper.md`) accompanies the package.

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
