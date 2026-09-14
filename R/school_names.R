# =============================================================================
# School names: the medical-school unit CMS puts on every clinician's school
# =============================================================================

#' Medical-school unit phrases, longest first
#'
#' The trailing academic units [strip_med_suffix()] removes from a school name.
#' Derived from the strings CMS actually uses for non-physician clinicians in
#' the Doctors and Clinicians file (the dental schools and "college of
#' physicians and surgeons" are CMS taxonomy noise, and are in the list for
#' that reason). The order matters: a shorter phrase must never match first and
#' leave the tail of a longer one ("COLLEGE OF MEDICINE" before
#' "COLLEGE OF MED", which would otherwise leave "INE").
#' @export
MEDICAL_UNIT_PATTERNS <- c(
  "SCHOOL OF MEDICINE AND DENTISTRY", "COLLEGE OF PHYSICIANS AND SURGEONS",
  "SCHOOL OF OSTEOPATHIC MEDICINE",   "COLLEGE OF OSTEOPATHIC MEDICINE",
  "COLLEGE OF MEDICINE AND SURGERY",  "SCHOOL OF DENTAL MEDICINE",
  "SCHOOL OF DENTAL MED",             "COLLEGE OF DENTISTRY",
  "SCHOOL OF MEDICINE",               "COLLEGE OF MEDICINE",
  "MEDICAL DEPARTMENT",               "MEDICAL BRANCH",
  "MEDICAL SCHOOL",                   "MEDICAL COLLEGE",
  "MEDICAL CENTER",                   "MEDICAL UNIVERSITY",
  "COLLEGE OF MED", "SCHOOL OF MED", "SCH OF MED", "MED CTR", "MED SCH")

# A remainder that still names an institution. "UN OF" is CMS's abbreviation
# in "STATE UN OF NY".
.INSTITUTION_WORD <- "\\b(UNIVERSITY|UNIV|UN OF|COLLEGE|INSTITUTE)\\b"

.has_institution_word <- function(v) {
  !is.na(v) & grepl(.INSTITUTION_WORD, v, ignore.case = TRUE, perl = TRUE)
}

# Trailing connective a strip leaves behind ("... AT THE", "... SYSTEM,"),
# then whitespace squished.
.trim_connective <- function(v) {
  v <- sub("[ ,\\-]+(AT|OF|THE|AND|SYSTEM|HSC)?[ ,\\-]*$", "", v,
           ignore.case = TRUE, perl = TRUE)
  gsub("\\s+", " ", trimws(v), perl = TRUE)
}

#' The institution in a CMS medical-school name
#'
#' CMS maps every clinician's education through a MEDICAL-school code list, so
#' a nurse-midwife, nurse practitioner or physician assistant trained at a
#' university's nursing or health-professions school arrives as
#' "<University> SCHOOL OF MEDICINE". Read verbatim, that says the clinician
#' holds an MD. Other directories built on the same CMS field (commercial
#' provider directories among them) carry the identical strings. This returns
#' the institution and drops the medical unit.
#'
#' Three rules, each written for a string that came out wrong before it:
#'
#' 1. **A trailing unit is removed**: "GEORGETOWN UNIVERSITY SCHOOL OF
#'    MEDICINE" gives "GEORGETOWN UNIVERSITY". Phrases are tried longest first
#'    ([MEDICAL_UNIT_PATTERNS]). At least one character must precede the unit,
#'    so a phrase that opens the name is never taken for a suffix.
#' 2. **A named school of a university gives the university**: when the unit is
#'    followed by "at", "of" or a comma and then a university, the words before
#'    the unit are the school's own name. "BRODY SCHOOL OF MEDICINE AT EAST
#'    CAROLINA UNIVERSITY" gives "EAST CAROLINA UNIVERSITY", not "BRODY".
#' 3. **A strip that leaves no institution is refused**: when what would remain
#'    contains no institution word (university, college, institute), the
#'    medical phrase is the institution's name and that step is skipped.
#'    "BAYLOR COLLEGE OF MEDICINE", "OHIO MEDICAL UNIVERSITY" and
#'    "PHILADELPHIA COLLEGE OF OSTEOPATHIC MEDICINE" come back whole, not as
#'    "BAYLOR", "OHIO" and "PHILADELPHIA". Refusing one step does not refuse
#'    the rest: "MEHARRY MEDICAL COLLEGE SCHOOL OF MEDICINE" gives
#'    "MEHARRY MEDICAL COLLEGE".
#'
#' Matching ignores case and the result keeps the input's case, so it can be
#' applied to raw strings either way. It names an institution, not a
#' programme: it cannot tell a nursing school from the medical school of the
#' same university, and a school that has no medical school (Frontier Nursing
#' University) never appears in the CMS field to begin with.
#'
#' @param x character vector of school names (a factor is read as its labels;
#'   an all-`NA` vector of any type is allowed).
#' @return character vector the same length as `x`: the institution, the input
#'   unchanged when no rule applies, and `NA` where `x` is `NA`.
#' @examples
#' strip_med_suffix(c(
#'   "GEORGETOWN UNIVERSITY SCHOOL OF MEDICINE",
#'   "Perelman School of Med at the University of Pennsylvania",
#'   "BAYLOR COLLEGE OF MEDICINE",
#'   "MEDICAL UNIVERSITY OF SOUTH CAROLINA COLLEGE OF MEDICINE",
#'   NA))
#' @export
strip_med_suffix <- function(x) {
  if (is.factor(x)) x <- as.character(x)
  if (!is.character(x)) {
    if (!all(is.na(x))) stop("x must be a character vector", call. = FALSE)
    x <- as.character(x)
  }
  y <- x
  miss <- is.na(y)
  y[miss] <- ""
  # Rule 2 first: a named school of a university.
  for (p in MEDICAL_UNIT_PATTERNS) {
    rx <- paste0("^.+?\\s*[,-]?\\s*", p,
                 "(?:\\s*,\\s*|\\s+(?:AT|OF)\\s+(?:THE\\s+)?)(.+)$")
    hit <- regmatches(y, regexec(rx, y, ignore.case = TRUE, perl = TRUE))
    tail <- vapply(hit, function(m) if (length(m) >= 2L) m[2L] else NA_character_,
                   character(1))
    use <- .has_institution_word(tail)
    y[use] <- tail[use]
  }
  # Rules 1 and 3: strip the unit, one phrase at a time, keeping a strip only
  # if an institution is left.
  for (p in MEDICAL_UNIT_PATTERNS) {
    cand <- .trim_connective(sub(paste0("^(.+?)\\s*[,-]?\\s*", p, "\\b.*$"), "\\1",
                                 y, ignore.case = TRUE, perl = TRUE))
    ok <- cand != y & nzchar(cand) & .has_institution_word(cand)
    y[ok] <- cand[ok]
  }
  y[miss] <- NA_character_
  y
}
