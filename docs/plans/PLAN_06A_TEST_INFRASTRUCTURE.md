<plan id="06A" label="Test Infrastructure Setup" status="complete" blocked_by="none">

<objective>
Establish a working test infrastructure before any substantive test writing begins. This
sub-plan fixes broken tests left by Plan 05D, upgrades the testthat configuration to edition 3,
builds shared fixture data, and writes the shared helper utilities used by Plans 06B–06F.
</objective>

<reference_documents>
  docs/plans/PLAN_06_TEST_SUITE.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md
  docs/reference/TESTING_STRATEGY.md
  docs/reference/DATA_STRUCTURES.md
</reference_documents>

<current_state>
  - tests/testthat/ contains 16 test files and 5 fixture .rda files
  - 7 test files call makeReport_* functions deleted in Plan 05D → error on load
  - helper.R defines check_chunks_enclosed() — only used by deleted makeReport tests
  - DESCRIPTION has `testthat` without version; no Config/testthat/edition: 3
  - Existing fixture files: input_createSubdataSorted.rda, output_readDesignMatrix.rda,
    output_readParameters.rda, output_selectDesignMatrix.rda, output_selectParmValues.rda
  - 9 surviving tests use these fixtures and should continue to pass after this sub-plan
</current_state>

<tasks>

<task id="06A-1" status="complete">
<subject>Upgrade DESCRIPTION for testthat edition 3</subject>
<description>
Modify RSPARROW_master/DESCRIPTION:
1. Change `testthat` in Suggests to `testthat (>= 3.0.0)`.
2. Add `Config/testthat/edition: 3` as a top-level field (after RoxygenNote).

This is a CRAN blocker: without edition 3, self_contained = TRUE behavior (parallel tests,
snapshot testing) is unavailable, and CRAN notes the missing edition declaration.
</description>
<files_modified>RSPARROW_master/DESCRIPTION</files_modified>
<success_criteria>
  - DESCRIPTION Suggests contains `testthat (>= 3.0.0)`
  - DESCRIPTION contains `Config/testthat/edition: 3`
  - R CMD build succeeds
</success_criteria>
</task>

<task id="06A-2" status="complete">
<subject>Delete 7 broken makeReport_* test files</subject>
<description>
Delete the following test files whose target functions were removed in Plan 05D:
  tests/testthat/test-makeReport_diagnosticPlotsNLLS.R
  tests/testthat/test-makeReport_drainageAreaErrorsPlot.R
  tests/testthat/test_makeReport_header.R
  tests/testthat/test-makeReport_modelEstPerf.R
  tests/testthat/test-makeReport_modelSimPerf.R
  tests/testthat/test-makeReport_outputMaps.R
  tests/testthat/test-makeReport_residMaps.R

These 7 files reference makeReport_diagnosticPlotsNLLS(), makeReport_drainageAreaErrorsPlot(),
makeReport_header(), makeReport_modelEstPerf(), makeReport_modelSimPerf(),
makeReport_outputMaps(), makeReport_residMaps() — all deleted from R/ in Plan 05D.
Running R CMD check with these present produces errors.

Do not replace these files in this task; replacement tests for the plot.rsparrow()
dispatch that replaced these functions are written in Plan 06F.
</description>
<files_modified>
  DELETE: tests/testthat/test-makeReport_diagnosticPlotsNLLS.R
  DELETE: tests/testthat/test-makeReport_drainageAreaErrorsPlot.R
  DELETE: tests/testthat/test_makeReport_header.R
  DELETE: tests/testthat/test-makeReport_modelEstPerf.R
  DELETE: tests/testthat/test-makeReport_modelSimPerf.R
  DELETE: tests/testthat/test-makeReport_outputMaps.R
  DELETE: tests/testthat/test-makeReport_residMaps.R
