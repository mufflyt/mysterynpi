# End-to-End NPPES Name Matching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `match_npi()` to take a user-provided provider roster and Type 1 NPPES data through candidate generation, conservative resolution, and rationale-bearing outputs using either R data frames or DuckDB.

**Architecture:** Keep candidate blocking and evidence interpretation in shared helpers, with separate reference-row retrieval backends for in-memory data frames and DuckDB. Feed the same candidate evidence into `resolve_one_to_one()` and return a structured result; the vignette demonstrates reproducible synthetic examples without external data.

**Tech Stack:** R, DBI, DuckDB, testthat, knitr/rmarkdown, Mermaid, mysterymaps.

**Spec:** `dev/superpowers/specs/2026-10-03-end-to-end-nppes-matching-design.md`

## Global Constraints

- Type 1 individuals are the default candidate universe.
- Candidate generation is bounded/indexed; never compare every roster row with every national reference row.
- Nickname-only or fuzzy-only evidence can create review candidates but cannot independently auto-resolve.
- Equal-best candidates, contested NPIs, and conflicts go to review; no row-order or arbitrary maximum-score assignment.
- In-memory and DuckDB backends use the same candidate blocks, evidence tiers, reason codes, tie behavior, and output schema.
- The DuckDB source is read-only from the workflow's perspective: do not create, update, or replace persistent tables.
- NPI identifiers are character values and are validated with the package helper.
- CI and the vignette use synthetic data only; no network, private provider records, or mounted-drive dependency.

## Review Focus

- Duplicate or blank roster IDs: reject blank IDs and make duplicate IDs an explicit input error; test in Task 1.
- Missing/blank source names: retain the source row as unmatched with `missing_required_name`; test in Task 1.
- Invalid NPI and unusable reference names: exclude from candidates and report exclusion counts; test in Task 2.
- Duplicate NPI rows and multiple blocking routes: deduplicate candidate identity without losing route lineage; test in Task 3.
- Unsupported DBI backend, absent table/columns, empty Type 1 set, and SQL-special identifiers: fail clearly and quote identifiers safely; test in Task 4.

---

### Task 1: Define the public input contract and result partitions

**Files:**
- Create: `R/match_npi.R`
- Modify: `NAMESPACE`
- Modify: `DESCRIPTION`
- Test: `tests/testthat/test-match-npi-contract.R`

**Interfaces:**
- Produces exported `match_npi(roster, nppes, table = NULL, id, given, middle, surname, full_name, npi, entity_type, nppes_given, nppes_middle, nppes_surname, nppes_full_name, entity_filter = "1", backend = c("auto", "data.frame", "duckdb"))`.
- Returns a list with `matches`, `review`, `unmatched`, `candidates`, `counts`, and `run_manifest` data-frame/list elements.
- Column arguments are character column names; `nppes` is either a data frame or a DBI connection. DuckDB additionally requires `table`.

- [ ] **Step 1: Write failing tests for input validation and empty partitions**

Add tests for a valid synthetic roster, missing required columns, duplicate/blank IDs, missing source name, and Type 1 default. Assert missing-name rows appear in `unmatched` with reason `missing_required_name`, not dropped.

- [ ] **Step 2: Run the focused tests and verify they fail**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-contract.R')"`
Expected: FAIL because `match_npi()` and result contract do not yet exist.

- [ ] **Step 3: Implement the exported contract and input normalization**

Use a named `columns` list internally after validating mapped fields. Preserve source roster columns and preserve NPI as character. Add DBI to `Suggests` for optional backend detection; keep DuckDB optional. Export `match_npi()` with roxygen.

- [ ] **Step 4: Run the focused tests**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-contract.R')"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/match_npi.R NAMESPACE DESCRIPTION tests/testthat/test-match-npi-contract.R
git commit -m "feat: define NPPES matching workflow contract"
```

### Task 2: Implement shared candidate evidence and conservative dispositions

**Files:**
- Create: `R/match_npi_evidence.R`
- Test: `tests/testthat/test-match-npi-evidence.R`

**Interfaces:**
- Consumes candidate pairs from a backend with columns `source_id`, `npi`,
  `roster_first`, `roster_middle`, `roster_last`, `nppes_first`,
  `nppes_middle`, `nppes_last`, and `block_route`. Backends pass only rows
  produced by bounded candidate generation; this helper never forms pairs.
- Produces `build_npi_candidate_evidence(candidate_pairs)` returning one row
  per `(source_id, npi)` with character `npi`, sorted unique `block_routes`,
  explicit name-evidence fields, an ordered evidence class, disposition, and
  stable reason code.
- Produces `partition_npi_matches(roster, candidates, missing_name = rep(FALSE, nrow(roster)), id = "source_id", result_columns)`; `roster` contains all original source columns plus canonical `source_id`, and Task 1's `inputs$missing_name` is passed as the separate flag vector. `result_columns` is the collision-safe map from Task 1. The helper returns `matches`, `review`, `unmatched`, and `candidates`, preserving original source fields and using mapped NPI/reason columns in dispositions; complete-name rows without candidates are unmatched for the no-candidate reason, while incomplete-name rows retain `missing_required_name`.

- [ ] **Step 1: Write synthetic tests for exact evidence, nickname-only, fuzzy-only, ambiguity, contested NPI, conflict, and unmatched behavior**

Assert only a unique evidence-supported best candidate resolves; weak-only, equal-best, contested, and conflicting candidates are review items with stable reason codes. Assert duplicate routes collapse to one `(source_id, npi)` candidate while retaining all route labels. Include the interaction where source A has two equally strongest eligible NPIs and source B uniquely selects one of them; both sources must be review because A's tied claim still contests that NPI. A review-only weak candidate does not create automatic-resolution contention.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-evidence.R')"`
Expected: FAIL because evidence construction and partition helpers are absent.

