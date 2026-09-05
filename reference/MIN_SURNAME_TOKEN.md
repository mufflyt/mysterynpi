# Minimum surname token length.

A real threshold, not a formatting detail: at 2 characters, particles
and initials become blocking keys and unrelated people collide. Pinned
by value in the tests so lowering it fails loudly rather than quietly
widening every candidate pool.

## Usage

``` r
MIN_SURNAME_TOKEN
```

## Format

An object of class `integer` of length 1.
