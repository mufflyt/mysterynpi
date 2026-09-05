# First initial of a name, punctuation and accents removed

Distinct from \[first_initial()\], and the difference is load-bearing.
This one strips non-letters BEFORE taking the character, so \`"(Sandra)
Theresa"\` yields \`"S"\`. \[first_initial()\] takes the first character
of the normalised key, which for that input is \`"("\` unless alternate
names were stripped.

## Usage

``` r
extract_first_initial(x)
```

## Arguments

- x:

  character vector.

## Value

character vector of single upper-case letters, \`NA\` where no letter is
present.

## Details

Neither is wrong; they answer different questions. Use this to summarise
a name for display or a coarse block; use \[first_initial()\] when the
initial must agree with the join key the rest of the match is built on,
because an initial that disagrees with its own key matches nothing.
