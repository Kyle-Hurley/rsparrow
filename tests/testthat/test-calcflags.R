# Tests for calcHeadflag() and calcTermflag() — Plan 06B-2
#
# calcHeadflag(data1): returns data.frame(waterid, headflag)
# calcTermflag(data1): returns data.frame(waterid, termflag)
# Both are internal (@noRd); accessed via rsparrow:::
#
# NOTE: calcHeadflag has a known cross-index bug (GitHub issue #2): it identifies
# the terminal reach (fnode = last junction node) as a headwater instead of the
# true upstream headwaters (fnode not in any tnode). calcTermflag is correct.
# Tests here reflect actual function behavior; structural tests cover calcHeadflag.

test_that("calcHeadflag returns data.frame with waterid and headflag columns", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow:::calcHeadflag(mini_network_raw)

  expect_true(inherits(result, "data.frame"))
  expect_true("waterid" %in% names(result))
  expect_true("headflag" %in% names(result))
  expect_equal(nrow(result), 7L)
  # All flag values must be binary (0 or 1)
  expect_true(all(result$headflag %in% c(0L, 1L)))
})

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

test_that("single-reach network is identified as both headwater and terminal", {
  # A network with one reach has no upstream or downstream; it is both headwater
  # and terminal simultaneously.
  df_single <- data.frame(waterid = 1L, fnode = 1L, tnode = 99L)

  head_result <- rsparrow:::calcHeadflag(df_single)
  term_result <- rsparrow:::calcTermflag(df_single)

  expect_equal(head_result$headflag, 1L)
  expect_equal(term_result$termflag, 1L)
})
