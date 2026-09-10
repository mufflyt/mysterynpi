# Are two given names compatible?

Two modes; the caller picks. See \[name_matching_primitives\] for the
source contract that determines which.

## Usage

``` r
names_have_compatible_given(
  a_first,
  b_first,
  a_middle = NULL,
  b_middle = NULL,
  mode
)
```

## Arguments

- a_first, b_first:

  \`character\`: given-name fields.

- a_middle, b_middle:

  \`character\`: middle-name fields; may be \`NULL\`.

- mode:

  \`character(1)\`: \`"positional_ie"\` or \`"any_token"\`.
  \*\*Required\*\* – omitting it is an error, never a default.

## Value

\`logical\` of the recycled length.

## mode = "positional_ie"

For structured-to-structured sources, where field order is reliable. The
LEADING given names are compared, and agree when any of these holds:

- they are equal after normalization;

- they are nickname variants of one another (\[nickname_agreement()\]
  corroborates), evaluated on FULL tokens only – an initial is never a
  nickname;

- \*\*initial expansion\*\*: one side is a single alphabetic character
  *I* and the other is a full token of \>= 2 characters beginning with
  *I*.

Invariants:

- an initial NEVER identifies a person on its own – initial expansion
  requires a full token on the opposite side;

- two initials on both sides (\`S.\` vs \`S.\`) do NOT admit a pair,
  even when they agree;

- a missing or empty given name on either side yields \`FALSE\`.

## mode = "any_token"

For unreliable free text against a structured record, where order cannot
be trusted – an author byline may be reordered, credential-laden, or
published under a middle name. Any shared FULL token admits a candidate.
Position is not discarded: call \[name_given_match_position()\]
alongside and carry the result, because a middle-only match must stay
distinguishable.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)

## Examples

``` r
names_have_compatible_given("Chad", "C", mode = "positional_ie")   # TRUE
#> [1] TRUE
names_have_compatible_given("C", "S", mode = "positional_ie")      # FALSE
#> [1] FALSE
```
