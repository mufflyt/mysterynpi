# The 1,000 most frequent U.S. surnames, Census 2010

The top of the Census Bureau's "Frequently Occurring Surnames from the
2010 Census" file: aggregate frequencies, no individuals. Vendored for
term-frequency awareness – agreement on \`SMITH\` (rank 1) is weaker
evidence than agreement on a rare surname, and an ordered-class policy
may rank it accordingly – and for generating realistic synthetic
fixtures (\[ROSTER_BENCHMARK\] draws its surnames here).

## Usage

``` r
SURNAME_FREQUENCIES
```

## Format

data.frame with columns \`surname\`, \`rank\`, \`count\`, \`per_100k\`;
1,000 rows.

## Source

U.S. Census Bureau,
<https://www.census.gov/topics/population/genealogy/data/2010_surnames.html>
– a U.S. government work in the public domain. Derivation:
\`data-raw/SURNAME_FREQUENCIES.R\`.
