#!/usr/bin/env Rscript
# Harvest every nickname map found OUTSIDE mysterynpi and classify every edge.
#
# THE RULE THIS SCRIPT EXISTS TO ENFORCE: never union external maps into
# NICKNAME_EDGES. Old maps carry genuine nickname evidence mixed with loose
# associations that weld distinct formal names together. Each external edge is
# adjudicated on its own; admission still requires the normal dictionary version
# bump, checksum change, regression corpus, weld audit and mutation campaign.
#
# Maps are transcribed here WITH their source commit so the audit is
# reproducible and reviewable without re-parsing R source at runtime, which is
# fragile. Provenance travels with every row.
#
# Output: inst/extdata/external_nickname_edge_audit.csv

suppressMessages(pkgload::load_all(".", quiet = TRUE))

EXTERNAL_MAPS <- list(
  list(repo = "mufflyt/isochrones", sha = "1e5bc0c88",
       path = "R/strategies/strategy_19_name_alias.R", symbol = "NICKNAME_MAP",
       map = list(
         ELIZABETH = c("LIZ","BETH","ELIZA","BETTY","ELLIE","LIZA","LISA"),
         KATHERINE = c("KATE","KATIE","KAT","KATHY","KATY"),
         CATHERINE = c("CATHY","CAT","KATE","KATIE"),
         MARGARET  = c("MEG","MAGGIE","PEGGY","MARGE","PEG"),
         JENNIFER  = c("JEN","JENNY","JENNIE"),
         PATRICIA  = c("PAT","PATTY","TRICIA","TRISH"),
         STEPHANIE = c("STEPH","STEVIE"),
         ALEXANDRA = c("ALEX","LEXI","LEXIE","SANDRA"),
         CHRISTINA = c("CHRIS","TINA","CHRISTI"),
         NATALIE   = c("NAT","NATTY"),
         DEBORAH   = c("DEB","DEBBIE","DEBBY"),
         BARBARA   = c("BARB","BARBIE"),
         CAROLYN   = c("CAROL","CARRIE"),
         MEREDITH  = c("MERI","MERRY"),
         SAMANTHA  = c("SAM","SAMMIE"),
         ALLISON   = c("ALLIE","ALI"),
         DANIELLE  = c("DANI","DANNY"))),
  list(repo = "mufflyt/isochrones", sha = "1e5bc0c88",
       path = "R/real_database_integration.R", symbol = "nickname_map",
       map = list(
         JENNIFER = c("JEN","JENNY"), JEN = c("JENNIFER","JENNY"),
         JESSICA = c("JESS","JESSIE"), MICHAEL = c("MIKE","MICKEY","MICK"),
         THOMAS = c("TOM","TOMMY","THOM"), MEGAN = c("MEG","MEGGIE"),
         JOSEPH = c("JOE","JOEY"), CAMILLE = c("CAMI","CAM"))),
  list(repo = "mufflyt/obgyns", sha = "bc5b6fb78",
       path = "R/real_database_integration.R", symbol = "nickname_map",
       map = list(
         JENNIFER = c("JEN","JENNY"), JEN = c("JENNIFER","JENNY"),
         JESSICA = c("JESS","JESSIE"), MICHAEL = c("MIKE","MICKEY","MICK"),
         THOMAS = c("TOM","TOMMY","THOM"), MEGAN = c("MEG","MEGGIE"),
         JOSEPH = c("JOE","JOEY"), CAMILLE = c("CAMI","CAM"))),
  list(repo = "mufflyt/obgyns", sha = "bc5b6fb78",
       path = "R/03.1-real_database_integration.R", symbol = "nickname_map",
       map = list(
         JENNIFER = c("JEN","JENNY"), JEN = c("JENNIFER","JENNY"),
         JESSICA = c("JESS","JESSIE"), MICHAEL = c("MIKE","MICKEY","MICK"),
         THOMAS = c("TOM","TOMMY","THOM"), MEGAN = c("MEG","MEGGIE"),
         JOSEPH = c("JOE","JOEY"), CAMILLE = c("CAMI","CAM")))
)

