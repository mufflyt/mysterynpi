# =============================================================================
# Parsing a free-text person name into given / middle / surname
# =============================================================================

#' Credential and title tokens seen in provider directories.
#'
#' Stripped BEFORE parsing: a name parser has no way to know `CRNP` is not a
#' middle name.
#'
#' The vocabulary began nursing/midwifery-centric. The final block was added
#' from an all-provider-type source (the 2026-09-13 OpenSanctions Medicaid
#' exclusion linkage, 8,450 sanctioned individuals): the NPPES credential
#' column there showed DC on 314 providers, DDS 248, LPN 130, DPM 114,
#' DMD 101, PA 73, with OD, PSYD, PHARMD, RPH, LVN, LCSW and DPT at lower
#' counts -- none of which were in the vocabulary, so any of them appearing
#' in a name string sailed through [strip_name_noise()] into a parsed name
#' slot. Short ambiguous tokens (PA, OD, DC) follow the precedent already
#' set by MS, MA, DO and LM: in a PROVIDER-DIRECTORY name string the
#' credential reading is overwhelmingly the correct one.
#' @export
NAME_NOISE <- c(
  "DNP","DNSC","DNS","PHD","EDD","MD","DO","MSN","MSC","MS","MA","MPH",
  "BSN","BS","BA","RN","APRN","ARNP","CNM","CM","CNS","CRNP","CRNA",
  "NP","FNP","WHNP","PNP","ANP","AGNP","IBCLC","LCCE","FACNM","FAAN",
  "FACOG","FACS","FRCS","RNC","LM","CPM","DR","PROF","MR","MRS","MS",
  "MISS","JR","SR","II","III","IV",
  # all-provider-type credentials (2026-09-13 Medicaid exclusion linkage)
  "DDS","DMD","DC","DPM","OD","PA","PAC","PA-C","LPN","LVN","PSYD",
  "PHARMD","RPH","LCSW","DPT")

#' Strip credential and title TOKENS from a personal-name string
#'
#' TOKEN-BASED ON PURPOSE. A `\\b`-delimited regex alternation destroys accented
#' surnames: in `"Mróz"` the `ó` is not an ASCII word character, so `\\bMr\\b`
#' matches INSIDE the name and the parser returns a surname of `"OZ"`. That is
#' the same population transliteration exists to protect, broken by the cleaner
#' meant to help it. Splitting on delimiters and dropping whole tokens cannot
#' match a substring, so no name can be truncated here.
#'
#' @param x character vector.
#' @return character vector with credential and title tokens removed.
#' @export
strip_name_noise <- function(x) {
  vapply(as.character(x), function(s) {
    if (is.na(s)) return(NA_character_)
    parts <- strsplit(s, "[[:space:],]+")[[1]]
    parts <- parts[nzchar(parts)]
    bare <- toupper(gsub("[.]", "", parts))
    keep <- parts[!(bare %in% NAME_NOISE)]
    out <- gsub("[.]", " ", paste(keep, collapse = " "))
    gsub("[[:space:]]+", " ", trimws(out))
  }, character(1), USE.NAMES = FALSE)
}

