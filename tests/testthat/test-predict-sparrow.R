# Tests for predict_sparrow() — Plan 06E-1
#
# predict_sparrow(estimate.list, estimate.input.list, bootcorrection,
#                DataMatrix.list, SelParmValues, subdata, dlvdsgn)
#   internally calls .predict_core() (shared kernel from Plan 05B)
#   then builds predmatrix, yldmatrix, oparmlist, oyieldlist
#
# mini_network: 7 reaches, 1 source (s1), 1 delivery var (d1), 1 decay var (k1)
#   predmatrix: 7 rows × 14 cols (waterid + load types + per-source shares)
#   yldmatrix:  7 rows × 10 cols (waterid + concentration + yield types)
#   Terminal reach (waterid=7, row 7) accumulates all upstream loads.
#
# Tests 1–2 verify structure; tests 3–4 verify dimension consistency;
# tests 5–6 verify accumulation and bootcorrection sensitivity;
# tests 7–8 verify reproducibility and concentration non-negativity.

testthat::skip_if_not_installed("rsparrow")

load_predict_inputs_06E <- function() {
  env <- new.env()
  load(test_path("fixtures/mini_model_inputs.rda"), envir = env)
  load(test_path("fixtures/mini_network.rda"), envir = env)
  net <- env$mini_network_raw
  # Sort by hydseq (no-op for mini_network where hydseq == waterid order)
  if ("hydseq" %in% names(net)) net <- net[order(net$hydseq), ]
  list(mi = env$mini_inputs, subdata = net)
}

run_predict_06E <- function(bootcorrection = 1.0) {
  inp <- load_predict_inputs_06E()
  rsparrow:::predict_sparrow(
    inp$mi$estimate.list,
    inp$mi$estimate.input.list,
    bootcorrection = bootcorrection,
    inp$mi$DataMatrix.list,
    inp$mi$SelParmValues,
    subdata = inp$subdata,
    dlvdsgn = inp$mi$dlvdsgn
  )
}

# Test 1 -----------------------------------------------------------------------
test_that("predict_sparrow returns list with required names", {
  result <- run_predict_06E()
  expect_true(is.list(result))
  expect_names_present(result, c("predmatrix", "yldmatrix", "oparmlist", "oyieldlist"))
})

# Test 2 -----------------------------------------------------------------------
test_that("predmatrix and yldmatrix have nreach (7) rows", {
  result <- run_predict_06E()
  expect_equal(nrow(result$predmatrix), 7L)
  expect_equal(nrow(result$yldmatrix),  7L)
})

# Test 3 -----------------------------------------------------------------------
test_that("ncol(predmatrix) equals length(oparmlist)", {
  result <- run_predict_06E()
  expect_equal(ncol(result$predmatrix), length(result$oparmlist))
})

# Test 4 -----------------------------------------------------------------------
test_that("ncol(yldmatrix) equals length(oyieldlist)", {
  result <- run_predict_06E()
  expect_equal(ncol(result$yldmatrix), length(result$oyieldlist))
})

# Test 5 -----------------------------------------------------------------------
test_that("pload_total (predmatrix col 2) is non-negative for all reaches", {
  result <- run_predict_06E()
  pload_total <- result$predmatrix[, 2]
  expect_true(all(pload_total >= 0.0),
              label = "all total load predictions non-negative")
})

# Test 6 -----------------------------------------------------------------------
test_that("terminal reach (waterid=7) has the largest total load in the network", {
  # In a linear-accumulating network the terminal reach receives contributions
  # from all upstream reaches; its pload_total must be the network maximum.
  inp    <- load_predict_inputs_06E()
  result <- rsparrow:::predict_sparrow(
    inp$mi$estimate.list,
    inp$mi$estimate.input.list,
    bootcorrection = 1.0,
    inp$mi$DataMatrix.list,
    inp$mi$SelParmValues,
    subdata = inp$subdata,
    dlvdsgn = inp$mi$dlvdsgn
  )
  pload_total  <- result$predmatrix[, 2]
  terminal_row <- which(inp$subdata$waterid == 7L)
  expect_equal(pload_total[terminal_row], max(pload_total),
               label = "terminal reach accumulates maximum total load")
})

# Test 7 -----------------------------------------------------------------------
test_that("bootcorrection=2.0 produces different predictions than bootcorrection=1.0", {
  # bootcorrection multiplies all load outputs; a different scalar must change results.
  result1 <- run_predict_06E(bootcorrection = 1.0)
  result2 <- run_predict_06E(bootcorrection = 2.0)
  expect_false(identical(result1$predmatrix, result2$predmatrix),
               label = "bootcorrection is actually applied to predmatrix")
})

# Test 8 -----------------------------------------------------------------------
test_that("two identical calls return identical predmatrix (no hidden random state)", {
  result1 <- run_predict_06E()
  result2 <- run_predict_06E()
  expect_identical(result1$predmatrix, result2$predmatrix,
                   label = "predict_sparrow is fully deterministic")
})

# Test 9 -----------------------------------------------------------------------
test_that("concentration column (yldmatrix col 2) is non-negative where finite", {
  # yldmatrix col 2 = "concentration" (flow-weighted, ConcUnits).
  # Reaches with meanq=0 or demtarea=0 return 0 (not NA) in this implementation.
  result <- run_predict_06E()
  conc <- result$yldmatrix[, 2]
  expect_true(all(conc >= 0 | is.na(conc)),
              label = "concentration values are non-negative or NA")
})
