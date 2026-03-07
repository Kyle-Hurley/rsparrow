<plan id="06D" label="Estimation Core Tests" status="pending" blocked_by="06C">

<objective>
Write unit tests for the estimation support functions: estimateWeightedErrors, setNLLSWeights,
and a lightweight estimateOptimize convergence check. These tests verify the R-level estimation
logic separate from the Fortran accumulation routines (which were tested in Plan 06C via
estimateFeval). All tests use mini_network fixtures. An optional smoke test for estimateOptimize
verifies that the NLLS optimizer converges on the mini_network without testing for exact
coefficient values.
</objective>

<reference_documents>
  docs/plans/PLAN_06_TEST_SUITE.md
  docs/plans/PLAN_06C_FORTRAN_TESTS.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md
  RSPARROW_master/R/estimateWeightedErrors.R
  RSPARROW_master/R/setNLLSWeights.R
  RSPARROW_master/R/estimateOptimize.R
  RSPARROW_master/R/estimateFeval.R
</reference_documents>

<prerequisite_check>
Before writing tests, read the following to confirm current signatures:
  setNLLSWeights(Csites.weights.list, NLLS_weights, tiarea, ...)
  estimateWeightedErrors(sitedata, estimate.list, ...)
  estimateOptimize(DataMatrix.list, SelParmValues, Csites.weights.list,
                   estimate.input.list, dlvdsgn, ...)
Adjust test calls to match actual signatures.
</prerequisite_check>

<tasks>

<task id="06D-1" status="pending">
<subject>Write test-setNLLSWeights.R</subject>
<description>
File: tests/testthat/test-setNLLSWeights.R

setNLLSWeights computes observation weights for the NLLS regression. Two modes:
  NLLS_weights = "no"  → uniform weights (all 1.0)
  NLLS_weights = "yes" → area-proportional weights (proportional to incremental area)

Before writing: Read setNLLSWeights.R to confirm:
  - Function signature (may take file.output.list, subdata, sitedata, or separate args)
  - Return structure (Csites.weights.list with $weight and $tiarea, or different?)
  - The power function regression for area-based weights

Test 1: "setNLLSWeights with NLLS_weights='no' returns unit weights"
  Build minimal inputs from mini_network (calibration sites only: reach 7).
  Call setNLLSWeights with NLLS_weights="no".
  expect: all(result$weight == 1.0) OR all(result$weight == rep(1, n_calsites))

Test 2: "setNLLSWeights with NLLS_weights='yes' returns positive weights"
  Call setNLLSWeights with NLLS_weights="yes".
  All weights should be positive.
  expect: all(result$weight > 0)

Test 3: "setNLLSWeights weight length matches number of reaches"
  The weight vector should have length equal to nreach (one weight per reach,
  with zero-weight for non-monitoring reaches, or equal to number of calibration sites).
  Verify convention from source code.
  expect: length(result$weight) == expected_length

Test 4: "setNLLSWeights tiarea element is numeric and positive"
  expect: is.numeric(result$tiarea)
  expect: all(result$tiarea > 0)
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-setNLLSWeights.R</files_modified>
<success_criteria>
  - 4 tests pass
  - Both NLLS_weights modes verified
  - No Fortran dependency
</success_criteria>
</task>

<task id="06D-2" status="pending">
<subject>Write test-estimateWeightedErrors.R</subject>
<description>
File: tests/testthat/test-estimateWeightedErrors.R

estimateWeightedErrors computes the mean exponential weighted error (bias correction factor).
It takes sitedata (subset of subdata at calibration sites) and estimate.list (after NLLS fit).

The mean exponential weighted error is used as bootcorrection in predict_sparrow().
A value of 1.0 indicates no bias; values near 1.0 are expected for reasonable fits.

Before writing: Read estimateWeightedErrors.R to confirm:
  - Exact function signature
  - Whether it returns a scalar or named list element
  - What sitedata columns it accesses

Test 1: "estimateWeightedErrors returns a positive scalar"
  Build mock sitedata (1 site: the monitoring site in mini_network, reach 7).
  Build mock estimate.list with residuals near zero.
  result &lt;- estimateWeightedErrors(sitedata=..., estimate.list=...)
  expect: is.numeric(result)
  expect: length(result) == 1L
  expect: result > 0

Test 2: "estimateWeightedErrors is near 1.0 when residuals are near zero"
  With residuals ≈ 0 at calibration sites, exp(weighted_error) ≈ 1.0.
  Construct mock estimate.list with Resids = rep(0, n_sites).
  expect: abs(result - 1.0) &lt; 0.01

