# Resolve a ranked candidate table to an unambiguous one-to-one linkage

Applies caller-supplied lexicographic ranking independently to each
record, then enforces that a candidate is assigned to at most one
record. A record is resolved only when exactly one distinct candidate
has its best ranking tuple. If several records uniquely select the same
candidate, all of those claims are quarantined rather than awarding the
candidate to the highest score or first row. This is deliberately not a
maximum-weight assignment.

## Usage

``` r
resolve_one_to_one(candidates, id = "id", candidate = "candidate", rank_by)
```

## Arguments

- candidates:

  A data frame with one or more candidate rows per record.

- id:

  Character scalar naming the source-record identifier column.

- candidate:

  Character scalar naming the candidate-identity column.

- rank_by:

  A named character vector mapping ranking column names to directions:
  `"asc"` (smaller is better) or `"desc"` (larger is better). Earlier
  entries have precedence over later entries.

## Value

A list with `resolved`, `quarantined`, `unmatched`, and `counts`. The
first three elements are data frames retaining the supplied columns and
adding `resolution_status`; quarantine statuses distinguish a tie within
a record from a candidate claimed by multiple records.

## Details

Duplicate evidence rows for the same record-candidate pair are collapsed
to that pair's best ranking tuple. Equal-ranked duplicate rows are
represented deterministically by sorting their remaining scalar columns.
Missing ranking values rank below observed values; when all values for a
ranking field are missing, that field does not break the tie. Rows
without a candidate are returned separately as unmatched and never
compete for a shared missing ID.

The caller owns candidate generation, evidence interpretation, and the
meaning and direction of each ranking field. This function only applies
the supplied order and ambiguity policy.

## Examples

``` r
candidates <- data.frame(
  person = c("A", "A", "B"), npi = c("n1", "n2", "n1"),
  source_priority = c(1L, 2L, 1L), agreement = c(90, 100, 85)
)
result <- resolve_one_to_one(
  candidates, id = "person", candidate = "npi",
  rank_by = c(source_priority = "asc", agreement = "desc")
)
result$resolved  # empty: A and B both uniquely claim n1
#> [1] person            npi               source_priority   agreement        
#> [5] resolution_status
#> <0 rows> (or 0-length row.names)
result$quarantined
#>   person npi source_priority agreement             resolution_status
#> 1      A  n1               1        90 ambiguous_contested_candidate
#> 2      B  n1               1        85 ambiguous_contested_candidate
```