#' Parse a free-text person name into given, middle and surname
#'
#' THE ORDER IS THE POINT. humaniformat decides which token is which; it does
#' not clean, and it does not judge content. Handed a raw directory string it
#' returns, verbatim:
#'
#' \preformatted{
#'   "Ann M. Barbaccia (Pollack)"  ->  last = "(Pollack)"
#'   "Samuel (NMN) Anaya"          ->  middle = "(NMN)"
#'   "Álvarez"                     ->  first = "Álvarez"   (not transliterated)
#' }
#'
#' A maiden name becomes the SURNAME, `(NMN)` -- which means "no middle name" --
#' becomes a middle name, and the accent survives into a join key that can never
#' match its unaccented registry spelling. Each of those looks like a clean
#' parse downstream, which is what makes them dangerous.
#'
#' So the sequence below is not stylistic:
#'
#' \enumerate{
#'   \item strip credential and title tokens
#'   \item decide "Last, First" by asking whether a comma separates two
#'     stretches that BOTH still hold a name once credentials are gone -- the
#'     comma in `", M.D."` does not
#'   \item remove parenthesised alternates BEFORE parsing, so the parser never
#'     sees a bracket to assign to a slot
#'   \item parse
#'   \item normalise each part
#' }
#'
#' Steps 2 and 3 are each a defect observed in a working pipeline, not a
#' precaution: testing the raw string for a comma turned
#' `"Ann M. Barbaccia (Pollack), M.D."` into first `"M"`, middle `"BARBACCIA"`,
#' surname `"ANN"`.
#'
#' SURNAME-FIRST WITHOUT A COMMA CANNOT BE DETECTED, ONLY DECLARED. The
#' comma logic above covers `"Smith, John"`; some rosters publish
#' `"FINCH SHANNON"` -- surname first, no comma -- and NOTHING in that string
#' distinguishes it from a given-first "Finch Shannon" (Finch is a plausible
#' given name). The caller knows the source's convention; `format =
#' "surname_first"` declares it. Implementation: a comma is inserted after
#' the surname span, and the string then flows through the SAME
#' credential-aware reversal as an explicit `"Last, First"` -- one reversal
#' path, not two. The surname span is the first token plus any leading
#' [SURNAME_PARTICLES] run, so `"DE LA CRUZ JUAN"` reverses to
#' `"JUAN DE LA CRUZ"`. Strings already carrying a comma are left to the
#' comma logic. Limitation: an unhyphenated compound surname with no
#' particle (`"SMITH JONES MARY"`) reads as surname `SMITH` -- there is no
#' signal to do better without a recorded surname to check against.
#'
#' @param x character vector of free-text names.
#' @param format `"given_first"` (the default: current behaviour, with
#'   `"Last, First"` handled via the comma) or `"surname_first"` for
#'   rosters that publish the surname first WITHOUT a comma.
#' @return data.frame with `first`, `middle`, `last`, normalised via
#'   [name_key()]. Absent parts are `""`, never `NA`, so
#'   [has_name_information()] is the only test a caller needs.
#' @export
parse_person <- function(x, format = c("given_first", "surname_first")) {
  format <- match.arg(format)
  if (!requireNamespace("humaniformat", quietly = TRUE)) {
    stop("parse_person() requires the humaniformat package.\n",
         "  install.packages(\"humaniformat\")", call. = FALSE)
  }
  x <- as.character(x)
  if (format == "surname_first") {
    x <- vapply(x, function(one) {
      if (is.na(one) || grepl(",", one, fixed = TRUE)) return(one)
      tokens <- strsplit(trimws(one), "[[:space:]]+")[[1]]
      if (length(tokens) < 2L) return(one)
      bare <- toupper(gsub("[.]", "", tokens))
      end <- 1L
      while (end < length(tokens) && bare[end] %in% SURNAME_PARTICLES) {
        end <- end + 1L
      }
      end <- min(end, length(tokens) - 1L)  # always leave a given name
      paste(paste(tokens[1:end], collapse = " "),
            paste(tokens[(end + 1L):length(tokens)], collapse = " "),
            sep = ", ")
    }, character(1), USE.NAMES = FALSE)
  }
  # 2. IS THIS A "Last, First" REVERSAL, OR JUST A CREDENTIAL COMMA?
  # Two wrong answers were tried before this one. Testing the RAW string reads
  # ", M.D." as a reversal and returns first "M", surname "ANN". Testing the
  # CLEANED string never fires at all, because strip_name_noise() splits on
  # "[[:space:],]+" and so deletes every comma before it can be seen.
  # The decidable question is whether a comma separates two stretches that BOTH
  # still hold a name once credentials are gone.
  raw <- vapply(x, function(one) {
    if (is.na(one)) return(NA_character_)
    seg <- trimws(strip_name_noise(strsplit(one, ",")[[1]]))
    seg <- seg[!is.na(seg) & nzchar(seg)]
    if (!length(seg)) return("")
    if (length(seg) >= 2L) paste(c(seg[-1], seg[1]), collapse = " ")  # reversed
    else seg[1]
  }, character(1), USE.NAMES = FALSE)
  # 3. BEFORE parsing, so no slot can be assigned a bracket.
  raw <- gsub("\\s+", " ", trimws(strip_parenthetical(raw)))
  # humaniformat throws a C++ range_error on an empty string, so an absent name
  # would abort the whole vector. Parse only the rows that carry text and put
  # the blanks back afterwards: absence is a value here, not an exception.
  out <- data.frame(first = rep("", length(raw)), middle = "", last = "",
                    stringsAsFactors = FALSE)
  ok <- !is.na(raw) & nzchar(raw)
  if (any(ok)) {
    p <- humaniformat::parse_names(raw[ok])   # already in First-Last order
    blank <- function(v) { k <- name_key(v); k[is.na(k)] <- ""; k }
    out$first[ok]  <- blank(p$first_name)
    out$middle[ok] <- blank(p$middle_name)
    out$last[ok]   <- blank(p$last_name)
  }
  out
}
