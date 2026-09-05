# Nickname-aware first-name similarity SCORE (never a verdict)

A number for RANKING candidates, extracted verbatim from isochrones: 1.0
exact after normalisation; 0.98 both map to one formal name; 0.96 one is
the other's canonical form; 0.94 cross-nickname; 0.5 neutral for
missing; otherwise Jaro-Winkler similarity (the larger of raw and
umlaut-digraph-simplified). Scores rank; only agreement rules decide,
and the no-fuzzy guard proves they cannot reach this function.

## Usage

``` r
calculate_enhanced_first_name_similarity(name1, name2, nickname_dict = NULL)
```

## Arguments

- name1, name2:

  names to compare.

- nickname_dict:

  from \[create_nickname_dictionary()\]; NULL falls back to plain
  Jaro-Winkler.

## Value

numeric in \`\[0, 1\]\`.
