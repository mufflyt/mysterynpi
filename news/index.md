# Changelog

## mysterynpi (development version)

- Documented (not changed) a third instance of the `"Do"` collision
  class: `SURNAME_PARTICLES` lists `"DO"` as a genuine Portuguese/
  Lusophone particle (as in `"do Carmo"`), which collides with `"Do"` as
  a standalone Vietnamese surname.
  `parse_person("Do Nguyen Van", format = "surname_first")` reads
  leading `"Do"` as a particle and walks one token further, corrupting
  the real surname into a false compound (`"Do Nguyen"`) while losing
  the real given name. Removing `"DO"` from the list would equally break
  the genuine Portuguese case. No evidence either population is rarer in
  this package’s target data, so – same precedent as the all-caps DO/Ma
  limitations already documented – this is a documented known
  limitation, not an unproven directional fix. See `SURNAME_PARTICLES`’s
  docs.

- The `"Do"` surname/credential carve-out is generalised to `"Ma"`
  (`SURNAME_CREDENTIAL_COLLISIONS`, new export). `"Ma"` is a top-20
  Chinese surname (Yo-Yo Ma, Jack Ma) that is ALSO `NAME_NOISE`’s
  spelling for the Master of Arts credential, and carried none of
  `"Do"`’s protection because the earlier fix was scoped to the `DO`
  token specifically: `strip_name_noise("John Ma")` silently returned
  `"John"`, reading as unqueryable downstream exactly like the pre-fix
  `"Do"` case. Fixed with the identical two-part rule (protected as a
  surname when it is one of exactly two tokens in its comma segment, or
  spelled in the exact title-case `"Ma"` regardless of token count).
  Separately, a 3+-token title-case `"Ma"` surname
  (e.g. `"John Michael Ma"`) hit a SECOND, unrelated bug:
  [`humaniformat::parse_names()`](https://rdrr.io/pkg/humaniformat/man/parse_names.html)
  has its own independent notion of degree-suffix tokens that also
  claims `"Ma"` once a name has three or more tokens
  (`humaniformat::suffix("John Michael Ma")` returns `"Ma"`, not `NA`),
  and
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)
  never read humaniformat’s own `$suffix` field, so the
  reclaimed-in-the-string token was silently lost a second time by a
  completely different mechanism.
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)
  now reclaims it into the surname when humaniformat’s suffix exactly
  matches a `SURNAME_CREDENTIAL_COLLISIONS` title-case spelling. Other
  short `NAME_NOISE` tokens (`PA`, `OD`, `DC`, `MS`, `LM`, `BA`) are NOT
  known common surnames the way `"Do"`/`"Ma"` are and stay
  unconditionally stripped – this is a claim about specific token
  spellings, not a policy reversal for the vocabulary.

