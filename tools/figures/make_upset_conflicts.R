#!/usr/bin/env Rscript
# =============================================================================
# UpSet-style figure: which evidence axes conflict TOGETHER across the 190
# ROSTER_BENCHMARK pairs, using the exact reference-policy axes computed in
# vignette("roster-benchmark"). Hand-rolled in base graphics -- this package
# ships zero plotting dependencies (see README's "What is deliberately NOT
# here"), and a single documentation figure is not a reason to add one.
#
# Usage: Rscript tools/figures/make_upset_conflicts.R
# Writes: man/figures/README-conflict-upset.png
# =============================================================================
suppressMessages(library(mysterynpi))

b  <- ROSTER_BENCHMARK
ex <- extract_suffix(b$roster_name)
p  <- parse_person(ex$name)

axes <- data.frame(
  surname = surname_agreement(p$last, b$npi_last,
                              middle_a = p$middle, middle_b = b$npi_middle),
  given   = nickname_agreement(sub(" .*", "", p$first), b$npi_first),
  middle  = middle_agreement(middle_tokens(p$middle),
                             middle_tokens(b$npi_middle)),
  suffix  = suffix_agreement(ex$suffix, b$npi_suffix),
  gender  = gender_agreement(b$roster_gender, b$npi_gender),
  license = license_agreement(b$roster_license, b$roster_state,
                              b$npi_license, b$npi_state))

sets <- names(axes)
conf <- as.data.frame(lapply(axes, function(x) x == "conflicts"))
combo_key <- apply(conf, 1, function(r) paste(sets[r], collapse = "+"))
combo_key[combo_key == ""] <- "(none)"

counts <- sort(table(combo_key), decreasing = TRUE)
# keep (none) but draw it last/greyed-out -- it is not an "intersection",
# it is the complement of all of them, shown for scale.
none_n <- counts[["(none)"]]
counts <- counts[names(counts) != "(none)"]
combo_names <- names(counts)
combo_sets  <- strsplit(combo_names, "\\+")

n_combo <- length(combo_names)
n_sets  <- length(sets)

png("man/figures/README-conflict-upset.png", width = 1000, height = 680, res = 130)
layout(matrix(c(1, 2), nrow = 2), heights = c(2, 1.3))

# --- top: bar chart of each conflicting combination's size -------------------
par(mar = c(1.8, 4.5, 2.5, 1))
bp <- barplot(as.numeric(counts), ylim = c(0, max(counts) * 1.25),
              col = "grey30", border = NA, axes = FALSE,
              main = sprintf(
                "Which evidence axes conflict together\n(%d of %d ROSTER_BENCHMARK pairs have ANY conflicting axis)",
                sum(counts), sum(counts) + none_n), cex.main = 0.95)
axis(2, las = 1)
text(bp, as.numeric(counts), labels = as.numeric(counts), pos = 3, cex = 0.9)
mtext(sprintf("%d pairs have no conflicting axis at all (not shown as a bar)", none_n),
      side = 1, line = 0.6, cex = 0.7, col = "grey40")

# --- bottom: dot matrix showing set membership per combination --------------
par(mar = c(3, 4.5, 0.5, 1))
plot(NA, xlim = c(0.5, n_combo + 0.5), ylim = c(0.5, n_sets + 0.5),
     axes = FALSE, xlab = "", ylab = "")
axis(2, at = seq_len(n_sets), labels = rev(sets), las = 1)
for (i in seq_len(n_combo)) {
  on <- match(combo_sets[[i]], sets)
  y  <- n_sets + 1 - on
  points(rep(i, n_sets), seq_len(n_sets), pch = 19, col = "grey85", cex = 1.6)
  points(rep(i, length(y)), y, pch = 19, col = "grey20", cex = 1.6)
  if (length(y) > 1) segments(i, min(y), i, max(y), col = "grey20", lwd = 2)
}
invisible(dev.off())
cat("wrote man/figures/README-conflict-upset.png\n")
