# Refuse list columns, with the reason

A list column reaching a string comparison does not error: it
stringifies, and the comparison then runs on \`"c(\\A\\, \\B\\)"\`. That
is worse than failing, so this fails (srr G2.12).

## Usage

``` r
reject_list_columns(x, arg = "input")
```

## Arguments

- x:

  \[data.frame\] to inspect.

- arg:

  \[character(1)\] the argument name, for the message.

## Value

\`x\`, invisibly, when no column is a list.

## Examples

``` r
reject_list_columns(data.frame(a = 1:2), "roster")
```