</files_modified>
<success_criteria>
  - All 7 files removed from tests/testthat/
  - R CMD check no longer errors on missing makeReport_* functions
  - Remaining 9 test files still pass (readParameters, readDesignMatrix, selectDesignMatrix,
    selectParmValues, createSubdataSorted, checkDynamic, copyStructure)
</success_criteria>
</task>

<task id="06A-3" status="complete">
<subject>Rewrite helper.R with shared test utilities</subject>
<description>
Replace the contents of tests/testthat/helper.R with the shared utilities defined in
docs/implementation/PLAN_06_SYNTHETIC_DATASET.md under &lt;helper_utilities&gt;:

  1. expect_numeric_close(actual, expected, tol=1e-6, label="")
     — Wraps testthat::expect_true(all(abs(actual - expected) &lt; tol))
     — Used by estimation and prediction tests to compare floating point results

  2. expect_names_present(x, required_names)
     — Wraps testthat::expect_true(all(required_names %in% names(x)))
     — Used by structure tests on estimate.list, predict.list, rsparrow objects

  3. make_mock_rsparrow()
     — Returns a minimal rsparrow S3 object with all required fields populated with
       plausible values (see full spec in PLAN_06_SYNTHETIC_DATASET.md)
     — Used by Plan 06F API tests to avoid running rsparrow_model()

Remove the old check_chunks_enclosed() function (only used by the deleted makeReport tests).
</description>
<files_modified>RSPARROW_master/tests/testthat/helper.R</files_modified>
<success_criteria>
  - helper.R contains: expect_numeric_close, expect_names_present, make_mock_rsparrow
  - make_mock_rsparrow() returns an object with class "rsparrow"
  - helper.R is automatically loaded by testthat before any test file runs
  - Old check_chunks_enclosed() is removed
</success_criteria>
</task>

<task id="06A-4" status="complete">
<subject>Create mini_network fixture (mini_network.rda)</subject>
<description>
Create the 7-reach synthetic network fixture specified in docs/implementation/PLAN_06_SYNTHETIC_DATASET.md.

Steps:
1. Write a fixture-building script at tests/testthat/helper-build-fixtures.R.
   Guard the entire body with `if (FALSE) { ... }` so it is never auto-executed by R CMD check.
   The script defines mini_network_raw as a data.frame with columns:
     waterid, fnode, tnode, frac, iftran, demiarea, demtarea, meanq,
     headflag, termflag, depvar, staidseq, calsites, s1, d1, k1
   (See exact values in PLAN_06_SYNTHETIC_DATASET.md &lt;build_code&gt; section.)
2. Source the script interactively once to generate the fixture:
   source("tests/testthat/helper-build-fixtures.R")   # manually
   OR include the build in a helper-build-fixtures.R that, when evaluated in its entirety
   (not within if (FALSE)), writes the .rda files.
3. Actually run the build to produce tests/testthat/fixtures/mini_network.rda.
4. Verify the fixture loads correctly: load("fixtures/mini_network.rda"); str(mini_network_raw)

Note: The .rda file must be committed to the repository. The build script is for future
regeneration only.
</description>
<files_modified>
  CREATE: RSPARROW_master/tests/testthat/helper-build-fixtures.R
  CREATE: RSPARROW_master/tests/testthat/fixtures/mini_network.rda
</files_modified>
<success_criteria>
  - fixtures/mini_network.rda exists and loads as `mini_network_raw`
  - mini_network_raw has 7 rows and all required columns
  - fnode/tnode values match the topology in PLAN_06_SYNTHETIC_DATASET.md
  - headflag, termflag, depvar, calsites match expected values
</success_criteria>
</task>

<task id="06A-5" status="complete">
<subject>Create mini_model_inputs fixture (mini_model_inputs.rda)</subject>
<description>
Create the DataMatrix.list, SelParmValues, Csites.weights.list, estimate.input.list,
dlvdsgn, and mock estimate.list needed for estimation and prediction unit tests.

