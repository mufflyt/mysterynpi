# =============================================================================
# Name keys: absence, normalisation, and the split of a fused given-name field
# =============================================================================

#' Does this field carry identity information?
#'
#' NEVER use a naked `nzchar()` for this. `nzchar(NA_character_)` is `TRUE`,
#' which reads missingness as evidence. In a real pipeline that single fact
#' made every absent middle name agree with every other absent middle name:
#' `paste(NA_character_, "")` produced the literal `"NA"`, every record gained
#' a fabricated middle initial of `N`, all 18,397 candidate pairs reported
#' middle agreement, and the evidence class meaning "exact name, no middle
#' information" was empty.
#'
#' @param x character vector.
#' @return logical: `TRUE` where `x` is neither `NA` nor empty.
#' @export
has_name_information <- function(x) !is.na(x) & nzchar(x)

#' Strip parenthesised alternate names, keeping word-internal brackets.
#'
#' Rosters publish preferred names inline: `"Cynthia (Cindi)"`. The bracket
#' survives naive normalisation, and a downstream split then hands the middle
#' slot a literal `"("`, which equals no recorded initial anywhere -- so a
#' middle-name veto deletes the whole candidate set. Every affected row failed
#' in the pipeline this was found in: 7 unmatched, 2 tied, none resolved.
#'
#' Two conventions appear and they mean opposite things:
#'
#' \preformatted{
#'   "Cynthia (Cindi) A."   separate token  -> an alternate name, dropped
#'   "C(arolyn) Diane"      inside a token  -> optional letters, KEPT
#' }
#'
#' Deleting the group in the second case leaves a given name of `"C"`, which is
#' not a name -- it is a blocking key that joins to every record whose given
#' name is a bare initial.
#'
#' @param x character vector, already upper-cased.
#' @return character vector.
#' @export
strip_parenthetical <- function(x) {
  # [A-Za-z'] not [A-Z']: this also runs BEFORE parsing, on mixed-case input.
  out <- gsub("([A-Za-z'])\\(([^)]*)\\)", "\\1\\2", x)   # word-internal: unwrap
  out <- gsub("\\([^)]*\\)", " ", out)                # standalone: drop
  out <- gsub("\\([^)]*$", " ", out)                  # unclosed: runs to end
  # "]" FIRST inside the class is the portable way to mean a literal bracket;
  # written [()\\[\\]] the escapes are ambiguous in TRE and the class ends early.
  gsub("[][()]", " ", out)
}

