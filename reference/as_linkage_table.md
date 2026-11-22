# Coerce any tabular input to a plain data frame, loudly

Accepts a \`data.frame\` and anything that subclasses or converts to one
– \`tbl_df\`, \`data.table\`, a matrix with column names – and returns a
plain \`data.frame\`. The conversion is announced when it discards
anything a caller might expect to survive, which is the point: a silent
conversion is how a \`data.table\`'s reference semantics or an \`sf\`
geometry column disappears between the call and the join (srr G2.7,
G2.9).

## Usage

``` r
as_linkage_table(x, arg = "input", quiet = FALSE)
```

## Arguments

- x:

  tabular input.

- arg:

  \[character(1)\] the argument name, for messages.

- quiet:

  \[logical(1)\] suppress the conversion message. Defaults to \`FALSE\`,
  because the message is the standard.

## Value

\[data.frame\] a plain data frame with the same columns and rows.

## Examples

``` r
as_linkage_table(data.frame(id = 1:2, surname = c("A", "B")), "roster")
#>   id surname
#> 1  1       A
#> 2  2       B
as_linkage_table(matrix(c("1", "A"), nrow = 1,
                        dimnames = list(NULL, c("id", "surname"))), "roster")
#> roster converted from matrix to data.frame: every column becomes character, because a matrix has one type
#>   id surname
#> 1  1       A
```
