# The leading given name, initials retained

The first token of the given-name field, INCLUDING a single-letter
initial. This is the one place an initial must survive: "Dowdle, S.
Addreina" has leading given \`S\`, and dropping it would leave
\`ADDREINA\` – the middle name – masquerading as the first, which is
exactly the collision the positional mode exists to prevent.

## Usage

``` r
name_leading_given(first)
```

## Arguments

- first:

  \`character\`: the given-name field.

## Value

\`character\` of the same length; \`NA\` where absent.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)