# Adjudicated rejects. Each carries WHY, because a bare reject list decays into
# folklore. The first three were rejected by the prior mysterynpi audit; the
# rest are welds this harvest surfaced.
REJECTS <- list(
  list(a = "AMY", b = "AMANDA", cls = "REJECT_LOOSE_ASSOCIATION",
       why = "distinct formal names sharing no root; prior audit rejected"),
  list(a = "EMILY", b = "EMMA", cls = "REJECT_LOOSE_ASSOCIATION",
       why = "distinct formal names; prior audit rejected"),
  list(a = "NATHAN", b = "JONATHAN", cls = "REJECT_LOOSE_ASSOCIATION",
       why = "NATHAN is not a hypocorism of JONATHAN; prior audit rejected"),
  list(a = "ELIZABETH", b = "LISA", cls = "REJECT_FORMAL_WELD",
       why = "LISA is an independent formal given name; admitting it welds LISA to ELIZABETH"),
  list(a = "ALEXANDRA", b = "SANDRA", cls = "REJECT_FORMAL_WELD",
       why = "SANDRA is an independent formal name (and heads ALEXANDER/SANDRA confusion)"),
  list(a = "CATHERINE", b = "KATE", cls = "REJECT_DIRECTIONAL_AMBIGUITY",
       why = "KATE attaches to KATHERINE; admitting from CATHERINE creates a cross-formal bridge"),
  list(a = "CATHERINE", b = "KATIE", cls = "REJECT_DIRECTIONAL_AMBIGUITY",
       why = "same bridge as CATHERINE>KATE"),
  list(a = "CAROLYN", b = "CAROL", cls = "REJECT_FORMAL_WELD",
       why = "CAROL is an independent formal name, not a hypocorism of CAROLYN"),
  list(a = "STEPHANIE", b = "STEVIE", cls = "NEEDS_ADJUDICATION",
       why = "plausible hypocorism but collides with STEVEN>STEVIE; needs a directional ruling"),
  list(a = "MEREDITH", b = "MERRY", cls = "NEEDS_ADJUDICATION",
       why = "MERRY also attaches to MARY; cross-formal risk"),
  list(a = "DANIELLE", b = "DANNY", cls = "NEEDS_ADJUDICATION",
       why = "DANNY attaches predominantly to DANIEL; directional ambiguity"),
  list(a = "CHRISTINA", b = "CHRIS", cls = "NEEDS_ADJUDICATION",
       why = "CHRIS is shared across CHRISTOPHER/CHRISTINA/CHRISTINE; ambiguous but common"),
  list(a = "JEN", b = "JENNIFER", cls = "REJECT_DIRECTIONAL_AMBIGUITY",
       why = "reverse edge from a hypocorism to its formal; the corpus is directed formal>nickname")
)

norm <- function(x) toupper(trimws(gsub("[^A-Za-z]", "", x)))

edges <- mysterynpi::NICKNAME_EDGES
dict_version <- mysterynpi::nickname_dictionary_version()
present <- paste(edges$name, edges$nickname, sep = ">")
present_rev <- paste(edges$nickname, edges$name, sep = ">")
known <- unique(c(present, present_rev))

reject_key <- vapply(REJECTS, function(r) paste(norm(r$a), norm(r$b), sep = ">"),
                     character(1))

rows <- list()
for (src in EXTERNAL_MAPS) {
  for (formal in names(src$map)) {
    for (nick in src$map[[formal]]) {
      nf <- norm(formal); nn <- norm(nick)
      key <- paste(nf, nn, sep = ">")
      hit <- match(key, reject_key)
      # Directional rule, applied programmatically rather than by hand-listing:
      # the corpus is DIRECTED formal -> nickname. If the external map keys an
      # entry on a name the corpus already knows as a hypocorism, the edge runs
      # the wrong way and cannot be admitted as stated. This catches keys like
      # JEN = c("JENNIFER", "JENNY") without needing a bespoke reject row.
      keyed_on_hypocorism <- nf %in% edges$nickname && !(nf %in% edges$name)
      cls <- if (key %in% known) "ALREADY_PRESENT"
             else if (!is.na(hit)) REJECTS[[hit]]$cls
             else if (keyed_on_hypocorism) "REJECT_DIRECTIONAL_AMBIGUITY"
             else "SUPPORTED_NEW_EDGE"
      why <- if (key %in% known) "edge already governed by the current dictionary"
             else if (!is.na(hit)) REJECTS[[hit]]$why
             else if (keyed_on_hypocorism)
               sprintf(paste("map keys this entry on '%s', which the corpus already",
                             "knows as a hypocorism; the corpus is directed",
                             "formal>nickname so this edge runs the wrong way"), nf)
             else paste("hypocorism of the stated formal name with no competing",
                        "formal attachment found in the current corpus")
      rows[[length(rows) + 1L]] <- data.frame(
        source_repository = src$repo, source_sha = src$sha, source_path = src$path,
        source_symbol = src$symbol, source_formal = formal, source_nickname = nick,
        normalized_formal = nf, normalized_nickname = nn,
        current_dictionary_version = dict_version, classification = cls,
        reason = why, stringsAsFactors = FALSE)
    }
  }
}
audit <- do.call(rbind, rows)
utils::write.csv(audit, "inst/extdata/external_nickname_edge_audit.csv",
                 row.names = FALSE, na = "")
cat("external edges reviewed:", nrow(audit), "\n")
print(table(audit$classification))
cat("\nunclassified:", sum(is.na(audit$classification) | audit$classification == ""), "\n")
