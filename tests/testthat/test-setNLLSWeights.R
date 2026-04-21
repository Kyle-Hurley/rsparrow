# Tests for setNLLSWeights() — Plan 06D-1
#
# setNLLSWeights(NLLS_weights, run_id, subdata, sitedata, data_names,
#                minimum_reaches_separating_sites)
#
# Returns Csites.weights.list with: NLLS_weights, tiarea, count, weight
#
# Two weight modes:
#   "default"       → weight = 1 (scalar)
#   "lnload"/"user" → weight = sitedata$weight (pre-computed weights)
#
# Network topology used in these tests (3-reach linear network):
#   Reach 1 (headwater, no monitoring) → Reach 2 (monitoring, staid=1) → Reach 3 (terminal)
#   fnode/tnode: 1→10 / 10→11 / 11→99
#   demiarea:     4        3        2
#
# With monitoring at the middle reach (reach 2), sites_incr assigns:
#   staidseq = c(1, 1, 0)  (reach 3 is downstream of the only monitoring site → 0)
# This guarantees a staidseq=0 group in count/siteiarea so that count[-1,] leaves
# the staidseq=1 row intact and tiarea is correctly computed as 4+3=7.

testthat::skip_if_not_installed("rsparrow")

make_nlls_test_inputs <- function() {
  # 3-reach linear network: headwater → monitoring → terminal
  subdata <- data.frame(
    waterid  = 1:3,
    fnode    = c(1L, 10L, 11L),
    tnode    = c(10L, 11L, 99L),
    demiarea = c(4, 3, 2),
    staid    = c(0L, 1L, 0L),   # integer: 0 = no site, 1 = monitoring
    stringsAsFactors = FALSE
  )
  # sitedata: calibration sites subset (reach 2 only)
  # Must have staidseq (from assignIncremSiteIDs) and hydseq
  sitedata <- data.frame(
    waterid  = 2L,
    staidseq = 1L,
    hydseq   = 2L,
    stringsAsFactors = FALSE
  )
  list(subdata = subdata, sitedata = sitedata)
}

test_that("setNLLSWeights with NLLS_weights='default' returns scalar weight of 1", {
  inp <- make_nlls_test_inputs()
  result <- rsparrow:::setNLLSWeights(
    NLLS_weights                     = "default",
    run_id                           = "test",
    subdata                          = inp$subdata,
    sitedata                         = inp$sitedata,
    data_names                       = list(),
    minimum_reaches_separating_sites = 1L
  )
  expect_equal(result$weight, 1)
})

test_that("setNLLSWeights with NLLS_weights='lnload' returns sitedata$weight", {
  inp <- make_nlls_test_inputs()
  inp$sitedata$weight <- 2.5   # pre-computed lnload weight for this site
  result <- rsparrow:::setNLLSWeights(
    NLLS_weights                     = "lnload",
    run_id                           = "test",
    subdata                          = inp$subdata,
    sitedata                         = inp$sitedata,
    data_names                       = list(),
    minimum_reaches_separating_sites = 1L
  )
  expect_equal(result$weight, 2.5)
})

test_that("setNLLSWeights tiarea is numeric and positive", {
  inp <- make_nlls_test_inputs()
  result <- rsparrow:::setNLLSWeights(
    NLLS_weights                     = "default",
    run_id                           = "test",
    subdata                          = inp$subdata,
    sitedata                         = inp$sitedata,
    data_names                       = list(),
    minimum_reaches_separating_sites = 1L
  )
  # tiarea = sum of demiarea in the incremental area of the monitoring site
  # reaches 1 and 2 are in the incremental area of site 1: 4 + 3 = 7
  expect_true(is.numeric(result$tiarea))
  expect_true(all(result$tiarea > 0))
})

test_that("setNLLSWeights return list has required names", {
  inp <- make_nlls_test_inputs()
  result <- rsparrow:::setNLLSWeights(
    NLLS_weights                     = "default",
    run_id                           = "test",
    subdata                          = inp$subdata,
    sitedata                         = inp$sitedata,
    data_names                       = list(),
    minimum_reaches_separating_sites = 1L
  )
  expect_true(all(c("NLLS_weights", "tiarea", "count", "weight") %in% names(result)))
})
