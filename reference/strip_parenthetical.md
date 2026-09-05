# Strip parenthesised alternate names, keeping word-internal brackets.

Rosters publish preferred names inline: \`"Cynthia (Cindi)"\`. The
bracket survives naive normalisation, and a downstream split then hands
the middle slot a literal \`"("\`, which equals no recorded initial
anywhere – so a middle-name veto deletes the whole candidate set. Every
affected row failed in the pipeline this was found in: 7 unmatched, 2
tied, none resolved.

## Usage

``` r
strip_parenthetical(x)
```

## Arguments

- x:

  character vector, already upper-cased.

## Value

character vector.

## Details

Two conventions appear and they mean opposite things:


      "Cynthia (Cindi) A."   separate token  -> an alternate name, dropped
      "C(arolyn) Diane"      inside a token  -> optional letters, KEPT

Deleting the group in the second case leaves a given name of \`"C"\`,
which is not a name – it is a blocking key that joins to every record
whose given name is a bare initial.
