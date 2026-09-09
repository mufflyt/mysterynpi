#!/usr/bin/env Rscript

suppressPackageStartupMessages(pkgload::load_all(".", quiet = TRUE))

external_maps <- list(
  list(
    repo = "mufflyt/isochrones",
    sha = "c03c3733f8376af49bb2e141ec5970424299a43f",
    path = "R/strategies/strategy_19_name_alias.R",
    symbol = "NICKNAME_MAP",
    map = list(
      ELIZABETH = c("LIZ", "BETH", "ELIZA", "BETTY", "ELLIE", "LIZA", "LISA"),
      KATHERINE = c("KATE", "KATIE", "KAT", "KATHY", "KATY"),
      CATHERINE = c("CATHY", "CAT", "KATE", "KATIE"),
      MARGARET = c("MEG", "MAGGIE", "PEGGY", "MARGE", "PEG"),
      JENNIFER = c("JEN", "JENNY", "JENNIE"),
      PATRICIA = c("PAT", "PATTY", "TRICIA", "TRISH"),
      STEPHANIE = c("STEPH", "STEVIE"),
      ALEXANDRA = c("ALEX", "LEXI", "LEXIE", "SANDRA"),
      CHRISTINA = c("CHRIS", "TINA", "CHRISTI"),
      NATALIE = c("NAT", "NATTY"),
      DEBORAH = c("DEB", "DEBBIE", "DEBBY"),
      BARBARA = c("BARB", "BARBIE"),
      CAROLYN = c("CAROL", "CARRIE"),
      MEREDITH = c("MERI", "MERRY"),
      SAMANTHA = c("SAM", "SAMMIE"),
      ALLISON = c("ALLIE", "ALI"),
      DANIELLE = c("DANI", "DANNY")
    )
  ),
  list(
    repo = "mufflyt/isochrones",
    sha = "c03c3733f8376af49bb2e141ec5970424299a43f",
    path = "R/real_database_integration.R",
    symbol = "nickname_map",
    map = list(
      JENNIFER = c("JEN", "JENNY"),
      JEN = c("JENNIFER", "JENNY"),
      JESSICA = c("JESS", "JESSIE"),
      MICHAEL = c("MIKE", "MICKEY", "MICK"),
      THOMAS = c("TOM", "TOMMY", "THOM"),
      MEGAN = c("MEG", "MEGGIE"),
      JOSEPH = c("JOE", "JOEY"),
      CAMILLE = c("CAMI", "CAM")
    )
  ),
  list(
    repo = "mufflyt/isochrones",
    sha = "c03c3733f8376af49bb2e141ec5970424299a43f",
    path = "scripts/match_aao_to_nppes.R",
    symbol = "NICKNAMES",
    map = list(
      WILLIAM = c("BILL", "BILLY", "WILL"),
      ROBERT = c("BOB", "ROB", "BOBBY"),
      JOHN = c("JACK", "JOHNNY"),
      JAMES = c("JIM", "JIMMY", "JAY"),
      THOMAS = c("TOM", "TOMMY"),
      RICHARD = c("DICK", "RICH", "RICK", "RICKY"),
      MICHAEL = c("MIKE", "MICK"),
      DANIEL = c("DAN", "DANNY"),
      DAVID = c("DAVE", "DAVY"),
      CHRISTOPHER = "CHRIS",
      MATTHEW = c("MATT", "MATTY"),
      STEVEN = "STEVE",
      STEPHEN = "STEPH",
      ANDREW = c("ANDY", "DREW"),
      ANTHONY = "TONY",
      NICHOLAS = c("NICK", "NICKY"),
      ALEXANDER = "ALEX",
      JOSEPH = c("JOE", "JOEY"),
      PETER = "PETE",
      PATRICK = "PAT",
      SAMUEL = "SAM",
      JOSHUA = "JOSH",
      KENNETH = "KEN",
      JEFFREY = "JEFF",
      GREGORY = "GREG",
      FREDERICK = c("FRED", "FREDDY"),
      CHARLES = c("CHUCK", "CHARLIE"),
      ALBERT = c("AL", "BERT"),
      BENJAMIN = "BEN",
      NATHANIEL = c("NATE", "NAT"),
      FRANCIS = "FRANK",
      ELIZABETH = c("LIZ", "BETH", "BETTY"),
      KATHERINE = c("KATE", "KATHY", "KAY"),
      CATHERINE = c("CATHY", "CAT"),
      SUSAN = c("SUE", "SUSIE"),
      CYNTHIA = "CINDY",
      PATRICIA = c("PATTY", "TRISH"),
      JENNIFER = c("JENNY", "JEN"),
      ANNE = c("ANNIE", "ANN"),
      MARGARET = c("MAGGIE", "MEG", "PEGGY")
    )
  ),
  list(
    repo = "mufflyt/obgyns",
    sha = "bc5b6fb7854f8f1cf35a580d3e3e4b66e4c023f1",
    path = "R/03.1-real_database_integration.R",
    symbol = "nickname_map",
    map = list(
      JENNIFER = c("JEN", "JENNY"),
      JEN = c("JENNIFER", "JENNY"),
      JESSICA = c("JESS", "JESSIE"),
      MICHAEL = c("MIKE", "MICKEY", "MICK"),
      THOMAS = c("TOM", "TOMMY", "THOM"),
      MEGAN = c("MEG", "MEGGIE"),
      JOSEPH = c("JOE", "JOEY"),
      CAMILLE = c("CAMI", "CAM")
    )
  ),
  list(
    repo = "mufflyt/obgyns",
    sha = "bc5b6fb7854f8f1cf35a580d3e3e4b66e4c023f1",
    path = "R/centralized_npi_matching.R",
    symbol = "check_nickname_match::nicknames",
    map = list(
      ROBERT = c("BOB", "ROB", "BOBBY"),
      WILLIAM = c("BILL", "WILL", "BILLY"),
      ELIZABETH = c("LIZ", "BETH", "BETTY", "ELIZA"),
      KATHERINE = c("KATE", "KATHY", "KAT", "KATIE"),
      RICHARD = c("RICK", "DICK", "RICH"),
      MARGARET = c("MEG", "MAGGIE", "PEGGY"),
      JAMES = c("JIM", "JIMMY", "JAMIE"),
      MICHAEL = c("MIKE", "MICKEY"),
      CHRISTOPHER = c("CHRIS", "KIT"),
      PATRICIA = c("PAT", "PATTY", "TRISH")
    )
  )
)

