# The six agreement axes for a benchmark-shaped table

Applies \[surname_agreement()\], \[nickname_agreement()\],
\[middle_agreement()\], \[suffix_agreement()\], \[gender_agreement()\]
and \[license_agreement()\] to a table of paired roster/registry
records, and flags the maiden-as-middle pairs whose middle-name conflict
must not veto (the roster's middle token \*is\* the registry surname, so
the surname rescue has already used it).

## Usage

``` r
benchmark_axes(data = mysterynpi::ROSTER_BENCHMARK)
```

## Arguments

- data:

  \[data.frame\] shaped like \[ROSTER_BENCHMARK\]: \`roster_name\`,
  \`roster_gender\`, \`roster_state\`, \`roster_license\`,
  \`npi_first\`, \`npi_middle\`, \`npi_last\`, \`npi_suffix\`,
  \`npi_gender\`, \`npi_state\`, \`npi_license\`.

## Value

\[data.frame\] one row per input row: the six axes plus \`excused\`.

## Examples

``` r
head(benchmark_axes(ROSTER_BENCHMARK[1:5, ]), 3)
#>        surname        given        middle        suffix       gender
#> 1 corroborates corroborates uninformative uninformative corroborates
#> 2 corroborates corroborates uninformative uninformative corroborates
#> 3 corroborates corroborates uninformative uninformative corroborates
#>        license excused
#> 1 corroborates   FALSE
#> 2 corroborates   FALSE
#> 3 corroborates   FALSE
```
