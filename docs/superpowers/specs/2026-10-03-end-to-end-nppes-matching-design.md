# End-to-End NPPES Name Matching Design

**Status:** Design approved in conversation on 2026-10-03; awaiting review of this
written spec.

## Goal

Make `mysterynpi` take a source roster and caller-provided NPPES Type 1 data all
the way through candidate generation, evidence assessment, conservative identity
resolution, and reviewable outputs with a rationale for every candidate.

## User and operating context

The primary user has a provider roster and access to a full national NPPES Type 1
dataset. The workflow must support both a fully loaded R `data.frame` and a
DuckDB table accessed through DBI. The in-memory path is convenient for smaller
or already-loaded tables; the DuckDB path must avoid importing the full national
reference table into R merely to generate candidates.

NPPES Type 1 individuals are the default candidate universe. The source table is
provided by the caller: the package does not download NPPES, choose a database
path, or assume that a particular local database is current. Matching is
limited to identity linkage; it does not establish licensure, specialty,
practice status, or whether a provider is currently active.

## Public workflow

Add a high-level `match_npi()` entry point in `mysterynpi`.

- `roster` is a data frame. It contains a stable source-record ID and either
  structured name fields or a full-name field handled through existing
  `mysterynpi` parsing tools. Callers may map nonstandard source columns.
- `nppes` is either a data frame or a DuckDB DBI connection. When it is a
  connection, a caller-supplied table identifier is required. Callers map the
  NPPES NPI, entity type, and name columns when they do not use standard NPPES
  headers.
- The entity-type filter defaults to Type 1. The input data frame and persistent
  database tables are never modified.
- Both input modes produce the same result contract and use the same name,
  evidence, nickname, ambiguity, and one-to-one policies.

The output is a structured list containing:

- `matches`: records with one uniquely supported NPI;
- `review`: candidate-bearing records that cannot safely resolve, with a
  specific review reason;
- `unmatched`: source records for which candidate generation found no candidate;
- `candidates`: candidate pairs with the evidence and rationale used to assess
  them;
- `counts`: stage and disposition counts; and
- `run_manifest`: package/policy version, backend, entity filter, column map,
  candidate-generation settings, and input row counts.

Source roster fields are preserved. NPI identifiers are represented as
characters and validated using the package's NPI validation helper. A missing
or blank source-record ID is an input error. A row without enough source-name
information is returned as unmatched with a `missing_required_name` reason.
Reference rows with invalid NPIs or missing required name fields are excluded
from candidate generation and counted in the run manifest; they are never
silently discarded.

## Candidate generation and evidence

The workflow filters the reference universe to the requested entity type before
matching. It creates candidates through bounded, indexed name blocks; it must
not perform a roster-by-national-table Cartesian comparison. The in-memory
backend builds a compact index from only the required reference columns. The
DuckDB backend performs Type 1 filtering and candidate-block joins in DuckDB,
returning candidate pairs and the columns needed for evidence evaluation rather
than all national rows.

Candidate evaluation reuses `mysterynpi`'s canonical name normalization,
structured given-name comparison, surname-component rules, middle-name
agreement, nickname policy, and NPI validation. Each candidate retains the
blocking route(s), evidence fields, and stable reason codes that explain why it
was generated and how its evidence was interpreted. Multiple routes to one
NPI are deduplicated without discarding lineage.

Evidence is ordered by explicit classes, not described as calibrated
probability. A uniquely supported strongest candidate may resolve. Equal-best
candidates, candidates claimed by multiple source records, conflicts, and
weak-only evidence are routed to review. Nickname-only or fuzzy-only evidence
may surface candidates for human review but cannot independently produce an
automatic match. `resolve_one_to_one()` remains the final conservative gate;
the workflow does not award a contested NPI by row order or an arbitrary
maximum-score assignment.

## Backend consistency and data safety

The two backends may use different indexing/query mechanics, but must implement
the same candidate blocks, evidence tiers, reason codes, tie behavior, and
output schema. Shared synthetic fixtures will run through both paths and assert
equivalent candidate identities and dispositions.

The DuckDB path accepts an existing DBI connection and a table identifier. It
uses only connection-scoped temporary/registered data where needed; it must not
create, update, or replace persistent tables or write to the caller's database.
Identifiers are quoted through DBI rather than interpolated as raw SQL. A
missing table, missing required field, unsupported connection backend, or empty
Type 1 reference set produces a clear error rather than an empty-looking result.

The in-memory path accepts the full NPPES data frame and internally projects
only required fields before indexing. It does not silently sample or truncate
the data. Documentation reports memory implications and recommends the DuckDB
path for full national data when RAM is constrained.

## End-to-end vignette

Add a self-contained vignette that runs without private data, network access, or
an external drive. A deterministic synthetic roster and NPPES-like table will
demonstrate exact support, nickname/fuzzy review-only candidates, ambiguous
names, contested NPIs, and unmatched records. It will show both input paths
converging on identical output and rationale.

The vignette includes Mermaid flowcharts for the two data-access paths and the
evidence/resolution policy; figures for candidate flow and match/review
dispositions; and state-level maps built with `mysterymaps` from the synthetic
roster's state and outcome fields. The maps describe linkage outcomes in the
example roster only; they do not imply provider availability or quality.
Provider dot maps are not generated from street addresses and the vignette does
not geocode real NPPES addresses.

Separate, non-evaluated examples show how to pass a full NPPES data frame loaded
into R and how to pass an existing DuckDB connection/table. Package checks must
not depend on the user's mounted drives, real provider data, CMS API, or
Tailscale/SMB availability. Mermaid/map dependencies remain optional to the
core matching API and are declared/documented for the vignette build.

## Verification and acceptance criteria

The feature is acceptable when:

1. One public call can take roster rows through candidate generation, evidence,
   conservative resolution, and rationale-bearing result outputs.
2. Type 1 filtering is the default in both backends; Type 2 organizations are
   excluded unless the caller deliberately changes the entity filter.
3. Candidate generation is bounded/indexed and there is no all-pairs join.
4. Name conflicts, tied candidates, contested NPIs, nickname-only candidates,
   fuzzy-only candidates, missing names, invalid NPIs, duplicate evidence paths,
   empty references, and unmatched records have explicit tested behavior.
5. Identical fixtures sent through data-frame and DuckDB backends return
   equivalent candidates, statuses, and rationale.
6. A read-only DuckDB source remains unchanged after a run; no persistent
   derived objects are written.
7. The synthetic vignette knits reproducibly offline, includes Mermaid diagrams,
   figures, and `mysterymaps` state maps, and demonstrates both backends without
   loading external data.
8. A manual smoke test against the available local DuckDB validates the NPPES
   column mapping and a small end-to-end Type 1 run; package CI uses only
   synthetic fixtures.

## Non-goals

- Replacing source-specific cohort or eligibility decisions in consumer
  repositories.
- Treating the public NPPES API as the national candidate source.
- Automatically resolving identity from nickname-only, fuzzy-only, or
  contested evidence.
- Geocoding NPPES addresses or making maps part of the identity decision.
- Claiming match probabilities, precision, or recall without an adjudicated
  validation set.
- Writing persistent indexes, match tables, or outputs into caller databases.
