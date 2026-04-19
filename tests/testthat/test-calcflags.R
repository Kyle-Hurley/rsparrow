# Tests for calcTermflag() — Plan 06B-2
#
# calcTermflag(data1): returns data.frame(waterid, termflag)
# Internal (@noRd); accessed via rsparrow:::
#
# NOTE: calcHeadflag() was archived to inst/archived/legacy_data_import/ in Plan 09.
# The calcHeadflag tests that were here have been removed. The known bug is
# documented in GH #2. calcTermflag is correct and remains active.

test_that("calcTermflag correctly identifies terminal reaches", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow:::calcTermflag(mini_network_raw)

  # Only reach 7 (tnode = 99, which is not any fnode) is terminal
  expect_equal(sum(result$termflag == 1L), 1L)
  expect_equal(result$termflag[result$waterid == 7L], 1L)
  expect_true(all(result$termflag[result$waterid != 7L] == 0L))
})

test_that("calcTermflag returns data.frame with waterid and termflag columns", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow:::calcTermflag(mini_network_raw)

  expect_true(inherits(result, "data.frame"))
  expect_true("waterid" %in% names(result))
  expect_true("termflag" %in% names(result))
  expect_equal(nrow(result), 7L)
  # All flag values must be binary (0 or 1)
  expect_true(all(result$termflag %in% c(0L, 1L)))
})

test_that("single-reach network is identified as terminal", {
  # A network with one reach has no downstream; it is terminal.
  # (calcHeadflag archived in Plan 09 — headwater test removed)
  df_single <- data.frame(waterid = 1L, fnode = 1L, tnode = 99L)

  term_result <- rsparrow:::calcTermflag(df_single)

  expect_equal(term_result$termflag, 1L)
})