rejects <- list(
  list(a = "JEN", b = "JENNIFER", cls = "REJECT_DIRECTIONAL_AMBIGUITY",
       why = "reverse edge from a hypocorism to its formal; the corpus is directed formal>nickname"),
  list(a = "JEN", b = "JENNY", cls = "REJECT_DIRECTIONAL_AMBIGUITY",
       why = "map keys this entry on a hypocorism; the edge runs through a nickname instead of a formal"),
  list(a = "MEREDITH", b = "MERRY", cls = "NEEDS_ADJUDICATION",
       why = "MERRY also attaches to MARY; cross-formal risk"),
  list(a = "DANIELLE", b = "DANNY", cls = "NEEDS_ADJUDICATION",
       why = "DANNY attaches predominantly to DANIEL; directional ambiguity"),
  list(a = "RICHARD", b = "DICK", cls = "NEEDS_ADJUDICATION",
       why = "valid traditional nickname but high downstream ambiguity; keep out until governed explicitly"),
  list(a = "CHRISTOPHER", b = "KIT", cls = "NEEDS_ADJUDICATION",
       why = "valid but uncommon in medical datasets; needs governed review before admission")
)

normalize_name <- function(x) {
  toupper(trimws(gsub("[^A-Za-z]", "", x)))
}

nickname_edges <- mysterynpi::NICKNAME_EDGES
dictionary_version <- mysterynpi::nickname_dictionary_version()
governed_forward_edges <- unique(paste(nickname_edges$name,
                                       nickname_edges$nickname, sep = ">"))
governed_reverse_pairs <- unique(paste(nickname_edges$nickname,
                                       nickname_edges$name, sep = ">"))
known_nicknames <- unique(nickname_edges$nickname)
explicit_supported_edges <- character(0)

reject_keys <- stats::setNames(
  seq_along(rejects),
  vapply(rejects, function(x) paste(normalize_name(x$a), normalize_name(x$b), sep = ">"),
         character(1))
)

classify_edge <- function(formal, nickname) {
  key <- paste(formal, nickname, sep = ">")
  reject_idx <- unname(reject_keys[key])
  if (!is.na(reject_idx)) {
    return(list(
      classification = rejects[[reject_idx]]$cls,
      reason = rejects[[reject_idx]]$why
    ))
  }
  if (key %in% governed_forward_edges) {
    return(list(
      classification = "ALREADY_PRESENT",
      reason = "forward edge already governed by the current dictionary"
    ))
  }
  if (key %in% governed_reverse_pairs) {
    return(list(
      classification = "REJECT_DIRECTIONAL_AMBIGUITY",
      reason = paste(
        "reverse of a governed formal>nickname edge;",
        "the external row is not an independently governed forward edge"
      )
    ))
  }
  if (formal %in% known_nicknames && !(formal %in% nickname_edges$name)) {
    return(list(
      classification = "REJECT_DIRECTIONAL_AMBIGUITY",
      reason = paste(
        "map is keyed on a name the corpus already knows as a hypocorism;",
        "the corpus is directed formal>nickname"
      )
    ))
  }
  if (key %in% explicit_supported_edges) {
    return(list(
      classification = "SUPPORTED_NEW_EDGE",
      reason = "explicit positive evidence encoded in the audit generator"
    ))
  }
  list(
    classification = "NEEDS_ADJUDICATION",
    reason = paste(
      "external map is evidence that the pair was used downstream,",
      "but no independent positive support is encoded here"
    )
  )
}

rows <- list()
for (source_map in external_maps) {
  for (formal in names(source_map$map)) {
    for (nickname in source_map$map[[formal]]) {
      normalized_formal <- normalize_name(formal)
      normalized_nickname <- normalize_name(nickname)
      verdict <- classify_edge(normalized_formal, normalized_nickname)
      rows[[length(rows) + 1L]] <- data.frame(
        source_repository = source_map$repo,
        source_sha = source_map$sha,
        source_path = source_map$path,
        source_symbol = source_map$symbol,
        raw_formal = formal,
        raw_nickname = nickname,
        normalized_formal = normalized_formal,
        normalized_nickname = normalized_nickname,
        current_dictionary_version = dictionary_version,
        classification = verdict$classification,
        reason = verdict$reason,
        stringsAsFactors = FALSE
      )
    }
  }
}

audit <- do.call(rbind, rows)
stopifnot(
  all(nzchar(audit$classification)),
  all(nzchar(audit$reason))
)

utils::write.csv(
  audit,
  "inst/extdata/external_nickname_edge_audit.csv",
  row.names = FALSE,
  na = ""
)

cat("external edges reviewed:", nrow(audit), "\n")
print(table(audit$classification))
cat("unclassified:", sum(!nzchar(audit$classification)), "\n")
