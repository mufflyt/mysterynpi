# =============================================================================
# Vendor the carltonnorthern/nicknames edge list as NICKNAME_EDGES
# =============================================================================
#
# Source: https://github.com/carltonnorthern/nicknames (Apache-2.0; the license
# text ships with this package as inst/nicknames-LICENSE). The download is
# pinned to a commit so rebuilding this data is reproducible, not a function of
# whatever upstream looks like today. To take an upstream update: bump the SHA,
# rerun, and review the diff of the .rda like any other code change.
#
# Rerun from the package root with:  Rscript data-raw/NICKNAME_EDGES.R

sha <- "1524308b6859f04335693b76de86f349dc5b78da"  # names.csv as of 2026-08-02
url <- sprintf(
  "https://raw.githubusercontent.com/carltonnorthern/nicknames/%s/names.csv",
  sha)

raw <- read.csv(url, stringsAsFactors = FALSE)
stopifnot(identical(names(raw), c("name1", "relationship", "name2")),
          all(raw$relationship == "has_nickname"))

# The same normalisation the agreement rule applies to its inputs: uppercase,
# periods removed (the corpus writes a few initialism nicknames as "k.c.").
norm <- function(x) gsub("[.]", "", toupper(trimws(x)))

NICKNAME_EDGES <- unique(data.frame(name = norm(raw$name1),
                                    nickname = norm(raw$name2),
                                    stringsAsFactors = FALSE))

# -- CURATED DROPS (issue #4, 2026-09-05) -------------------------------------
# The upstream corpus writes some pairs in BOTH directions, and a reverse row
# can turn a nickname into a shared ROOT that welds two distinct formal names:
# bill->robert plus bill->william made nickname_agreement(ROBERT, WILLIAM)
# corroborate. Exhaustive audit found 15 indirectly welded formal pairs; the
# spelling-variant welds (TERESA/THERESA, LAURENCE/LAWRENCE, NICHOLE/NICOLE,
# MARGARET/MARGARETTA, the WILL/BILL/WILBUR family) are defensible and stay;
# the rows below create the genuinely false ones and are dropped. Each drop
# kills one weld while every defensible direct pair survives through its
# forward row.
drops <- data.frame(
  name = c("BILL", "BILLY",     # welded ROBERT to WILLIAM
           "HARRY", "HARRY",    # welded HAROLD to HENRY
           "CHICK", "CHICK",    # welded CAROLINE to CHARLOTTE
           "DELLA", "DELLA",    # welded ADELAIDE to DELILAH
           "BELLA",             # welded ARABELLA to ISABELLA (Bella stays Isabella's)
           "ELOISE",            # welded HELOISE to LOUISE
           "WILBER",            # welded BERT (Albert/Robert family) to WILL
           "CATHY", "CATHY"),   # welded CATHERINE to CATHLEEN
  nickname = c("ROBERT", "ROBERT",
               "HAROLD", "HENRY",
               "CAROLINE", "CHARLOTTE",
               "ADELAIDE", "DELILAH",
               "ARABELLA",
               "LOUISE",
               "BERT",
               "CATHERINE", "CATHLEEN"),
  stringsAsFactors = FALSE)
key <- function(d) paste(d$name, d$nickname, sep = "\r")
dropped <- key(NICKNAME_EDGES) %in% key(drops)
stopifnot(sum(dropped) == nrow(drops))   # every drop must hit exactly once
NICKNAME_EDGES <- NICKNAME_EDGES[!dropped, , drop = FALSE]

# -- SUPPLEMENT (adjudicated 2026-09-05) --------------------------------------
# Real nicknames the corpus lacks, surfaced by auditing the two hand-rolled
# isochrones maps against it. Every candidate was adjudicated; the rejects
# (AMY->AMANDA, EMILY->EMMA, NATHAN->JONATHAN, GEOFFREY-as-JEFFREY,
# LANCE->LAWRENCE, RICK/PATTY under PATRICK, LAUREN->LAURA, KRISTIN under
# CHRISTINE) are exactly the loose merges the corpus is right to lack.
supplement <- data.frame(
  name = c("ROBERT", "CHARLES", "CHRISTOPHER", "BENJAMIN", "ALEXANDER",
           "GREGORY", "JEFFREY",
           "CATHERINE", "CATHERINE", "CATHERINE", "KATHERINE",
           "BARBARA", "SUSAN", "KIMBERLY", "RACHEL", "ALEXANDRA",
           "CAROLYN", "ROBIN", "MICHELLE",
           "STEPHEN", "PETER", "PHILIP", "DIANE", "ELEANOR",
           "GABRIELLA", "JOANNA", "KAREN", "LINDA", "MARGARET",
           "MICHELLE", "SANDRA", "STEPHANIE"),
  nickname = c("ROBBIE", "CHAS", "TOPHER", "BENJI", "SASHA",
               "GREGG", "JEFFERY",
               "KATE", "KATIE", "KITTY", "KITTY",
               "BARB", "SUZY", "KIMMY", "RAE", "LEXIE",
               "CAROL", "ROBBY", "MICH",
               "STEVEN", "PETEY", "PHILLIP", "DIANA", "ELLA",
               "GABRIELLE", "JOANNE", "KARIN", "LYNDA", "MARGOT",
               "MICHELE", "SANDI", "STEFANIE"),
  stringsAsFactors = FALSE)
supplement <- supplement[!key(supplement) %in% key(NICKNAME_EDGES), , drop = FALSE]
NICKNAME_EDGES <- unique(rbind(NICKNAME_EDGES, supplement))
stopifnot(!anyNA(NICKNAME_EDGES), all(nzchar(NICKNAME_EDGES$name)),
          all(nzchar(NICKNAME_EDGES$nickname)),
          all(grepl("^[A-Z]+$", NICKNAME_EDGES$name)),
          all(grepl("^[A-Z]+$", NICKNAME_EDGES$nickname)))
NICKNAME_EDGES <- NICKNAME_EDGES[order(NICKNAME_EDGES$name,
                                       NICKNAME_EDGES$nickname), ]
rownames(NICKNAME_EDGES) <- NULL

save(NICKNAME_EDGES, file = "data/NICKNAME_EDGES.rda", compress = "bzip2",
     version = 2)
cat(nrow(NICKNAME_EDGES), "edges written to data/NICKNAME_EDGES.rda\n")
