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
#'
#' THAT "MA" PRECEDENT WAS WRONG. `"Ma"` is a top-20 Chinese surname (Yo-Yo
#' Ma, Jack Ma) with the same shape as the `"Do"` collision below -- a
#' single token that is BOTH a real NAME_NOISE credential (Master of Arts)
#' AND a common real surname -- and it was carrying none of `"Do"`'s
#' protection: `strip_name_noise("John Ma")` silently returned `"John"`,
#' and since [parse_person()] threads its result through
#' [has_name_information()], that record read as unqueryable and would be
#' silently dropped exactly like the pre-fix `"Do"` case (see
#' [strip_name_noise()]'s "THE DO CARVE-OUT" docs for the DEA-action
#' provenance of that original defect). Found 2026-09-18; given the SAME
#' carve-out `"Do"` already has, via [SURNAME_CREDENTIAL_COLLISIONS]. The
#' other short, ambiguous tokens named above (PA, OD, DC, MS, LM, BA) are
#' NOT known common surnames the way "Do" and "Ma" are -- protecting them
#' would invent a fake surname for a genuinely credential-only input rather
#' than recover a real one, so they are deliberately left stripped
#' unconditionally. This is a claim about which token spellings are real
#' surnames, not a general policy reversal for the vocabulary.
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

#' `NAME_NOISE` tokens that are ALSO common real surnames.
#'
#' A single token cannot mean both things in [NAME_NOISE]'s flat
#' vocabulary, so each entry here gets the SAME two-part protection inside
#' [strip_name_noise()]: kept as a surname when it is one of exactly two
#' tokens in its comma segment, or written in the exact title-case spelling
#' recorded here (the value), regardless of token count. The name (the
#' vector's names) is the `NAME_NOISE` spelling the protection applies to.
#'
#' Membership bar: the token must be a WELL-KNOWN, common real surname --
#' not merely conceivable. `"DO"` (Vietnamese, e.g. the DEA-action records
#' that motivated this file) and `"MA"` (Chinese -- Yo-Yo Ma, Jack Ma) both
#' clear that bar. Most other short `NAME_NOISE` tokens (`PA`, `OD`, `DC`,
#' `MS`, `LM`, `BA`) do NOT -- protecting one of those would invent a fake
#' surname for a genuinely credential-only input rather than recover a real
#' one, so they stay unconditionally stripped. Add a token here only with
#' the same standard of evidence: a real, common surname, not a hypothetical
#' one.
#' @export
SURNAME_CREDENTIAL_COLLISIONS <- c(DO = "Do", MA = "Ma")

