# Vetoes and quarantine: using conflicts without deleting people

The agreement rules in this package report **verdicts** –
`"corroborates"`, `"conflicts"`, `"uninformative"` – and deliberately do
not decide what a verdict does. That split matters most for the two
rules whose conflicts are built on fields that are *sometimes wrong
about true matches*:

- **Gender.** A recorded code can be stale or simply wrong: data entry,
  a transition the registry has not caught up with, a source that coded
  the practice owner rather than the provider. The linkage literature’s
  guidance is consistent: disagreement on one error-prone field should
  not be unrecoverable when everything else agrees at the strongest
  class.
- **Surnames.** Marriage moves a surname wholesale. In a cohort where
  that is plausible – most physician cohorts – total surname
  disagreement alongside top-class agreement on given name and middle
  name is a case for review, not deletion.
  ([`surname_agreement()`](https://mufflyt.github.io/mysterynpi/reference/surname_agreement.md)’s
  maiden-as-middle rescue catches the cases where the old surname
  survives in a middle slot; this vignette is about the ones it cannot.)

The policy this vignette recommends: **a conflict vetoes in the weaker
evidence classes, and quarantines at the strongest one.** Fully
deterministic, and every action it takes is recorded.

## A cohort of two people

`r1`’s only strong candidate carries a conflicting gender code. `r2` is
the clean case.

``` r

cands <- data.frame(
  id              = c("r1",   "r1",   "r2",   "r2"),
  candidate       = c("N100", "N101", "N200", "N201"),
  gender_roster   = c("F",    "F",    "F",    "F"),
  gender_registry = c("M",    "F",    "F",    "M"),
  evidence_class  = c(1L,     2L,     1L,     2L),
  stringsAsFactors = FALSE)
cands$gender <- gender_agreement(cands$gender_roster, cands$gender_registry)
cands
#>   id candidate gender_roster gender_registry evidence_class       gender
#> 1 r1      N100             F               M              1    conflicts
#> 2 r1      N101             F               F              2 corroborates
#> 3 r2      N200             F               F              1 corroborates
#> 4 r2      N201             F               M              2    conflicts
```

## The policy that looks safe and is not

A hard veto drops every `"conflicts"` row before resolution:

``` r

hard <- cands[cands$gender != "conflicts", ]
resolve_ordered_classes(hard, tiebreak = "candidate")$resolved[
  , c("id", "candidate", "evidence_class")]
#>   id candidate evidence_class
#> 1 r1      N101              2
#> 2 r2      N200              1
```

`r1` resolves – to `N101`, its *class-2* candidate. If the registry’s
code for `N100` was the error (a true match with a wrong byte), the hard
veto did not just lose a match: it silently published a **different
identity** for a real person, with nothing in the output recording that
a stronger candidate was deleted on one field.

## Veto below, quarantine at the top

``` r

conflict  <- cands$gender == "conflicts"
top_class <- cands$evidence_class == min(cands$evidence_class)

vetoed      <- cands[conflict & !top_class, ]        # recorded, then removed
quarantined <- unique(cands$id[conflict & top_class])

kept <- cands[!(conflict & !top_class) & !cands$id %in% quarantined, ]
res  <- resolve_ordered_classes(kept, tiebreak = "candidate")

res$resolved[, c("id", "candidate", "evidence_class")]
#>   id candidate evidence_class
#> 1 r2      N200              1
quarantined
#> [1] "r1"
vetoed[, c("id", "candidate", "evidence_class")]
#>   id candidate evidence_class
#> 4 r2      N201              2
```

`r2` still resolves at class 1, and its class-2 rival’s veto is
**recorded** in `vetoed` – the \[count_rivals()\] discipline: a row
published as “no candidate” must be distinguishable from a row whose
candidate was deleted on one field. `r1` resolves to nothing; it goes to
review carrying the reason.

## Quarantine feeds review, review feeds numbers

The quarantined pairs are exactly what \[clerical_sample()\] is for: a
blinded reviewer decides whether `N100` is `r1` with a wrong code or a
different person, and \[clerical_precision()\] turns those decisions
into the per-class precision a methods section can print. The conflict
was never ignored and never fatal – it changed *who decides*, from the
pipeline to a person.
