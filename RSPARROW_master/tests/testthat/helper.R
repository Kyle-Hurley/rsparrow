# Numeric tolerance comparator for SPARROW outputs
expect_numeric_close <- function(actual, expected, tol = 1e-6, label = "") {
  testthat::expect_true(
    all(abs(actual - expected) < tol),
    label = paste0(label, ": numeric values within tolerance")
  )
}

# Check that a list has all required names
expect_names_present <- function(x, required_names) {
  testthat::expect_true(
    all(required_names %in% names(x)),
    label = paste0("Missing names: ",
                   paste(setdiff(required_names, names(x)), collapse = ", "))
  )
}

# Build a minimal mock rsparrow object for API tests
make_mock_rsparrow <- function() {
  structure(
    list(
      call        = quote(rsparrow_model(".")),
      coefficients = c(beta_s1 = 0.5, beta_d1 = -0.5, beta_k1 = 0.1),
      std_errors  = c(beta_s1 = 0.1, beta_d1 = 0.05, beta_k1 = 0.02),
      vcov        = NULL,
      residuals   = c(SITE001 = 0.12),
      fitted_values = c(SITE001 = 88.5),
      fit_stats   = list(R2 = 0.95, RMSE = 0.15, npar = 3L, nobs = 1L, convergence = 0L),
      data        = list(
        subdata   = data.frame(waterid = 1:7),
        sitedata  = data.frame(waterid = 7L),
        vsitedata = NULL,
        DataMatrix.list = NULL,
        SelParmValues   = NULL,
        dlvdsgn         = NULL,
        Csites.weights.list = NULL,
        Vsites.list     = NULL,
        classvar        = NA_character_,
        estimate.list   = list(
          JacobResults = list(
            oEstimate = c(0.5, -0.5, 0.1),
            Parmnames = c("beta_s1", "beta_d1", "beta_k1"),
            mean_exp_weighted_error = 1.0
          ),
          ANOVA.list = list(RSQ = 0.95, RMSE = 0.15, npar = 3L, mobs = 1L)
        ),
        estimate.input.list = list(
          loadUnits = "kg/yr", yieldUnits = "kg/km2/yr",
          ConcUnits = "mg/L", ConcFactor = 1.0, yieldFactor = 0.01
        ),
        file.output.list = list(run_id = "mock_run"),
        data_names = list(),
        mapping.input.list = list(),
        scenario.input.list = list()
      ),
      predictions = NULL,
      bootstrap   = NULL,
      validation  = NULL,
      metadata    = list(
        version    = "2.1.0",
        timestamp  = Sys.time(),
        run_id     = "mock_run",
        model_type = "static",
        path_main  = "."
      )
    ),
    class = "rsparrow"
  )
}
