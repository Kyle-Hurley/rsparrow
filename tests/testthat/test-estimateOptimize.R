# Tests for estimateOptimize() — Plan 06D-3
#
# estimateOptimize(file.output.list, SelParmValues, estimate.input.list,
#                  DataMatrix.list, dlvdsgn, Csites.weights.list)
#
# Runs the full NLLS optimization via nlmrt::nlfb() and returns sparrowEsts,
# a list with: resid, jacobian, feval, jeval, coefficients, ssquares, lower,
# upper, maskidx, betamn, betamx, if_mean_adjust_delivery_vars, NLLS_weights, dlvdsgn.
#
# NOTE: A bug was found during Plan 06D implementation: Csites.weights.list was
# referenced inside estimateOptimize but was missing from the function signature.
# The bug was fixed as part of Plan 06D (estimate.R call updated simultaneously).
#
# IMPORTANT: The mini_network has 1 calibration site and 3 parameters — an
# underdetermined system.  The optimizer terminates rapidly because it can drive
# the sum of squares toward 0 by adjusting a single parameter.  Tests check
# structural correctness and bounds compliance rather than exact coefficient values.
#
# The function writes two files into path_results/estimate/:
#   {run_id}_log.txt   — optimization trace (via sink)
#   {run_id}_sparrowEsts — saved sparrowEsts object (via save())
# Tests use a temporary directory for all file I/O.

testthat::skip_if_not_installed("rsparrow")
testthat::skip_if_not_installed("nlmrt")

load_mini_inputs <- function() {
  env <- new.env()
  load(test_path("fixtures/mini_model_inputs.rda"), envir = env)
  env$mini_inputs
}

make_optimize_env <- function() {
  tmp <- tempfile(pattern = "sparrow_opt_")
  est_dir <- file.path(tmp, "estimate")
  dir.create(est_dir, recursive = TRUE, showWarnings = FALSE)
  file.output.list <- list(
    path_results = tmp,
    run_id       = "test_opt"
  )
  list(tmp = tmp, file.output.list = file.output.list)
}

test_that("estimateOptimize returns list with coefficients element", {
  mi  <- load_mini_inputs()
  env <- make_optimize_env()
  on.exit(unlink(env$tmp, recursive = TRUE))

  result <- rsparrow:::estimateOptimize(
    file.output.list    = env$file.output.list,
    SelParmValues       = mi$SelParmValues,
    estimate.input.list = mi$estimate.input.list,
    DataMatrix.list     = mi$DataMatrix.list,
    dlvdsgn             = mi$dlvdsgn,
    Csites.weights.list = mi$Csites.weights.list
  )

  expect_false(is.null(result))
  expect_true("coefficients" %in% names(result))
  expect_true(is.numeric(result$coefficients))
  expect_equal(length(result$coefficients), 3L)  # 3 parameters: beta_s1, beta_d1, beta_k1
})

test_that("estimateOptimize coefficients are within specified bounds", {
  mi  <- load_mini_inputs()
  env <- make_optimize_env()
  on.exit(unlink(env$tmp, recursive = TRUE))

  result <- rsparrow:::estimateOptimize(
    file.output.list    = env$file.output.list,
    SelParmValues       = mi$SelParmValues,
    estimate.input.list = mi$estimate.input.list,
    DataMatrix.list     = mi$DataMatrix.list,
    dlvdsgn             = mi$dlvdsgn,
    Csites.weights.list = mi$Csites.weights.list
  )

  # betamn and betamx are stored on sparrowEsts after the optimizer returns
  expect_true(all(result$coefficients >= result$betamn),
              label = "all coefficients >= betamin")
  expect_true(all(result$coefficients <= result$betamx),
              label = "all coefficients <= betamax")
})

test_that("estimateOptimize residuals from result are finite", {
  mi  <- load_mini_inputs()
  env <- make_optimize_env()
  on.exit(unlink(env$tmp, recursive = TRUE))

  result <- rsparrow:::estimateOptimize(
    file.output.list    = env$file.output.list,
    SelParmValues       = mi$SelParmValues,
    estimate.input.list = mi$estimate.input.list,
    DataMatrix.list     = mi$DataMatrix.list,
    dlvdsgn             = mi$dlvdsgn,
    Csites.weights.list = mi$Csites.weights.list
  )

  # Plug the estimated coefficients back into estimateFeval — must return finite values
  e <- rsparrow:::estimateFeval(
    result$coefficients,
    mi$DataMatrix.list,
    mi$SelParmValues,
    mi$Csites.weights.list,
    mi$estimate.input.list,
    mi$dlvdsgn,
    ifadjust = 1L
  )
  expect_true(all(is.finite(e)),
              label = "estimateFeval with optimized coefficients returns finite residuals")
})

test_that("estimateOptimize on mini_network terminates within 60 seconds", {
  mi  <- load_mini_inputs()
  env <- make_optimize_env()
  on.exit(unlink(env$tmp, recursive = TRUE))

  elapsed <- system.time(
    rsparrow:::estimateOptimize(
      file.output.list    = env$file.output.list,
      SelParmValues       = mi$SelParmValues,
      estimate.input.list = mi$estimate.input.list,
      DataMatrix.list     = mi$DataMatrix.list,
      dlvdsgn             = mi$dlvdsgn,
      Csites.weights.list = mi$Csites.weights.list
    )
  )[["elapsed"]]

  expect_lt(elapsed, 60,
            label = "optimizer terminates in under 60 seconds on mini_network")
})
