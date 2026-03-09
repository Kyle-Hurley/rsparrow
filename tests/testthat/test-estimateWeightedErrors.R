# Tests for estimateWeightedErrors() — Plan 06D-2
#
# estimateWeightedErrors(file.output.list, xrun_id, pre_run_id, nreaches, calsites)
#
# Reads {path_user}/{results_directoryName}/{pre_run_id}/estimate/{pre_run_id}_residuals.csv
# containing log-residuals and predicted loads from a prior model run.
# Fits a nonlinear power-function regression:
#   sqResids ~ a * lnload^b1   (sqResids = Resids^2, lnload = log(predict))
# Returns numeric vector of length nreaches, with normalized NLS weights at
# calibration sites and 0 elsewhere.
#
# NOTE: The plan description incorrectly described estimateWeightedErrors as
# computing a bias-correction scalar (mean_exp_weighted_error).  That quantity
# lives in estimateNLLSmetrics.R.  These tests test the actual file-based,
# regression-weight-computing function.
#
# Mock residuals CSV uses predict values > 1 (so log(predict) > 0) and
# residuals near zero so that sqResids ~ a * lnload^b1 with a≈1, b1≈-0.1 —
# very close to the NLS starting values — ensuring rapid convergence.

testthat::skip_if_not_installed("rsparrow")

# Helper: build file.output.list pointing at a temp directory
make_weighted_errors_env <- function(tmp, pre_run_id = "prior", xrun_id = "current") {
  # create required directory tree
  prior_est_dir   <- file.path(tmp, "results", pre_run_id, "estimate")
  current_est_dir <- file.path(tmp, "results", xrun_id,   "estimate")
  dir.create(prior_est_dir,   recursive = TRUE, showWarnings = FALSE)
  dir.create(current_est_dir, recursive = TRUE, showWarnings = FALSE)

  # Mock residuals CSV: 15 calibration sites from a prior model run.
  # predict >> 1 so log(predict) > 0 (required for lnload^b1 power-function NLS).
  #
  # Data follow sqResids ~ 1.0 * lnload^(-0.2) (truth), while NLS starts at
  # c(a=1, b1=-0.1).  Only b1 needs to move (-0.1 → -0.2), so the optimizer
  # converges rapidly.  Tiny alternating perturbation avoids the "exact fit"
  # problem that causes nls() to stall when residuals are exactly 0.
  predict_vals  <- round(exp(seq(log(100), log(50000), length.out = 15)))
  lnload_vals   <- log(predict_vals)
  sqResids_true <- lnload_vals^(-0.2)         # true model: a=1, b1=-0.2
  sqResids_vals <- sqResids_true * (1 + 0.005 * rep(c(1, -1), length.out = 15))
  Resids_vals   <- sqrt(sqResids_vals) * rep(c(1, -1), length.out = 15)

  csv_path <- file.path(prior_est_dir, paste0(pre_run_id, "_residuals.csv"))
  write.csv(
    data.frame(Resids = Resids_vals, predict = predict_vals),
    file = csv_path, row.names = FALSE
  )

  file.output.list <- list(
    path_user              = tmp,
    results_directoryName  = "results",
    csv_decimalSeparator   = ".",
    csv_columnSeparator    = ","
  )
  list(
    file.output.list = file.output.list,
    xrun_id          = xrun_id,
    pre_run_id       = pre_run_id
  )
}

# The residuals CSV produced by make_weighted_errors_env has 15 rows (one per
# calibration site from a prior model run).  estimateWeightedErrors assigns the
# computed weights_nlr (length 15) into weight[calsites==1].  To avoid a
# recycling warning, the number of calibration sites in calsites must equal the
# number of CSV rows (15).  Non-calibration reaches get weight = 0.

test_that("estimateWeightedErrors returns numeric vector of length nreaches", {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE))
  env <- make_weighted_errors_env(tmp)

  # 15 calibration sites (match CSV rows) + 5 non-calibration reaches = 20 total
  n_csv      <- 15L
  n_noncal   <- 5L
  nreaches   <- n_csv + n_noncal
  calsites   <- c(rep(1L, n_csv), rep(0L, n_noncal))

  result <- rsparrow:::estimateWeightedErrors(
    file.output.list = env$file.output.list,
    xrun_id          = env$xrun_id,
    pre_run_id       = env$pre_run_id,
    nreaches         = nreaches,
    calsites         = calsites
  )
  expect_true(is.numeric(result))
  expect_equal(length(result), nreaches)
})

test_that("estimateWeightedErrors assigns zero weight to non-calibration reaches", {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE))
  env <- make_weighted_errors_env(tmp)

  n_csv    <- 15L
  n_noncal <- 5L
  nreaches <- n_csv + n_noncal
  calsites <- c(rep(1L, n_csv), rep(0L, n_noncal))

  result <- rsparrow:::estimateWeightedErrors(
    file.output.list = env$file.output.list,
    xrun_id          = env$xrun_id,
    pre_run_id       = env$pre_run_id,
    nreaches         = nreaches,
    calsites         = calsites
  )
  # Last 5 reaches are not calibration sites — weight must be 0
  expect_true(all(result[calsites == 0L] == 0))
})

test_that("estimateWeightedErrors assigns positive weights at calibration sites", {
  tmp <- tempfile()
  on.exit(unlink(tmp, recursive = TRUE))
  env <- make_weighted_errors_env(tmp)

  n_csv    <- 15L
  calsites <- rep(1L, n_csv)   # all reaches are calibration sites

  result <- rsparrow:::estimateWeightedErrors(
    file.output.list = env$file.output.list,
    xrun_id          = env$xrun_id,
    pre_run_id       = env$pre_run_id,
    nreaches         = n_csv,
    calsites         = calsites
  )
  # All reaches are calibration sites — all normalized weights must be > 0
  expect_true(all(result > 0))
})
