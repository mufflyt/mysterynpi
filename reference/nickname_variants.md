# The one route from an input first name to additional queried names

The expansion PLAN a nickname-aware search executes: one row per name to
query, and for every row beyond the input itself, the exact dictionary
edge that put it there. One hop over \[NICKNAME_EDGES\], both
directions, never transitive closure: \`BILL\` reaches \`WILLIAM\`;
\`ALBERT\` reaches \`AL\` but never \`ALEXANDER\`; and although \`BILL\`
reaches \`FRED\` and \`FRED\` reaches \`FREDERICK\`, \`BILL\` never
reaches \`FREDERICK\` – the second hop exists in the corpus and is
deliberately not taken.

## Usage

``` r
nickname_variants(x, edges = mysterynpi::NICKNAME_EDGES, max_expansion = 25L)
```

## Arguments

- x:

  a single name token.

- edges:

  the corpus; defaults to \[NICKNAME_EDGES\]. A custom table needs only
  \`name\` and \`nickname\` columns; edge ids are derived, and its
  \`alias_dictionary_version\` is \`NA\` unless it carries a \`version\`
  attribute.

- max_expansion:

  hard ceiling on plan rows (queries), input row included. Exceeding it
  is an error, never a silent truncation.

## Value

data.frame: \`input_first_name\`, \`queried_first_name\`,
\`alias_edge_id\`, \`alias_dictionary_version\`. The input leads, the
variants follow sorted – a stable, auditable query plan. Zero rows when
\`x\` is \`NA\` or empty.

## Details

THIS IS THE ONLY PLACE FIRST-NAME EXPANSION MAY HAPPEN. A repo invariant
test enforces it: no function outside this one may read
\[NICKNAME_EDGES\] to manufacture query variants, and only
\[npi_search()\] may call this function. NPPES's API does its own alias
expansion BY DEFAULT, against a list nobody outside CMS can read, cite
or test; \[npi_search()\] turns that off unconditionally and this plan
is the daylight replacement.

PROVENANCE IS MANDATORY, so the return value is a data.frame, not a
vector: \`input_first_name\` (the normalised input),
\`queried_first_name\` (a name to send), \`alias_edge_id\` (the
\[NICKNAME_EDGES\] row responsible, \`NAME\>NICKNAME\`; \`NA\` on the
identity row), and \`alias_dictionary_version\` (the corpus version the
plan was computed against). When a variant is recorded in both
directions, the forward edge (\`input\>variant\`) is credited.

CARDINALITY IS GUARDED. The widest legitimate name in the shipped corpus
is CHRIS at 18 one-hop variants; \`max_expansion\` defaults just above
that, at 25. A plan that exceeds it is almost certainly a dictionary
defect, so the function STOPS rather than fanning out – raising
\`max_expansion\` explicitly is the review.
