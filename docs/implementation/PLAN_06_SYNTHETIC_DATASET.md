<synthetic_dataset_spec>

<overview>
This document specifies the synthetic data fixtures used across Plan 06 sub-plans. All fixtures
are stored as .rda files in tests/testthat/fixtures/. They are constructed programmatically in
a fixture-building script (tests/testthat/helper-fixtures.R or a one-time build script) so
that they can be regenerated if needed and reviewed for correctness.

Two fixtures are defined:
  1. mini_network — a 7-reach branching stream network for hydseq/topology/Fortran tests
  2. mini_model_inputs — DataMatrix.list + SelParmValues + estimate.list built from
     mini_network for use in estimateFeval/predict_sparrow unit tests
</overview>

<fixture name="mini_network">

<purpose>
Tests for: rsparrow_hydseq, hydseq, calcHeadflag, calcTermflag, accumulateIncrArea,
deliver, and the DataMatrix construction helpers.
</purpose>

<network_topology>
A 7-reach branching network shaped like a "Y" with one outlet:

  Reach 1 (headwater) \
  Reach 2 (headwater)  → Reach 5 → Reach 7 (outlet, monitoring)
  Reach 3 (headwater) /          ↗
  Reach 4 (headwater)  → Reach 6
Node numbering:
  fnode/tnode pairs define directed edges (upstream → downstream):
    Reach 1: fnode=1,  tnode=10
    Reach 2: fnode=2,  tnode=10
    Reach 3: fnode=3,  tnode=11
    Reach 4: fnode=4,  tnode=11
    Reach 5: fnode=10, tnode=12
    Reach 6: fnode=11, tnode=12
    Reach 7: fnode=12, tnode=99   (terminal; tnode=99 is outlet node)

Expected hydseq ordering (upstream-first):
  Reaches 1, 2, 3, 4 first (headwaters; any order among them)
  Reaches 5, 6 next (any order among them)
  Reach 7 last (terminal)

Expected headflag:  c(1, 1, 1, 1, 0, 0, 0)   (reaches 1-4 are headwaters)
Expected termflag:  c(0, 0, 0, 0, 0, 0, 1)   (reach 7 is terminal)
</network_topology>

<data_frame_columns>
Required columns for subdata (data1 equivalent):
  waterid   integer  c(1, 2, 3, 4, 5, 6, 7)
  fnode     integer  c(1, 2, 3, 4, 10, 11, 12)
  tnode     integer  c(10, 10, 11, 11, 12, 12, 99)
  frac      numeric  rep(1.0, 7)          # no braiding
  iftran    integer  rep(1L, 7)           # all reaches transport
  demiarea  numeric  c(5, 5, 4, 4, 3, 4, 2)  # incremental drainage area (km2)
  demtarea  numeric  c(5, 5, 4, 4, 13, 13, 26) # total drainage area (km2)
  meanq     numeric  c(0.01, 0.01, 0.01, 0.01, 0.05, 0.05, 0.1)  # m3/s
  headflag  integer  c(1, 1, 1, 1, 0, 0, 0)
  termflag  integer  c(0, 0, 0, 0, 0, 0, 1)
  depvar    numeric  c(0, 0, 0, 0, 0, 0, 100)  # monitored load only at reach 7 (kg/yr)
  staid     character c(NA, NA, NA, NA, NA, NA, "SITE001")
  staidseq  integer  c(0, 0, 0, 0, 0, 0, 1)   # site sequence for monitoring sites
  calsites  integer  c(0, 0, 0, 0, 0, 0, 1)   # 1 = calibration site
  # Source variable: one simple source (agricultural area, km2)
  s1        numeric  c(3, 3, 2, 2, 1, 2, 1)   # incremental source 1
  # Delivery variable: log(precipitation) — moderate values
  d1        numeric  c(0.2, 0.2, 0.3, 0.3, 0.1, 0.2, 0.1)
  # Stream decay variable
  k1        numeric  c(0.05, 0.05, 0.03, 0.03, 0.02, 0.02, 0.01) # decay rate (1/day)
  hydseq    integer  # filled by hydseq() — headwaters first

Note: hydseq is appended by createVerifyReachAttr/hydseq(); the fixture stores the raw
data before hydseq computation so that tests verify hydseq output.
</data_frame_columns>

<build_code>
The following R code builds and saves the mini_network fixture. Run once; save to fixtures/.

