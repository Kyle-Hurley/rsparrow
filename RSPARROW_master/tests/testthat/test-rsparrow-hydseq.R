test_that("rsparrow_hydseq is exported and callable without model object", {
  expect_true(exists("rsparrow_hydseq"))
  expect_true(is.function(rsparrow_hydseq))
  expect_true("from_col" %in% names(formals(rsparrow_hydseq)))
})

test_that("rsparrow_hydseq returns data.frame with hydseq column", {
  # Minimum columns required by internal hydseq(): fnode, tnode, waterid,
  # termflag, frac, demiarea
  network <- data.frame(
    waterid  = 1:3L,
    fnode    = c(1L, 2L, 3L),
    tnode    = c(2L, 3L, 99L),
    termflag = c(0L, 0L, 1L),
    frac     = c(1, 1, 1),
    demiarea = c(1, 1, 1)
  )
  result <- rsparrow_hydseq(network)
  expect_true(is.data.frame(result))
  expect_true("hydseq" %in% names(result))
  expect_equal(nrow(result), 3L)
})

test_that("rsparrow_hydseq accepts custom column names via from_col/to_col", {
  network <- data.frame(
    waterid    = 1:3L,
    upstream   = c(1L, 2L, 3L),
    downstream = c(2L, 3L, 99L),
    termflag   = c(0L, 0L, 1L),
    frac       = c(1, 1, 1),
    demiarea   = c(1, 1, 1)
  )
  result <- rsparrow_hydseq(network, from_col = "upstream", to_col = "downstream")
  expect_true(is.data.frame(result))
  expect_true("hydseq" %in% names(result))
  # Original column names preserved
  expect_true("upstream" %in% names(result))
  expect_true("downstream" %in% names(result))
})

test_that("rsparrow_hydseq stops with informative error for non-data.frame input", {
  expect_error(rsparrow_hydseq(list(fnode = 1L, tnode = 2L, waterid = 1L)))
})

test_that("rsparrow_hydseq stops when from_col not found in data", {
  expect_error(
    rsparrow_hydseq(data.frame(waterid = 1L, fnode = 1L, tnode = 99L), from_col = "x")
  )
})

test_that("rsparrow_hydseq stops when waterid column missing", {
  expect_error(rsparrow_hydseq(data.frame(fnode = 1L, tnode = 99L)))
})
