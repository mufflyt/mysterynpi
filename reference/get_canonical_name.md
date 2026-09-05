# Resolve a name, possibly a nickname, to its canonical formal form

Resolve a name, possibly a nickname, to its canonical formal form

## Usage

``` r
get_canonical_name(name, nickname_dict)
```

## Arguments

- name:

  a name; NULL and length-one NA return as given.

- nickname_dict:

  from \[create_nickname_dictionary()\]; NULL returns the input.

## Value

the formal name, or the normalised input when unknown.
