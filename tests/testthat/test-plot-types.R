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

# ---- results subtype mock and tests --------------------------------------------

make_mock_rsparrow_pred <- function(n = 30) {
  set.seed(99)
  mod <- make_mock_rsparrow_diag(n)

  # Extend subdata with spatial + hydrological columns
  mod$data$subdata <- data.frame(
    waterid  = seq_len(n),
    lat      = runif(n, 35, 45),
    lon      = runif(n, -100, -80),
    demtarea = sort(runif(n, 10, 5000)),
    demiarea = runif(n, 1, 100),
    hydseq   = sample(seq_len(n)),
    meanq    = runif(n, 1, 1000)
  )

  # Also extend Mdiagnostics.list with fields used by obs_pred / network / map
  Md <- mod$data$estimate.list$Mdiagnostics.list
  Md$tarea   <- mod$data$sitedata$demtarea
  Md$xlon    <- runif(n, -100, -80)
  Md$xlat    <- runif(n, 35, 45)
  Md$classgrp <- as.integer(cut(Md$tarea,
                                quantile(Md$tarea, probs = 0:10 / 10),
                                include.lowest = TRUE))
  mod$data$estimate.list$Mdiagnostics.list <- Md

  # Build minimal predmatrix / yldmatrix
  oparmlist <- c("waterid", "pload_total", "pload_b1", "pload_b2",
                 "mpload_total", "pload_nd_total",
                 "share_total_b1", "share_total_b2")
  ncols_p  <- length(oparmlist)
  predmatrix <- matrix(0, nrow = n, ncol = ncols_p)
  predmatrix[, 1] <- seq_len(n)
  predmatrix[, 2] <- exp(rnorm(n, 8, 1))
  predmatrix[, 3] <- predmatrix[, 2] * 0.6
  predmatrix[, 4] <- predmatrix[, 2] * 0.4
  predmatrix[, 5] <- predmatrix[, 2] * 1.02
  predmatrix[, 6] <- predmatrix[, 2] * 0.95
  predmatrix[, 7] <- 60 + rnorm(n, 0, 5)
  predmatrix[, 8] <- 100 - predmatrix[, 7]

  oyieldlist <- c("waterid", "concentration", "yield_total",
                  "yield_b1", "yield_b2",
                  "myield_total", "yield_inc", "yield_inc_deliv")
  ncols_y   <- length(oyieldlist)
  yldmatrix <- matrix(0, nrow = n, ncol = ncols_y)
  yldmatrix[, 1] <- seq_len(n)
  yldmatrix[, 2] <- runif(n, 0.1, 5)
  yldmatrix[, 3] <- predmatrix[, 2] / mod$data$subdata$demtarea * 0.01
  yldmatrix[, 4] <- yldmatrix[, 3] * 0.6
  yldmatrix[, 5] <- yldmatrix[, 3] * 0.4
  yldmatrix[, 6] <- yldmatrix[, 3] * 1.02
  yldmatrix[, 7] <- yldmatrix[, 3] * 0.1
  yldmatrix[, 8] <- yldmatrix[, 7] * 0.9

  mod$predictions <- list(
    oparmlist  = oparmlist,
    predmatrix = predmatrix,
    oyieldlist = oyieldlist,
    yldmatrix  = yldmatrix
  )
  mod
}

test_that("type='results' dispatches without invalid-type error", {
  mod <- make_mock_rsparrow_pred()
  err <- tryCatch(plot(mod, type = "results"), error = function(e) e)
  if (inherits(err, "error"))
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
})

test_that("results subtype='profile' produces output without error", {
  mod <- make_mock_rsparrow_pred()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "results", subtype = "profile"),
                  error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("results subtype='network' produces output without error", {
  mod <- make_mock_rsparrow_pred()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "results", subtype = "network"),
                  error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("results subtype='map' produces output without error", {
  mod <- make_mock_rsparrow_pred()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "results", subtype = "map"),
                  error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("results subtype='sources' produces output without error", {
  mod <- make_mock_rsparrow_pred()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "results", subtype = "sources"),
                  error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("results subtype='obs_pred' produces output without error (no predictions needed)", {
  mod <- make_mock_rsparrow_diag()
  tmp <- tempfile(fileext = ".pdf")
  on.exit(unlink(tmp))
  pdf(tmp)
  err <- tryCatch(plot(mod, type = "results", subtype = "obs_pred"),
                  error = function(e) e)
  dev.off()
  expect_null(err)
})

test_that("results plot gives informative error when predictions=NULL for non-obs_pred subtypes", {
  mod <- make_mock_rsparrow_diag()
  expect_error(
    plot(mod, type = "results", subtype = "profile"),
    regexp = "Predictions not available"
  )
})

test_that("results subtype='map' gives informative error when lat/lon absent from subdata", {
  mod <- make_mock_rsparrow_pred()
  mod$data$subdata <- mod$data$subdata[, setdiff(names(mod$data$subdata), c("lat", "lon"))]
  expect_error(
    plot(mod, type = "results", subtype = "map"),
    regexp = "lat.*lon|lon.*lat"
  )
})
