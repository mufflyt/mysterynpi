% Documentation source: R/resolve.R
\name{resolve_one_to_one}
\alias{resolve_one_to_one}
\title{Resolve a ranked candidate table to an unambiguous one-to-one linkage}
\usage{
resolve_one_to_one(candidates, id = "id", candidate = "candidate", rank_by)
}
\arguments{
\item{candidates}{A data frame with one or more candidate rows per record.}

\item{id}{Character scalar naming the source-record identifier column.}

\item{candidate}{Character scalar naming the candidate-identity column.}

\item{rank_by}{A named character vector mapping ranking column names to
directions: \code{"asc"} (smaller is better) or \code{"desc"} (larger is
better). Earlier entries have precedence over later entries.}
}
\value{
A list with \code{resolved}, \code{quarantined}, \code{unmatched}, and
\code{counts}. The first three elements are data frames retaining the supplied
columns and adding \code{resolution_status}; quarantine statuses distinguish a
tie within a record from a candidate claimed by multiple records.
}
\description{
Applies caller-supplied lexicographic ranking independently to each record,
then enforces that a candidate is assigned to at most one record. A record is
resolved only when exactly one distinct candidate has its best ranking tuple.
If several records uniquely select the same candidate, all of those claims are
quarantined rather than awarding the candidate to the highest score or first
row. This is deliberately not a maximum-weight assignment.
}
\details{
Duplicate evidence rows for the same record-candidate pair are collapsed to
that pair's best ranking tuple. Equal-ranked duplicate rows are represented
deterministically by sorting their remaining scalar columns. Missing ranking
values rank below observed values; when all values for a ranking field are
missing, that field does not break the tie. Rows without a candidate are
returned separately as unmatched and never compete for a shared missing ID.

The caller owns candidate generation, evidence interpretation, and the meaning
and direction of each ranking field. This function only applies the supplied
order and ambiguity policy.
}
\examples{
candidates <- data.frame(
  person = c("A", "A", "B"), npi = c("n1", "n2", "n1"),
  source_priority = c(1L, 2L, 1L), agreement = c(90, 100, 85)
)
result <- resolve_one_to_one(
  candidates, id = "person", candidate = "npi",
  rank_by = c(source_priority = "asc", agreement = "desc")
)
result$resolved  # empty: A and B both uniquely claim n1
result$quarantined
}
