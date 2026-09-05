test_that("the Census facts come back keyed and normalised", {
  r <- surname_rarity(c("smith", "SMITH", "Garcia"))
  expect_identical(r$key, c("SMITH", "SMITH", "GARCIA"))
  expect_identical(r$rank[1], 1L)
  expect_identical(r$rank[1], r$rank[2])
  expect_gt(r$per_100k[1], 800)
  expect_lt(r$rank[3], 20L)
})

test_that("absence from the top 1,000 is NA, never a value", {
  r <- surname_rarity(c("MUFFLY", "REINHARD-RYE", "", NA))
  expect_true(all(is.na(r$rank)))
  expect_true(all(is.na(r$per_100k)))
})

test_that("rarity refines a class, and can never suppress a veto", {
  # the worked pattern: same evidence, different surname frequency
  common <- surname_rarity("SMITH")$per_100k
  rare   <- surname_rarity("MUFFLY")$per_100k    # NA: rarer than rank 1000
  refine <- function(base_class, per_100k, threshold = 50) {
    if (is.na(per_100k) || per_100k < threshold) base_class else base_class + 1L
  }
  expect_identical(refine(3L, rare), 3L)      # rare surname keeps the class
  expect_identical(refine(3L, common), 4L)    # SMITH agreement demotes one
  # and a conflict stays a conflict regardless of frequency: the refinement
  # has no code path into any agreement verdict
  expect_identical(surname_agreement("SMITH", "JONES"), "conflicts")
})

test_that("a caller-supplied table drives the same accessor", {
  tab <- data.frame(surname = "XAVIERSMITH", rank = 1L, per_100k = 999,
                    stringsAsFactors = FALSE)
  expect_identical(surname_rarity("Xaviersmith", frequencies = tab)$rank, 1L)
  expect_error(surname_rarity("A", frequencies = data.frame(x = 1)),
               "surname, rank and per_100k")
})
