# Resolve a name, possibly a nickname, to a canonical formal form

A hub nickname has SEVERAL formal roots (\`AL\` records dozens); this
returns the lexicographically first as a stable display value. Ranking
and equivalence never rely on it – \[are_nickname_equivalents()\] uses
ALL roots. Unknown names return normalised; NULL and length-one NA
return as given.

## Usage

``` r
get_canonical_name(name, nickname_dict)
```

## Arguments

- name:

  a name.

- nickname_dict:

  from \[create_nickname_dictionary()\]; NULL returns the input.

## Value

one formal name, or the normalised input when unknown.
