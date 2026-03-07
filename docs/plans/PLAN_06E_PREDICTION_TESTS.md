<plan id="06E" label="Prediction Tests" status="pending" blocked_by="06C">

<objective>
Write unit tests for the prediction layer: predict_sparrow (renamed from predict() in Plan 03),
predict_core (shared kernel created in Plan 05B), and predictSensitivity. Tests verify output
structure, matrix dimensions, and that consolidation in Plan 05B did not introduce numeric
discrepancies between predict_sparrow and predict_core. All tests use the mini_model_inputs
fixture and require the package to be compiled for Fortran routines.
</objective>

<reference_documents>
  docs/plans/PLAN_06_TEST_SUITE.md
  docs/plans/PLAN_06C_FORTRAN_TESTS.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md
  RSPARROW_master/R/predict.R         (predict_sparrow function)
  RSPARROW_master/R/predict_core.R    (shared prediction kernel)
  RSPARROW_master/R/predictBoot.R     (predictBoot function)
  RSPARROW_master/R/predictSensitivity.R
</reference_documents>

<background>
Plan 05B created predict_core.R (266 lines) as a shared kernel. predict.R was reduced from
574→291 lines and predictBoot.R from 475→190 lines — both now delegate to predict_core.R.
The key risk is that this consolidation introduced numeric differences. The tests here
verify that predict_sparrow and the shared kernel produce consistent outputs for the same
inputs. Since predictBoot is tested in the bootstrap context, this sub-plan focuses on
the main prediction and sensitivity paths.
</background>

<tasks>

<task id="06E-1" status="pending">
<subject>Write test-predict-sparrow.R — main prediction function</subject>
<description>
File: tests/testthat/test-predict-sparrow.R

Tests for predict_sparrow() in predict.R.

Load mini_inputs from fixtures/mini_model_inputs.rda.
Sort mini_network_raw by hydseq to get subdata in correct order.
Call:
  result &lt;- predict_sparrow(
    estimate.list    = mini_inputs$estimate.list,
    estimate.input.list = mini_inputs$estimate.input.list,
    bootcorrection   = 1.0,
    DataMatrix.list  = mini_inputs$DataMatrix.list,
    SelParmValues    = mini_inputs$SelParmValues,
    subdata          = subdata_sorted,
    dlvdsgn          = mini_inputs$dlvdsgn
  )

Test 1: "predict_sparrow returns a list (predict.list)"
  expect: is.list(result)
  expect_names_present(result, c("predmatrix", "yldmatrix", "oparmlist", "oyieldlist"))

Test 2: "predmatrix and yldmatrix have nreach rows"
  expect: nrow(result$predmatrix) == 7L
  expect: nrow(result$yldmatrix) == 7L

Test 3: "column count matches oparmlist and oyieldlist lengths"
  expect: ncol(result$predmatrix) == length(result$oparmlist)
  expect: ncol(result$yldmatrix) == length(result$oyieldlist)

Test 4: "total load column is non-negative for all reaches"
  Find the "total load" column (first column, or the column named "pload_total" or similar —
  verify from getVarList.R or by inspecting predict.R output).
  expect: all(result$predmatrix[, total_col] >= 0)

Test 5: "terminal reach total load is the largest in the network"
  In a linear-accumulating network, the terminal reach accumulates all upstream loads.
  reach7_row &lt;- which(subdata_sorted$waterid == 7L)
  expect: result$predmatrix[reach7_row, total_col] ==
          max(result$predmatrix[, total_col])

Test 6: "bootcorrection=1.0 vs actual mean_exp_weighted_error are consistent"
  Call predict_sparrow twice: once with bootcorrection=1.0, once with bootcorrection=2.0.
  The predictions with bootcorrection=2.0 should differ from bootcorrection=1.0.
  (Verifies bootcorrection is actually applied, not ignored.)
  expect: !identical(result1$predmatrix, result2$predmatrix)

Test 7: "predict_sparrow with known coefficients produces reproducible results"
  Call predict_sparrow twice with identical arguments.
  expect_identical(result1$predmatrix, result2$predmatrix)
  (Verifies no hidden random state in prediction.)

Test 8: "concentration predictions are non-negative"
  If yldmatrix contains concentration columns (ConcUnits="mg/L"), verify non-negative.
  If the simple mini_network cannot compute concentration (missing meanq in the right form),
  skip this test or use expect_true(is.na) for unreachable columns.
  expect: all(result$yldmatrix[, conc_col] >= 0 | is.na(result$yldmatrix[, conc_col]))
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-predict-sparrow.R</files_modified>
<success_criteria>
  - 8 tests pass
  - Requires compiled package (skip if not installed)
  - Total load accumulation at terminal reach verified
  - Reproducibility confirmed (test 7)
</success_criteria>
</task>

<task id="06E-2" status="pending">
<subject>Write test-predict-core.R — shared prediction kernel consistency</subject>
<description>
File: tests/testthat/test-predict-core.R

predict_core.R was created in Plan 05B as a shared kernel called by both predict_sparrow
and predictBoot. These tests verify that predict_core produces outputs consistent with
predict_sparrow (no divergence from the consolidation refactoring).

