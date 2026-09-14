# Disciplinary-action data sources for mysterynpi

Reverse-engineering notes, verified live on 2026-09-13. Goal: attach state-medical-board
disciplinary actions (and ultimately original order PDFs) to NPIs, with provenance rigid
enough that an action can never be synthesized — an action exists only when an official
board record or FSMB record backs it.

## Target record schema

```
npi, state, license_number, board_name,
action_date, action_type, action_status, case_number,
order_id, order_url, order_pdf (sha256), order_text,
source, source_retrieved_at, match_method, match_confidence
```

---

## 1. FSMB MED API (authenticated; the authoritative machine route)

Spec: https://github.com/fsmb/med-api (FSMB's own repo). Verified 2026-09-13:
production rejects everything without OAuth (401), demo swagger URL is dead (404).

- Hosts: prod `https://services-med.fsmb.org/`, demo `https://services-med-demo.fsmb.org/`
- Auth: OAuth2 client credentials, `POST {base}/connect/token`
  (`client_id`, `client_secret`, `scope`, `grant_type=client_credentials`, form-encoded).
  Credentials only by contacting FSMB: pdc@fsmb.org
- Scopes: `med.read`, `med.order_read`, `med.pdc_read`, `med.source_read`, …

### The NPI → PDF chain

1. **NPI → FID** — `GET /v2/practitioners/search?firstName=&lastName=&npi=`
   (scope `med.read`). Returns `{"fid": "#########"}` (9-digit Federation ID).
   Name plus at least one identifying number (npi / dea / license / nccpaId) required.
