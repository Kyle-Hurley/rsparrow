# Tests for predict_sparrow() — Plan 06C-3
#
# predict_sparrow(estimate.list, estimate.input.list, bootcorrection,
#                DataMatrix.list, SelParmValues, subdata, dlvdsgn)
#   internally calls .Fortran("ptnoder") and .Fortran("mptnoder") via predict_core
#   also calls deliver() → .Fortran("deliv_fraction")
#   requires compiled rsparrow
#
# Returns a named list with (at minimum): predmatrix, yldmatrix, oparmlist, oyieldlist
#
# mini_network: 7 reaches, 1 source (s1), 1 delivery var (d1), 1 decay var (k1)
# predmatrix: 7 rows x 14 cols (waterid + load vars + shares)
# yldmatrix:  7 rows x 10 cols (waterid + yield/conc vars)
# Terminal reach (waterid=7, row 7) accumulates all upstream loads → highest pload_total

testthat::skip_if_not_installed("rsparrow")

load_predict_inputs <- function() {
  env <- new.env()
  load(test_path("fixtures/mini_model_inputs.rda"), envir = env)
  load(test_path("fixtures/mini_network.rda"), envir = env)
  list(mi = env$mini_inputs, net = env$mini_network_raw)
}

run_predict <- function() {
  inp <- load_predict_inputs()
  rsparrow:::predict_sparrow(
    inp$mi$estimate.list,
    inp$mi$estimate.input.list,
    bootcorrection = 1.0,
    inp$mi$DataMatrix.list,
    inp$mi$SelParmValues,
    subdata  = inp$net,
    dlvdsgn  = inp$mi$dlvdsgn
  )
}

test_that("predict_sparrow returns a list containing predmatrix and yldmatrix", {
  result <- run_predict()
  expect_true(is.list(result))
  expect_true("predmatrix" %in% names(result))
  expect_true("yldmatrix"  %in% names(result))
})

test_that("predmatrix has nreach rows", {
  result <- run_predict()
  expect_equal(nrow(result$predmatrix), 7L)
})

test_that("terminal reach accumulates the largest total load in the network", {
  # The terminal reach (waterid=7, row 7) receives all upstream loads via accumulation.
  # pload_total is column 2 of predmatrix (first column is waterid).
  result <- run_predict()
  pload_total <- result$predmatrix[, 2]  # col 1=waterid, col 2=pload_total
  terminal_load <- pload_total[7]

  expect_equal(terminal_load, max(pload_total),
               label = "terminal reach has maximum pload_total")
})

test_that("all total predicted loads are non-negative", {
  result <- run_predict()
  pload_total <- result$predmatrix[, 2]
  expect_true(all(pload_total >= 0.0))
})

test_that("yldmatrix has the same number of rows as predmatrix", {
  result <- run_predict()
  expect_equal(nrow(result$yldmatrix), nrow(result$predmatrix))
})

test_that("oparmlist and oyieldlist are non-empty character vectors", {
  result <- run_predict()
  expect_true(is.character(result$oparmlist))
  expect_true(is.character(result$oyieldlist))
  expect_true(length(result$oparmlist) > 0L)
  expect_true(length(result$oyieldlist) > 0L)
  # waterid must be the first column name in both output lists
  expect_equal(result$oparmlist[1],  "waterid")
  expect_equal(result$oyieldlist[1], "waterid")
})
