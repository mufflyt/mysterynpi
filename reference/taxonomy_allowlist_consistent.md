# Test taxonomy codes against a specialty allowlist

Convenience wrapper over \[taxonomy_consistent()\] for the common case
where a caller has a vector of exact NUCC codes or profession-family
prefixes. The full pipe-concatenated taxonomy string is inspected, so a
residency or student code ahead of the specialty code cannot hide the
specialty code.

## Usage

``` r
taxonomy_allowlist_consistent(taxonomy, allowlist)
```

## Arguments

- taxonomy:

  Character vector of pipe-concatenated NUCC codes.

- allowlist:

  Character vector of exact codes or prefixes. Elements are treated as
  alternatives.

## Value

Logical vector: \`TRUE\` when any code starts with any allowlist
element, \`FALSE\` when codes exist but none do, and \`NA\` when either
side is missing.

## Examples

``` r
taxonomy_allowlist_consistent("390200000X|208800000X", c("208800000X", "2088F0040X"))
#> [1] TRUE
```
