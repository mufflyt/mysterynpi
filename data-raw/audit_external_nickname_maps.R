# =============================================================================
# External nickname maps: harvested as EVIDENCE, classified, never unioned
# =============================================================================
# The owner-wide consolidation (2026-09-08) found every nickname dictionary
# outside this package. This script normalizes each one to directed candidate
# edges, compares them against the canonical NICKNAME_EDGES, classifies every
# edge, and writes inst/extdata/external_nickname_edge_audit.csv.
#
# THE FORBIDDEN OPERATION, spelled out: bind_rows(NICKNAME_EDGES, external).
# The 0.3.1 audit proved why -- old maps mix genuinely useful evidence with
# loose associations that weld distinct formal names. CLASSIFICATION IS NOT
# ADMISSION: a SUPPORTED_NEW_EDGE row is a recommendation into the governed
# queue. Admitting any edge means a dictionary version bump, checksum change,
# weld audit, snapshot regeneration, mutation campaign -- and, because
# NICKNAME_POLICY pins dictionary_version 2026-09-06.1, a policy
# SUPERSESSION. That is an owner decision, not a side effect of an audit.
#
# Pair literals below are vendored VERBATIM from the source repositories at
# the pinned SHAs, with file/line provenance, exactly like the drops and
# supplement blocks in data-raw/NICKNAME_EDGES.R.
# =============================================================================

suppressMessages(pkgload::load_all(".", quiet = TRUE))
e <- mysterynpi::NICKNAME_EDGES

src <- function(repo, sha, path, symbol, formal, nick) {
  data.frame(source_repository = repo, source_sha = sha, source_path = path,
             source_symbol = symbol, source_formal = formal,
             source_nickname = nick, stringsAsFactors = FALSE)
}

ext <- rbind(
  # ---- obgyns R/real_database_integration.R:549-557 (nickname_map; the
  # identical twin lives in R/03.1-real_database_integration.R:663-671 and
  # two tracked .bak copies -- ONE implementation, four files) --------------
  src("obgyns", "bc5b6fb7854f8f1cf35a580d3e3e4b66e4c023f1",
      "R/real_database_integration.R:549", "nickname_map",
      c("Jennifer", "Jennifer", "Jen", "Jen", "Jessica", "Jessica",
        "Michael", "Michael", "Michael", "Thomas", "Thomas", "Thomas",
        "Megan", "Megan", "Joseph", "Joseph", "Camille", "Camille"),
      c("Jen", "Jenny", "Jennifer", "Jenny", "Jess", "Jessie",
        "Mike", "Mickey", "Mick", "Tom", "Tommy", "Thom",
        "Meg", "Meggie", "Joe", "Joey", "Cami", "Cam")),
  # ---- obgyns R/centralized_npi_matching.R:1288-1300 (check_nickname_match;
  # tracked .bak twin at :1207) ---------------------------------------------
  src("obgyns", "bc5b6fb7854f8f1cf35a580d3e3e4b66e4c023f1",
      "R/centralized_npi_matching.R:1288", "check_nickname_match",
      c(rep("ROBERT", 3), rep("WILLIAM", 3), rep("ELIZABETH", 4),
        rep("KATHERINE", 4), rep("RICHARD", 3), rep("MARGARET", 3),
        rep("JAMES", 3), rep("MICHAEL", 2), rep("CHRISTOPHER", 2),
        rep("PATRICIA", 3)),
      c("BOB", "ROB", "BOBBY", "BILL", "WILL", "BILLY",
        "LIZ", "BETH", "BETTY", "ELIZA", "KATE", "KATHY", "KAT", "KATIE",
        "RICK", "DICK", "RICH", "MEG", "MAGGIE", "PEGGY",
        "JIM", "JIMMY", "JAMIE", "MIKE", "MICKEY", "CHRIS", "KIT",
        "PAT", "PATTY", "TRISH")),
  # ---- obgyns tests/testthat/test-performance-comparison.R:214-222
  # (create_nickname_variation; test-only third dictionary) -----------------
  src("obgyns", "bc5b6fb7854f8f1cf35a580d3e3e4b66e4c023f1",
      "tests/testthat/test-performance-comparison.R:214",
      "create_nickname_variation",
      c("John", "Robert", "William", "James", "Michael", "David",
        "Jennifer", "Elizabeth", "Patricia", "Susan", "Barbara", "Linda"),
      c("Jack", "Bob", "Bill", "Jim", "Mike", "Dave",
        "Jen", "Liz", "Pat", "Sue", "Barb", "Lin")))

norm <- function(x) gsub("[.]", "", name_key(x))
ext$normalized_formal <- norm(ext$source_formal)
ext$normalized_nickname <- norm(ext$source_nickname)
ext$current_dictionary_version <- attr(e, "version")

