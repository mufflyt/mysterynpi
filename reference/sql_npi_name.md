# SQL expression normalising a name column the same way R does

The join key must be built identically on both sides or the database
half of a pipeline quietly disagrees with the R half about who matched
whom. Requires a \`strip_accents\` UDF registered on the connection.

## Usage

``` r
sql_npi_name(col)
```

## Arguments

- col:

  character(1): a column expression.

## Value

character(1) SQL.