- [ ] **Step 3: Implement evidence helpers using existing name primitives and resolver**

Use package name normalization, given/surname/middle comparison, nickname policy, NPI validation, and `resolve_one_to_one()` as the final conservative gate. Define explicit ordered evidence classes and stable reason codes; do not label classes as probabilities.

- [ ] **Step 4: Run focused tests**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-evidence.R')"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/match_npi_evidence.R tests/testthat/test-match-npi-evidence.R
git commit -m "feat: explain and conservatively resolve NPI candidates"
```

### Task 3: Add bounded in-memory NPPES candidate generation

**Files:**
- Create: `R/match_npi_memory.R`
- Test: `tests/testthat/test-match-npi-memory.R`

**Interfaces:**
- Produces `generate_npi_candidates_memory(roster, nppes, columns, entity_filter)` returning `list(pairs, reference_counts)`. `pairs` has the exact candidate-pair columns from Task 2; `reference_counts` is an integer named vector with `input`, `entity_type`, `invalid_npi`, `missing_required_name`, and `usable` counts.
- The helper projects required reference columns before indexing and reports excluded invalid-NPI/name row counts for the run manifest.

- [ ] **Step 1: Write tests for Type 1 default, Type 2 exclusion, invalid reference NPI/name accounting, candidate block recall on synthetic fixtures, and no truncation**

Include fixture rows for exact, reordered/variant, nickname-review, fuzzy-review, ambiguous, and no-hit examples. Verify all expected candidates and no full roster-by-reference pair expansion.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-memory.R')"`
Expected: FAIL because the in-memory generator is absent.

- [ ] **Step 3: Implement projected, indexed candidate blocks**

Create a compact index only from required NPPES fields and use shared block definitions to retrieve candidate pairs. Do not sample or truncate. Preserve the block route on each pair and pass pairs to `build_npi_candidate_evidence()`.

- [ ] **Step 4: Run focused tests**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-memory.R')"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add R/match_npi_memory.R tests/testthat/test-match-npi-memory.R
git commit -m "feat: generate bounded NPI candidates in memory"
```

### Task 4: Add DuckDB-backed candidate generation

**Files:**
- Create: `R/match_npi_duckdb.R`
- Test: `tests/testthat/test-match-npi-duckdb.R`
- Modify: `DESCRIPTION`

**Interfaces:**
- Produces `generate_npi_candidates_duckdb(con, table, roster, columns, entity_filter)` returning the same `list(pairs, reference_counts)` shape as Task 3. `pairs` has columns `source_id`, `npi`, `roster_first`, `roster_middle`, `roster_last`, `nppes_first`, `nppes_middle`, `nppes_last`, `block_route`; `reference_counts` has integer fields `input`, `entity_type`, `invalid_npi`, `missing_required_name`, and `usable`.
- Consumes a DBI connection and a table identifier; returns only blocked candidate rows, never the full national table.
- For DuckDB, require structured NPPES given and surname columns with optional middle; reject full-name-only NPPES schemas clearly. The national NPPES source has structured fields, and parsing millions of reference names in R would undermine the database-backed memory path. Roster full-name parsing remains supported.

- [ ] **Step 1: Write DuckDB tests using a temporary synthetic database**

Test Type 1 filtering, parity with Task 3 including DOUBLE/integer-backed NPI and entity-type columns plus noncomposing combining accents, empty Type 1 reference, missing table/columns, unsupported connection backend, SQL-special table/column names, full-name-only NPPES rejection, and a DuckDB connection reopened with `read_only = TRUE`. Snapshot persistent table names before and after and assert they are identical.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-duckdb.R')"`
Expected: FAIL because the DuckDB generator is absent.

- [ ] **Step 3: Implement safe DuckDB candidate blocks**

Validate the DuckDB connection and table schema, quote identifiers via DBI, apply entity filtering and reference block joins in DuckDB, and use only connection-scoped temporary/registered roster blocks if needed. Mirror Task 3's route definitions: exact surname plus full given/middle tokens; surname plus leading initial; surname component/concatenation variants plus token/initial; nickname candidates anchored on exact surname; and one-character deletion-signature intersections for given or surname anchored on the exact opposite field. Return only blocked candidate rows and sequential exclusion counts. Never write persistent tables or collect all NPPES rows into R.

- [ ] **Step 4: Run focused tests and verify backend parity and no persistent writes**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-duckdb.R')"`
Expected: PASS, including parity and unchanged persistent table list.