#' Canonical name join key: transliterated, upper-cased, whitespace-collapsed.
#'
#' THE DEFECT THIS EXISTS TO PREVENT. Hand-rolled normalisers are
#' `toupper(trimws(...))` and nothing more, so they do not delete accented
#' characters -- they PRESERVE them:
#'
#' \preformatted{
#'   toupper("Alvarez" with an accent)  -> accented, not "ALVAREZ"
#'   first_initial(that)                -> the accented letter, never "A"
#' }
#'
#' Every blocking strategy joins on an exact name or an exact first initial, so
#' an accented roster name cannot reach its unaccented registry spelling by any
#' route. Measured in one frozen linkage: of the 27 roster rows carrying
#' non-ASCII name characters, the weakest evidence tier ran 26% against 1.5%
#' cohort-wide, and the unmatched rate ran 30% against 10.4%.
#'
#' `NA` in, `NA` out. Callers needing `""` for a join must say so via
#' [blank_na()], so absence is never converted to a value by accident.
#'
#' @section Migrating from an existing normaliser:
#' `strip_alternates` exists so a swap can be PROVEN rather than assumed. The
#' incumbent normaliser this was extracted alongside does not remove
#' parenthesised alternate names; this one does, and that is a deliberate fix,
#' not an accident of reimplementation -- every roster row whose derived middle
#' initial came out as `"("` failed to resolve, 9 of 9.
#'
#' So the migration is two reviewable steps, not one leap:
#'
#' \preformatted{
#'   name_key(x, strip_alternates = FALSE)   # byte-identical to the incumbent
#'   name_key(x)                             # then flip, as its own diff
#' }
#'
#' Step one should change nothing and can be merged on that evidence. Step two
#' changes keys for exactly the rows carrying a bracket, and deserves to be
#' looked at on its own.
#'
#' @param x character vector.
#' @param strip_alternates logical: remove parenthesised alternate names.
#'   `TRUE` is correct for person names and is the default. `FALSE` reproduces a
#'   normaliser that does not handle the convention -- use it to prove a swap,
#'   not to ship.
#' @return character vector.
#' @export
name_key <- function(x, strip_alternates = TRUE) {
  if (is.null(x) || length(x) == 0L) return(character(0))
  x <- as.character(x)
  # A NUL byte terminates a PCRE string, silently truncating the rest of the
  # name; replace with a space so the fragments stay separately joinable.
  out <- gsub("\\x00", " ", x, perl = TRUE)
  if (!requireNamespace("stringi", quietly = TRUE)) {
    stop("stringi is required: without it accented names cannot be ",
         "transliterated and every non-ASCII person silently fails to match.",
         call. = FALSE)
  }
  out <- stringi::stri_trans_nfc(out)
  # German romanisation BEFORE the Latin-ASCII strip, which would otherwise
  # degrade the umlauts to bare vowels and lose parity with sources that
  # romanise them.
  for (p in list(c("\u00fc", "UE"), c("\u00dc", "UE"), c("\u00f6", "OE"),
                 c("\u00d6", "OE"), c("\u00e4", "AE"), c("\u00c4", "AE"),
                 c("\u00df", "SS"))) {
    out <- gsub(p[1], p[2], out, fixed = TRUE)
  }
  out <- stringi::stri_trans_general(out, "Latin-ASCII")
  out <- toupper(out)
  if (isTRUE(strip_alternates)) out <- strip_parenthetical(out)
  out <- gsub("\\s+", " ", trimws(out))
  out[is.na(x)] <- NA_character_
  out
}

#' Normalised key with absence rendered as `""`, for use as a join key.
#' @param x character vector.
#' @param strip_alternates see [name_key()].
#' @return character vector, `NA` mapped to `""`.
#' @export
blank_na <- function(x, strip_alternates = TRUE) {
  k <- name_key(x, strip_alternates)
  k[is.na(k)] <- ""
  k
}

#' First initial of a normalised name, or `NA` when there is no name.
#'
#' Returns `NA` rather than `""` for missing input so a caller cannot read
#' absence as a value. Taken AFTER transliteration, so an accented surname
#' yields the unaccented letter and joins against the registry spelling.
#'
#' @param x character vector.
#' @param strip_alternates see [name_key()].
#' @return character vector of single letters, or `NA`.
#' @export
first_initial <- function(x, strip_alternates = TRUE) {
  k <- name_key(x, strip_alternates)
  out <- substr(k, 1L, 1L)
  out[is.na(k) | !nzchar(k)] <- NA_character_
  out
}

#' Split a fused given-name field into given name and trailing middle tokens.
#'
#' Rosters routinely fuse middle names into the given-name column
#' (`"Julie Ann"`): the first token is the given name, the remainder is middle.
#'
#' The middle name this derives is EVIDENCE THE SOURCE NEVER PUBLISHED. In the
#' pipeline this comes from, 62 of 82 records whose only candidate was deleted
#' on a middle-name conflict had that conflicting middle initial derived here
#' rather than read from a middle-name column. Treat the result as weaker than
#' a recorded middle name, and never let it veto on its own.
#'
#' @param given character vector: the roster's given-name field.
#' @param strip_alternates see [name_key()].
#' @return list with `given` and `middle_from_given`, both normalised.
#' @export
split_given <- function(given, strip_alternates = TRUE) {
  k <- blank_na(given, strip_alternates)
  list(given = sub("\\s.*$", "", k),
       middle_from_given = trimws(sub("^[^ ]*", "", k)))
}
