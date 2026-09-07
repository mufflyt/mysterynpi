# The nickname dictionary is a first-class, versioned artifact: every search
# fan-out and every nickname verdict is attributable to a row of it, so its
# integrity is tested like code. The pins here are deliberate friction --
# changing an edge without bumping the version, or reintroducing a refused
# weld, must fail in CI, not surface months later as a wrong match.

e <- mysterynpi::NICKNAME_EDGES

test_that("the dictionary is versioned, and edits without a bump fail here", {
  # THE RULE: any edge change bumps `version` in data-raw/NICKNAME_EDGES.R
  # and updates this triple in the same PR. A mismatch means someone edited
  # edges without declaring a new dictionary version.
  expect_identical(attr(e, "version"), "2026-09-06.1")
  expect_identical(nrow(e), 2846L)
  expect_identical(attr(e, "checksum"),
                   sum(utf8ToInt(paste(e$edge_id, collapse = "|"))))
  expect_identical(attr(e, "checksum"), 2981180L)
})

test_that("edge ids are stable, unique, and content-derived", {
  expect_identical(e$edge_id, paste0(e$name, ">", e$nickname))
  expect_identical(anyDuplicated(e$edge_id), 0L)
  expect_true(all(grepl("^[A-Z]+>[A-Z]+$", e$edge_id)))
})

test_that("no self-edges, no duplicate edges, no non-alphabetic garbage", {
  expect_false(any(e$name == e$nickname))
  expect_identical(anyDuplicated(e[c("name", "nickname")]), 0L)
  expect_true(all(grepl("^[A-Z]+$", e$name)))
  expect_true(all(grepl("^[A-Z]+$", e$nickname)))
  expect_false(anyNA(e$name) || anyNA(e$nickname))
})

test_that("refused edges stay refused: the 13 issue-4 weld drops", {
  # These exact rows shipped once and welded distinct formal names into
  # false corroboration (ROBERT==WILLIAM). They were dropped by
  # adjudication in data-raw; a vendored-corpus refresh must never
  # reintroduce them.
  refused <- data.frame(
    name = c("BILL", "BILLY", "HARRY", "HARRY", "CHICK", "CHICK",
             "DELLA", "DELLA", "BELLA", "ELOISE", "WILBER",
             "CATHY", "CATHY"),
    nickname = c("ROBERT", "ROBERT", "HAROLD", "HENRY", "CAROLINE",
                 "CHARLOTTE", "ADELAIDE", "DELILAH", "ARABELLA",
                 "LOUISE", "BERT", "CATHERINE", "CATHLEEN"),
    stringsAsFactors = FALSE)
  expect_identical(nrow(refused), 13L)
  present <- paste0(refused$name, ">", refused$nickname) %in% e$edge_id
  expect_false(any(present))
  # and the welds they caused stay impossible in EITHER direction
  for (p in list(c("ROBERT", "WILLIAM"), c("HAROLD", "HENRY"),
                 c("CAROLINE", "CHARLOTTE"), c("ADELAIDE", "DELILAH"),
                 c("CATHERINE", "CATHLEEN"))) {
    expect_false(any((e$name == p[1] & e$nickname == p[2]) |
                     (e$name == p[2] & e$nickname == p[1])),
                 info = paste(p, collapse = "~"))
  }
})

test_that("historically approved edges are preserved exactly", {
  # The load-bearing pairs adjudicated across issues 3-4 and the isochrones
  # hand maps: a corpus refresh that loses one of these changes verdicts.
  approved <- list(c("WILLIAM", "BILL"), c("ELIZABETH", "BETH"),
                   c("ROBERT", "BOB"), c("MARGARET", "PEG"),
                   c("ANN", "NANCY"), c("RICHARD", "RICK"),
                   c("CATHERINE", "KATE"), c("BARBARA", "BARB"),
                   c("STEVEN", "STEPHEN"), c("PHILLIP", "PHILIP"),
                   c("ALBERT", "AL"), c("ALEXANDER", "AL"))
  for (p in approved) {
    expect_true(any((e$name == p[1] & e$nickname == p[2]) |
                    (e$name == p[2] & e$nickname == p[1])),
                info = paste(p, collapse = "~"))
  }
})

test_that("degree profile is pinned: no name explodes past the known hubs", {
  toks <- unique(c(e$name, e$nickname))
  deg <- vapply(toks, function(k)
    length(unique(c(e$nickname[e$name == k], e$name[e$nickname == k]))),
    integer(1))
  # widest legitimate hub is CHRIS at 18; nickname_variants' default
  # max_expansion (25) sits just above this measured ceiling
  expect_identical(max(deg), 18L)
  expect_identical(names(deg)[deg == 18L], "CHRIS")
  expect_identical(sum(deg > 10L), 21L)
  # a new name above the ceiling is an explosion until adjudicated here
  expect_true(all(deg <= 18L))
})

test_that("cycles exist, are counted, and are never traversed", {
  # 270 edges have a recorded reverse (135 two-cycles). Cycles are ALLOWED
  # in the data -- usage really is bidirectional for many pairs -- but no
  # rule walks them: nickname_variants() and nickname_agreement() are
  # one-hop by construction, proven in their own tests. This pin exists so
  # a corpus refresh that changes the cycle count is a reviewed event.
  expect_identical(sum(paste(e$name, e$nickname) %in%
                         paste(e$nickname, e$name)), 270L)
})