2. **FID → orders** — the documented `GET /v2/practitioners/{fid}/verification`
   returns only `category` + action code/description — **no orderId, no dates**.
   The endpoint that carries full order metadata (`orders[].id`, board, dates, bases)
   is `GET /v2/practitioners/{fid}/pdcprofile` (scope `med.pdc_read`). Its docs were
   removed from the repo in May 2023 (PR #24) but it still ships in FSMB's public
   Postman collection, i.e. it appears to remain in service for entitled clients.
3. **orderId → PDF** — `GET /v2/boardOrders/{fid}/public/{orderId}`
   (scope `med.order_read`) returns the board-order PDF directly.

Demo environment has canned test FIDs (999999907–999999956; 999999915 = multiple
licenses and board orders) for integration tests once credentials exist.

**Status: blocked on credentials.** Action item: email pdc@fsmb.org for API access
and a PDC bulk-file quote (academic/research). Nothing on this API is callable anonymously.

## 2. DocInfo.org (free; FSMB's consumer front end — verified working)

DocInfo is FSMB's free public search. It exposes the same discipline facts
(state, action date, action type) as JSON through three unauthenticated,
same-origin endpoints. Verified live in a real browser session 2026-09-13:

```
GET https://www.docinfo.org/TypeAhead?docname={fragment}
  -> [{"name":"Tyler Mac Muffly","id":"2a734305-84b7-45a7-8e07-a23d02f3e4e4"}, ...]

GET https://www.docinfo.org/Search?docname={name}&pracType=Physician|PA|Both&licstate=all|{state}&from=0&size=30
  -> {"hits":[{"_id":"<guid>","_source":{"fullName","degreeCode","locations":[{city,state}]}}]}

GET https://www.docinfo.org/GetProfile?id={guid}
  -> {"_id":"<guid>","_source":{
        "fullName","graduationYear","medicalSchoolName","degreeCode",
        "certifications":[...],
        "locations":[{"city","state"}],
        "boardsActionsByState":[{
           "state","stateURL",
           "orders":[{"orderDate":"YYYY-MM-DD","action":"REVOCATION OF MEDICAL LICENSE"}]
        }]}}
```

Verified example (Christopher Duntsch, guid 16e4a3d3-ed9f-4530-883f-9c91f1738d9f):
TX 2013-06-26 summary suspension, TX 2013-12-06 revocation, TN 2014-01-29 voluntary
surrender — matches the public record exactly.

Constraints, all confirmed:

- **Behind Imperva/Incapsula.** Plain curl/httr gets a JS-challenge interstitial,
  not JSON. The endpoints only answer inside a real browser session. We do NOT
  build challenge-solving/bot-evasion into the package; that is both fragile and
  the wrong side of the line. Usable modes: (a) interactive clerical review —
  an analyst verifies flagged matches in their own browser; (b) a documented,
  low-volume, browser-driven session for small batches.
- **No NPI, no license numbers, no case numbers, no PDFs** anywhere in the JSON.
  Linkage to NPI is therefore name + location + specialty + graduation-year
  matching — exactly mysterynpi's core competence. `match_method` /
  `match_confidence` must be populated; DocInfo-derived rows can never be
  auto-accepted at low confidence.
- Search is name-required (no enumeration key), paged via `from`/`size`.
- Footer disclaimer: not valid for credentialing (Joint Commission/NCQA/DNV).

Role: **free verification/enrichment source for the discipline flag, action dates,
action types, and acting states.** Order PDFs still require FSMB API or the state
board itself.

## 3. FSMB PDC bulk data files (paid; the shortcut to national NPI-keyed data)

https://www.fsmb.org/PDC/pdc-data-files/ — 1.2M+ MD/DO/PA records, monthly updates,
**explicitly includes NPI and DEA**, licensure history and regulatory actions.
Delivered as files, MFT, or API. Quote-only pricing; no published academic tier.
If FSMB grants a reasonable research quote this obsoletes most matching work,
because the NPI linkage already exists inside FSMB's data.

## 4. Free NPI-keyed complements (bulk, no matching required)

- **HHS OIG LEIE** (https://oig.hhs.gov/exclusions/exclusions_list.asp): monthly CSV
  of federally excluded providers, carries NPI natively. Not board orders, but the
  highest-severity discipline signal and trivially joinable. Good first adapter.
- **SAM.gov exclusions**: federal debarment, NPI sometimes present.
- **NPDB Public Use File**: de-identified (no NPI by design) — useless for linkage,
  useful for calibrating expected action rates by state/specialty/year.

## 5. State-board bulk files (free backbone, state-by-state)

Several boards publish machine-readable action lists (TX TMB monthly actions,
CA MBC via DCA, FL MQA data portal, NY OPMC, NC, OH, WA DOH — WA pattern already
demonstrated by the WAFraudScan repo). These carry license numbers and case numbers,
and link to order PDFs — everything DocInfo lacks. Inventory and per-state adapters
are the follow-on task once the FSMB answer (credentials/quote) is known.

## 6-7. DEA registrant actions + FDA debarments (MOVED to isochrones, 2026-09-13)

The Federal Register acquisition layer (DEA 21 U.S.C. 823/824 registrant
actions, FDA 21 U.S.C. 335a debarments), the event taxonomy, the
exclusion-weight policy (adverse final orders 1.0 / favorable 0 / pending NA),
and the harvested tables now live in the isochrones repo:
`~/isochrones/R/federal_register_dea_actions.R`,
`R/federal_register_fda_debarments.R`,
`data/federal_adverse_actions/*.csv`, documented in
`docs/APPENDIX_FEDERAL_ADVERSE_ACTIONS.md` there. Key facts kept here so this
map stays complete: both feeds are per-person Federal Register notices via the
keyless API (the only two such federal series -- OIG exclusions, CMS
revocations, and FDA investigator disqualifications are NOT in the FR); DEA's
"Cases Against Doctors" app is dead (404); neither feed carries an NPI, so
linkage is mysterynpi's job (name + credential + state + city for DEA,
name-only for FDA).

## Provenance rules (non-negotiable)

1. An action row exists only with an official source record behind it
   (`source` ∈ {fsmb_med_api, docinfo, state:<XX>, oig_leie, ...}).
2. Retain the original order PDF when obtainable, plus its SHA-256, in `order_pdf`.
3. `source_retrieved_at` is mandatory; DocInfo rows additionally store the profile
   GUID in `order_url` position (`docinfo:{guid}`) since DocInfo has no order URLs.
4. Identity joins record `match_method` (npi_exact, license_exact, name_prob) and
   `match_confidence`; probabilistic joins below threshold go to clerical review,
   never silently into the dataset.

## Deeper FSMB API map

A fuller endpoint-by-endpoint map (incl. the AVR resource in open PR #27 and the
v1-vs-v2 history) is in `~/isochrones/docs/FSMB_MED_API_MAP_2026-09-13.md`
(written by a background research agent; relocate here if useful).
