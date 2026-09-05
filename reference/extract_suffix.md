# Pull the generational suffix out of a raw name string, keeping both parts

Run this BEFORE \[parse_person()\] or \[strip_name_noise()\]: both treat
suffix tokens as noise and delete them, which is correct for parsing and
fatal for the father/son veto. Token-based like \[strip_name_noise()\],
for the same reason – a regex alternation can match inside an accented
name.

## Usage

``` r
extract_suffix(x)
```

## Arguments

- x:

  character vector of raw name strings.

## Value

data.frame with \`name\` (the string with suffix tokens removed,
whitespace normalised) and \`suffix\` (canonical label or \`NA\`).

## Details

When a string carries more than one recognised suffix token the LAST one
wins (suffixes trail), and all of them are removed from the name.
