# The dictionary version is part of the PUBLIC contract.
#
# Every consumer that records nickname provenance has to stamp the version it
# matched under. Until 2026-09-08 the accessor existed but was unexported, so a
# downstream repository could only get it by reaching past the access boundary
# and reading NICKNAME_EDGES directly, which is the exact thing the boundary
# exists to prevent. The audit script in data-raw/ failed on this.

testthat::test_that("consumers can call mysterynpi::nickname_dictionary_version()", {
  testthat::expect_true("nickname_dictionary_version" %in% getNamespaceExports("mysterynpi"))
  v <- mysterynpi::nickname_dictionary_version()
  testthat::expect_type(v, "character")
  testthat::expect_length(v, 1L)
  testthat::expect_true(nzchar(v))
})

testthat::test_that("the reported version is the corpus version, not a literal", {
  # It must track the data, so a corpus bump cannot leave a stale string behind.
  testthat::expect_identical(mysterynpi::nickname_dictionary_version(),
                             attr(mysterynpi::NICKNAME_EDGES, "version"))
})

testthat::test_that("there is exactly ONE accessor, not a family of aliases", {
  # Consolidation means one authoritative surface. An alternate accessor would
  # reintroduce the ambiguity this workstream is removing.
  exports <- getNamespaceExports("mysterynpi")
  versionish <- grep("dictionary_version|nickname_version|dict_version",
                     exports, value = TRUE)
  testthat::expect_identical(sort(versionish), "nickname_dictionary_version")
})
