# Tests for predictSensitivity() — Plan 06E-3
#
# predictSensitivity(AEstimate, estimate.list, DataMatrix.list,
#                    SelParmValues, subdata, dlvdsgn)
#
# Called by diagnosticSensitivity() to compute reach loads under perturbed
# parameter values for parameter sensitivity analysis.
# After Plan 04B: 3 dead spec-string params removed from signature.
# After Plan 04C: unPackList() replaced with direct $ extractions.
#
# Returns: pload_total — numeric vector of length nreach.
#   Computed with ifadjust=0 (no monitoring adjustment).
#   AEstimate is the full parameter vector, perturbed or unperturbed.
#
# NOTE: predictSensitivity still uses local assign() for pload_inc_<src>
# variables (lines 119-120) — these do not affect correctness of the
# returned pload_total and are tested implicitly via Test 1.

testthat::skip_if_not_installed("rsparrow")

load_sensitivity_inputs_06E <- function() {
  env <- new.env()
  load(test_path("fixtures/mini_model_inputs.rda"), envir = env)
  load(test_path("fixtures/mini_network.rda"), envir = env)
  net <- env$mini_network_raw
  if ("hydseq" %in% names(net)) net <- net[order(net$hydseq), ]
  list(mi = env$mini_inputs, subdata = net)
}

# Test 1 -----------------------------------------------------------------------
test_that("predictSensitivity returns numeric vector of length nreach (7)", {
  inp      <- load_sensitivity_inputs_06E()
  mi       <- inp$mi
  oEstimate <- mi$estimate.list$JacobResults$oEstimate

  result <- rsparrow:::predictSensitivity(
    AEstimate       = oEstimate,
    estimate.list   = mi$estimate.list,
    DataMatrix.list = mi$DataMatrix.list,
    SelParmValues   = mi$SelParmValues,
    subdata         = inp$subdata,
    dlvdsgn         = mi$dlvdsgn
  )

  expect_true(is.numeric(result))
  expect_equal(length(result), 7L)
})

# Test 2 -----------------------------------------------------------------------
test_that("predictSensitivity with 10x parameter perturbation differs from baseline", {
  # A 10× scaling of all parameters is large enough to guarantee a change in
  # predictions regardless of the parameter direction or model structure.
  inp       <- load_sensitivity_inputs_06E()
  mi        <- inp$mi
  oEst      <- mi$estimate.list$JacobResults$oEstimate
  perturbed <- oEst * 10.0

  result_base <- rsparrow:::predictSensitivity(
    AEstimate       = oEst,
    estimate.list   = mi$estimate.list,
    DataMatrix.list = mi$DataMatrix.list,
    SelParmValues   = mi$SelParmValues,
    subdata         = inp$subdata,
    dlvdsgn         = mi$dlvdsgn
  )

  result_pert <- rsparrow:::predictSensitivity(
    AEstimate       = perturbed,
    estimate.list   = mi$estimate.list,
    DataMatrix.list = mi$DataMatrix.list,
    SelParmValues   = mi$SelParmValues,
    subdata         = inp$subdata,
    dlvdsgn         = mi$dlvdsgn
  )

  expect_false(identical(result_base, result_pert),
               label = "10x parameter perturbation changes pload_total")
})

# Test 3 -----------------------------------------------------------------------
test_that("predictSensitivity with original estimates matches predict_sparrow pload_total", {
  # Both functions compute pload_total via ptnoder with ifadjust=0.
  # With AEstimate = oEstimate and bootcorrection = 1.0 they must agree to 1e-10.
  # This verifies that predictSensitivity's inline computation is equivalent to
  # the refactored .predict_core path used by predict_sparrow (Plan 04B / 05B check).
  inp  <- load_sensitivity_inputs_06E()
  mi   <- inp$mi
  oEst <- mi$estimate.list$JacobResults$oEstimate

  result_sens <- rsparrow:::predictSensitivity(
    AEstimate       = oEst,
    estimate.list   = mi$estimate.list,
    DataMatrix.list = mi$DataMatrix.list,
    SelParmValues   = mi$SelParmValues,
    subdata         = inp$subdata,
    dlvdsgn         = mi$dlvdsgn
  )

  result_pred <- rsparrow:::predict_sparrow(
    mi$estimate.list,
    mi$estimate.input.list,
    bootcorrection = 1.0,
    mi$DataMatrix.list,
    mi$SelParmValues,
    subdata = inp$subdata,
    dlvdsgn = mi$dlvdsgn
  )

  # predmatrix[, 2] = pload_total * bootcorrection(=1) = pload_total
  expect_numeric_close(
    as.vector(result_sens),
    as.vector(result_pred$predmatrix[, 2]),
    tol   = 1e-10,
    label = "predictSensitivity pload_total == predict_sparrow pload_total"
  )
})
