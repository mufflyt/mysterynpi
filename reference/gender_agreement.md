# Do two recorded genders agree, disagree, or decide nothing?

The blocking rule for name-to-name matching. Both inputs are passed
through \[normalize_gender()\], so \`"Female"\` vs \`"F"\` corroborates
rather than conflicting over an encoding difference.

## Usage

``` r
gender_agreement(a, b)
```

## Arguments

- a, b:

  character vectors of recorded gender codes, the same length. Raw
  encodings are fine; normalisation is applied internally.

## Value

character: \`"corroborates"\`, \`"conflicts"\`, or \`"uninformative"\`.

## Details

THREE VERDICTS, SAME CONTRACT AS \[middle_agreement()\]:

\* \`"corroborates"\` – both sides recorded and equal. This is WEAK
evidence: half the registry corroborates. It exists so a caller can
count it, not so a caller can rank on it. \* \`"conflicts"\` – both
sides recorded and different. This is the verdict a blocking caller acts
on. \* \`"uninformative"\` – either side unrecorded or unmapped. Absence
of a gender code is not evidence the people differ, and a caller must
never fold this verdict in with \`"conflicts"\`.

USE THE VETO WITH THE SAME DISCIPLINE AS ANY OTHER VETO. Recorded gender
can be stale or simply wrong – data entry, a transition the registry has
not caught up with, a source that coded the practice owner rather than
the provider. A caller that drops \`"conflicts"\` pairs should record
what it dropped (the \[count_rivals()\] pattern) rather than silently
deleting, so a row published as "no candidate" can be distinguished from
a row whose only candidate was vetoed on one field.
