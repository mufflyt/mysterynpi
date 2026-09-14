# Federal adverse-action sources

Acquired by `R/federal_adverse_actions.R`. Every file is timestamped; nothing
here is overwritten, because two of these sources publish only what is CURRENTLY
active and history exists only if each pull is kept.

## Status, measured 2026-09-13

| source | route | records | note |
|---|---|---:|---|
| SAM.gov, OPM/FEHBP | keyed bulk extract | 40,601 of 168,458 | 40,595 carry `excluding_agency = OPM` |
| Federal Register, ORI | keyless API | 582 | 177 look like case notices, 1994 to 2026 |
| TRICARE-only | HTML, 9 pages | 128 of 129 | 56 MD/DO |
| ORI current cases | HTML | 28 | current administrative actions only |
| DOJ press releases | keyless API | crawling 272,247 | body-matched, roughly 0.3% hit rate |
| **HHS DAB** | **blocked** | **0** | **HTTP 403, every URL, every user agent** |

## What each source cannot tell you

**SAM** holds currently active exclusions only. A reinstated provider is simply
absent, so absence from one pull is never evidence of a clean record. Also, 38,001
of the 40,601 are `Reciprocal`, meaning they mirror another agency's action rather
than being an independent OPM finding. Treating the full count as independent
evidence would double-count exclusions the project already holds elsewhere.

**ORI's** case page lists only people who currently have administrative actions
and drops them when the period expires, which is why the Federal Register feed is
acquired alongside it rather than instead of it.

**TRICARE** reports its own last update as 2023-10-20. It also announces 129
records and renders 128; both numbers are carried per row rather than silently
reporting the smaller one.

**DOJ** releases are news items. A release describing a plea is strong evidence
but is not the signed plea agreement, so rows carry
`record_class = DOJ_PRESS_RELEASE`.

**HHS DAB** is the costliest gap. It is the only source here that states the NPI
in the decision text, which removes name resolution entirely. It is blocked at the
edge, not by a scraper defect.

## Nothing here labels a physician retired

These are source observations with provenance. Turning a sanction into a
workforce-exit inference is a separate and reviewable decision.
