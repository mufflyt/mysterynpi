test_that("external nickname audit preserves governed edge direction", {
  audit <- utils::read.csv(
    testthat::test_path("..", "..", "inst", "extdata",
                        "external_nickname_edge_audit.csv"),
    stringsAsFactors = FALSE
  )

  lookup <- function(formal, nickname) {
    rows <- audit[
      audit$normalized_formal == formal &
        audit$normalized_nickname == nickname,
      ,
      drop = FALSE
    ]
    expect_gt(nrow(rows), 0L)
    unique(rows$classification)
  }

  expect_identical(lookup("JENNIFER", "JEN"), "ALREADY_PRESENT")
  expect_identical(lookup("JEN", "JENNIFER"), "REJECT_DIRECTIONAL_AMBIGUITY")
  expect_identical(lookup("JEN", "JENNY"), "REJECT_DIRECTIONAL_AMBIGUITY")
})

test_that("unsupported external pairs are not auto-promoted to supported edges", {
  audit <- utils::read.csv(
    testthat::test_path("..", "..", "inst", "extdata",
                        "external_nickname_edge_audit.csv"),
    stringsAsFactors = FALSE
  )
  unknown_pair <- audit[
    audit$normalized_formal == "ELIZABETH" &
      audit$normalized_nickname == "ELLIE",
    ,
    drop = FALSE
  ]

  expect_gt(nrow(unknown_pair), 0L)
  expect_identical(unique(unknown_pair$classification), "NEEDS_ADJUDICATION")
  expect_true(all(nzchar(unknown_pair$reason)))
})
