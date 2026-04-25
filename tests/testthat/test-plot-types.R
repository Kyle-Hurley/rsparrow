# Tests for new plot.rsparrow() types added in Plan 18C

# ---- helpers -------------------------------------------------------------------

# Mock with Mdiagnostics.list populated for simulation/class/ratio plots
make_mock_rsparrow_diag <- function(n = 20) {
  set.seed(1)
  obs      <- exp(rnorm(n, mean = 5, sd = 1))
  pred     <- obs * exp(rnorm(n, sd = 0.3))
  resids   <- log(obs) - log(pred)
  demtarea <- sort(runif(n, 10, 5000))

  # Use integer class labels (1–10 deciles) as classvar column
  cls <- as.integer(cut(demtarea, quantile(demtarea, probs = 0:10 / 10),
                        include.lowest = TRUE))

  sitedata <- data.frame(
    waterid  = seq_len(n),
    demtarea = demtarea,
    my_class = cls
  )

  Md <- list(
    Obs            = obs,
    predict        = pred,
    yldpredict     = pred * 0.01,
    yldobs         = obs  * 0.01,
    Resids         = resids,
    standardResids = resids / sd(resids),
    ratio.obs.pred = obs / pred,
    ppredict       = pred,
    pyldpredict    = pred * 0.01,
    pyldobs        = obs  * 0.01,
    pResids        = resids,
    pratio.obs.pred = obs / pred
  )

  structure(
    list(
      call         = quote(rsparrow_model(".")),
      coefficients = c(b1 = 0.5, b2 = -0.5),
      std_errors   = c(b1 = 0.1, b2 = 0.05),
      vcov         = NULL,
      residuals    = resids,
      fitted_values = pred,
      fit_stats    = list(R2 = 0.9, RMSE = 0.3, npar = 2L, nobs = n, convergence = 0L),
      data = list(
        subdata             = data.frame(waterid = seq_len(n)),
        sitedata            = sitedata,
        vsitedata           = NULL,
        DataMatrix.list     = NULL,
        SelParmValues       = NULL,
        dlvdsgn             = NULL,
        Csites.weights.list = NULL,
        Vsites.list         = NULL,
        classvar            = "my_class",
        estimate.list       = list(
          JacobResults = list(
            oEstimate               = c(0.5, -0.5),
            Parmnames               = c("b1", "b2"),
            mean_exp_weighted_error = 1.0
          ),
          ANOVA.list       = list(RSQ = 0.9, RMSE = 0.3, npar = 2L, mobs = n),
          Mdiagnostics.list = Md,
          vMdiagnostics.list = NULL
        ),
        estimate.input.list = list(
          loadUnits = "kg/yr", yieldUnits = "kg/km2/yr",
          ConcUnits = "mg/L", ConcFactor = 1.0, yieldFactor = 0.01
        ),
        file.output.list    = list(run_id = "mock_run"),
        data_names          = list(),
        mapping.input.list  = list(loadUnits = "kg/yr", yieldUnits = "kg/km2/yr"),
        scenario.input.list = list()
      ),
      predictions = NULL,
      bootstrap   = NULL,
      validation  = NULL,
      metadata    = list(version = "2.1.0", timestamp = Sys.time(), run_id = "mock_run")
    ),
    class = "rsparrow"
  )
}

# ---- dispatch tests (no invalid-type error) ------------------------------------

test_that("plot.rsparrow accepts type='simulation' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "simulation"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow accepts type='class' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "class"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow accepts type='ratio' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "ratio"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow accepts type='validation' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "validation"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow accepts type='bootstrap' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "bootstrap"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

# ---- guard tests ---------------------------------------------------------------

test_that("validation plot errors with informative message when no validation data", {
  mod <- make_mock_rsparrow_diag()
  expect_error(
    plot(mod, type = "validation"),
    regexp = "Validation diagnostics not available"
  )
})

test_that("bootstrap plot errors with informative message when no bootstrap data", {
  mod <- make_mock_rsparrow_diag()
  expect_error(
    plot(mod, type = "bootstrap"),
    regexp = "Bootstrap results not available"
  )
})

# ---- functional plot tests (require full Mdiagnostics data) --------------------

test_that("simulation plot panel A produces output without error", {
  mod <- make_mock_rsparrow_diag()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "simulation", panel = "A"), error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("simulation plot panel B produces output without error", {
  mod <- make_mock_rsparrow_diag()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "simulation", panel = "B"), error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("simulation plot panel both produces output without error", {
  mod <- make_mock_rsparrow_diag()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "simulation", panel = "both"), error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("class plot produces output without error", {
  mod <- make_mock_rsparrow_diag()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "class"), error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("ratio plot produces output without error", {
  mod <- make_mock_rsparrow_diag()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "ratio"), error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("bootstrap plot produces output with bootstrap data", {
  mod <- make_mock_rsparrow_diag()
  set.seed(42)
  n_boot <- 30L
  n_coef <- 2L
  mod$bootstrap <- list(
    bEstimate                  = matrix(rnorm(n_boot * n_coef), nrow = n_boot, ncol = n_coef),
    bootmean_exp_weighted_error = rnorm(n_boot),
    boot_resids                = matrix(0, nrow = n_boot, ncol = 20L),
    boot_lev                   = matrix(0, nrow = n_boot, ncol = 20L)
  )
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "bootstrap"), error = function(e) e)
  dev.off()
  expect_null(err)
})
