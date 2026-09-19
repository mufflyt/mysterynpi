# Full given-name tokens, initials excluded

Tokens of length \>= 2 drawn from the given and middle name fields.
Initials are excluded ON PURPOSE: "W." is compatible with every W and
identifies nobody, so it must never enter a set that is compared by
intersection. \[name_leading_given()\] retains them for the one
comparison where an initial does carry information.

## Usage

``` r
name_given_tokens(first, middle = NULL)
```

## Arguments

- first, middle:

  \`character\`: given and middle name fields. \`middle\` may be
  \`NULL\`.

## Value

\`list\` of \`character\` token vectors, one per input element.

## A hyphen never splits a token

"Mary-Jane" is ONE given name. Splitting it into \`"MARY"\`/\`"JANE"\`
let a compound given name satisfy \[names_have_compatible_given()\]'s
\`mode = "any_token"\` shared-token test against an unrelated "Jane" who
shares nothing but the second half of the compound – the same false-
corroboration defect \[name_key()\]'s \`fold_hyphens\` documentation
describes for given names generally (three cross-state false identity
matches), just not yet applied to this tokeniser. Consistent with
\[split_given()\], which already never folds a given-name hyphen.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)
