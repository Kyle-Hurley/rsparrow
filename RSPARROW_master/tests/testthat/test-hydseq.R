test_that("hydseq returns data.frame with hydseq column", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow:::hydseq(mini_network_raw, c("hydseq"))

  expect_true(inherits(result, "data.frame"))
  expect_true("hydseq" %in% names(result))
  expect_equal(nrow(result), 7L)
})

test_that("hydseq headwaters come before downstream reaches", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow:::hydseq(mini_network_raw, c("hydseq"))

  # Terminal reach has the highest hydseq value (least negative)
  expect_equal(result$hydseq[result$waterid == 7L], max(result$hydseq))

  # Sorted ascending = upstream-first (headwaters precede terminal)
  result_sorted <- result[order(result$hydseq), ]
  head_positions <- which(result_sorted$headflag == 1L)
  term_position  <- which(result_sorted$waterid == 7L)
  expect_true(all(head_positions < term_position))
})

test_that("hydseq ordering is consistent with network flow direction", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow:::hydseq(mini_network_raw, c("hydseq"))

  # Sorted ascending: terminal reach must be last
  result_sorted <- result[order(result$hydseq), ]
  expect_equal(result_sorted$waterid[nrow(result_sorted)], 7L)
})

test_that("hydseq handles linear network (no branching)", {
  df_linear <- data.frame(
    waterid  = 1:3L,
    fnode    = c(1L, 2L, 3L),
    tnode    = c(2L, 3L, 99L),
    termflag = c(0L, 0L, 1L),
    frac     = c(1, 1, 1),
    demiarea = c(1, 1, 1)
  )
  result <- rsparrow:::hydseq(df_linear, c("hydseq"))

  expect_equal(nrow(result), 3L)
  result_sorted <- result[order(result$hydseq), ]
  # Terminal reach (fnode=3 -> tnode=99) must be last
  expect_equal(result_sorted$waterid[nrow(result_sorted)], 3L)
})

test_that("rsparrow_hydseq matches internal hydseq", {
  load(test_path("fixtures/mini_network.rda"))
  r1 <- rsparrow_hydseq(mini_network_raw)
  r2 <- rsparrow:::hydseq(mini_network_raw, c("hydseq"))

  expect_identical(r1$hydseq, r2$hydseq)
})

test_that("rsparrow_hydseq validates input", {
  # data must be a data.frame
  expect_error(rsparrow_hydseq(list(fnode = 1, tnode = 2, waterid = 1)))

  # from_col must exist in data
  expect_error(
    rsparrow_hydseq(data.frame(fnode = 1, tnode = 1, waterid = 1), from_col = "x")
  )

  # waterid column must be present
  expect_error(rsparrow_hydseq(data.frame(fnode = 1, tnode = 1)))
})

test_that("rsparrow_hydseq preserves non-hydseq columns", {
  load(test_path("fixtures/mini_network.rda"))
  result <- rsparrow_hydseq(mini_network_raw)

  expect_true(all(names(mini_network_raw) %in% names(result)))
  expect_true("hydseq" %in% names(result))
})
