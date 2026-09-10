# Canonical person-name matching primitives

Shared mechanics for deciding whether two person-name records describe
the same human, so that every consumer repository compares names ONE way
instead of each carrying its own. Ported from mufflyt/isochrones with
proven parity; see the file header for the two rewired seams.

## Two modes, chosen by the caller

Given-name comparison is NOT one rule. It depends on whether the source
preserves name ORDER:


      structured <-> structured   (registry fields <-> registry fields)
          -> mode = "positional_ie"

      unreliable free text <-> structured   (repository author string <-> record)
          -> mode = "any_token", with position retained as evidence

\*\*Mode is a property of the source contract, not of an individual
person's name.\*\* These functions never inspect a string and guess
which mode to use. A library that sniffs "does this look like free
text?" has buried an unauditable scientific decision in a heuristic; the
caller knows what it holds and must say so.

## Evidence for two modes

An external linkage experiment (AMCB midwifery project, 2026-08-16) ran
both rules over the same 35,038 repository author strings against 22,309
certificants, holding everything except candidate generation constant.
\`any_token\` produced a 19 projects; \`positional_ie\` produced 13
middle-name-only matches, 67 ambiguity resolutions, and 13 high-evidence
links only \`any_token\` could reach – people who publish under a middle
name.

Those percentages are PERMUTATION COLLISION PROXIES. They are not
false-positive rates, precision, sensitivity, specificity or accuracy:
no adjudicated truth set exists for those links. Neither mode dominated,
which is why both are kept.

## What is reused rather than reimplemented

Normalization is \[normalize_string()\] with whitespace collapse, which
folds Unicode, transliterates Latin to ASCII, and collapses whitespace.
Nickname equivalence is \[nickname_agreement()\]. Nothing here
re-derives either.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_surname_components()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_components.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)
