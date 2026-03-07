<testing_strategy>

<current_state>
<framework>testthat (listed as Suggests in DESCRIPTION)</framework>
<runner>tests/testthat.R (standard testthat runner)</runner>
<helper>tests/testthat/helper.R (test setup)</helper>
<fixtures>tests/testthat/fixtures/ (test data files)</fixtures>
<test_count>16 test files</test_count>
</current_state>

<existing_tests>
<test_group name="Report Generation" files="7">
test-makeReport_diagnosticPlotsNLLS.R
test-makeReport_drainageAreaErrorsPlot.R
test_makeReport_header.R
test-makeReport_modelEstPerf.R
test-makeReport_modelSimPerf.R
test-makeReport_outputMaps.R
test-makeReport_residMaps.R
Note: These test Rmd report rendering, not core modeling logic. The makeReport_* functions
remain in R/ but are candidates for removal. If reports are removed for CRAN, these tests
become irrelevant.
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
NO tests for: hydseq, hydseqTerm, upstream, accumulateIncrArea, sumIncremAttributes.
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
