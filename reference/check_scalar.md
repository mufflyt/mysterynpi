# Assert that an argument is a single value

The length assertion srr G2.2 asks for, on the arguments that are scalar
by contract: a seed, a table name, an entity filter. A length-2 \`seed\`
would silently use its first element and make the draw irreproducible
from the methods section, which is the failure \`clerical_sample()\`
exists to prevent.

## Usage

``` r
check_scalar(x, arg = "argument", null_ok = FALSE)
```

## Arguments

- x:

  the value to check.

- arg:

  \[character(1)\] the argument name, for the message.

- null_ok:

  \[logical(1)\] whether \`NULL\` is acceptable.

## Value

\`x\`, invisibly.

## Examples

``` r
check_scalar(1L, "seed")
check_scalar(NULL, "table", null_ok = TRUE)
```
