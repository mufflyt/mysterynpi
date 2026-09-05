# =============================================================================
# Similarity SCORING -- candidate-ranking machinery, walled off from verdicts
# =============================================================================
#
# THIS FILE IS THE PACKAGE'S ONE FENCED EXCEPTION to its no-fuzzy rule, and
# the fence is load-bearing. The rule's target was always fuzz in the
# IDENTITY VERDICT path -- an edit-distance tolerance that silently converts
# "conflicts" to "corroborates" -- and that refusal stands in full: the
# no-fuzzy guard now asserts, by call-graph reachability over the installed
# namespace, that NO agreement rule can reach anything in this file, and a
# mutation in the campaign proves the guard fires on exactly that smuggling.
# What lives here is different machinery for a different stage: SCORING for
# candidate generation and ranking, where a fuzzy pass GENERATES a candidate
# that exact evidence then outranks -- the asymmetry the README has always
# called legitimate. Same evolution as the nickname table: the machinery is
# shared, the decision to use it -- and at which pipeline stage -- stays
# policy.
#
# EXTRACTED VERBATIM from mufflyt/isochrones R/nickname_system.R
# (2026-09-05, at 2a0ddc99b), proven byte-identical over 4,000 real ABOG
# name pairs before and after the swap. Verbatim includes the QUIRKS, which
# are pinned by tests rather than silently repaired, because a
# behaviour-preserving extraction must preserve behaviour it would not have
# written: the mapping list carries duplicate formal-name entries whose
# second definitions are shadowed; reused nicknames resolve to whichever
# formal name wrote them LAST (RICK belongs to ERIC, not RICHARD; DONNIE to
# DONNA, not RONALD); and a handful of names are recorded as their own
# nicknames. Repairing any of that changes scores and is a deliberate,
# versioned decision for another day.
#
# stringdist is a Suggests, required at the point of use only, so the
# package's verdict machinery installs and runs without it.
# =============================================================================

.nickname_cache <- new.env(parent = emptyenv())

