# Match a source roster against user-provided NPPES data

One call takes roster rows through bounded candidate generation, shared
name evidence, conservative one-to-one resolution, and rationale-bearing
result partitions. \`nppes\` is either a data frame (the in-memory
backend) or a DuckDB DBI connection plus \`table\` (the DuckDB backend);
both backends use the same candidate blocks, evidence classes, reason
codes, tie behaviour, and output schema. The reference universe is
filtered to \`entity_filter\` (Type 1 individuals by default) before
matching.

## Usage

``` r
match_npi(
  roster,
  nppes,
  table = NULL,
  id,
  given = NULL,
  middle = NULL,
  surname = NULL,
  full_name = NULL,
  npi,
  entity_type,
  nppes_given = NULL,
  nppes_middle = NULL,
  nppes_surname = NULL,
  nppes_full_name = NULL,
  entity_filter = "1",
  backend = c("auto", "data.frame", "duckdb")
)
```

## Arguments

- roster:

  Source roster data frame, preserved in disposition partitions.

- nppes:

  Reference data frame or DuckDB DBI connection.

- table:

  Reference table identifier (name or \[DBI::Id()\]) for a DBI
  connection; must be \`NULL\` for a data frame.

- id:

  Stable, unique, nonblank source ID column.

- given, middle, surname, full_name:

  Source name column mappings.

- npi, entity_type:

  Reference NPI and entity-type column mappings.

- nppes_given, nppes_middle, nppes_surname, nppes_full_name:

  Reference name mappings.

- entity_filter:

  Entity type to include; defaults to individuals ("1").

- backend:

  One of "auto", "data.frame", or "duckdb".

## Value

A list with:

- matches:

  Roster rows with one uniquely supported NPI (reason
  \`unique_best_evidence\`).

- review:

  Roster rows with candidates that cannot safely resolve
  (\`ambiguous_tied_evidence\`, \`ambiguous_contested_candidate\`,
  \`nickname_only_evidence\`, \`fuzzy_only_evidence\`,
  \`weak_name_evidence\`, or a named conflict). No NPI is assigned; see
  \`candidates\`.

- unmatched:

  Roster rows with no candidate (\`no_candidate\`) or without enough
  source name (\`missing_required_name\`).

- candidates:

  One row per source/NPI identity pair with the blocking routes,
  evidence fields, evidence class, disposition, and reason.

- counts:

  Roster, partition, candidate, and reference-exclusion counts.

- run_manifest:

  Package and nickname-policy versions, backend, table, entity filter,
  column maps, candidate-generation settings, result column names, and
  input/exclusion row counts; \`execution_status\` is \`"complete"\`.

Source columns are preserved; result columns \`source_id\`, \`npi\`, and
\`reason\` are renamed with \[make.unique()\] when the roster already
uses those names (the names used are recorded in
\`run_manifest\$result_columns\`). NPI result columns are character.

## Details

Column mappings are character column names. Supply either given and
surname mappings (with optional middle), or a full-name mapping, for
each input. Full names use \[parse_person()\] and therefore require
humaniformat; the DuckDB backend requires structured reference given and
surname columns.

Candidate generation never compares every roster row with every
reference row: it joins exact surname/given keys, surname-component
variants, an exact-surname nickname block, and single-character deletion
signatures anchored on the exact opposite name. Nickname-only and
fuzzy-only evidence can surface a candidate for review but never
resolves a match on its own. A record resolves only when exactly one
eligible candidate holds its strongest evidence; ties, NPIs claimed by
more than one record, and name conflicts go to \`review\` with a stable
reason. The DuckDB source is read only: no persistent table is created,
replaced, or altered.

## Examples

``` r
roster <- data.frame(record = c("r1", "r2", "r3"),
                     first = c("Jane", "Bob", NA), last = c("Doe", "Smith", "Lee"))
nppes <- data.frame(provider = c("1234567893", "1245319599", "1004000000"),
                    type = c("1", "1", "2"),
                    first = c("Jane", "Robert", "Jane"), last = c("Doe", "Smith", "Doe"))
result <- match_npi(roster, nppes, id = "record", given = "first", surname = "last",
                    npi = "provider", entity_type = "type",
                    nppes_given = "first", nppes_surname = "last")
result$matches[, c("record", "npi", "reason")]
#>   record        npi               reason
#> 1     r1 1234567893 unique_best_evidence
result$review[, c("record", "reason")]
#>   record                 reason
#> 2     r2 nickname_only_evidence
result$unmatched[, c("record", "reason")]
#>   record                reason
#> 3     r3 missing_required_name
```
