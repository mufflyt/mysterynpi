# =============================================================================
# ABLATION EXPERIMENT 2: verdict layer -- nickname admission ON vs OFF
# =============================================================================
# PRE-REGISTERED before results were seen (2026-09-07):
#   Matcher frozen at mysterynpi fa7216f. No dictionary or threshold changes.
#   Condition A ("none"):     given-name agreement WITHOUT nickname admission:
#                             exact full-token equality corroborates; initials
#                             and absence are uninformative; else conflicts.
#                             The table is never consulted.
#   Condition B ("curated"):  nickname_agreement() as shipped.
#   Everything else byte-identical: same parse, same axes, same reference
#   policy from vignette("roster-benchmark"), same truth.
# DECISION RULE (pre-specified): nickname admission is retained at the
#   verdict layer only if it rescues true matches (A-rejected, B-accepted,
#   truth=match) while adding ZERO accepted nonmatches (truth=nonmatch,
#   decision=accept under B but not A). Any accepted nonmatch under B alone
#   is disqualifying regardless of rescues.
# =============================================================================
if (requireNamespace("mysterynpi", quietly = TRUE)) {
  suppressMessages(library(mysterynpi))
} else suppressMessages(pkgload::load_all(".", quiet = TRUE))
b  <- ROSTER_BENCHMARK
ex <- extract_suffix(b$roster_name)
p  <- parse_person(ex$name)
roster_first <- sub(" .*", "", p$first)

# Condition A: the no-nickname given-name rule. Same normalization and
# same initials-as-uninformative handling as nickname_agreement (so ONLY the
# table is ablated),
# built from public helpers -- no package internals are modified.
given_agreement_none <- function(a, b) {
  norm <- function(x) gsub("[.]", "", name_key(x))
  ka <- norm(a); kb <- norm(b)
  vapply(seq_along(ka), function(i) {
    x <- ka[i]; y <- kb[i]
    if (!has_name_information(x) || !has_name_information(y))
      return("uninformative")
    if (nchar(x) == 1L || nchar(y) == 1L) {
      return("uninformative")
    }
    if (x == y) return("corroborates")
    "conflicts"
  }, character(1))
}

run_policy <- function(given) {
  axes <- data.frame(
    surname = surname_agreement(p$last, b$npi_last,
                                middle_a = p$middle, middle_b = b$npi_middle),
    given   = given,
    middle  = middle_agreement(middle_tokens(p$middle),
                               middle_tokens(b$npi_middle)),
    suffix  = suffix_agreement(ex$suffix, b$npi_suffix),
    gender  = gender_agreement(b$roster_gender, b$npi_gender),
    license = license_agreement(b$roster_license, b$roster_state,
                                b$npi_license, b$npi_state))
  excused <- mapply(function(mt, nl)
    length(intersect(mt, surname_tokens(nl))) > 0,
    middle_tokens(p$middle), b$npi_last)
  conflict <- axes$surname == "conflicts" | axes$given == "conflicts" |
    (axes$middle == "conflicts" & !excused) | axes$suffix == "conflicts"
  name_ok <- axes$surname == "corroborates" & axes$given == "corroborates"
  ifelse(conflict, "reject",
  ifelse(!name_ok, "review",
  ifelse(axes$gender == "conflicts", "review", "accept")))
}

A <- run_policy(given_agreement_none(roster_first, b$npi_first))
B <- run_policy(nickname_agreement(roster_first, b$npi_first))

cat("== Condition A (no nicknames): decision x truth\n")
print(table(A, truth = b$truth))
cat("\n== Condition B (curated one-hop): decision x truth\n")
print(table(B, truth = b$truth))

metrics <- function(d) {
  acc_m  <- sum(d == "accept" & b$truth == "match")
  acc_n  <- sum(d == "accept" & b$truth == "nonmatch")
  rej_m  <- sum(d == "reject" & b$truth == "match")
  rev    <- sum(d == "review")
  c(auto_accept_TP = acc_m, auto_accept_FP = acc_n,
    rejected_true_matches = rej_m, review_queue = rev,
    auto_accept_precision = if ((acc_m + acc_n) > 0)
      round(acc_m / (acc_m + acc_n), 4) else NA_real_)
}
cat("\n== Endpoints\n")
print(rbind(A = metrics(A), B = metrics(B)))

# Discordant-case table with the edge responsible
disc <- which(A != B)
if (length(disc)) {
  edge_for_pair <- function(x, y) {
    e <- mysterynpi::NICKNAME_EDGES
    norm <- function(z) gsub("[.]", "", name_key(z))
    x <- norm(x); y <- norm(y)
    direct <- e$edge_id[(e$name == x & e$nickname == y) |
                        (e$name == y & e$nickname == x)]
    if (length(direct)) return(paste(direct, collapse = "|"))
    shared <- intersect(e$name[e$nickname == x], e$name[e$nickname == y])
    if (length(shared))
      return(paste0("shared-root:", paste(shared, collapse = "|")))
    "initial-or-other"
  }
  out <- data.frame(
    pair_id = b$pair_id[disc], family = b$family[disc],
    truth = b$truth[disc],
    roster_first = roster_first[disc], npi_first = b$npi_first[disc],
    without = A[disc], with = B[disc],
    edge = vapply(disc, function(i)
      edge_for_pair(roster_first[i], b$npi_first[i]), character(1)),
    outcome = ifelse(b$truth[disc] == "match" & B[disc] == "accept" &
                       A[disc] != "accept", "rescued_true_match",
              ifelse(b$truth[disc] == "nonmatch" & B[disc] == "accept",
                     "new_false_positive",
              ifelse(b$truth[disc] == "match" & B[disc] == "review" &
                       A[disc] == "reject", "rescued_to_review",
                     "other_change"))))
  cat("\n== Discordant pairs (A != B):", nrow(out), "\n")
  print(out, row.names = FALSE)
  cat("\n== Outcome classes\n"); print(table(out$outcome))
} else cat("\nNo discordant pairs.\n")

# ---- EXPERIMENT 3: negative controls ---------------------------------------
cat("\n== Negative controls: known-rejection fixtures under both conditions\n")
ghosts <- data.frame(a = c("MARVIN", "GEORGE", "CHRISTINA", "PATRICIA",
                           "DANIELLE", "ROBERT", "HAROLD", "ALBERT",
                           "ELISABETH", "JANE"),
                     b = c("MORRIS", "GRETA", "CHRISTOPHER", "PATRICK",
                           "DANIEL", "WILLIAM", "HENRY", "ALEXANDER",
                           "ELIZABETH", "JOAN"))
ghosts$A <- given_agreement_none(ghosts$a, ghosts$b)
ghosts$B <- nickname_agreement(ghosts$a, ghosts$b)
ghosts$expansion_reaches <- mapply(function(x, y)
  y %in% nickname_variants(x)$queried_first_name, ghosts$a, ghosts$b)
print(ghosts, row.names = FALSE)
cat("ghost pairs corroborated by B:", sum(ghosts$B == "corroborates"),
    "| reached by expansion:", sum(ghosts$expansion_reaches), "\n")