- [ ] **Step 5: Commit**

```bash
git add R/match_npi_duckdb.R DESCRIPTION tests/testthat/test-match-npi-duckdb.R
git commit -m "feat: query NPI candidates from DuckDB"
```

### Task 5: Wire `match_npi()` across both backends and record provenance

**Files:**
- Modify: `R/match_npi.R`
- Test: `tests/testthat/test-match-npi-backend-parity.R`

**Interfaces:**
- `match_npi()` dispatches to Task 3 for a data frame and Task 4 for a DBI connection, then Task 2 for common evidence/dispositions.
- `run_manifest` includes package/policy version, backend, entity filter, column maps, candidate settings, source/reference row counts, and invalid-reference exclusion counts.

- [ ] **Step 1: Write cross-backend integration tests**

Run the same synthetic data through both input modes. Assert equal candidate identities, evidence/reason fields, disposition partitions, counts, and NPI character type; assert manifest backend differs and each manifest records source/reference counts.

- [ ] **Step 2: Run focused tests and verify failure**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-backend-parity.R')"`
Expected: FAIL until public dispatch connects both backend helpers.

- [ ] **Step 3: Wire backend dispatch and manifest construction**

For a DBI connection, require `table`; for data frames, reject an unexpected table argument. Validate empty filtered references with an actionable error. Call shared evidence and disposition helpers in both cases.

- [ ] **Step 4: Run integration and regression checks**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-backend-parity.R')"`
Expected: PASS with parity assertions. Then run `Rscript RUN_REGRESSION_TESTS.R` as the package checkpoint.

- [ ] **Step 5: Commit**

```bash
git add R/match_npi.R tests/testthat/test-match-npi-backend-parity.R
git commit -m "feat: connect NPPES matching backends"
```

### Task 6: Document the complete workflow in a synthetic vignette

**Files:**
- Create: `vignettes/end-to-end-nppes-matching.Rmd`
- Modify: `DESCRIPTION`
- Modify: `README.md`
- Test: `tests/testthat/test-match-npi-vignette.R`

**Interfaces:**
- Vignette calls `match_npi()` on deterministic synthetic roster/NPPES data in both backends.
- Shows the result components, evidence rationale, and how to pass a full in-memory data frame or existing DuckDB connection/table. Large external-data examples are non-evaluated.

- [ ] **Step 1: Add a vignette build test that checks required sections and offline synthetic execution**

Assert the vignette source contains Mermaid flowcharts, candidate/disposition figures, `mysterymaps` state maps, both backend demonstrations, and explicit interpretation limits. Keep long-running or external national-data examples non-evaluated.

- [ ] **Step 2: Run the test and verify failure**

Run: `Rscript -e "testthat::test_file('tests/testthat/test-match-npi-vignette.R')"`
Expected: FAIL because the vignette has not been added.

- [ ] **Step 3: Write the self-contained vignette and package metadata**

Add Mermaid data-path and evidence-policy flowcharts, candidate funnel and disposition figures, and state-level maps made from synthetic roster outcome/state fields with `mysterymaps`. Declare optional vignette dependencies in `Suggests`; keep matching API usable without map/diagram packages. Add a concise README link and explain data/memory choice and limitations.

- [ ] **Step 4: Knit offline and test**

Run: `Rscript -e "rmarkdown::render('vignettes/end-to-end-nppes-matching.Rmd', quiet = TRUE)"`
Expected: successful render without network, private data, or mounted drives. Then run the focused test.

- [ ] **Step 5: Commit**

```bash
git add vignettes/end-to-end-nppes-matching.Rmd DESCRIPTION README.md tests/testthat/test-match-npi-vignette.R
git commit -m "docs: add end-to-end NPPES matching vignette"
```

### Task 7: Validate package behavior and the available local DuckDB

**Files:**
- No product files unless validation reveals a defect; any fix belongs in its owning task's file and test.

**Interfaces:**
- Uses the public `match_npi()` API and the synthetic fixtures from Tasks 1–6.
- Manual database smoke test reads `/Volumes/MufflySamsung/DuckDB/nber_my_duckdb.duckdb` read-only and runs a small Type 1 roster sample only; CI never depends on this path.

- [ ] **Step 1: Run focused and full package checks**

Run: `Rscript RUN_REGRESSION_TESTS.R`
Expected: non-zero test count and all tests pass.

- [ ] **Step 2: Run spatial/DuckDB repository validation**

Run: `Rscript tests/run_valhalla_tests.R`
Expected: PASS; this is required for DuckDB ingestion logic per repository guidance.

- [ ] **Step 3: Run read-only local DuckDB smoke test**

Open the local database with `DBI::dbConnect(duckdb::duckdb(), path, read_only = TRUE)`, map `main.npidata` columns, run a small synthetic/selected Type 1 case, then disconnect. Confirm table inventory is unchanged and report this only as a manual smoke test, not full-national validation.

- [ ] **Step 4: Review generated documentation and report evidence**

Check the knitted vignette, README link, and `git diff --check`; report exact tests and whether the optional local-database smoke test ran.
