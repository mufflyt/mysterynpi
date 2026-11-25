roster <- data.frame(
  id = c("r1", "r2", "r3", "r4", "r5"),
  npi = c("100", "200", "300", NA, "500"),
  stringsAsFactors = FALSE)
registry <- data.frame(
  npi = c("100", "200", "200", NA, "900"),
  taxonomy = c("OB", "OB", "MFM", "PED", "GP"),
  stringsAsFactors = FALSE)

test_that("the ledger recomputes what the row count must be", {
  j <- ledgered_join(roster, registry, by = "npi", kind = "left",
                     relationship = "one-to-many", step = "roster->registry")
  L <- j$ledger
  # r2 matches two registry rows (declared one-to-many), r1 one, r3/r5
  # unmatched, r4 has no key at all -- and the arithmetic must say so
  expect_identical(L$rows_x, 5L)
  expect_identical(L$matched_pairs, 3)
  expect_identical(L$unmatched_x, 3)          # r3, r5, and NA-key r4
  expect_identical(L$na_key_x, 1L)
  expect_identical(L$max_fanout, 2)
  expect_identical(L$rows_out, 6L)            # 3 matched pairs + 3 kept
  expect_true(L$conserved)
  expect_identical(nrow(j$result), 6L)
})

test_that("absence never joins: NA keys meet nothing, but are kept and counted", {
  j <- ledgered_join(roster, registry, by = "npi", kind = "left",
                     relationship = "one-to-many")
  na_row <- j$result[is.na(j$result$npi), ]
  expect_identical(nrow(na_row), 1L)          # r4 survives a left join
  expect_identical(na_row$id, "r4")
  expect_true(is.na(na_row$taxonomy))         # matched to NOTHING
  inner <- ledgered_join(roster, registry, by = "npi", kind = "inner",
                         relationship = "one-to-many")
  expect_false("r4" %in% inner$result$id)     # dropped by inner, and ledgered
  expect_identical(inner$ledger$na_key_x, 1L)
  expect_identical(inner$ledger$rows_out, 3L)
  expect_true(inner$ledger$conserved)
})

test_that("unmatched NA-key rows keep their values when column names collide", {
  # merge() suffixes shared non-key names (.x/.y); the held-out rows must be
  # mapped onto those suffixed names or every colliding value is lost.
  x <- data.frame(id = c("a", "b"), k = c("K1", "K2"),
                  note = c("x-a", "x-b"), stringsAsFactors = FALSE)
  y <- data.frame(id = c("c", "d"), k = c("K1", NA),
                  note = c("y-c", "y-d"), stringsAsFactors = FALSE)
  j <- ledgered_join(x, y, by = "k", kind = "full",
                     relationship = "many-to-many")
  na_y <- j$result[is.na(j$result$id.x) & !is.na(j$result$id.y), ]
  expect_identical(na_y$id.y, "d")
  expect_identical(na_y$note.y, "y-d")
  x2 <- data.frame(id = c("a", "b"), k = c("K1", NA),
                   note = c("x-a", "x-b"), stringsAsFactors = FALSE)
  y2 <- data.frame(id = c("c", "d"), k = c("K1", "K3"),
                   note = c("y-c", "y-d"), stringsAsFactors = FALSE)
  jl <- ledgered_join(x2, y2, by = "k", kind = "left",
                      relationship = "many-to-many")
  na_x <- jl$result[is.na(jl$result$k), ]
  expect_identical(na_x$id.x, "b")
  expect_identical(na_x$note.x, "x-b")
  expect_true(is.na(na_x$id.y))
})

test_that("multi-column keys cannot collide through merge()'s internal paste", {
  # merge() joins multi-column keys by paste()-ing them with "\r"; these two
  # DIFFERENT tuples paste to the same string and false-matched before the
  # surrogate-key path. They must stay unmatched and conserved.
  x <- data.frame(k1 = "a\rb", k2 = "c", v = "x", stringsAsFactors = FALSE)
  y <- data.frame(k1 = "a", k2 = "b\rc", w = "y", stringsAsFactors = FALSE)
  j <- ledgered_join(x, y, by = c("k1", "k2"), kind = "full",
                     relationship = "many-to-many")
  expect_true(j$ledger$conserved)
  expect_identical(j$ledger$matched_pairs, 0)
  expect_identical(nrow(j$result), 2L)
  # and a genuine multi-column match still works through the same path
  x2 <- data.frame(k1 = c("K1", "K2"), k2 = c("p", "q"), v = 1:2,
                   stringsAsFactors = FALSE)
  y2 <- data.frame(k1 = c("K1", "K3"), k2 = c("p", "r"), w = 3:4,
                   stringsAsFactors = FALSE)
  j2 <- ledgered_join(x2, y2, by = c("k1", "k2"), kind = "full",
                      relationship = "many-to-many")
  expect_identical(j2$result$v[j2$result$k1 == "K1" & j2$result$k2 == "p"], 1L)
  expect_true(j2$ledger$conserved)
})