# ---- classification ----------------------------------------------------------
# Hand-adjudicated per edge, the 0.3.1 discipline. The classifier computes
# the mechanical facts; the REJECT/NEEDS decisions carry written reasons.
formals_of <- split(e$nickname, e$name)
present <- function(f, n) any(e$name == f & e$nickname == n) ||
  any(e$name == n & e$nickname == f)
is_recorded_nick <- function(x) x %in% e$nickname
adjudicate <- function(f, n) {
  if (present(f, n)) return(c("ALREADY_PRESENT",
                              "recorded in NICKNAME_EDGES"))
  # a "formal" that is itself only a recorded nickname (Jen = Jennifer's
  # nickname) makes the pair directionally ambiguous, and pairing it with a
  # SIBLING nickname (Jen>Jenny) is the reverse-edge weld of issue #4
  if (is_recorded_nick(f) && !f %in% e$name) {
    shared <- intersect(e$name[e$nickname == f], e$name[e$nickname == n])
    if (length(shared)) return(c("REJECT_FORMAL_WELD",
      paste0("both are recorded nicknames of ", paste(shared, collapse = "/"),
             "; admitting would weld through a shared root (issue-4 class)")))
    return(c("REJECT_DIRECTIONAL_AMBIGUITY",
             "left side is itself only a recorded nickname"))
  }
  c("NEEDS_ADJUDICATION",
    "not recorded; plausible hypocorism awaiting the governed data decision")
}
cls <- t(vapply(seq_len(nrow(ext)), function(i)
  adjudicate(ext$normalized_formal[i], ext$normalized_nickname[i]),
  character(2)))
ext$classification <- cls[, 1]
ext$reason <- cls[, 2]

# Hand overrides where the mechanical default is not the right adjudication,
# each with its reason -- the audit is reviewable line by line:
override <- function(f, n, classification, reason) {
  i <- which(ext$normalized_formal == f & ext$normalized_nickname == n)
  ext$classification[i] <<- classification
  ext$reason[i] <<- reason
}
override("RICHARD", "DICK", "SUPPORTED_NEW_EDGE",
         "canonical English hypocorism; no weld path in current corpus")
override("CHRISTOPHER", "KIT", "SUPPORTED_NEW_EDGE",
         "recorded historical hypocorism; no weld path in current corpus")
override("PATRICIA", "TRISH", "SUPPORTED_NEW_EDGE",
         "canonical hypocorism; no weld path in current corpus")
override("ELIZABETH", "ELIZA", "SUPPORTED_NEW_EDGE",
         "canonical contraction; ELIZA not recorded as anyone else's nickname")
override("LINDA", "LIN", "REJECT_LOOSE_ASSOCIATION",
         "test-convenience truncation, not attested usage; LIN also a surname")
override("MICHAEL", "MICK", "NEEDS_ADJUDICATION",
         "attested but MICK also freestanding; owner call")
override("MICHAEL", "MICKEY", "NEEDS_ADJUDICATION",
         "attested but MICKEY also freestanding given name; owner call")
override("THOMAS", "THOM", "SUPPORTED_NEW_EDGE",
         "attested spelling hypocorism; no weld path")
override("MEGAN", "MEGGIE", "REJECT_LOOSE_ASSOCIATION",
         "MEGGIE attested for MARGARET more than MEGAN; ambiguous, low value")
override("CAMILLE", "CAMI", "SUPPORTED_NEW_EDGE",
         "attested hypocorism; no weld path")
override("CAMILLE", "CAM", "NEEDS_ADJUDICATION",
         "CAM is CAMERON's hypocorism too; cross-gender hub risk; owner call")

# The one INTERNAL edge the consolidation put in question (differential
# fixture DIFF-001): recorded MELINDA>LINDA vs an adjudicated false merge.
ext <- rbind(ext, within(src(
  "midwifery/isochrones (adjudicated case)", "-",
  "isochrones tests/testthat/test-name-matching-primitives.R (fixture)",
  "DIFF-001", "MELINDA", "LINDA"), {
    normalized_formal <- "MELINDA"; normalized_nickname <- "LINDA"
    current_dictionary_version <- attr(e, "version")
    classification <- "NEEDS_ADJUDICATION"
    reason <- paste("edge IS recorded, but the midwifery cohort holds an",
                    "adjudicated false merge of two certificants through it;",
                    "candidate for a drop-list entry, owner decision")
  }))

stopifnot(!any(ext$classification == ""),
          all(ext$classification %in% c(
            "ALREADY_PRESENT", "SUPPORTED_NEW_EDGE",
            "REJECT_LOOSE_ASSOCIATION", "REJECT_FORMAL_WELD",
            "REJECT_DIRECTIONAL_AMBIGUITY", "REJECT_NOT_NICKNAME",
            "NEEDS_ADJUDICATION")))
dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(ext, "inst/extdata/external_nickname_edge_audit.csv",
                 row.names = FALSE)
cat("edges reviewed:", nrow(ext), "\n")
print(table(ext$classification))
