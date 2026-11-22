# Standardised statistics from a match result

One tidy frame of named statistics, so a report does not have to reach
into the result's structure and compute its own rates (srr EA3.0). Every
rate is over \`nobs()\`, stated in the frame rather than implied.

The \`columns\` element reports the class and storage mode of every
column of the matched table, which is what srr EA5.3 asks of a
column-based summary: an identifier silently stored as a double is a
defect you can only see if something tells you the storage mode.

## Usage

``` r
# S3 method for class 'npi_match_result'
summary(object, digits = 3L, ...)
```

## Arguments

- object:

  an \`npi_match_result\`.

- digits:

  \[integer(1)\] precision for the reported proportions. The explicit
  numeric-precision control srr EA4.1 asks for; the default of 3 is
  stated rather than inherited from \`options(digits)\`.

- ...:

  ignored.

## Value

a list of two data frames, \`statistics\` and \`columns\`, with class
\`"summary.npi_match_result"\`.
