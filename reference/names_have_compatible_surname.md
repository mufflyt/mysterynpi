# Do two surnames describe the same family name?

Component subset in either direction. This admits the legitimate
variation between sources – \`Nelson\` against \`Nelson-Becker\`,
\`Dyer\` against \`Dyer Hill\` – while rejecting the containment
accidents that a substring test allows.

\*\*Never substring containment.\*\* \`str_detect(a, fixed(b))\` accepts
\`Anderson\` inside \`Sanderson\`, \`Williams\` inside \`Williamson\`
and \`Martin\` inside \`Martinez\`, each of which attributes one
person's record to another. Those differ WITHIN a component; subset
differs BY a component.

## Usage

``` r
names_have_compatible_surname(a, b)
```

## Arguments

- a, b:

  \`character\`: two surnames.

## Value

\`logical\` of the recycled length. \`NA\` or empty on either side
returns \`FALSE\` – absence is never evidence.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md)

## Examples

``` r
names_have_compatible_surname("Nelson", "Nelson-Becker")  # TRUE
#> [1] TRUE
names_have_compatible_surname("Anderson", "Sanderson")    # FALSE
#> [1] FALSE
```