test_that("the entry catches an engine that matched NA to NA", {
  # base::merge()'s default is exactly that defect -- and it even FANS OUT
  # on shared absence: one NA-key x row against two NA-key y rows becomes
  # two output rows. With one NA per side the row COUNT happens to survive
  # (only the content is wrong -- r4 silently gains a taxonomy), which is
  # why this test uses two: the arithmetic must diverge to be caught.
  reg2 <- rbind(registry,
                data.frame(npi = NA, taxonomy = "NEO",
                           stringsAsFactors = FALSE))
  lied <- merge(roster, reg2, by = "npi", all.x = TRUE)
  e <- join_ledger_entry(roster, reg2, lied, by = "npi", kind = "left")
  expect_false(e$conserved)
  expect_gt(e$rows_out, e$rows_expected)
  # and the ledgered join itself, on the same inputs, refuses the defect
  j <- ledgered_join(roster, reg2, by = "npi", kind = "left",
                     relationship = "one-to-many")
  expect_true(j$ledger$conserved)
  expect_true(is.na(j$result$taxonomy[is.na(j$result$npi)]))
})

test_that("a declared relationship is verified and names the offenders", {
  expect_error(
    ledgered_join(roster, registry, by = "npi", kind = "left",
                  relationship = "one-to-one"),
    "y keys unique.*200")
  dup_roster <- rbind(roster, roster[1, ])
  expect_error(
    ledgered_join(dup_roster, registry, by = "npi", kind = "left",
                  relationship = "one-to-many"),
    "x keys unique.*100")
  expect_error(
    ledgered_join(roster, registry, by = "npi", kind = "left"),
    "relationship must be declared")
})

test_that("unmatched = 'error' stops exactly when rows would be dropped", {
  expect_error(
    ledgered_join(roster, registry, by = "npi", kind = "inner",
                  relationship = "one-to-many", unmatched = "error"),
    "drops 3 unmatched x row")
  # a full join drops nothing, so it cannot trip the same declaration
  j <- ledgered_join(roster, registry, by = "npi", kind = "full",
                     relationship = "one-to-many", unmatched = "error")
  expect_true(j$ledger$conserved)
  expect_identical(j$ledger$rows_out, 8L)     # 3 pairs + 3 x-only + 2 y-only
})

test_that("min_match_rate has teeth, and zero visibly has none", {
  expect_error(
    ledgered_join(roster, registry, by = "npi", kind = "inner",
                  relationship = "one-to-many", min_match_rate = 0.5),
    "match rate 0.400 below the declared minimum")
  j <- ledgered_join(roster, registry, by = "npi", kind = "inner",
                     relationship = "one-to-many")
  expect_identical(j$ledger$match_rate_x, 0.4)
})

test_that("named by maps differing key columns", {
  reg2 <- registry; names(reg2)[1] <- "provider_npi"
  j <- ledgered_join(roster, reg2, by = c(npi = "provider_npi"),
                     kind = "left", relationship = "one-to-many")
  expect_true(j$ledger$conserved)
  expect_identical(j$ledger$by, "npi=provider_npi")
  expect_error(
    ledgered_join(roster, registry, by = c(npi = "provider_npi"),
                  kind = "left", relationship = "one-to-many"),
    "join keys missing: provider_npi")
})

test_that("ledgers rbind into the reconciliation table a pipeline ships", {
  s1 <- ledgered_join(roster, registry, by = "npi", kind = "left",
                      relationship = "one-to-many", step = "s1")
  s2 <- ledgered_join(s1$result[!is.na(s1$result$taxonomy), ],
                      data.frame(taxonomy = c("OB", "MFM"), grp = c("a", "b"),
                                 stringsAsFactors = FALSE),
                      by = "taxonomy", kind = "left",
                      relationship = "many-to-one", step = "s2")
  ledger <- rbind(s1$ledger, s2$ledger)
  expect_identical(ledger$step, c("s1", "s2"))
  expect_true(all(ledger$conserved))
})

test_that("resolve_best_class refuses stats that would fan its merge out", {
  pc <- data.frame(id = "p1", candidate = "N1", evidence_class = 1L,
                   stringsAsFactors = FALSE)
  stats <- data.frame(id = c("p1", "p1"), best_class = 1L, n_at_best = 1L,
                      stringsAsFactors = FALSE)
  expect_error(resolve_best_class(pc, stats), "one row per id")
})
