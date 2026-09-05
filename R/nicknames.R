# =============================================================================
# Nickname equivalence: a vendored table, and the one-hop rule over it
# =============================================================================
#
# WHY A TABLE NOW SHIPS, WHEN THE README ONCE REFUSED ONE. The refusal was
# aimed at the DECISION -- whether BETH may stand for ELIZABETH in a given
# study, and which evidence class that pairing earns, is policy and stays with
# the caller. The TABLE is different: it is shared machinery, and every
# pipeline curating its own copy is how two pipelines quietly disagree about
# who matched whom. So the package vendors one table, versioned and pinned,
# and a rule with exactly one behaviour over it. Adopting the rule at all, and
# where its verdict ranks, remains the caller's claim.
#
# THE TABLE IS AN EDGE LIST, NOT EQUIVALENCE CLASSES, AND THAT IS LOAD-BEARING.
# AL is a recorded nickname of ALBERT and of ALEXANDER. Closing the relation
# transitively would therefore merge ALBERT with ALEXANDER -- two names that
# share nothing but a lazy abbreviation -- and every such hub nickname (AL,
# CHRIS, JJ) would weld whole families of distinct given names into one. The
# rule below never takes that step: two names corroborate only within one hop.
# =============================================================================

#' Formal-name / nickname edges, vendored from carltonnorthern/nicknames
#'
#' One row per recorded (formal name, nickname) pair, both sides uppercased
#' with periods removed. The relation is DIRECTIONAL: `name` is the formal
#' side, `nickname` the hypocorism. It is not closed transitively, and
#' [nickname_agreement()] deliberately never closes it (see the file header:
#' AL must not merge ALBERT with ALEXANDER).
#'
#' Vendored at a pinned commit by `data-raw/NICKNAME_EDGES.R`; updating the
#' pin is a code change, reviewed like one, because a row added here can move
#' a verdict from `"conflicts"` to `"corroborates"`.
#'
#' @format data.frame with columns `name`, `nickname`; one row per edge.
#' @source \url{https://github.com/carltonnorthern/nicknames} (Apache-2.0; the
#'   license text is installed as
#'   `system.file("nicknames-LICENSE", package = "mysterynpi")`).
"NICKNAME_EDGES"

#' Do two given-name tokens agree once recorded nicknames are admitted?
#'
#' THREE VERDICTS, SAME CONTRACT AS [middle_agreement()]. `"corroborates"`
#' when the tokens are equal, when one is a recorded nickname of the other,
#' or when both are recorded nicknames of a COMMON formal name (BOB and BOBBY
#' both stand for ROBERT). `"uninformative"` when either side holds no name.
#' `"conflicts"` otherwise: `ELISABETH`/`ELIZABETH` and `JANE`/`JOAN` conflict
#' here exactly as they would in [middle_agreement()].
#'
#' THIS IS NOT AN EDIT-DISTANCE RULE WEARING A TABLE. Admission requires a
#' RECORDED edge, never a distance computation -- but be clear-eyed about
#' what the corpus records: usage, as its curators found it, and usage
#' includes some spelling-adjacent pairs (`JULIA`/`JULIE` and `ANN`/`ANNE`
#' are recorded edges and corroborate here, where [middle_agreement()]
#' conflicts on them). A caller ranking this rule's verdict must rank it as
#' what it is -- "a published corpus says these names substitute" -- and a
#' study that finds an edge too loose should supply its own `edges`, which is
#' a reviewable data decision, not a code change.
#'
#' WHAT SHARING A NICKNAME DOES NOT DO. ALBERT and ALEXANDER both own the
#' nickname AL; they do not thereby corroborate each other. The lookup runs
#' from each token to the formal names it may stand for -- one hop, no
#' transitive closure -- so a hub nickname can never weld two distinct formal
#' names together. AL vs ALBERT corroborates; ALBERT vs ALEXANDER conflicts.
#'
#' Each element should be ONE given-name token (e.g. one element of
#' [given_tokens()]). Inputs pass through [name_key()] plus period removal,
#' so `"k.c."` meets the table's `KC`.
#'
#' @param a,b character vectors of given-name tokens, the same length.
#' @param edges the edge table; defaults to [NICKNAME_EDGES]. A caller with
#'   a study-specific table supplies it here and the rule's behaviour over it
#'   stays identical.
#' @return character: `"corroborates"`, `"conflicts"`, or `"uninformative"`.
#' @export
nickname_agreement <- function(a, b, edges = mysterynpi::NICKNAME_EDGES) {
  if (length(a) != length(b)) {
    stop("a and b must be the same length", call. = FALSE)
  }
  for (nm in c("name", "nickname")) if (!nm %in% names(edges))
    stop("edges needs columns name and nickname", call. = FALSE)
  norm <- function(x) gsub("[.]", "", name_key(x))
  ka <- norm(a); kb <- norm(b)
  formals_of <- split(edges$name, edges$nickname)
  vapply(seq_along(ka), function(i) {
    x <- ka[i]; y <- kb[i]
    if (!has_name_information(x) || !has_name_information(y)) {
      return("uninformative")
    }
    if (x == y) return("corroborates")
    # one hop: each token, plus the formal names it is recorded to stand for
    cx <- c(x, formals_of[[x]])
    cy <- c(y, formals_of[[y]])
    if (length(intersect(cx, cy))) "corroborates" else "conflicts"
  }, character(1))
}
