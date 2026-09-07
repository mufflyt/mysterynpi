# The governed source-class registry

The ONE place source classes and their expansion permissions are
defined. \[npi_search()\] resolves its gate by lookup here – never by
string-matching source names, and with no fallback: a class this table
does not name cannot be passed at all, and \`unknown\` fails closed.

## Usage

``` r
SOURCE_CLASSES
```

## Format

data.frame with columns \`class\` and \`expansion\` (\`"forbidden"\`,
\`"review_only"\`, or \`"fail_closed"\`).
