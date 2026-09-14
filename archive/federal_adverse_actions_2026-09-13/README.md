# Archived: federal adverse-action harvester (2026-09-13)

**Status:** archived / retired. Not part of the mysterynpi package. Nothing
here is sourced by `pkgload::load_all()` (which loads only top-level `R/`),
run by the test suite (only `tests/testthat/`), or built into the package
(`archive/` is `.Rbuildignore`d). Kept for provenance and possible reuse.

## What this was

A single-session acquisition module (`federal_adverse_actions.R`, originally
`R/federal_adverse_actions.R`) harvesting six federal streams that publish
adverse actions against individuals:

| Stream | What | Access |
|---|---|---|
| HHS DAB | ALJ / Board decisions | (blocked) |
| SAM.gov exclusions | OPM FEHBP sanctions | keyed bulk extract |
| TRICARE | TRICARE-only exclusions | small HTML scrape |
| ORI | research-misconduct cases | HTML scrape |
| Federal Register | historical ORI notices | keyless API |
| DOJ | press releases | keyless API |

It returned source observations with provenance attached; it did not label any
physician retired. Two live traps it guarded against are documented in the
module header (the DOJ API silently ignoring unknown filters and returning the
full corpus; a filter that does nothing reading exactly like one that worked).

## Why it is archived

Two federal feeds it overlaps — **DEA controlled-substance registration
actions** and **FDA debarments** — were consolidated into the isochrones repo
as their permanent home (`R/federal_register_dea_actions.R`,
`R/federal_register_fda_debarments.R`,
`data/federal_adverse_actions/`, `docs/APPENDIX_FEDERAL_ADVERSE_ACTIONS.md`),
where the physician-workforce cohort work lives. mysterynpi handles
state-medical-board discipline and NPI/name resolution only, so this broader
federal harvester does not belong in the package. Archived rather than deleted
so the DOJ/SAM/ORI/TRICARE/OPM harvesting logic and its guards are not lost.

## Contents

- `federal_adverse_actions.R` — the module (was `R/`)
- `test-federal-adverse-actions.R` — its tests (was `tests/testthat/`)
- `data/HARVEST_README.md` — the harvest run's own notes
- `data/*.csv.gz` — the small committed harvest outputs (ORI current cases +
  Federal Register notices, TRICARE-only exclusions, FDA debarments). The
  larger regenerable outputs (OPM FEHB sanctions, DOJ checkpoints, parquet
  copies) were working-tree only and are not archived; regenerate from the
  module if needed.
