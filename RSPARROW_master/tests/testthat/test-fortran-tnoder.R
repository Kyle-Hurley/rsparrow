# Tests for estimateFeval() — Plan 06C-2
#
# estimateFeval(beta0, DataMatrix.list, SelParmValues, Csites.weights.list,
#               estimate.input.list, dlvdsgn, ifadjust=1L)
#   wraps .Fortran("tnoder") — requires compiled rsparrow
#
# Important: tnoder writes residuals into ee(nreach) but in estimateFeval.R,
# ee is allocated with nrow=nstaid (number of monitoring sites = 1 in mini_network).
# The final step `e <- sqrt(weight) * e` uses R recycling: weight is length nreach (7)
# and ee is length nstaid (1), so the returned vector has length 7 with all elements
# equal to the single monitoring-site residual multiplied by sqrt(weight).
# When NLLS weights are uniform (all 1s), all 7 elements are identical.
#
# mini_network: 7 reaches, 1 calibration site (reach 7, depvar=100),
#   3 parameters (beta_s1, beta_d1, beta_k1), beta0 = c(0.5, -0.5, 0.1)

testthat::skip_if_not_installed("rsparrow")

load_mini_inputs <- function() {
  env <- new.env()
  load(test_path("fixtures/mini_model_inputs.rda"), envir = env)
  env$mini_inputs
}

test_that("estimateFeval returns numeric vector of length nreach", {
  mi    <- load_mini_inputs()
  beta0 <- mi$SelParmValues$beta0
  e <- rsparrow:::estimateFeval(beta0, mi$DataMatrix.list, mi$SelParmValues,
                                mi$Csites.weights.list, mi$estimate.input.list,
                                mi$dlvdsgn, ifadjust = 1L)
  expect_true(is.numeric(e))
  expect_equal(length(e), 7L)
})

test_that("estimateFeval residual at monitoring site is finite and non-zero", {
  # With beta0 = c(0.5, -0.5, 0.1) and depvar=100, the model prediction is
  # unlikely to equal exactly 100, so the log-residual should be non-zero.
  # All elements of e are the same value (R recycling with 1 monitoring site).
  mi    <- load_mini_inputs()
  beta0 <- mi$SelParmValues$beta0
  e <- rsparrow:::estimateFeval(beta0, mi$DataMatrix.list, mi$SelParmValues,
                                mi$Csites.weights.list, mi$estimate.input.list,
                                mi$dlvdsgn, ifadjust = 1L)
  expect_true(all(is.finite(e)))
  expect_true(e[1] != 0.0)
})

test_that("estimateFeval with uniform weights repeats residual across all elements", {
  # With NLLS_weights="no", weight=rep(1,7), so sqrt(weight)*ee recycles ee[1] across
  # all 7 positions.  This is the expected structural behavior for 1 monitoring site.
  mi    <- load_mini_inputs()
  beta0 <- mi$SelParmValues$beta0
  e <- rsparrow:::estimateFeval(beta0, mi$DataMatrix.list, mi$SelParmValues,
                                mi$Csites.weights.list, mi$estimate.input.list,
                                mi$dlvdsgn, ifadjust = 1L)
  expect_true(all(e == e[1]),
              label = "all elements equal (recycled single-site residual)")
})

test_that("estimateFeval with ifadjust=0 returns finite vector", {
  # ifadjust=0: unconditioned predictions, unit weights.  Should still return
  # a valid finite residual vector of length nreach.
  mi    <- load_mini_inputs()
  beta0 <- mi$SelParmValues$beta0
  e_noadj <- rsparrow:::estimateFeval(beta0, mi$DataMatrix.list, mi$SelParmValues,
                                      mi$Csites.weights.list, mi$estimate.input.list,
                                      mi$dlvdsgn, ifadjust = 0L)
  expect_true(is.numeric(e_noadj))
  expect_equal(length(e_noadj), 7L)
  expect_true(all(is.finite(e_noadj)))
})

test_that("estimateFeval residual changes monotonically with source coefficient", {
  # Increasing beta_s1 increases predicted source load (s1 is positive source).
  # With depvar=100 fixed, a larger predicted load → smaller log-residual.
  # The residual magnitude must differ between low and high beta_s1.
  mi <- load_mini_inputs()
  e_low  <- rsparrow:::estimateFeval(c(0.1, -0.5, 0.1), mi$DataMatrix.list,
                                     mi$SelParmValues, mi$Csites.weights.list,
                                     mi$estimate.input.list, mi$dlvdsgn, ifadjust = 1L)
  e_high <- rsparrow:::estimateFeval(c(1.0, -0.5, 0.1), mi$DataMatrix.list,
                                     mi$SelParmValues, mi$Csites.weights.list,
                                     mi$estimate.input.list, mi$dlvdsgn, ifadjust = 1L)
  expect_true(abs(e_low[1]) != abs(e_high[1]),
              label = "residual magnitude changes with beta_s1")
})

test_that("estimateFevalNoadj backward-compat wrapper matches ifadjust=0", {
  # estimateFevalNoadj(...) was merged into estimateFeval(..., ifadjust=0L) in Plan 05B.
  # The wrapper must produce identical results.
  mi    <- load_mini_inputs()
  beta0 <- mi$SelParmValues$beta0

  e_ifadjust0 <- rsparrow:::estimateFeval(beta0, mi$DataMatrix.list, mi$SelParmValues,
                                          mi$Csites.weights.list, mi$estimate.input.list,
                                          mi$dlvdsgn, ifadjust = 0L)
  e_wrapper   <- rsparrow:::estimateFevalNoadj(beta0, mi$DataMatrix.list, mi$SelParmValues,
                                               mi$Csites.weights.list, mi$estimate.input.list,
                                               mi$dlvdsgn)
  expect_identical(e_wrapper, e_ifadjust0)
})
