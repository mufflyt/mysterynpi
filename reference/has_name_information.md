# Does this field carry identity information?

NEVER use a naked \`nzchar()\` for this. \`nzchar(NA_character\_)\` is
\`TRUE\`, which reads missingness as evidence. In a real pipeline that
single fact made every absent middle name agree with every other absent
middle name: \`paste(NA_character\_, "")\` produced the literal
\`"NA"\`, every record gained a fabricated middle initial of \`N\`, all
18,397 candidate pairs reported middle agreement, and the evidence class
meaning "exact name, no middle information" was empty.

## Usage

``` r
has_name_information(x)
```

## Arguments

- x:

  character vector.

## Value

logical: \`TRUE\` where \`x\` is neither \`NA\` nor empty.
