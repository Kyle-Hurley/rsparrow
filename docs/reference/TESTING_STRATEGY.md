<testing_strategy>

<current_state>
<framework>testthat (>= 3.0.0) in DESCRIPTION Suggests; Config/testthat/edition: 3</framework>
<runner>tests/testthat.R (standard testthat runner)</runner>
<helper>tests/testthat/helper.R (expect_numeric_close, expect_names_present, make_mock_rsparrow)</helper>
<fixtures>tests/testthat/fixtures/ (mini_network.rda, mini_model_inputs.rda, regression outputs)</fixtures>
<test_count>9 test files, 30 tests passing</test_count>
<last_updated>2026-03-07</last_updated>
</current_state>

<existing_tests>
<test_group name="Network Processing" files="1">
test-hydseq.R (7 tests, added 2026-03-07, Plan 06B-1)
Tests: hydseq() return structure, headwater ordering, flow-direction consistency,
linear network handling, rsparrow_hydseq/hydseq agreement, input validation,
column preservation.
Note: Internal hydseq() accessed via rsparrow:::hydseq(). Ordering convention confirmed:
terminal reach = hydseq max (least negative); headwaters = most negative; sorted ascending
= upstream-first. hydseqTerm, upstream, accumulateIncrArea, sumIncremAttributes still untested.
</test_group>

<test_group name="Data Reading/Preparation" files="3">
test_readDesignMatrix.R
test_readParameters.R
test_selectDesignMatrix.R
Note: Tests for CSV input parsing. Useful foundation.
</test_group>

<test_group name="Parameter Handling" files="2">
test_selectParmValues.R
test_createSubdataSorted.R
Note: Tests parameter selection logic and data filtering.
</test_group>

<test_group name="Utility" files="2">
test_checkDynamic.R - Tests dynamic model detection (year/season columns)
test-copyStructure.R - Tests file structure copying
</test_group>
</existing_tests>

<critical_gaps>
<gap priority="1" name="Estimation Core">
NO tests for: estimateFeval, estimateFevalNoadj, estimateOptimize, estimateNLLSmetrics,
estimateBootstraps, estimate (orchestrator).
These are the mathematical heart of SPARROW. Any refactoring without tests risks breaking
the science.
</gap>

<gap priority="1" name="Prediction Core">
NO tests for: predict, predictBoot, predictScenarios, predictSensitivity, deliver.
These compute all model outputs. Duplication refactoring (merging predict/predictBoot)
is high risk without regression tests.
</gap>

<gap priority="1" name="Network Processing">
PARTIAL coverage (Plan 06B-1 complete): hydseq and rsparrow_hydseq have 7 tests in
test-hydseq.R. Still NO tests for: hydseqTerm, upstream, accumulateIncrArea,
sumIncremAttributes (planned in 06B-2 and 06B-3).
Hydrological sequencing is foundational; bugs would corrupt all downstream results.
</gap>

<gap priority="2" name="Data Matrix Construction">
NO tests for: createDataMatrix, which builds the numeric matrix used by optimization.
Column index mapping errors would produce silent incorrect results.
</gap>

<gap priority="2" name="Site Selection">
NO tests for: selectCalibrationSites, selectValidationSites.
Site filtering logic affects which observations are used in estimation.
</gap>

<gap priority="2" name="Fortran Interface">
NO tests for: .Fortran() calls to tnoder, ptnoder, mptnoder, deliv_fraction, sites_incr,
sum_atts. Interface correctness (argument order, dimensions, types) is critical.
</gap>

<gap priority="3" name="Weight Computation">
NO tests for: setNLLSWeights, estimateWeightedErrors.
</gap>

<gap priority="3" name="Validation Metrics">
NO tests for: validateMetrics.
</gap>
</critical_gaps>

<recommended_testing_approach>

<phase name="1. Create Reference Test Data">
Before any refactoring, run the UserTutorial Model6 end-to-end and capture:
- DataMatrix.list contents (numeric matrix, indices)
- estimateFeval output for known parameter values
- sparrowEsts (coefficients, residuals, ssquares)
- JacobResults (oEstimate, diagnostics)
- predict.list (predmatrix, yldmatrix)
- delivery fractions
Save these as RDS files in tests/testthat/fixtures/.
This creates a "golden reference" for regression testing.
</phase>

<phase name="2. Unit Test Core Math">
Test estimateFeval with known inputs and verify residual output matches reference.
Test predict with known coefficients and verify load/yield matrices match reference.
Test deliver with known network and verify delivery fractions.
Test hydseq with small network (5-10 reaches) and verify sequencing.
Test Fortran wrappers (tnoder, ptnoder) directly with small matrix inputs.
</phase>

<phase name="3. Integration Tests">
Test estimate -> predict pipeline end-to-end with tutorial data subset.
Test bootstrap estimation produces reasonable coefficient distributions.
Test scenario predictions match manual source modification + predict.
</phase>

<phase name="4. Refactoring Safety Net">
For each refactoring task (e.g., merging predict/predictBoot):
1. Write test that captures current behavior
2. Perform refactoring
3. Verify test still passes
4. Add new tests for edge cases exposed by refactoring
</phase>

</recommended_testing_approach>

<test_infrastructure_needs>
<need>Small synthetic reach network dataset (10-20 reaches) for fast unit tests</need>
<need>Subset of UserTutorial data (100 reaches) for integration tests</need>
<need>Mock/stub for .Fortran() calls to enable testing without compiled Fortran</need>
<need>Reference output files (RDS) from verified model run</need>
<need>Test helper functions for comparing numeric matrices within tolerance</need>
<need>CRAN check time budget: all tests must complete in under 10 minutes</need>
</test_infrastructure_needs>

</testing_strategy>