#' Build the bidirectional nickname dictionary used by the similarity score
#'
#' ~125 formal first names mapped to their common variants, extracted
#' verbatim from isochrones' nickname system (quirks pinned -- see the file
#' header). Distinct from [NICKNAME_EDGES] on purpose: that corpus feeds the
#' three-verdict [nickname_agreement()] rule; this dictionary feeds a
#' SIMILARITY SCORE for candidate ranking, and the two must never be
#' silently merged, because a table change here moves scores while a table
#' change there moves verdicts.
#'
#' @param verbose message the build, as the original did.
#' @return list: `formal_to_nicknames`, `nickname_to_formal`, `source`,
#'   `created`, `formal_count`, `nickname_count`.
#' @export
create_nickname_dictionary <- function(verbose = TRUE) {
  if (verbose) {
    message("Building comprehensive nickname dictionary...")
  }
  nickname_mappings <- list(
    "ROBERT" = c("BOB", "BOBBY", "ROB", "ROBBIE", "BERT"),
    "WILLIAM" = c("BILL", "BILLY", "WILL", "WILLY", "LIAM"),
    "JAMES" = c("JIM", "JIMMY", "JAMIE", "JAMEY"),
    "JOHN" = c("JACK", "JOHNNY", "JACK", "JOCK"),
    "MICHAEL" = c("MIKE", "MICKEY", "MICK", "MIKEY"),
    "DAVID" = c("DAVE", "DAVY", "DAVEY"),
    "RICHARD" = c("RICK", "RICKY", "RICH", "RICHIE", "DICK"),
    "CHARLES" = c("CHUCK", "CHARLIE", "CHUCKY", "CHAS"),
    "CHRISTOPHER" = c("CHRIS", "CHRISTY", "KIT"),
    "MATTHEW" = c("MATT", "MATTY"),
    "ANTHONY" = c("TONY", "TONEY"),
    "DONALD" = c("DON", "DONNY", "DONNIE"),
    "STEVEN" = c("STEVE", "STEVIE"),
    "JOSEPH" = c("JOE", "JOEY"),
    "THOMAS" = c("TOM", "TOMMY", "THOM"),
    "DANIEL" = c("DAN", "DANNY", "DANIEL"),
    "PAUL" = c("PAULIE"),
    "MARK" = c("MARKY"),
    "GEORGE" = c("GEORG"),
    "KENNETH" = c("KEN", "KENNY"),
    "JOSHUA" = c("JOSH"),
    "KEVIN" = c("KEV"),
    "BRIAN" = c("BRI"),
    "EDWARD" = c("ED", "EDDIE", "TED", "TEDDY"),
    "RONALD" = c("RON", "RONNY", "RONNIE"),
    "TIMOTHY" = c("TIM", "TIMMY"),
    "JASON" = c("JASE"),
    "JEFFREY" = c("JEFF", "JEFFIE"),
    "RYAN" = c("RY"),
    "JACOB" = c("JAKE", "JAKEY"),
    "GARY" = c("GARY"),
    "NICHOLAS" = c("NICK", "NICKY"),
    "ERIC" = c("RICK", "RICKY"),
    "JONATHAN" = c("JON", "JONNY"),
    "STEPHEN" = c("STEVE", "STEVIE"),
    "LARRY" = c("LAWRENCE"),
    "JUSTIN" = c("JUST"),
    "SCOTT" = c("SCOTTY"),
    "BRANDON" = c("BRAND"),
    "BENJAMIN" = c("BEN", "BENNY", "BENJI"),
    "SAMUEL" = c("SAM", "SAMMY"),
    "FRANK" = c("FRANKY", "FRANKIE"),
    "PATRICK" = c("PAT", "PATTY", "PADDY"),
    "RAYMOND" = c("RAY", "RAYMUND"),
    "JACK" = c("JACKY", "JACKIE"),
    "DENNIS" = c("DENNY", "DENNIE"),
    "JERRY" = c("GERR", "GERALD"),
    "TYLER" = c("TY"),
    "AARON" = c("ARON"),
    "JOSE" = c("JOSEPH"),
    "HENRY" = c("HANK", "HARRY", "HENRI"),
    "ADAM" = c("ADDY"),
    "DOUGLAS" = c("DOUG", "DOUGIE"),
    "NATHAN" = c("NATE", "NATEY"),
    "PETER" = c("PETE", "PETEY"),
    "ZACHARY" = c("ZACK", "ZACKY", "ZACH"),
    "KYLE" = c("KY"),
    "NOAH" = c("NO"),
    "ALAN" = c("AL", "ALLIE"),
    "ETHAN" = c("ETH"),
    "JEREMY" = c("JERRY", "JEREM"),
    "CARL" = c("CHARLIE"),
    "HAROLD" = c("HARRY", "HAL"),
    "ARTHUR" = c("ART", "ARTIE"),
    "LAWRENCE" = c("LARRY", "LANCE"),
    "SEAN" = c("SHAWN"),
    "CHRISTIAN" = c("CHRIS", "CHRISTY"),
    "ALBERT" = c("AL", "ALBIE", "BERT"),
    "JUSTIN" = c("JUST"),
    "WAYNE" = c("WAY"),
    "RALPH" = c("RALPHY"),
    "ROY" = c("ROYIE"),
    "EUGENE" = c("GENE"),
    "LOUIS" = c("LOU", "LOUIE"),
    "PHILIP" = c("PHIL", "PHILLY"),
    "MARY" = c("MARY", "MARIE", "MARIA", "MOLLY", "POLLY"),
    "PATRICIA" = c("PAT", "PATTY", "TRICIA", "PATSY"),
    "JENNIFER" = c("JEN", "JENNY", "JENNIE"),
    "LINDA" = c("LIN", "LINDY"),
    "ELIZABETH" = c("LIZ", "LIZZY", "BETH", "BETTY", "BETSY", "ELIZA"),
    "BARBARA" = c("BARB", "BARBIE", "BABS"),
    "SUSAN" = c("SUE", "SUZY", "SUSIE", "SUZIE"),
    "JESSICA" = c("JESS", "JESSIE"),
    "SARAH" = c("SARA"),
    "KAREN" = c("KARI", "KARRIE"),
    "NANCY" = c("NAN", "NANNY"),
    "LISA" = c("LIS"),
    "BETTY" = c("BET", "BETTE"),
    "HELEN" = c("HELEN"),
    "SANDRA" = c("SANDY", "SANDI"),
    "DONNA" = c("DON", "DONNIE"),
    "CAROL" = c("CARRIE", "CAROLINE"),
    "RUTH" = c("RUTHIE"),
    "SHARON" = c("SHARI", "SHERRY"),
    "MICHELLE" = c("MICH", "MICKEY", "MICKI", "SHELLY"),
    "LAURA" = c("LAUR", "LAURIE"),
    "SARAH" = c("SARA"),
    "KIMBERLY" = c("KIM", "KIMMY"),
    "DEBORAH" = c("DEB", "DEBBIE", "DEBBI"),
    "DOROTHY" = c("DOT", "DOTTIE", "DOLLY"),
    "AMY" = c("AMI"),
    "ANGELA" = c("ANGIE", "ANG"),
    "ASHLEY" = c("ASH", "ASHIE"),
    "BRENDA" = c("BREN"),
    "EMMA" = c("EM", "EMMY"),
    "OLIVIA" = c("OLLY", "LIV", "LIVY"),
    "CYNTHIA" = c("CINDY", "CYNDI", "CYNN"),
    "MARIE" = c("MARY"),
    "JANET" = c("JAN", "JANNY"),
    "CATHERINE" = c("CATHY", "CATH", "KATE", "KATIE", "KAT"),
    "FRANCES" = c("FRAN", "FRANNIE", "FANNY"),
    "CHRISTINE" = c("CHRIS", "CHRISTY", "CHRISSY"),
    "SAMANTHA" = c("SAM", "SAMMY"),
    "DEBRA" = c("DEB", "DEBBIE"),
    "RACHEL" = c("RAY"),
    "CAROLYN" = c("CAROL", "CARRIE"),
    "JANET" = c("JAN", "JANNY"),
    "VIRGINIA" = c("GINNY", "GINGER", "VIRGINIA"),
    "MARIA" = c("MARY", "MARIE"),
    "HEATHER" = c("HEATH"),
    "DIANE" = c("DI", "DIDI"),
    "JULIE" = c("JUL", "JULY"),
    "JOYCE" = c("JOY"),
    "VICTORIA" = c("VICKY", "VIC", "TORI"),
    "KELLY" = c("KEL"),
    "CHRISTINA" = c("CHRIS", "CHRISTY", "TINA", "CHRISSY"),
    "JOAN" = c("JO", "JOANIE"),
    "EVELYN" = c("EVE", "EVIE"),
    "LAUREN" = c("LAUR"),
    "JUDITH" = c("JUDY", "JUDIE"),
    "MEGAN" = c("MEG", "MEGGIE"),
    "CHERYL" = c("CHERI", "CHERRY"),
    "ANDREA" = c("ANDI", "ANDIE"),
    "HANNAH" = c("HAN"),
    "JACQUELINE" = c("JACKIE", "JACK", "JAC"),
    "MARTHA" = c("MARTY"),
    "GLORIA" = c("GLORY"),
    "TERESA" = c("TERRI", "TERRY", "TERI"),
    "SARA" = c("SARAH"),
    "JANICE" = c("JAN"),
    "MARIE" = c("MARY"),
    "JULIA" = c("JULIE", "JUL"),
    "HEATHER" = c("HEATH"),
    "DIANE" = c("DI"),
    "RUTH" = c("RUTHIE"),
    "JULIE" = c("JUL"),
    "JOYCE" = c("JOY"),
    "VIRGINIA" = c("GINNY", "GINGER")
  )
  formal_to_nicknames <- nickname_mappings
  nickname_to_formal <- list()
  for (formal_name in names(nickname_mappings)) {
    nicknames <- nickname_mappings[[formal_name]]
    for (nickname in nicknames) {
      nickname_to_formal[[nickname]] <- formal_name
    }
  }
  dict <- list(
    formal_to_nicknames = formal_to_nicknames,
    nickname_to_formal = nickname_to_formal,
    source = "integrated_codebase_patterns",
    created = Sys.time(),
    formal_count = length(formal_to_nicknames),
    nickname_count = length(nickname_to_formal)
  )
  if (verbose) {
    message(sprintf("Nickname dictionary created with %d formal names and %d nicknames",
                    dict$formal_count, dict$nickname_count))
  }
  dict
}

