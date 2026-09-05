# mysterynpi

<!-- badges: start -->
[![R-CMD-check](https://github.com/mufflyt/mysterynpi/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/mufflyt/mysterynpi/actions/workflows/R-CMD-check.yaml)
[![Codecov test coverage](https://codecov.io/gh/mufflyt/mysterynpi/graph/badge.svg)](https://app.codecov.io/gh/mufflyt/mysterynpi)
<!-- badges: end -->

One definition of the name handling a provider linkage needs: transliterating
join keys, given/middle/surname tokenisation, and the rules that decide whether
two records name the same person.

**Every rule here encodes a defect that already shipped in a real pipeline, and
each ships with the test that catches its return.** That is the whole design.
The functions are small; the comments and the tests are the product.

```r
# install.packages("remotes"); remotes::install_local("~/mysterynpi")
library(mysterynpi)

middle_agreement(middle_tokens("A REINHARD"), middle_tokens("REINHARD"))
#> "corroborates"     -- a shared token, wherever each side keeps it
middle_agreement(middle_tokens("VL"), middle_tokens("VELMA LAURITZEN"))
#> "corroborates"     -- concatenated initials are initials
middle_agreement(middle_tokens("JULIA"), middle_tokens("JULIE"))
#> "conflicts"        -- no edit-distance tolerance, deliberately
middle_agreement(middle_tokens(""), middle_tokens("MARIE"))
#> "uninformative"    -- absence is never evidence of difference
```

## Why this is a package and not another `source()`

The pipelines this was extracted from already shared code across repositories.
**That sharing is what broke.** A consolidation upstream moved a resolver's
default identifier column; a caller relying on the default died fifteen minutes
into a run, twice. The loud failure was the lucky one — a caller whose data
happened to carry a column named by the *new* default would have enforced its
one-to-one constraint over the wrong identifier and produced a clean-looking,
wrong cohort.

Co-locating code does not fix that. Three things do, and they are the point of
packaging:

1. **One definition.** A second copy of a name normaliser is how two pipelines
   quietly disagree about who matched whom.
2. **Versioning.** A `source()` across repos has no version at all. Here,
   changing a default is a major bump, not a Tuesday.
3. **Contracts you can assert.** `assert_middle_agreement_contract()` runs in
   *your* test suite. A breaking change fails in your CI instead of in your
   published numbers. It is written so it can also be run against a stand-in,
   because an assertion only the real implementation can pass is
   indistinguishable from one that always passes.

## The three defects that motivated it

| defect | symptom | rule |
|---|---|---|
| `nzchar(NA)` is `TRUE` | every absent middle name agreed with every other; the "no middle information" evidence class was empty | `has_name_information()` |
| naive normalisation preserves accents rather than stripping them | accented names could not reach their unaccented registry spelling by **any** blocking route; unmatched ran 30% against 10.4% | `name_key()` |
| middle names compared at position 1 | a maiden surname in a different slot scored as a disagreement and deleted the candidate; 82 rows lost their only match and were published as "no candidate" | `middle_agreement()` |

## What it covers

| stage | functions |
|---|---|
| keys | `name_key()`, `blank_na()`, `has_name_information()`, `first_initial()`, `strip_parenthetical()`, `split_given()` |
| tokens | `middle_tokens()`, `given_tokens()`, `surname_tokens()` |
| suffixes | `extract_suffix()`, `normalize_suffix()` — parse the suffix out *before* the noise strip deletes it |
| agreement | `middle_agreement()`, `person_matches()`, `gender_agreement()`, `nickname_agreement()`, `suffix_agreement()`, `license_agreement()` |
| ordered classes | `resolve_ordered_classes()` and its parts |
| one-to-one | `award_contested()`, `count_rivals()` |
| clerical review | `clerical_sample()`, `clerical_precision()` — blinded, class-stratified, seed-pinned |
| contracts | `assert_middle_agreement_contract()` and one per agreement rule |

See `vignette("resolving-a-roster")`.

The split between **mechanism** and **policy** is the design. "Collapse to one
row per (person, candidate), take the strongest class, resolve only when that
class holds exactly one" is mechanism. *Which* classes exist and what evidence
earns each one is policy, and stays with you.

## What is deliberately NOT here

**Blocking.** Which candidates to generate — exact name, surname plus initial,
fuzzy surname, surname component — and which class each earns, is where a study
declares what it will claim from a name. That belongs in your pipeline, in code
a reviewer can read.

**Scoring gates.** Credential gates encode claims about identity, not facts
about strings. Gender is the partial exception: `gender_agreement()` ships the
*verdict* — do two recorded codes agree, disagree, or decide nothing — because
comparing recorded codes is a fact about fields. Whether a `"conflicts"`
verdict vetoes outright or routes to quarantine is still a claim about the
study, and stays with you.

**A method-priority lookup keyed on strategy names.** One existed upstream; it
contained none of the calling pipeline's method names, so every row missed the
lookup and was coalesced to a constant. A shared table that silently does
nothing is worse than no table.

**A blended match score.** A numeric threshold expresses a continuous question
about categorical evidence. The upstream version's margin constant turned out to
have zero-conflict behaviour that was *structural* — the candidates it compared
never coexisted — rather than evidence the threshold was right.

Two specific exclusions worth naming:

- **No edit-distance tolerance on the middle name.** One was added and removed
  the same day. Measured: it changed 64 of 30,740 candidate pairs and was worth
  22 records, while admitting pairs that are genuinely different given names
  (`JULIA`/`JULIE`, `LEE`/`LEA`, `ANN`/`ANNE`). It is not symmetric with fuzzy
  *surname* blocking, which generates a candidate that is then ranked below
  exact evidence; this suppressed a veto with no tier recording that it
  happened.
- **The nickname table is vendored; the decision to use it is not.** An
  earlier version of this README refused a nickname dictionary outright. The
  refusal was aimed at the *decision* — whether `BETH` may stand for
  `ELIZABETH` in a given study, and which evidence class that pairing earns —
  and that decision still stays with the caller. The *table* is different:
  every pipeline curating its own copy is how two pipelines quietly disagree
  about who matched whom, so one copy now ships (`NICKNAME_EDGES`, vendored at
  a pinned commit), with a one-hop rule (`nickname_agreement()`) that never
  closes the relation transitively — `AL` may stand for `ALBERT` or
  `ALEXANDER` without ever welding `ALBERT` to `ALEXANDER`.

## Versioning

Semantic. Any change that flips an assertion in
`assert_middle_agreement_contract()` is **major**. Adding a verdict, loosening a
conflict, or changing a default argument is major. Callers should run the
contract in their own suite and pin a version.

## Status

`0.1.0`, extracted from a working linkage but **not yet adopted by it**. The
migration — pointing `midwifery` and `isochrones` at this instead of their own
copies — is the next step and has not been done. Until then this is a fourth
copy, which is the thing it exists to prevent; adopt it or delete it.
