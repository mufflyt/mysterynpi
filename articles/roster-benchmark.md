# The roster benchmark: 190 labeled pairs, and what they measure

No public benchmark exists for physician-roster-to-NPPES name matching:
NPPES describes real providers, so a labeled gold standard would name
real people, and nobody ships one. `ROSTER_BENCHMARK` is the synthetic
alternative – 190 (roster record, registry candidate) pairs, truth
assigned **by construction** in reviewable code, each pair carrying the
name of the defect family it encodes. The authoring rule: *a pair whose
truth a reviewer could not assign did not go in.* (That rule has teeth.
The first draft’s spelling-trap family paired `Julia Bennett` against
`JULIE BENNETT` with nothing else recorded and called it a nonmatch –
but no reviewer could know that, and the nickname corpus records
`JULIA`/`JULIE` as substitutable usage. The shipped rows carry
conflicting middle initials, so the deciding evidence is real and
spelling alone decides nothing, in either direction.)

``` r

table(ROSTER_BENCHMARK$family, ROSTER_BENCHMARK$truth)
#>                          
#>                           match nonmatch
#>   absence                     8        0
#>   common-name-collision       0       10
#>   compound-surname           12        0
#>   cross-gender-derivative     0        8
#>   exact                      10        0
#>   formatting                 12        0
#>   hub-nickname                0        6
#>   initials                   10        4
#>   license-anchor              8        4
#>   maiden-as-middle           12        0
#>   nickname                   16        0
#>   noise                      12        0
#>   spelling-trap               0       10
#>   stacked-defects            10        6
#>   stale-gender                6        0
#>   suffix-generations          6       10
#>   transliteration            10        0
```

## A reference policy from the package’s own rules

Pairs are pre-formed (blocking is the pipeline’s job, not this
package’s), so the policy is pure agreement: parse the roster’s free
text, compare every axis, veto on hard conflicts, quarantine gender
conflicts at the top, accept what the name evidence earns.

``` r

b  <- ROSTER_BENCHMARK
ex <- extract_suffix(b$roster_name)          # BEFORE the noise strip eats it
p  <- parse_person(ex$name)

axes <- data.frame(
  surname = surname_agreement(p$last, b$npi_last,
                              middle_a = p$middle, middle_b = b$npi_middle),
  given   = nickname_agreement(sub(" .*", "", p$first), b$npi_first),
  middle  = middle_agreement(middle_tokens(p$middle),
                             middle_tokens(b$npi_middle)),
  suffix  = suffix_agreement(ex$suffix, b$npi_suffix),
  gender  = gender_agreement(b$roster_gender, b$npi_gender),
  license = license_agreement(b$roster_license, b$roster_state,
                              b$npi_license, b$npi_state))
```

One refinement the maiden-as-middle family forces, and which any real
pipeline needs: when the roster’s middle token **is** the registry’s
surname, it is a former surname sitting in a middle slot – the surname
rescue has already used it – and its middle-name “conflict” must not
veto:

``` r

excused <- mapply(function(mt, nl) length(intersect(mt, surname_tokens(nl))) > 0,
                  middle_tokens(p$middle), b$npi_last)

conflict <- axes$surname == "conflicts" |
  axes$given == "conflicts" |
  (axes$middle == "conflicts" & !excused) |
  axes$suffix == "conflicts"
name_ok <- axes$surname == "corroborates" & axes$given == "corroborates"

decision <- ifelse(conflict, "reject",
            ifelse(!name_ok, "review",
            ifelse(axes$gender == "conflicts", "review", "accept")))
table(decision, truth = b$truth)
#>         truth
#> decision match nonmatch
#>   accept   126        0
#>   reject     0       58
#>   review     6        0
```

Every accept is a true match, every reject a true nonmatch, and the
review queue is exactly the stale-gender family: true matches whose
recorded gender codes conflict, routed to a person instead of deleted –
the policy
[`vignette("vetoes-and-quarantine")`](https://mufflyt.github.io/mysterynpi/articles/vetoes-and-quarantine.md)
argues for, doing its job.

Two honest caveats. First, this is the package evaluated on a corpus
built from the package’s own defect taxonomy – the families are the
failure modes these rules were written against, so clean separation is
*consistency*, not proof of generality; foreign corpora like
\[WINKLER_CENSUS\] exist to be harder. Second, the benchmark measures
the agreement rules, not blocking: every pair here was already formed.

The construction itself paid once already: the first evaluation run
rejected three formatting-family matches because
[`extract_suffix()`](https://mufflyt.github.io/mysterynpi/reference/extract_suffix.md)
was eating the comma that
[`parse_person()`](https://mufflyt.github.io/mysterynpi/reference/parse_person.md)’s
“Last, First” reversal needs. That defect is now fixed and pinned in the
suffix tests – which is the benchmark working as designed.

## From decisions to publishable numbers

The clerical machinery turns the accepted and quarantined pairs into
per-class precision with exact intervals. Class 1: license corroborates;
class 2: middle corroborates; class 3: name evidence alone; class 4:
quarantined for review.

``` r

kept <- data.frame(
  id = b$pair_id, candidate = paste0("N", seq_len(nrow(b))),
  evidence_class = ifelse(decision == "review", 4L,
                   ifelse(axes$license == "corroborates", 1L,
                   ifelse(axes$middle == "corroborates", 2L, 3L))),
  roster_name = b$roster_name,
  stringsAsFactors = FALSE)[decision != "reject", ]

s <- clerical_sample(kept, n_per_class = 12, seed = 20260905)
verdicts <- data.frame(
  review_id = s$key$review_id,
  is_match = b$truth[match(s$key$id, b$pair_id)] == "match")
clerical_precision(s$key, verdicts)
#>   evidence_class n_sampled n_reviewed n_match precision    ci_low ci_high
#> 1              1        12         12      12         1 0.7353515       1
#> 2              2         1          1       1         1 0.0250000       1
#> 3              3        12         12      12         1 0.7353515       1
#> 4              4         6          6       6         1 0.5407419       1
```

In a real study the `is_match` column comes from a blinded human
reviewer, not from stored truth; here the stored truth stands in to show
the workflow. The class-4 row is the payoff to notice: quarantine turned
six would-be deletions into six reviewed true matches.

The benchmark ships as plain CSV for use outside R:

``` r

system.file("extdata", "roster_benchmark.csv", package = "mysterynpi")
```
