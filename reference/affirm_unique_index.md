# Affirm that an index column is unique

EDA standards EA2.1 and EA2.5 ask that index uniqueness be affirmed as a
pre-processing step rather than assumed. \`resolve_one_to_one()\`
already affirms it on the roster side; this is the same check, exported
so it can be applied to the reference table too, where the package
previously assumed it.

## Usage

``` r
affirm_unique_index(x, col, arg = "input", action = c("error", "warn"))
```

## Arguments

- x:

  \[data.frame\] the table.

- col:

  \[character(1)\] the index column name.

- arg:

  \[character(1)\] the table's argument name, for the message.

- action:

  \[character(1)\] \`"error"\` (default) or \`"warn"\`.

## Value

\`x\`, invisibly.

## Examples

``` r
affirm_unique_index(data.frame(id = c("a", "b")), "id", "roster")
```
