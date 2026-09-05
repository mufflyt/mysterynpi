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
whitespace normalised, commas preserved) and \`suffix\` (canonical label
or \`NA\`).

## Details

When a string carries more than one recognised suffix token the LAST one
wins (suffixes trail), and all of them are removed from the name.

COMMAS SURVIVE. The returned name keeps its commas (minus any left
dangling at the end), because \[parse_person()\]'s "Last, First"
reversal NEEDS them: an earlier version of this function split on commas
and rejoined with spaces, which silently turned \`"Thomas, William"\`
into \`"Thomas William"\` and handed the parser the surname as a given
name. The roster benchmark caught it – three formatting-family pairs
rejected on a comma this function had eaten.
