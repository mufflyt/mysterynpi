# Which positions matched, under \`any_token\`

Retained as evidence so a caller can weight a shared FIRST name above a
shared MIDDLE name. A middle-name-only agreement is weak – common middle
names collide across unrelated people – and must remain distinguishable
so it is never silently promoted to identification.

## Usage

``` r
name_given_match_position(a_first, b_first, a_middle = NULL, b_middle = NULL)
```

## Arguments

- a_first, b_first:

  \`character\`: given-name fields.

- a_middle, b_middle:

  \`character\`: middle-name fields; may be \`NULL\`.

## Value

\`character\`: \`"both_leading"\`, \`"one_leading"\`,
\`"neither_leading"\`, or \`NA\` when no full token is shared.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)