- [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
  no longer reads a LEADING token as a generational suffix. Suffixes
  trail; a token in the first position is a title, not a generation. The
  gap mattered for “Sr.” – also the standard abbreviation for “Sister”
  (a nun) when it leads a name, e.g. a women-religious clinician’s
  record: `"Sr. Mary Josephine, CNM"`. Before this fix,
  [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
  read that leading “Sr.” as `SENIOR`, deleted it from the name, and
  reported `suffix = "SR"` – feeding a false generation into
  [`suffix_agreement()`](https://mufflyt.github.io/mysterynpi/reference/suffix_agreement.md)’s
  father/son veto for someone who was never a “Senior”.
  [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
  runs inside
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md),
  so every caller of
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)
  was exposed, not just direct callers of
  [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md).
  `"Sister"` unabbreviated was never affected; a genuine trailing suffix
  (`"...Smith Jr"`) still is – the fix is positional, not a vocabulary
  change.

- [`assert_org_name_matches_person_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_org_name_matches_person_contract.md)
  (new): every other agreement rule
  ([`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md),
  [`suffix_agreement()`](https://mufflyt.github.io/mysterynpi/reference/suffix_agreement.md),
  [`nickname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/nickname_agreement.md),
  [`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md),
  [`gender_agreement()`](https://mufflyt.github.io/mysterynpi/reference/gender_agreement.md),
  [`license_agreement()`](https://mufflyt.github.io/mysterynpi/reference/license_agreement.md),
  [`normalize_license_status()`](https://mufflyt.github.io/mysterynpi/reference/normalize_license_status.md))
  ships a portable contract assertion a downstream fork can run against
  its own copy;
  [`org_name_matches_person()`](https://mufflyt.github.io/mysterynpi/reference/org_name_matches_person.md)
  did not have one despite being exported with real,
  previously-undetected failure modes. Pins the professional-corporation
  pattern, the corporate-form/credential noise floor, hyphen folding,
  and the DO-surname collision fix.

- [`org_name_matches_person()`](https://mufflyt.github.io/mysterynpi/reference/org_name_matches_person.md)
  now runs
  [`strip_name_noise()`](https://mufflyt.github.io/mysterynpi/reference/strip_name_noise.md)
  on the raw string before normalising it, instead of stripping
  `NAME_NOISE` with a bare
  [`setdiff()`](https://rdrr.io/r/base/sets.html) afterward. The
  difference matters for exactly the surnames that collide with a
  credential token (`DO`, the Vietnamese surname vs. the Doctor of
  Osteopathic Medicine credential):
  `org_name_matches_person("Do Family Medicine Clinic", "Anh Do")` – a
  practice literally named after the physician’s own surname – returned
  `FALSE` before this fix, because the shared identity token “DO” was
  stripped as noise on both sides before comparison.
  [`strip_name_noise()`](https://mufflyt.github.io/mysterynpi/reference/strip_name_noise.md)’s
  DO carve-out must run before
  [`name_key()`](https://mufflyt.github.io/mysterynpi/reference/name_key.md)
  uppercases the string, since its title-case heuristic is a case
  distinction.

- [`given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/given_tokens.md),
  [`middle_tokens()`](https://mufflyt.github.io/mysterynpi/reference/middle_tokens.md),
  [`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md)
  and
  [`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md)
  no longer split a token on a hyphen. A genuinely compound given or
  middle name (“Mary-Jane”, “Anne-Marie”) is ONE name, exactly like
  [`split_given()`](https://mufflyt.github.io/mysterynpi/reference/split_given.md)
  already treats it – but these four tokenisers split on “-” like any
  other delimiter, and because
  [`person_matches()`](https://mufflyt.github.io/mysterynpi/reference/person_matches.md)/[`middle_agreement()`](https://mufflyt.github.io/mysterynpi/reference/middle_agreement.md)/[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md)
  corroborate on ANY shared token, that let a compound name satisfy a
  match against an unrelated person sharing only ONE half of the
  compound:
  `person_matches("SMITH", given_tokens("Mary-Jane"), "SMITH", given_tokens("Jane"))`
  returned `TRUE`. Same defect class `fold_hyphens`’s documentation
  already describes for given names (three cross-state false identity
  matches), just not yet applied to these four functions when that
  policy was set.

- [`strip_name_noise()`](https://mufflyt.github.io/mysterynpi/reference/strip_name_noise.md)/[`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md):
  the Vietnamese surname “Do” is no longer deleted as the DO credential
  (Doctor of Osteopathic Medicine). `NAME_NOISE` cannot record two
  answers for one token, and unconditional stripping turned
  `parse_person("Anh Do")` into `last = ""` – silent, not an error, and
  since callers thread the result through
  [`has_name_information()`](https://mufflyt.github.io/mysterynpi/reference/has_name_information.md),
  a downstream consumer (isochrones’ `resolve_dea_action_to_npi()`) was
  reading the empty surname as unqueryable and dropping DEA-action
  records for practitioners actually named “Do” before they ever reached
  NPI lookup. A `"do"`/`"DO"`/`"Do"` token is now read as the surname,
  not the credential, when it is one of exactly two tokens within its
  own comma-delimited segment (`"Anh Do"`, or the one-token segment
  `"Do"` in `"Do, Anh"`), or written in unambiguous title case
  regardless of token count (`"Nguyen Van Do"`). Segment-scoped:
  `"Do, Anh, M.D."` still protects `"Do"` even though the credential
  segment brings the whole string’s token count to three. The credential
  reading is unchanged everywhere else – `"John Smith DO"` and
  `"Smith, John, MD"` still strip to `"John Smith"`/`"Smith John"`.
  Found during an isochrones QA pass on honorific/credential
  disambiguation; isochrones had already independently discovered and
  fixed the same defect once, locally, in one of its own three call
  sites (`R/state_boards/normalize_state_board_roster.R`) before this
  was ported upstream to fix it for every consumer of this package. 19
  new assertions in `test-parse-person.R`; full suite (1,540 assertions)
  green.

## mysterynpi 0.6.0

- New UDF-free SQL builders in the join-key family, both proven by
  execution against a real DuckDB:
  [`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md)
  (database twin of
  [`extract_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/extract_first_initial.md):
  non-letters stripped BEFORE the character, so `"(Sandra) Theresa"`
  blocks as `'S'` and punctuation-only is `NULL`, never `''` or a
  punctuation byte; parity pinned on ASCII with the accented-letter
  divergence pinned explicitly as the documented boundary) and
  [`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md)
  (a governed string literal - `O'Brien` round- trips byte-identical,
  `NA` becomes SQL `NULL` - replacing per-call-site `sprintf`/`gsub`
  patches).

- [`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md)
  gains `detail = TRUE`, returning `data.frame(verdict, reason)` in the
  same shape as
  [`given_name_agreement()`](https://mufflyt.github.io/mysterynpi/reference/given_name_agreement.md).
  The coarse three-valued default is untouched (contract-asserted
  byte-identical), and the reason vocabulary is the measured one
  [`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md)
  already reports (`exact`, `separator_equivalent`,
  `concatenated_equivalent`, `component_subset`) plus the rule’s two
  rescues (`alternate_recorded`, `maiden_as_middle`), so hyphen-subset
  and rescue evidence become distinguishable from exact identity without
  flattening any verdict.
  [`assert_surname_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_surname_agreement_contract.md)
  now also proves the detail projection can never disagree with coarse
  mode and rejects undeclared reason values.

- New:
  [`blocking_key()`](https://mufflyt.github.io/mysterynpi/reference/blocking_key.md) -
  one governed construction for the keys candidate generation joins on,
  with named modes `surname_initial`
  (`<compact surname>|<first initial>`; the delimiter makes the
  component boundary explicit and pins the serialized contract - it is
  not needed for collision prevention, since a fixed one-character
  second field is already uniquely separable), `prefix_n` (explicit `n`
  required, a single finite whole number \>= 1, rejected loudly for
  1.5/Inf/NaN/“3”/ TRUE; supplying `n` with any other mode errors), and
  `compact`. Built from the primitives whose semantics match blocking:
  [`compact_name_key()`](https://mufflyt.github.io/mysterynpi/reference/compact_name_key.md)
  and
  [`extract_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/extract_first_initial.md)
  (which refuses to emit a non-letter, where
  [`first_initial()`](https://mufflyt.github.io/mysterynpi/reference/first_initial.md)’s
  join-key contract would hand back `-` for a punctuation-only name).
  Insufficient input is `NA_character_`, never a partial key; the
  audited legacy extractors kept components as separate columns and
  filtered missing rows pre-join, so plain missingness is an
  API-representation change only - EXCEPT punctuation-only given names,
  which the legacy nzchar() filter was blind to (a `-` initial reached
  candidate generation where the canonical key is NA): a potential
  candidate-set delta, characterized in the tests. Parity with the nine
  state-extractor constructions is characterized at the RESULTING-KEY
  level: all nine agree with each other everywhere, the canonical key
  agrees with them on plain-ASCII names, and the canonicalization deltas
  on BOTH key sides (surname punctuation/space compaction, accent
  transliteration, German digraph romanisation, parenthetical-alternate
  stripping; given-name initials normalized before extraction) each ship
  as a legacy-vs-canonical fixture classified as an intentional
  key-level canonicalization delta and potential candidate-set delta -
  actual candidate-set changes are measured at migration. prefix_n and
  compact call-site parity is characterized when those sites migrate.

- The package contains NO fuzzy person-name matching. Unreleased
  similarity APIs introduced after 0.5.0 were removed before this
  release, along with the 0.5.0-era fenced scoring pair
  (`calculate_enhanced_first_name_similarity()`,
  `create_nickname_aware_similarity()`), its opt-in option, and the
  stringdist dependency. The architectural rule: exact normalization,
  explicit equivalence, declared aliases, initials, documented surname
  history, credentials, gender evidence, and structured identity
  evidence are allowed; approximate spelling similarity is not.
  `test-no-fuzzy.R` enforces it with no exempt module (source scan,
  parse-tree scan, namespace reachability, dependency assertion,
  structural absence of the deleted names), and a mutation proves the
  guards fire on a direct
  [`adist()`](https://rdrr.io/r/utils/adist.html) reintroduction.

- New:
  [`given_name_agreement()`](https://mufflyt.github.io/mysterynpi/reference/given_name_agreement.md) -
  categorical three-valued given-name verdict returning
  `data.frame(verdict, reason)`: verdict in the house vocabulary
  (`corroborates` / `conflicts` / `uninformative`), reason naming the
  deterministic rule behind a corroboration (`exact`, `nickname` for a
  RECORDED one-hop `NICKNAME_EDGES` relation, `initial`). Missing is
  always `uninformative` - never a bad match, never a number.
  JULIA/JULIE corroborates because the corpus records the edge; LEE/LEA
  conflicts because nothing does. A full-corpus invariant test pins that
  [`are_nickname_equivalents()`](https://mufflyt.github.io/mysterynpi/reference/are_nickname_equivalents.md),
  [`nickname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/nickname_agreement.md)
  and
  [`given_name_agreement()`](https://mufflyt.github.io/mysterynpi/reference/given_name_agreement.md)
  can never give opposite answers to the same recorded relationship.
  [`assert_given_name_agreement_contract()`](https://mufflyt.github.io/mysterynpi/reference/assert_given_name_agreement_contract.md)
  ships alongside, falsifiable by construction.

- `R/similarity_scoring.R` is renamed `R/nickname_dictionary.R`: what
  remains there is the deterministic dictionary derived from
  `NICKNAME_EDGES` (five table-read utilities), and the old filename
  implied machinery that no longer exists.

## mysterynpi 0.5.0

- Equality-join surname keys
  ([`compact_name_key()`](https://mufflyt.github.io/mysterynpi/reference/compact_name_key.md),
  [`surname_key_variants()`](https://mufflyt.github.io/mysterynpi/reference/surname_key_variants.md)):
  letters-only keys emitting BOTH surname conventions (particles glued
  and bare final token), for the join that cannot come into R – millions
  of registry rows on the database side, where the candidate set is
  built by hash-join equality before any pairwise rule can run. Measured
  origin (isochrones ABMS-to-NPI matcher, 2026-09-18):
  punctuated/particled surnames matched at 80.1% against 97.5% for plain
  names, a glued-only repair would have traded 42 matched
  Vietnamese-name physicians for the recovered Dutch/Hispanic ones, and
  dual variants recovered 475 of 765 missing physicians while losing
  zero. A trailing single letter never becomes a surname key (positional
  rule; deliberately NOT a generation claim –
  [`normalize_suffix()`](https://mufflyt.github.io/mysterynpi/reference/normalize_suffix.md)
  still refuses to read `V` as a suffix).

- UDF-free SQL builders proven against the R side
  ([`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
  [`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
  [`sql_middle_initial_guard()`](https://mufflyt.github.io/mysterynpi/reference/sql_middle_initial_guard.md)):
  DuckDB/RE2 expressions for suffix-stripped, letters-only join keys and
  a middle-initial contradiction guard, executable-parity-tested against
  a live DuckDB connection in this package’s own suite. They exist
  because R/SQL normaliser drift has two documented specimens: a suffix
  regex whose doubled backslashes made it match NOTHING for twenty
  months while the comment beside it claimed otherwise, and a SQL side
  that spaced punctuation while the R side kept it, so `JONES-COX` could
  never equal `JONES COX`. RE2 has no lookahead, so the suffix strip is
  trailing-anchored – which is also why a bare surname `DO`, a bare
  `JR`, or `DOOLEY` can never be eaten. Complements
  [`sql_npi_name()`](https://mufflyt.github.io/mysterynpi/reference/sql_npi_name.md),
  which handles accents but requires a `strip_accents` UDF.

- Taxonomy identity screen
  ([`taxonomy_consistent()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_consistent.md),
  [`taxonomy_tiebreak_rank()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_tiebreak_rank.md),
  [`taxonomy_family_pattern()`](https://mufflyt.github.io/mysterynpi/reference/taxonomy_family_pattern.md),
  `TAXONOMY_FAMILY_PATTERNS`): three-valued profession-level consistency
  of an NPI record against a board specialty – an IDENTITY axis beside
  license/gender/graduation-year agreement, never a subspecialty
  classifier (taxonomy runs 57-82% sensitivity / 58-65% PPV for
  subspecialty). Inspects the FULL pipe-concatenated code string,
  because a record may retain a residency code ahead of its 207V and a
  first-segment shortcut misreads that clinician as a non-physician (a
  real review-tool defect from the 2026-09-19 promotion audit). `NA` can
  never read as clean, and the tie-break rank is documented for use
  AFTER every stronger ordering criterion: in its origin deployment it
  changed 360 of 22,002 selections, every one tied on recency and
  confidence, zero rank regressions and zero recency/confidence
  overrides.

## mysterynpi 0.4.0

- [`sql_npi_name()`](https://mufflyt.github.io/mysterynpi/reference/sql_npi_name.md)
  now folds German digraphs (`ü`/`ö`/`ä`/`ß` -\> `ue`/`oe`/ `ae`/`ss`)
  before handing the column to `strip_accents()`, matching
  [`normalize_string()`](https://mufflyt.github.io/mysterynpi/reference/normalize_string.md)‘s
  own ordering. `strip_accents()` alone only drops a diacritic, so it
  turned `"Müller"` into `"MULLER"` while `normalize_string("Müller")`
  gives `"MUELLER"` – a silent R/SQL parity break for exactly the
  population the function’s own docstring promises parity for. Confirmed
  against a live DuckDB connection and caught by isochrones’ own
  downstream parity test (`test-sql-npi-name-helper.R`), which now
  passes. `duckdb`/`DBI` added to Suggests for an executable parity test
  in this package’s own suite (`test-normalize.R`), not just a claim in
  a docstring.

- [`graduation_year_agreement()`](https://mufflyt.github.io/mysterynpi/reference/graduation_year_agreement.md)
  (new, with
  [`graduation_year_band()`](https://mufflyt.github.io/mysterynpi/reference/graduation_year_band.md)
  and the `GRADUATION_YEAR_BANDS` table): the package’s first identity
  axis that is not a name. Names are the axis registries agree on
  because they copy one another — measured against a commercial national
  directory, its first name matched NPPES for 100% of linked clinicians,
  surname 99.96%, sex 99.92% and primary taxonomy 99.75%, so evidence
  drawn from them is one source restated rather than two agreeing. A
  graduation year is independent: it equals the credentialing year for
  70.4% of true links but the NPI’s own enumeration year for only 39.4%.

  - **The bands are signed.** Graduating the year *before* credentialing
    carries a likelihood ratio of 10.2; the year *after*, 1.8. A
    symmetric “within one year” band averages a strong signal with a
    weak one.
  - **A two- to three-year gap is evidence AGAINST a link** (ratios
    0.4–0.8), not weak evidence for it. Two independent implementations
    reached that conclusion; both had been scoring it positive.
  - `"conflicts"` fires only beyond ten years, and is a flag rather than
    a veto: an earlier degree in another discipline or a later doctorate
    reads the same way. `"uninformative"` covers absence (about 47% of
    pairs) and the middle bands, whose weight a scoring caller takes
    from `log2_lr`.
  - **Provisional.** The weights come from a silver standard —
    high-confidence incumbent links against same-name decoys — not
    adjudicated pairs, and from one cohort against one directory
    snapshot. The table ships as data so a study can supply its own, as
    with `NICKNAME_EDGES`.

- [`strip_med_suffix()`](https://mufflyt.github.io/mysterynpi/reference/strip_med_suffix.md)
  (new, with `MEDICAL_UNIT_PATTERNS`): the institution in a CMS
  medical-school name. CMS maps every clinician’s education through a
  medical-school list, so a nurse-midwife trained at a university’s
  nursing school arrives as “ SCHOOL OF MEDICINE”. Extracted from the
  midwifery pipeline, where it had been applied to the Doctors and
  Clinicians file and a commercial directory carrying the same field.
  Two defects were fixed on the way in:

  - a named school of a university returned the school’s name (“BRODY
    SCHOOL OF MEDICINE AT EAST CAROLINA UNIVERSITY” gave “BRODY”); it
    now returns the university.
  - an institution whose name is the medical phrase was cut to a place
    (“BAYLOR COLLEGE OF MEDICINE” gave “BAYLOR”, “OHIO MEDICAL
    UNIVERSITY” gave “OHIO”); a strip that leaves no institution word is
    now refused.

  Base R only; no new dependency. The 88 distinct strings from that
  pipeline are pinned in
  `tests/testthat/fixtures/cms_medical_school_names.csv`.

- [`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md)
  no longer runs its own component/particle logic
  ([`surname_tokens()`](https://mufflyt.github.io/mysterynpi/reference/surname_tokens.md),
  `SURNAME_PARTICLES`, a 4-character floor). It now delegates to
  [`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
  this package’s single canonical surname-correspondence engine, which
  the two implementations had silently drifted apart from:
  `surname_agreement("Abu-Ghazaleh", "Abughazaleh")` returned
  `"conflicts"` because `ABU` was a stripped particle in the old logic
  and the only shared component, while
  [`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md)
  correctly reports `"concatenated_equivalent"`. The migration also
  incidentally fixes a floor asymmetry (`"Lee-Chen"` vs bare `"Lee"` now
  corroborates instead of conflicting, since the 3-letter `LEE` no
  longer needs to clear a 4-character floor). The alternate-surname
  rescue, the maiden-as-middle rescue, and the three-verdict contract
  are unchanged;
  [`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md)
  now simply runs before them as the primary correspondence check.
  [`surname_tokens()`](https://mufflyt.github.io/mysterynpi/reference/surname_tokens.md)
  and `MIN_SURNAME_TOKEN` remain, but only back
  [`surname_token_table()`](https://mufflyt.github.io/mysterynpi/reference/surname_token_table.md)’s
  blocking-key use case now, which is a different question (what is a
  safe join key?) from surname agreement (do these two surnames
  correspond?).

  Migrating exposed a bug in
  [`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md)
  itself: its empty-component short-circuit ran BEFORE the exact-key
  check, so two identical recorded surnames with zero letter-components
  (e.g. `"A."`) were reported as `"none"` – no correspondence – instead
  of `"exact"`. Fixed by checking exact-key identity first.

- [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)
  now extracts the generational suffix (JR/SR/II/III/IV) internally,
  BEFORE its own title-stripping runs, and returns it as a new `suffix`
  column. Previously a caller had to know to call
  [`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
  before
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)/[`strip_name_noise()`](https://mufflyt.github.io/mysterynpi/reference/strip_name_noise.md),
  because both of those treat suffix tokens as noise and silently delete
  them; a pipeline that composed “strip titles” and “suffix handling” as
  separate stages in the natural reading order lost every suffix – and
  with it,
  [`suffix_agreement()`](https://mufflyt.github.io/mysterynpi/reference/suffix_agreement.md)’s
  father/son veto – with no error. Baking the extraction into
  [`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)
  removes the ordering hazard by construction instead of relying on
  caller discipline.

- Documentation for the decision:
  [`vignette("nickname-policy")`](https://mufflyt.github.io/mysterynpi/articles/nickname-policy.md)
  – the appendix that recomputes the verdict-layer ablation on every
  build, documents the candidate-layer result, the source-class gate,
  the lineage contract, the ghost controls, and the ROBERT\>BILL
  governance record. The verdict-layer harness and per-edge ledger ship
  in `tools/ablation/`; the README gains the two ablation figures and a
  policy section.

- The policy is now GOVERNED CONFIGURATION. `NICKNAME_POLICY` carries
  the full machine-readable contract (policy_id, verdict_layer,
  candidate_expansion, auto_accept_rule, governing_matcher_sha,
  dictionary_version, governing_evidence, effective_date, supersedes)
  plus a governed-edges record pinning ROBERT\>BILL exactly as tested (0
  rescues, inflation present, contained by review-only). The ablation
  counts live in a versioned fixture whose checksum is pinned NEXT TO
  the policy_id – editing the evidence without a policy supersession
  fails

  101. `SOURCE_CLASSES` (exported) is the one canonical source-class
       registry: formal_record forbidden, informal_capable review-only,
       unknown FAILS CLOSED with no fallback; the gate resolves by
       registry lookup, never string matching. `acceptance_contribution`
       is a governed enum (none / supporting / nickname_only, with
       necessary / conflicting reserved for the acceptance layer); both
       paths of a nickname-plus-independent-evidence candidate are
       preserved, never collapsed.
       [`assert_nickname_policy()`](https://mufflyt.github.io/mysterynpi/reference/assert_nickname_policy.md)
       now also fails closed on broken lineage: missing policy columns,
       or missing lineage values on any expansion-influenced row. Four
       new mutants (unknown-goes-informal, lineage column dropped,
       nickname-only unflagged, fixture edited without supersession):
       campaign 32/32.

- THE NICKNAME POLICY IS LOCKED (`NICKNAME_POLICY`, decided 2026-09-07
  from the frozen-matcher ablation; governing evidence recorded in the
  object): verdict-layer nickname evidence retained globally; candidate
  expansion retained REVIEW-ONLY and gated to informal-name-capable
  source classes; auto-acceptance on nickname evidence alone impossible.
  [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  gains `source_class` (“formal_record” refuses expansion;
  “informal_capable” permits it), stamps `source_class`,
  `candidate_expansion_used`, `review_only` and
  `acceptance_contribution` on every row, and attaches a `run_manifest`
  attribute naming the policy id, governing matcher SHA, and dictionary
  version. New
  [`assert_nickname_policy()`](https://mufflyt.github.io/mysterynpi/reference/assert_nickname_policy.md)
  fails closed when an auto-accept set contains a nickname-only
  candidate. Eight policy tests pin the ablation results (126/0/0 with
  the table, 93/33/0 without, ten ghosts rejected); two new mutants
  (gate removed, guard hollowed) bring the campaign to 28.

- [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  stops letting NPPES fuzzy-match in the dark. Measured live: the API
  alias-expands first names BY DEFAULT against an internal list nobody
  can read – searching `bill` returned five providers all legally named
  WILLIAM, with nothing in the response saying why. Every query now
  carries `use_first_name_alias=False`; there is no argument to turn it
  back on.

- Nickname expansion is now a fully explicit, versioned transformation
  layer – the repo’s ONLY route from an input first name to additional
  queried names, enforced by an invariant test. `NICKNAME_EDGES` rows
  carry stable content-derived `edge_id`s (`NAME>NICKNAME`) and the
  table carries a hand-bumped `version` attribute pinned in CI.
  [`nickname_variants()`](https://mufflyt.github.io/mysterynpi/reference/nickname_variants.md)
  (new, exported) returns the expansion PLAN as a data.frame –
  `input_first_name`, `queried_first_name`, `alias_edge_id`,
  `alias_dictionary_version` – one hop, both directions, never
  transitive closure (BILL reaches FRED, FRED reaches FREDERICK, BILL
  never reaches FREDERICK), with a hard `max_expansion` cardinality
  guard (default 25, just above the corpus’s widest hub, CHRIS at 18)
  that stops rather than silently truncating.

- [`npi_search()`](https://mufflyt.github.io/mysterynpi/reference/npi_search.md)
  takes `name_expansion = "none" | "curated_one_hop"` – an enum,
  deliberately not a Boolean – executes the plan one fetch per row,
  dedupes by NPI (plan order makes retained provenance deterministic),
  and stamps all four provenance columns on every returned row.

- The alias-off guarantee is tested BEHAVIORALLY: all traffic flows
  through one mockable transport seam (`npi_fetch_impl`), and tests
  assert every outbound URL carries the flag – replacing a source-text
  check the mutation campaign proved insufficient (`if (FALSE) <flag>`
  still greps). The dictionary gains its own integrity suite
  (version/checksum pins, refused-weld pins for the 13 issue-4 drops,
  approved-edge preservation, degree profile, cycle census), and the
  campaign gains three mutants: alias-back-on, fan-out guard disabled,
  NPI dedup dropped – all killed.

- Deduplication never discards lineage. The declared dedup key is the
  NPI – a physician found by two expansion paths is ONE candidate, so
  counts cannot inflate by fan-out – and every path is kept:
  `found_by_queries` and `found_by_edges` aggregate all the spellings
  and edges that returned each NPI (`"input|BILL>WILLIAM"`), with the
  unexpanded query represented explicitly as `input`, never disguised as
  an alias edge. Four more mutants (transitive expansion, provenance
  corruption, lineage discard, unauthorized dictionary access outside
  the canonical module) bring the campaign to 26, all killed.

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
  `calculate_enhanced_first_name_similarity()`,
  `create_nickname_aware_similarity()`,
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