#' Strip credential and title TOKENS from a personal-name string
#'
#' TOKEN-BASED ON PURPOSE. A `\\b`-delimited regex alternation destroys accented
#' surnames: in `"Mróz"` the `ó` is not an ASCII word character, so `\\bMr\\b`
#' matches INSIDE the name and the parser returns a surname of `"OZ"`. That is
#' the same population transliteration exists to protect, broken by the cleaner
#' meant to help it. Splitting on delimiters and dropping whole tokens cannot
#' match a substring, so no name can be truncated here.
#'
#' THE "DO" CARVE-OUT. `"Do"` is both the `DO` credential (Doctor of
#' Osteopathic Medicine) and a common Vietnamese surname, and `NAME_NOISE`
#' cannot record both answers for one token. Unconditional stripping deletes
#' the surname from every `"Anh Do"`/`"Do, Anh"`-shaped name --
#' `strip_name_noise("Anh Do")` returned `"Anh"` before this carve-out, and
#' since [parse_person()] threads its result through
#' [has_name_information()], the record then read as unqueryable and was
#' silently dropped rather than resolved. First found in an isochrones
#' consumer (`resolve_dea_action_to_npi()`, `federal_register_dea_actions.R`)
#' whose DEA-action records for practitioners actually named "Do" were
#' vanishing before ever reaching NPI lookup.
#'
#' A `"do"`/`"DO"`/`"Do"` token (case-insensitive) is read as a SURNAME, not
#' the credential, when EITHER (a) it is one of exactly two tokens within its
#' own comma-delimited segment of the string -- a plausible `given surname`
#' pair, e.g. `"Anh Do"`, or, since [parse_person()] hands this function each
#' `"Last, First"` segment separately, a plausible lone surname segment, e.g.
#' the `"Do"` in `"Do, Anh"` -- or (b) it is written in unambiguous title case
#' `"Do"` (never `"DO"`), regardless of token count, e.g. `"Nguyen Van Do"`.
#' Segment-scoped, not string-scoped: `"Do, Anh, M.D."` protects the
#' one-token `"Do"` segment even though the credential segment `"M.D."`
#' brings the WHOLE string's token count to three, because each comma
#' segment is judged on its own, matching how [parse_person()] itself
#' decides `"Last, First"` reversal segment-by-segment. All-caps `"DO"` in a
#' three-or-more-token segment is still read as the credential (e.g.
#' `"John Michael Smith DO"`, one segment, three tokens) -- this carve-out
#' narrows `NAME_NOISE`'s reach for exactly the ambiguous case, it does not
#' widen it, and every other `NAME_NOISE` token is unaffected.
#'
#' THE SAME CARVE-OUT, GENERALISED. `"Do"` is not the only `NAME_NOISE`
#' token that is also a common real surname -- see
#' [SURNAME_CREDENTIAL_COLLISIONS] for the full curated set (currently `DO`
#' and `MA`) and the rule for exactly which tokens qualify. Every entry gets
#' the identical two-part protection described above, keyed on its own
#' title-case spelling.
#'
#' KNOWN LIMITATION: A SEGMENT THAT IS ENTIRELY UPPERCASE HAS NO CASE SIGNAL
#' LEFT TO GIVE. Case is the only thing that distinguishes a genuine
#' three-or-more-token compound surname (`"Nguyen Van Do"`) from a genuine
#' three-or-more-token credentialed name (`"John Michael Smith DO"`) once
#' both are past the two-token rule. A source that uppercases the whole
#' record -- common in bulk exports -- erases that signal for BOTH
#' directions at once: `"NGUYEN VAN DO"` reads as credentialed and loses its
#' real surname (`strip_name_noise("NGUYEN VAN DO")` returns `"NGUYEN VAN"`,
#' not `"NGUYEN VAN DO"`), and there is no available string-only fix, since
#' any rule that recovers the surname in that case would just as wrongly
#' protect `"JOHN MICHAEL SMITH DO"`'s real credential. Deciding which
#' failure to prefer needs a prior on which is more common in a given
#' pipeline's source data, which this package deliberately does not assume.
#' A caller feeding it known-uppercase-only source data and needing better
#' than this should resolve the ambiguity before calling in, e.g. by
#' checking a name/roster field the source already disambiguates elsewhere.
#'
#' @param x character vector.
#' @return character vector with credential and title tokens removed.
#' @export
strip_name_noise <- function(x) {
  vapply(as.character(x), function(s) {
    if (is.na(s)) return(NA_character_)
    # Segment on comma FIRST so the DO carve-out can be judged per segment
    # (see "THE DO CARVE-OUT" above); each segment is then space-tokenised
    # exactly as the original single-pass split did, so behaviour for every
    # other token is unchanged.
    segs <- strsplit(s, ",", fixed = TRUE)[[1]]
    keep_segs <- lapply(segs, function(seg) {
      parts <- strsplit(seg, "[[:space:]]+")[[1]]
      parts <- parts[nzchar(parts)]
      if (!length(parts)) return(character(0))
      bare <- toupper(gsub("[.]", "", parts))
      is_noise <- bare %in% NAME_NOISE
      for (tok in names(SURNAME_CREDENTIAL_COLLISIONS)) {
        coll_idx <- which(bare == tok)
        if (length(coll_idx)) {
          protect <- (length(parts) == 2L) |
            (parts[coll_idx] == SURNAME_CREDENTIAL_COLLISIONS[[tok]])
          is_noise[coll_idx[protect]] <- FALSE
        }
      }
      parts[!is_noise]
    })
    keep <- unlist(keep_segs, use.names = FALSE)
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
#'   \item extract the generational suffix (JR/SR/II/III/IV), BEFORE anything
#'     else touches the string
#'   \item (if `format = "surname_first"`) insert a comma after the surname
#'     span, so the string flows through the SAME reversal logic as an
#'     explicit `"Last, First"`
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
#' Steps 4 and 5 are each a defect observed in a working pipeline, not a
#' precaution: testing the raw string for a comma turned
#' `"Ann M. Barbaccia (Pollack), M.D."` into first `"M"`, middle `"BARBACCIA"`,
#' surname `"ANN"`.
#'
#' STEP 1 IS FIRST FOR A REASON THAT HAS NOTHING TO DO WITH PARSING. Step 3's
#' [strip_name_noise()] treats `JR`/`SR`/`II`/`III`/`IV` as noise and deletes
#' them -- correctly, since a name parser has no way to know `JR` is not a
#' surname. That means a caller who treats "strip titles" and "suffix
#' handling" as two independently-composable pipeline stages loses every
#' suffix the moment title-stripping happens to run first: the generation
#' that survives to distinguish father from son is silently gone before the
#' "suffix" stage ever sees the string, and [suffix_agreement()]'s father/son
#' veto goes quiet with no error. [extract_suffix()] running first, inside
#' this function, is what makes that ordering hazard impossible to hit by
#' composing stages in the wrong order -- see `tests/testthat/test-suffix.R`,
#' "extract_suffix must run BEFORE strip_name_noise, which deletes it". It
#' also runs before step 2's surname-first comma insertion: a trailing
#' `"... JUAN JR"` must lose the `JR` before the particle walk decides where
#' the surname span ends, or the suffix is read as part of the given name.
#'
#' SURNAME-FIRST WITHOUT A COMMA CANNOT BE DETECTED, ONLY DECLARED. The
#' comma logic in step 4 covers `"Smith, John"`; some rosters publish
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
#' [SURNAME_PARTICLES] has its own documented limitation for a leading
#' `"Do"`: a genuine Portuguese particle and a standalone Vietnamese
#' surname are indistinguishable from the string alone, see its docs.
#'
#' @param x character vector of free-text names.
#' @param format `"given_first"` (the default: current behaviour, with
#'   `"Last, First"` handled via the comma) or `"surname_first"` for
#'   rosters that publish the surname first WITHOUT a comma.
#' @return data.frame with `first`, `middle`, `last`, `suffix` (canonical
#'   `JR`/`SR`/`II`/`III`/`IV` label, from [extract_suffix()]), normalised via
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
  # 1. SUFFIX FIRST, before strip_name_noise() (step 3) gets a chance to
  # delete it as noise, and before the surname-first particle walk (step 2)
  # gets a chance to read it as part of the given name.
  ex <- extract_suffix(x)
  suffix_out <- ex$suffix
  suffix_out[is.na(suffix_out)] <- ""
  x <- ex$name
  # 2. SURNAME-FIRST, NO COMMA: declare the reversal the caller asserts,
  # then hand off to the SAME comma-driven reversal as step 4.
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
  # 3, 4. IS THIS A "Last, First" REVERSAL, OR JUST A CREDENTIAL COMMA?
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
  # 5. BEFORE parsing, so no slot can be assigned a bracket.
  raw <- gsub("\\s+", " ", trimws(strip_parenthetical(raw)))
  # humaniformat throws a C++ range_error on an empty string, so an absent name
  # would abort the whole vector. Parse only the rows that carry text and put
  # the blanks back afterwards: absence is a value here, not an exception.
  out <- data.frame(first = rep("", length(raw)), middle = "", last = "",
                    suffix = suffix_out, stringsAsFactors = FALSE)
  ok <- !is.na(raw) & nzchar(raw)
  if (any(ok)) {
    p <- humaniformat::parse_names(raw[ok])   # already in First-Last order
    # humaniformat has its OWN, independent notion of which trailing tokens
    # are degree suffixes -- unrelated to NAME_NOISE/SURNAME_CREDENTIAL_
    # COLLISIONS above -- and it includes "Ma" (case-insensitively: "Ma",
    # "MA" and "ma" all trigger it) once a name has three or more tokens,
    # discarding it from $last_name entirely: humaniformat::suffix(
    # "John Michael Ma") returns "Ma", not NA, and this file never reads
    # humaniformat's own $suffix field (mysterynpi's suffix comes from
    # extract_suffix() in step 1), so "Ma" was silently lost -- "John
    # Michael Ma" parsed to last = "Michael", not "Michael Ma". "Do" is
    # never affected (humaniformat does not treat it as a suffix).
    #
    # Reclaimed only for the EXACT title-case spelling recorded in
    # SURNAME_CREDENTIAL_COLLISIONS (`"Ma"`, not `"MA"`/`"ma"`), matching
    # the case boundary strip_name_noise() already draws for the identical
    # ambiguity: an all-caps "MA" in a 3+-token name has no case signal to
    # read as a surname any more than all-caps "DO" does (see the "KNOWN
    # LIMITATION" docs above), so reclaiming it here would contradict the
    # decision already made on the string side.
    recl <- p$suffix %in% SURNAME_CREDENTIAL_COLLISIONS
    if (any(recl)) {
      p$last_name[recl] <- trimws(paste(p$last_name[recl], p$suffix[recl]))
    }
    blank <- function(v) { k <- name_key(v); k[is.na(k)] <- ""; k }
    out$first[ok]  <- blank(p$first_name)
    out$middle[ok] <- blank(p$middle_name)
    out$last[ok]   <- blank(p$last_name)
  }
  out
}
