# Split a surname into comparable whole components

Returns the normalized whole-word components of a surname. Splitting on
any non-letter means "Barlow-Reed", "Barlow Reed" and "BARLOW REED"
produce the same components, so hyphenation differences between two
sources cannot cause a miss.

Particles (\`van\`, \`de\`, \`du\`, ...) are RETAINED as components
rather than stripped. They carry identity information, and because
comparison is by subset (see \[names_have_compatible_surname()\]) a
source that omits the particle still matches one that keeps it.

## Usage

``` r
name_surname_components(x)
```

## Arguments

- x:

  \`character\`: surname, possibly compound or hyphenated.

## Value

\`list\` of \`character\` component vectors, one per input element.
Components shorter than 2 characters are dropped.

## See also

Other name-matching:
[`NAME_SURNAME_PARTICLES`](https://mufflyt.github.io/mysterynpi/reference/NAME_SURNAME_PARTICLES.md),
[`name_given_match_position()`](https://mufflyt.github.io/mysterynpi/reference/name_given_match_position.md),
[`name_given_tokens()`](https://mufflyt.github.io/mysterynpi/reference/name_given_tokens.md),
[`name_leading_given()`](https://mufflyt.github.io/mysterynpi/reference/name_leading_given.md),
[`name_matching_primitives`](https://mufflyt.github.io/mysterynpi/reference/name_matching_primitives.md),
[`name_surname_match_type()`](https://mufflyt.github.io/mysterynpi/reference/name_surname_match_type.md),
[`names_have_compatible_given()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_given.md),
[`names_have_compatible_surname()`](https://mufflyt.github.io/mysterynpi/reference/names_have_compatible_surname.md)

## Examples

``` r
name_surname_components("Barlow-Reed")   # list(c("BARLOW", "REED"))
#> [[1]]
#> [1] "BARLOW" "REED"  
#> 
name_surname_components("van Erven")     # list(c("VAN", "ERVEN"))
#> [[1]]
#> [1] "VAN"   "ERVEN"
#> 
```