This is more involved than the network fixture because it requires assembling a correctly-
structured DataMatrix.list. Key steps:
1. Sort mini_network_raw by hydseq (headwaters first) to match the order that subdata
   would have after createSubdataSorted().
   NOTE: hydseq values must be computed first by calling hydseq() from the package.
2. Assemble the numeric data matrix (nreach x 10 columns) as described in
   PLAN_06_SYNTHETIC_DATASET.md under &lt;model_spec&gt;.
3. Build data.index.list with the exact integer column indices.
4. Build SelParmValues, Csites.weights.list, estimate.input.list, dlvdsgn.
5. Build the mock estimate.list (JacobResults with oEstimate, Parmnames, etc.)
   without running the optimizer — hand-coded values only.
6. Bundle as a named list `mini_inputs` and save:
   save(mini_inputs, file = "tests/testthat/fixtures/mini_model_inputs.rda")

Add the build code to helper-build-fixtures.R (inside the `if (FALSE)` guard).
</description>
<files_modified>
  MODIFY: RSPARROW_master/tests/testthat/helper-build-fixtures.R (add build code)
  CREATE: RSPARROW_master/tests/testthat/fixtures/mini_model_inputs.rda
</files_modified>
<success_criteria>
  - fixtures/mini_model_inputs.rda exists and loads as `mini_inputs`
  - mini_inputs$DataMatrix.list$data is a numeric matrix with 7 rows and 10 columns
  - mini_inputs$DataMatrix.list$data.index.list has all required index fields
  - mini_inputs$SelParmValues$bcols == 3L
  - mini_inputs$dlvdsgn is a 1x1 matrix with value 1
  - mini_inputs$estimate.list$JacobResults$oEstimate has length 3
</success_criteria>
</task>

<task id="06A-6" status="complete">
<subject>Verify existing 9 tests still pass after infrastructure changes</subject>
<description>
After completing tasks 06A-1 through 06A-5, run the test suite to verify that the 9
surviving test files still pass. Run from package root:

  R CMD INSTALL RSPARROW_master/   # install package with Fortran compiled
  R -e "testthat::test_dir('RSPARROW_master/tests/testthat')"

Expected passing tests:
  test_checkDynamic.R       — 2 tests
  test-copyStructure.R      — N tests
  test_createSubdataSorted.R — 1 test
  test_readDesignMatrix.R   — N tests
  test_readParameters.R     — 1 test
  test_selectDesignMatrix.R — N tests
  test_selectParmValues.R   — N tests

If any of the 9 existing tests fail, fix the regression before proceeding.
The batch_mode parameter passed to readParameters in test_readParameters.R may need
updating if it was removed during Plan 05A refactoring — verify the current function
signature of readParameters() and update the test call accordingly.
</description>
<files_modified>
  MODIFY if needed: tests/testthat/test_readParameters.R
  MODIFY if needed: any of the 9 surviving test files
</files_modified>
<success_criteria>
  - All surviving tests pass with 0 errors, 0 failures
  - R CMD check --as-cran reports no new errors related to tests
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>DESCRIPTION: testthat (>= 3.0.0) in Suggests; Config/testthat/edition: 3 present</criterion>
<criterion>7 broken makeReport_* test files deleted</criterion>
<criterion>helper.R exports: expect_numeric_close, expect_names_present, make_mock_rsparrow</criterion>
<criterion>fixtures/mini_network.rda: 7-row data.frame with correct topology</criterion>
<criterion>fixtures/mini_model_inputs.rda: complete mini model inputs list</criterion>
<criterion>All 9 surviving tests pass; R CMD check 0 test errors</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any of the 9 surviving tests fails after infrastructure changes</criterion>
<criterion>R CMD check reports errors in test files</criterion>
<criterion>mini_model_inputs.rda DataMatrix.list does not load into estimateFeval without error</criterion>
</failure_criteria>

<estimated_test_count>0 new tests (setup only)</estimated_test_count>
<estimated_wall_clock>30-60 minutes (mostly fixture construction and verification)</estimated_wall_clock>

</plan>
