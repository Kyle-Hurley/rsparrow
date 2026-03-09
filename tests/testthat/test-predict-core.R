# Tests for .predict_core() — Plan 06E-2
#
# .predict_core(data, data.index.list, Parmnames, beta1, dlvdsgn, numsites)
#   Internal shared kernel (not exported) created in Plan 05B.
#   Called by predict_sparrow(), predictBoot(), and predictScenarios().
#
# Returns named list: pload_total, mpload_total, pload_nd_total, pload_inc,
#   pload_src, mpload_src, pload_nd_src, pload_inc_src,
#   rchdcayf, resdcayf, ddliv2, incdecay, totdecay, nnode, data2
#
# Critical regression tests (Tests 3-4): verify that .predict_core and
# predict_sparrow produce numerically identical load results.  Any divergence
# indicates a bug introduced by the Plan 05B consolidation.
#
# Note: .predict_core does not compute yldmatrix (yield/concentration); those
# are derived in predict_sparrow from the core load vectors.  Tests here
# compare the load vectors that feed predmatrix directly.
#
# Test 5 (eval hover-text): CLAUDE.md lists predict_core.R as having 1 hardened
# hover-text eval(parse()) call.  Inspection of the current source shows no
# eval(parse()) in .predict_core itself; the count in CLAUDE.md may refer to
# a caller (diagnosticPlotsNLLS*.R) that was inlined during Plan 05D.  This
# test is documented as known-unreachable and skipped.

testthat::skip_if_not_installed("rsparrow")

load_core_inputs_06E <- function() {
  env <- new.env()
  load(test_path("fixtures/mini_model_inputs.rda"), envir = env)
  load(test_path("fixtures/mini_network.rda"), envir = env)
  net <- env$mini_network_raw
  if ("hydseq" %in% names(net)) net <- net[order(net$hydseq), ]
  list(mi = env$mini_inputs, subdata = net)
}

# Helper: build the beta1 matrix (nreach × npar) from oEstimate
build_beta1_06E <- function(data, oEstimate) {
  nreach <- nrow(data)
  t(matrix(oEstimate, ncol = nreach, nrow = length(oEstimate)))
}

# Helper: call .predict_core with mini_model_inputs
call_predict_core_06E <- function() {
  inp     <- load_core_inputs_06E()
  mi      <- inp$mi
  data    <- mi$DataMatrix.list$data
  dil     <- mi$DataMatrix.list$data.index.list
  oEst    <- mi$estimate.list$JacobResults$oEstimate
  Pnames  <- mi$estimate.list$JacobResults$Parmnames
  beta1   <- build_beta1_06E(data, oEst)
  nsites  <- sum(ifelse(data[, 10] > 0, 1, 0))

  list(
    core    = rsparrow:::.predict_core(data, dil, Pnames, beta1, mi$dlvdsgn, nsites),
    inp     = inp,
    Pnames  = Pnames
  )
}

# Test 1 -----------------------------------------------------------------------
test_that(".predict_core returns list with required load fields", {
  r <- call_predict_core_06E()
  expect_true(is.list(r$core))
  expect_names_present(r$core,
    c("pload_total", "mpload_total", "pload_nd_total",
      "pload_inc",   "pload_src",    "pload_inc_src",
      "incdecay",    "totdecay",     "nnode", "data2"))
})

# Test 2 -----------------------------------------------------------------------
test_that(".predict_core pload_total has length nreach (7)", {
  r <- call_predict_core_06E()
  expect_equal(length(r$core$pload_total), 7L)
})

# Test 3 -----------------------------------------------------------------------
test_that(".predict_core pload_total matches predict_sparrow predmatrix col 2 (Plan 05B regression)", {
  # predmatrix[, 2] = core$pload_total * bootcorrection.
  # With bootcorrection = 1.0 this must equal .predict_core$pload_total exactly.
  r      <- call_predict_core_06E()
  mi     <- r$inp$mi

  result <- rsparrow:::predict_sparrow(
    mi$estimate.list,
    mi$estimate.input.list,
    bootcorrection = 1.0,
    mi$DataMatrix.list,
    mi$SelParmValues,
    subdata = r$inp$subdata,
    dlvdsgn = mi$dlvdsgn
  )

  expect_numeric_close(
    as.vector(r$core$pload_total),
    as.vector(result$predmatrix[, 2]),
    tol   = 1e-10,
    label = "predict_core pload_total == predict_sparrow predmatrix col 2"
  )
})

# Test 4 -----------------------------------------------------------------------
test_that(".predict_core per-source load matches predict_sparrow predmatrix col 3 (Plan 05B regression)", {
  # mini_network has 1 source: predmatrix col 3 = pload_<src1> * bootcorrection.
  # With bootcorrection = 1.0, col 3 must equal core$pload_src[[Parmnames[1]]].
  r      <- call_predict_core_06E()
  mi     <- r$inp$mi

  result <- rsparrow:::predict_sparrow(
    mi$estimate.list,
    mi$estimate.input.list,
    bootcorrection = 1.0,
    mi$DataMatrix.list,
    mi$SelParmValues,
    subdata = r$inp$subdata,
    dlvdsgn = mi$dlvdsgn
  )

  src_name <- r$Pnames[1]   # "beta_s1" for mini_network
  expect_numeric_close(
    as.vector(r$core$pload_src[[src_name]]),
    as.vector(result$predmatrix[, 3]),
    tol   = 1e-10,
    label = paste0("predict_core pload_src[[", src_name, "]] == predict_sparrow col 3")
  )
})

# Test 5 -----------------------------------------------------------------------
test_that(".predict_core incdecay and totdecay are non-negative for all reaches", {
  r <- call_predict_core_06E()
  expect_true(all(as.vector(r$core$incdecay) >= 0),
              label = "incremental decay factors are non-negative")
  expect_true(all(as.vector(r$core$totdecay) >= 0),
              label = "total decay factors are non-negative")
})

# Test 6 (eval/parse hover-text) -----------------------------------------------
# SKIPPED: Inspection of predict_core.R shows no eval(parse()) in .predict_core
# itself.  The CLAUDE.md count of 1 for predict_core.R refers to a hardened
# hover-text call introduced when make_*.R bodies were inlined during Plan 05D,
# which is in diagnosticPlotsNLLS*.R caller context, not in .predict_core.
# No test needed here; the caller-side eval is covered by diagnostics tests.