mini_network_raw <- data.frame(
  waterid  = 1:7,
  fnode    = c(1L, 2L, 3L, 4L, 10L, 11L, 12L),
  tnode    = c(10L, 10L, 11L, 11L, 12L, 12L, 99L),
  frac     = rep(1.0, 7),
  iftran   = rep(1L, 7),
  demiarea = c(5, 5, 4, 4, 3, 4, 2),
  demtarea = c(5, 5, 4, 4, 13, 13, 26),
  meanq    = c(0.01, 0.01, 0.01, 0.01, 0.05, 0.05, 0.1),
  headflag = c(1L, 1L, 1L, 1L, 0L, 0L, 0L),
  termflag = c(0L, 0L, 0L, 0L, 0L, 0L, 1L),
  depvar   = c(0, 0, 0, 0, 0, 0, 100),
  staidseq = c(0L, 0L, 0L, 0L, 0L, 0L, 1L),
  calsites = c(0L, 0L, 0L, 0L, 0L, 0L, 1L),
  s1       = c(3, 3, 2, 2, 1, 2, 1),
  d1       = c(0.2, 0.2, 0.3, 0.3, 0.1, 0.2, 0.1),
  k1       = c(0.05, 0.05, 0.03, 0.03, 0.02, 0.02, 0.01),
  stringsAsFactors = FALSE
)
save(mini_network_raw, file = "tests/testthat/fixtures/mini_network.rda")
</build_code>

</fixture>

<fixture name="mini_model_inputs">

<purpose>
Tests for: estimateFeval, predict_sparrow, predict_core, setNLLSWeights,
estimateWeightedErrors. Provides a minimal DataMatrix.list, SelParmValues,
Csites.weights.list, estimate.input.list, dlvdsgn, and a pre-built estimate.list
so that these functions can be tested without running the full NLLS optimizer.
</purpose>

<model_spec>
Simple one-source (SOURCE), one-delivery-factor (DELIVF), one-stream-decay (STRM) model:
  Parameters:
    beta_s1    (SOURCE): coefficient for source s1; initial=0.5, min=0, max=100
    beta_d1    (DELIVF): log-linear delivery coefficient; initial=-0.5, min=-10, max=0
    beta_k1    (STRM):   stream decay; initial=0.1, min=0, max=10

  All three parameters are estimated (betaconstant = c(0, 0, 0)).

  Design matrix (dlvdsgn): 1-row, 1-column matrix: dlvdsgn = matrix(1, nrow=1, ncol=1)
  (one delivery variable applies to the one source variable)

DataMatrix.list$data columns (nreach=7 rows):
  [jsrcvar]  = column 1: s1 values from mini_network_raw
  [jdlvvar]  = column 2: d1 values
  [jdecvar]  = column 3: k1 values (stream decay)
  [jresvar]  = (none; index = integer(0))
  [jfrac]    = column 4: frac (all 1.0)
  [jfnode]   = column 5: fnode
  [jtnode]   = column 6: tnode
  [jdepvar]  = column 7: depvar (0 for headwaters, 100 for reach 7)
  [jiftran]  = column 8: iftran (all 1)
  [jstaid]   = column 9: staidseq (0 or 1)
  [jtarget]  = column 10: calsites (0 or 1)

DataMatrix.list$data must be a numeric matrix with nreach rows.
DataMatrix.list$beta: matrix(c(0.5, -0.5, 0.1), nrow=1) — initial parameter values.
DataMatrix.list$data.index.list:
  jsrcvar  = 1L
  jdlvvar  = 2L
  jdecvar  = 3L
  jresvar  = integer(0)
  jfrac    = 4L
  jfnode   = 5L
  jtnode   = 6L
  jdepvar  = 7L
  jiftran  = 8L
  jstaid   = 9L
  jtarget  = 10L
  jbsrcvar = 1L  (beta column index for source)
  jbdlvvar = 2L  (beta column index for delivery)
  jbdecvar = 3L  (beta column index for decay)
  jbresvar = integer(0)

SelParmValues:
  beta0       = c(0.5, -0.5, 0.1)
  betamin     = c(0, -10, 0)
  betamax     = c(100, 0, 10)
  betaconstant = c(0L, 0L, 0L)  # all estimated
  bcols       = 3L
  srcvar      = "s1"
  dlvvar      = "d1"
  decvar      = "k1"
  resvar      = character(0)
  sparrowNames = c("beta_s1", "beta_d1", "beta_k1")
  bCorrGroup  = c(1L, 1L, 0L)