Test 3: "estimateWeightedErrors increases with larger residuals"
  Compare result with small residuals vs. large residuals.
  The bias correction factor should increase as residuals grow.
  result_small &lt;- estimateWeightedErrors(..., Resids=rep(0.01, n))
  result_large &lt;- estimateWeightedErrors(..., Resids=rep(1.0, n))
  expect: result_large > result_small
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-estimateWeightedErrors.R</files_modified>
<success_criteria>
  - 3 tests pass
  - Bias correction behavior verified (near 1 for small residuals)
  - No Fortran dependency
</success_criteria>
</task>

<task id="06D-3" status="pending">
<subject>Write test-estimateOptimize.R — optimizer smoke test</subject>
<description>
File: tests/testthat/test-estimateOptimize.R

estimateOptimize() runs the full NLLS optimization via nlmrt::nlfb(). On the mini_network
(7 reaches, 1 calibration site, 3 parameters), convergence should be near-instant.

This is a smoke test verifying that:
  - The function returns the expected result structure
  - The optimizer terminates (convergence code is not a failure code)
  - The returned coefficients are within the specified bounds

The test should run in under 5 seconds on any machine. If nlmrt is not installed
(it is an Import, so it should be available when rsparrow is installed), add a skip guard.

Before writing: Read estimateOptimize.R to confirm:
  - Function signature
  - Return value structure (returns sparrowEsts from nlfb? Or a named list?)
  - Convergence code convention (0 = converged? Check nlmrt docs)

Test 1: "estimateOptimize returns a list-like object with coefficient vector"
  Load mini_inputs. Call estimateOptimize with the mini DataMatrix.list, SelParmValues,
  Csites.weights.list, estimate.input.list, dlvdsgn.
  expect: result is not NULL
  expect: "coefficients" %in% names(result) OR result$coef is accessible
  (Verify actual element name from nlmrt::nlfb output structure)

Test 2: "estimateOptimize coefficients are within specified bounds"
  The estimated parameters should be within [betamin, betamax].
  expect: all(coefs >= SelParmValues$betamin)
  expect: all(coefs &lt;= SelParmValues$betamax)

Test 3: "estimateOptimize on mini_network terminates within 60 seconds"
  Wrap in system.time() and verify elapsed time &lt; 60s.
  This catches infinite loop regressions.
  elapsed &lt;- system.time(estimateOptimize(...))[["elapsed"]]
  expect: elapsed &lt; 60

Test 4: "estimateOptimize residuals from result are finite"
  After optimization, plugging the estimated coefficients back into estimateFeval
  should return finite residuals.
  e &lt;- estimateFeval(result_coefs, DataMatrix.list, SelParmValues,
                     Csites.weights.list, estimate.input.list, dlvdsgn)
  expect: all(is.finite(e))
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-estimateOptimize.R</files_modified>
<success_criteria>
  - 4 tests pass
  - Optimizer runs successfully on mini_network with 1 site and 3 parameters
  - Total test runtime &lt; 10 seconds
  - Coefficients within bounds confirmed
</success_criteria>
<notes>
With only 1 calibration site and 3 parameters (an underdetermined system!), the optimizer
may not converge to a unique solution. If so, relax Test 2 to only check bounds, and focus
Test 1 on structural correctness. Add a note in the test file explaining the underdetermined
nature of the mini_network for documentation.

Alternative: extend mini_network to have 2 calibration sites (add staidseq/calsites=1 to
reach 5 or 6). This would make the system overdetermined and tests more meaningful. Update
the mini_network fixture spec if this change is made.
</notes>
</task>

</tasks>

<notes>
- These tests are relatively lightweight — they test R logic around the NLLS machinery,
  not the Fortran accumulators directly.
- estimateWeightedErrors may require a fairly complete estimate.list (JacobResults with
  Resids, Obs, standardResids, etc.). If building the mock is complex, create a helper
  make_mock_estimate_list() in helper.R and reuse it across tests.
- The mini_network is underdetermined (1 site, 3 params). If optimizer tests prove unreliable,
  add a second monitoring site to the fixture. Document any such change in
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md.
</notes>

<success_criteria>
<criterion>test-setNLLSWeights.R: 4 tests pass, both weight modes verified</criterion>
<criterion>test-estimateWeightedErrors.R: 3 tests pass, bias correction behavior confirmed</criterion>
<criterion>test-estimateOptimize.R: 4 tests pass, runs in under 10 seconds</criterion>
<criterion>All 11 tests combined run in under 30 seconds</criterion>
</success_criteria>

<failure_criteria>
<criterion>estimateOptimize runs longer than 60 seconds on mini_network</criterion>
<criterion>Returned coefficients violate specified bounds</criterion>
<criterion>setNLLSWeights returns negative weights</criterion>
</failure_criteria>

<estimated_test_count>11 new tests</estimated_test_count>
<estimated_runtime>~15 seconds total (dominated by estimateOptimize)</estimated_runtime>

</plan>
