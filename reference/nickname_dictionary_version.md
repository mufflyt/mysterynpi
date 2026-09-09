# Version of the governed nickname dictionary

The one sanctioned way to learn the dictionary's version without reading
the dictionary. Consumers call this instead of touching
\`NICKNAME_EDGES\`, so the access-boundary invariant stays exact: only
the canonical module's own functions ever name the table.

## Usage

``` r
nickname_dictionary_version()
```

## Value

\`character(1)\` version string, or \`NA_character\_\` when the corpus
carries no version attribute.

## Details

Every consumer that records nickname provenance needs this string, so it
is part of the public contract rather than an internal helper. It was
defined but unexported until 2026-09-08, which meant downstream
repositories could not stamp the dictionary version they had actually
matched under without reaching past the boundary the export exists to
protect.

## See also

\[nickname_agreement()\], \[nickname_variants()\]

## Examples

``` r
mysterynpi::nickname_dictionary_version()
#> [1] "2026-09-06.1"
```
