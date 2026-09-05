# =============================================================================
# Surname agreement: components, marriage, and the maiden-as-middle rescue
# =============================================================================

#' Do two surnames agree, disagree, or decide nothing?
#'
#' THE GAP THIS CLOSES. Until this rule existed the package compared surnames
#' only by exact equality inside [person_matches()], while every other axis
#' had a three-verdict rule. Surnames are the axis where that hurts most:
#' hyphenated surnames ran 27.1% unmatched against 9.8% for unhyphenated in
#' one measured crosswalk, and marriage moves a surname wholesale.
#'
#' FOUR STEPS, EACH ONE EARNING ITS PLACE:
#'
#' 1. Exact [name_key()] equality corroborates. This runs FIRST so that
#'    surnames below the token floor still compare: `LEE` vs `LEE` is real
#'    agreement even though `LEE` is too short to be a blocking token.
#' 2. A shared component from [surname_tokens()] corroborates:
#'    `MCCARTHY-DERVIN` shares `MCCARTHY` with `MCCARTHY`. Particles never
#'    count -- `DE LA CRUZ` and `DE LEON` share only convention.
#' 3. THE MAIDEN-AS-MIDDLE RESCUE. A changed surname often survives in the
#'    OTHER record's middle slot: `KATHERINE REINHARD RYE` against
#'    `KATHERINE A. REINHARD` holds the surname `REINHARD` as a middle token.
#'    When the surnames themselves share nothing, a full surname component
#'    (>= [MIN_SURNAME_TOKEN]) found among the other side's middle tokens
#'    corroborates. Pass the raw middle strings via `middle_a`/`middle_b`;
#'    without them this step is skipped, never guessed.
#' 4. Otherwise, two recorded surnames that share nothing conflict.
#'
#' USE THE CONFLICT WITH THE SAME DISCIPLINE AS THE GENDER VETO. In a cohort
#' where marriage-related change is plausible -- most physician cohorts --
#' total surname disagreement alongside top-class agreement on everything
#' else is a case for quarantine and review, not silent deletion. See
#' `vignette("vetoes-and-quarantine")`.
#'
#' @param a,b character vectors of surnames, the same length. Raw strings are
#'   fine; [name_key()] normalisation is applied internally.
#' @param middle_a,middle_b optional character vectors of the SAME record's
#'   raw middle-name strings, enabling the cross-slot rescue: `middle_a`
#'   belongs with `a`, and is searched for `b`'s surname components (and vice
#'   versa). `NULL` skips the rescue.
#' Apostrophes are erased before every comparison this rule makes:
#' `O'BRIEN` vs `OBRIEN` is one surname written two ways, and a formatting
#' difference must not become a veto. [name_key()] itself keeps the
#' apostrophe -- it is a join key with its own parity contract -- so the
#' erasure is local to this rule.
#'
#' @return character: `"corroborates"`, `"conflicts"`, or `"uninformative"`
#'   (either surname absent or reduced to nothing by normalisation).
#' @export
surname_agreement <- function(a, b, middle_a = NULL, middle_b = NULL) {
  n <- length(a)
  if (length(b) != n) stop("a and b must be the same length", call. = FALSE)
  for (m in list(middle_a, middle_b)) {
    if (!is.null(m) && length(m) != n) {
      stop("middle_a and middle_b must be NULL or the same length as a",
           call. = FALSE)
    }
  }
  deq <- function(x) if (is.character(x)) gsub("'", "", x, fixed = TRUE) else
    lapply(x, gsub, pattern = "'", replacement = "", fixed = TRUE)
  ka <- deq(name_key(a)); kb <- deq(name_key(b))
  mta <- if (is.null(middle_a)) vector("list", n) else deq(middle_tokens(middle_a))
  mtb <- if (is.null(middle_b)) vector("list", n) else deq(middle_tokens(middle_b))
  vapply(seq_len(n), function(i) {
    if (!has_name_information(ka[i]) || !has_name_information(kb[i])) {
      return("uninformative")
    }
    if (ka[i] == kb[i]) return("corroborates")
    ta <- deq(surname_tokens(a[i])); tb <- deq(surname_tokens(b[i]))
    if (length(intersect(ta, tb))) return("corroborates")
    # the maiden-as-middle rescue: a full surname component surviving in the
    # OTHER record's middle slot
    if (length(intersect(tb, mta[[i]])) || length(intersect(ta, mtb[[i]]))) {
      return("corroborates")
    }
    "conflicts"
  }, character(1))
}
