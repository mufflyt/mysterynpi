# Is this a structurally valid NPI?

Ten digits with a Luhn check over the \`80840\` prefix. Cheap, and it
catches the truncated, shifted and concatenated identifiers that
otherwise join to nothing and look like a matching failure.

## Usage

``` r
npi_luhn_ok(npi)
```

## Arguments

- npi:

  character vector.

## Value

logical vector.
