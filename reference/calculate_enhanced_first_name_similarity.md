# Nickname-aware first-name similarity SCORE (never a verdict)

A number for RANKING candidates, extracted verbatim from isochrones: 1.0
exact after normalisation; 0.98 one-hop nickname equivalent under the
consolidated corpus (the same relation the verdict rule corroborates
on); 0.5 neutral for missing; otherwise Jaro-Winkler similarity (the
larger of raw and umlaut-digraph-simplified). The old extraction's
0.96/0.94 sub-tiers were artifacts of the retired two-table shape and
are consolidated into 0.98. Scores rank; only agreement rules decide,
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

## Details

OFF BY DEFAULT: calling this without
\`options(mysterynpi.enable_similarity_scoring = TRUE)\` stops with
instructions. The opt-in line belongs in the pipeline script it governs,
where a reviewer reads it – approximate scoring must be a decision,
never a default.
