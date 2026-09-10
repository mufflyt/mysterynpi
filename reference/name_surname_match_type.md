# How two surnames correspond, as an evidence type

The mechanics of surname comparison, reported as a TYPE rather than
collapsed to a Boolean, so a caller can weight exact identity above
weaker component-subset evidence. \[names_have_compatible_surname()\] is
the Boolean convenience wrapper (\`!= "none"\`).

- \`exact\`:

  normalized strings identical

- \`separator_equivalent\`:

  same components, different separators – "Barlow-Reed" against "Barlow
  Reed"

- \`concatenated_equivalent\`:

  one side dropped the separator entirely – "Abu-Ghazaleh" against
  "Abughazaleh". EXACT equality of the joined components, never
  containment, so ANDERSON cannot reach SANDERSON

- \`component_subset\`:

  one component set nests in the other – "Nelson" in "Nelson-Becker",
  "Dyer" in "Dyer Hill". Requires at least one NON-PARTICLE component on
  the nesting side

- \`none\`:

  no correspondence, or absent input

## Usage

``` r
name_surname_match_type(a, b)
```

## Arguments

- a, b:

  \`character\`: two surnames. Equal lengths, or one of length 1.

## Value

\`character\` of the recycled length.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)

## Examples

``` r
name_surname_match_type("Nelson", "Nelson-Becker")  # "component_subset"
#> [1] "component_subset"
name_surname_match_type("Van", "van Erven")         # "none" (particle only)
#> [1] "none"
```