#' Cached access to the nickname dictionary
#' @param refresh rebuild even if cached.
#' @return see [create_nickname_dictionary()].
#' @export
get_nickname_dictionary <- function(refresh = FALSE) {
  if (refresh || is.null(.nickname_cache$dict)) {
    .nickname_cache$dict <- create_nickname_dictionary(verbose = FALSE)
  }
  .nickname_cache$dict
}

#' Resolve a name, possibly a nickname, to its canonical formal form
#' @param name a name; NULL and length-one NA return as given.
#' @param nickname_dict from [create_nickname_dictionary()]; NULL returns
#'   the input.
#' @return the formal name, or the normalised input when unknown.
#' @export
get_canonical_name <- function(name, nickname_dict) {
  if (is.null(name) || is.null(nickname_dict) ||
      (length(name) == 1 && is.na(name))) {
    return(name)
  }
  name_clean <- normalize_string(name)
  if (name_clean %in% names(nickname_dict$formal_to_nicknames)) {
    return(name_clean)
  }
  if (name_clean %in% names(nickname_dict$nickname_to_formal)) {
    return(nickname_dict$nickname_to_formal[[name_clean]])
  }
  name_clean
}

#' Do two names share a canonical formal root?
#' @param name1,name2 names to compare.
#' @param nickname_dict from [create_nickname_dictionary()]; NULL is FALSE.
#' @return logical.
#' @export
are_nickname_equivalents <- function(name1, name2, nickname_dict) {
  if (is.null(nickname_dict)) {
    return(FALSE)
  }
  canonical1 <- get_canonical_name(name1, nickname_dict)
  canonical2 <- get_canonical_name(name2, nickname_dict)
  !is.null(canonical1) && !is.null(canonical2) && canonical1 == canonical2
}