Csites.weights.list:
  weight  = rep(1.0, 7)   # one weight per reach (unit weights for simplicity)
  tiarea  = mini_network_raw$demiarea

estimate.input.list:
  ifHess                      = "no"
  s_offset                    = 0.0
  NLLS_weights                = "no"
  if_auto_scaling             = "no"
  if_mean_adjust_delivery_vars = "no"
  yieldFactor                 = 0.01
  ConcFactor                  = 1.0
  loadUnits                   = "kg/yr"
  yieldUnits                  = "kg/km2/yr"
  ConcUnits                   = "mg/L"

dlvdsgn: matrix(1, nrow=1, ncol=1)

estimate.list (mock, pre-built for predict tests):
  Built by running estimateFeval at beta0 = c(0.5, -0.5, 0.1) and recording
  the residuals. Then constructing a JacobResults list with:
    JacobResults$oEstimate = c(0.5, -0.5, 0.1)  # fixed known coefficients
    JacobResults$Parmnames = c("beta_s1", "beta_d1", "beta_k1")
    JacobResults$mean_exp_weighted_error = 1.0   # no bias correction
    JacobResults$leverage   = rep(0, 7)
    JacobResults$boot_resid = NULL
    JacobResults$Obs        = c(100)             # depvar at calibration site
    JacobResults$predict    = c(NA)              # populated after predict_sparrow
    JacobResults$Resids     = c(NA)
  ANOVA.list$RSQ  = NA_real_
  ANOVA.list$RMSE = NA_real_
  ANOVA.list$npar = 3L
  ANOVA.list$mobs = 1L
  sparrowEsts = NULL   # not needed for predict tests

Note: The estimate.list mock does NOT require running the optimizer. It is built by hand
in helper-fixtures.R and saved to fixtures/mini_model_inputs.rda.
</model_spec>

<build_notes>
The build script (tests/testthat/helper-build-fixtures.R) should:
1. Define mini_network_raw as shown above
2. Construct DataMatrix.list by sorting mini_network_raw by hydseq and assembling the numeric
   matrix column by column
3. Build SelParmValues, estimate.input.list, Csites.weights.list, dlvdsgn as specified
4. Build the mock estimate.list by hand
5. Save both fixtures:
   save(mini_network_raw, file = "fixtures/mini_network.rda")
   save(mini_inputs, file = "fixtures/mini_model_inputs.rda")
   where mini_inputs = list(DataMatrix.list, SelParmValues, Csites.weights.list,
                            estimate.input.list, dlvdsgn, estimate.list)

The build script itself is NOT a test file and should not be run by R CMD check.
Place it at tests/testthat/helper-build-fixtures.R with a guard:
  if (FALSE) { ... }   # never auto-executed; run manually to regenerate fixtures
</build_notes>

<expected_estimateFeval_output>
With beta0 = c(0.5, -0.5, 0.1) and the mini_network, estimateFeval should return a numeric
vector of length 7 (nreach) where all entries are 0 except entry for reach 7 (the single
calibration site). The value at that site is the weighted log-residual:
  weight * (log(observed_load) - log(predicted_load))
The exact value depends on the Fortran tnoder accumulation and cannot be pre-computed here
without running the code. Tests should verify:
  - length(e) == 7 (nreach)
  - all(e[1:6] == 0)  # non-site reaches contribute zero residual
  - is.finite(e[7])   # the calibration site residual is a finite number
  - e_unit <- estimateFeval(beta0, ..., ifadjust=0L)
    length(e_unit) == 7 and all residuals are finite (unit weights, no conditioning)
</expected_estimateFeval_output>

</fixture>

<helper_utilities>
The following utility functions should be defined in tests/testthat/helper.R (replacing the
current makeReport chunk-checker helper, which is no longer useful after Plan 05D):

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
                     paste(setdiff(required_names, names(x)), collapse=", "))
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
        fit_stats   = list(R2=0.95, RMSE=0.15, npar=3L, nobs=1L, convergence=0L),
        data        = list(
          subdata   = data.frame(waterid=1:7),
          sitedata  = data.frame(waterid=7L),
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
            ANOVA.list = list(RSQ=0.95, RMSE=0.15, npar=3L, mobs=1L)
          ),
          estimate.input.list = list(
            loadUnits="kg/yr", yieldUnits="kg/km2/yr",
            ConcUnits="mg/L", ConcFactor=1.0, yieldFactor=0.01
          ),
          file.output.list = list(run_id="mock_run"),
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
</helper_utilities>

</synthetic_dataset_spec>