Before writing: Read predict_core.R to understand:
  - Its function signature (may differ from predict_sparrow's public signature)
  - What subset of predict_sparrow's logic it implements
  - Whether it is called with the same arguments or a subset

Test 1: "predict_core returns list with required fields"
  Call predict_core with mini_inputs (using the same arguments as predict_sparrow
  or the subset it accepts).
  expect_names_present(result, c("predmatrix", "yldmatrix"))

Test 2: "predict_core nreach matches input data rows"
  expect: nrow(result$predmatrix) == 7L

Test 3: "predict_core and predict_sparrow produce identical predmatrix"
  Call predict_sparrow and predict_core with identical inputs.
  This is the critical regression test for the Plan 05B consolidation.
  expect_numeric_close(
    as.vector(result_core$predmatrix),
    as.vector(result_sparrow$predmatrix),
    tol = 1e-10,
    label = "predict_core vs predict_sparrow predmatrix"
  )

Test 4: "predict_core and predict_sparrow produce identical yldmatrix"
  Same as Test 3 for the yield matrix.
  expect_numeric_close(
    as.vector(result_core$yldmatrix),
    as.vector(result_sparrow$yldmatrix),
    tol = 1e-10,
    label = "predict_core vs predict_sparrow yldmatrix"
  )

Test 5: "predict_core eval(parse) hover-text pattern produces valid strings"
  predict_core.R contains 1 hardened hover-text eval(parse()) call (per CLAUDE.md).
  Verify it does not crash and produces character output when triggered.
  This test may require specific plotly-related inputs to trigger; if the eval is in a
  conditional branch, exercise that branch and verify no error.
  (If the eval is not reachable via simple inputs, document as known-unreachable and skip.)
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-predict-core.R</files_modified>
<success_criteria>
  - 4-5 tests pass (test 5 may be skipped if eval is in unreachable branch)
  - predict_core and predict_sparrow agree to 1e-10 tolerance
  - Plan 05B consolidation verified to not break prediction math
</success_criteria>
</task>

<task id="06E-3" status="pending">
<subject>Write test-predictSensitivity.R — parameter sensitivity predictions</subject>
<description>
File: tests/testthat/test-predictSensitivity.R

predictSensitivity() computes predictions under perturbed parameter values to assess
parameter sensitivity. After Plan 04C refactoring (unPackList replaced with direct $
extractions), this function is in a cleaner state. After Plan 04B, its 3 dead spec-string
params were removed from the signature.

Before writing: Read predictSensitivity.R to confirm current signature and return value.
The function likely requires:
  - estimate.list, estimate.input.list, DataMatrix.list, SelParmValues, subdata, dlvdsgn
  - Some sensitivity-specific parameters (perturbation fraction, parameter indices)

Test 1: "predictSensitivity returns a list"
  Call predictSensitivity with mini_inputs.
  expect: is.list(result)
  expect: length(result) > 0

Test 2: "predictSensitivity produces different predictions for different perturbation sizes"
  Perturb a parameter by 10% vs. 100%.
  The resulting predictions should differ.
  expect: !identical(result_10pct$predmatrix, result_100pct$predmatrix)

Test 3: "predictSensitivity with zero perturbation matches predict_sparrow baseline"
  If perturbing by 0% (factor=1.0), predictions should match the unperturbed baseline.
  expect_numeric_close(result_zero_pert, baseline_predict, tol=1e-10)

If predictSensitivity requires inputs not available from mini_model_inputs (e.g., it needs
class.input.list, mapping.input.list, or file.output.list for output), either:
  a) Supply NULL/empty list values where optional, OR
  b) Skip this test file and add a TODO comment linking to Plan 06G integration tests
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-predictSensitivity.R</files_modified>
<success_criteria>
  - 3 tests pass, OR file documents why skipped with clear TODO for integration test
  - No crash from parameter access (direct $ access verified working after Plan 04C)
</success_criteria>
</task>

</tasks>

<notes>
- The critical test is 06E-2 Test 3/4: confirming predict_core == predict_sparrow numerically.
  This is the Plan 05B regression guard. If these tests fail, it indicates the consolidation
  introduced a bug that must be fixed before CRAN submission.
- predict_sparrow's `bootcorrection` parameter: in normal usage, this is
  estimate.list$JacobResults$mean_exp_weighted_error. For the mini_inputs fixture, set this
  to 1.0 (no bias correction) to simplify tests.
- Column naming in predmatrix: verify column names against getVarList.R and predict.R.
  The "total load" column may be named "pload_total" or indexed by position. Use the column
  names from result$oparmlist to locate it dynamically rather than hardcoding position.
</notes>

<success_criteria>
<criterion>test-predict-sparrow.R: 8 tests — structure, dimensions, accumulation, reproducibility</criterion>
<criterion>test-predict-core.R: 4+ tests — predict_core matches predict_sparrow to 1e-10</criterion>
<criterion>test-predictSensitivity.R: 3 tests OR clearly documented skip</criterion>
<criterion>All tests run in under 10 seconds total</criterion>
<criterion>Plan 05B consolidation regression verified as non-breaking</criterion>
</success_criteria>

<failure_criteria>
<criterion>predict_core and predict_sparrow diverge by more than 1e-10 (Plan 05B regression)</criterion>
<criterion>Terminal reach total load is not the maximum (accumulation bug)</criterion>
<criterion>Predictions differ between two identical calls (hidden random state)</criterion>
</failure_criteria>

<estimated_test_count>15-16 new tests</estimated_test_count>
<estimated_runtime>~5 seconds total</estimated_runtime>

</plan>