#' All recorded nicknames for a formal name
#' @param formal_name the formal name.
#' @param nickname_dict from [create_nickname_dictionary()].
#' @return character vector; empty when unknown or inputs NULL.
#' @export
get_nicknames_for_name <- function(formal_name, nickname_dict) {
  if (is.null(nickname_dict) || is.null(formal_name)) {
    return(character(0))
  }
  formal_clean <- normalize_string(formal_name)
  if (formal_clean %in% names(nickname_dict$formal_to_nicknames)) {
    return(nickname_dict$formal_to_nicknames[[formal_clean]])
  }
  character(0)
}

#' Nickname-aware first-name similarity SCORE (never a verdict)
#'
#' A number for RANKING candidates, extracted verbatim from isochrones:
#' 1.0 exact after normalisation; 0.98 both map to one formal name; 0.96
#' one is the other's canonical form; 0.94 cross-nickname; 0.5 neutral for
#' missing; otherwise Jaro-Winkler similarity (the larger of raw and
#' umlaut-digraph-simplified). Scores rank; only agreement rules decide,
#' and the no-fuzzy guard proves they cannot reach this function.
#'
#' @param name1,name2 names to compare.
#' @param nickname_dict from [create_nickname_dictionary()]; NULL falls back
#'   to plain Jaro-Winkler.
#' @return numeric in `[0, 1]`.
#' @export
calculate_enhanced_first_name_similarity <- function(name1, name2,
                                                     nickname_dict = NULL) {
  if (!requireNamespace("stringdist", quietly = TRUE)) {
    stop("calculate_enhanced_first_name_similarity() requires stringdist.\n",
         "  install.packages(\"stringdist\")", call. = FALSE)
  }
  if (is.null(name1) || is.null(name2) || is.na(name1) || is.na(name2)) {
    return(0.5)
  }
  name1_clean <- normalize_string(name1)
  name2_clean <- normalize_string(name2)
  normalize_for_similarity <- function(value) {
    value <- normalize_string(value)
    if (requireNamespace("stringi", quietly = TRUE)) {
      value <- stringi::stri_trans_general(value, "Latin-ASCII")
    }
    value
  }
  simplify_umlaut_digraphs <- function(value) {
    value <- gsub("AE", "A", value, perl = TRUE)
    value <- gsub("OE", "O", value, perl = TRUE)
    value <- gsub("UE", "U", value, perl = TRUE)
    value
  }
  name1_norm <- normalize_for_similarity(name1_clean)
  name2_norm <- normalize_for_similarity(name2_clean)
  if (name1_norm == name2_norm) {
    return(1.0)
  }
  if (is.null(nickname_dict)) {
    return(1 - stringdist::stringdist(name1_norm, name2_norm, method = "jw"))
  }
  canonical1 <- get_canonical_name(name1_clean, nickname_dict)
  canonical2 <- get_canonical_name(name2_clean, nickname_dict)
  if (!is.null(canonical1) && !is.null(canonical2) && canonical1 == canonical2) {
    return(0.98)
  }
  if (canonical1 == name2_clean || canonical2 == name1_clean) {
    return(0.96)
  }
  if (!is.null(canonical1) && !is.null(canonical2)) {
    if (canonical1 == canonical2) {
      return(0.94)
    }
  }
  jw_similarity <- 1 - stringdist::stringdist(name1_norm, name2_norm,
                                              method = "jw")
  jw_simplified <- 1 - stringdist::stringdist(
    simplify_umlaut_digraphs(name1_norm),
    simplify_umlaut_digraphs(name2_norm),
    method = "jw"
  )
  max(jw_similarity, jw_simplified)
}

#' Factory: similarity closure with a bound dictionary
#' @param nickname_dict from [create_nickname_dictionary()].
#' @return `function(name1, name2)` returning the similarity score.
#' @export
create_nickname_aware_similarity <- function(nickname_dict) {
  function(name1, name2) {
    calculate_enhanced_first_name_similarity(name1, name2, nickname_dict)
  }
}
