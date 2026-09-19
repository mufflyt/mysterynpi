# SQL: middle initials must not contradict (absence is never contradiction)

Boolean predicate for a join: passes when EITHER side lacks a middle
initial, fails only on a live mismatch of first letters. Measured
origin: the isochrones matcher's fallback tiers carried NO
middle-initial condition and ran 7.5 guard existed – a contradicting
initial on a name-only match is close to direct wrong-person evidence,
and this predicate is how a candidate query refuses those rows without
ever treating a missing initial as evidence.

## Usage

``` r
sql_middle_initial_guard(left_initial_expr, right_middle_col)
```

## Arguments

- left_initial_expr:

  character(1): SQL expression yielding the roster side's single-letter
  initial (may be a bound column or a literal).

- right_middle_col:

  character(1): SQL column expression holding the registry side's middle
  NAME (the first letter is extracted in SQL).

## Value

character(1) SQL boolean expression.

## See also

Other sql-join-keys:
[`sql_first_initial()`](https://mufflyt.github.io/mysterynpi/reference/sql_first_initial.md),
[`sql_name_clean()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_clean.md),
[`sql_name_compact()`](https://mufflyt.github.io/mysterynpi/reference/sql_name_compact.md),
[`sql_quote_literal()`](https://mufflyt.github.io/mysterynpi/reference/sql_quote_literal.md),
[`sql_strip_parenthetical()`](https://mufflyt.github.io/mysterynpi/reference/sql_strip_parenthetical.md)
