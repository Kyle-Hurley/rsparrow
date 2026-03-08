<plan id="06F" label="Exported API Tests" status="complete" blocked_by="06A">

<objective>
Write tests for all 13 exported functions using the make_mock_rsparrow() helper and
temporary directories. These tests do NOT require running the full NLLS optimizer or even
a compiled package — they use the mock rsparrow object and test argument validation,
S3 dispatch, return types, and error handling. This makes them suitable for all platforms
including systems without gfortran.
</objective>

<reference_documents>
  docs/plans/PLAN_06_TEST_SUITE.md
  docs/implementation/PLAN_06_SYNTHETIC_DATASET.md (make_mock_rsparrow() spec)
  docs/api/S3_CLASS_DESIGN.md (if it exists)
  RSPARROW_master/R/rsparrow_hydseq.R
  RSPARROW_master/R/read_sparrow_data.R
  RSPARROW_master/R/print.rsparrow.R
  RSPARROW_master/R/summary.rsparrow.R
  RSPARROW_master/R/coef.rsparrow.R
  RSPARROW_master/R/residuals.rsparrow.R
  RSPARROW_master/R/vcov.rsparrow.R
  RSPARROW_master/R/plot.rsparrow.R
  RSPARROW_master/R/rsparrow_bootstrap.R
  RSPARROW_master/R/rsparrow_scenario.R
  RSPARROW_master/R/rsparrow_validate.R
  RSPARROW_master/R/rsparrow_model.R
</reference_documents>

<tasks>

<task id="06F-1" status="complete">
<subject>Write test-rsparrow-hydseq.R — exported hydseq function</subject>
<description>
File: tests/testthat/test-rsparrow-hydseq.R

rsparrow_hydseq() is the only exported function that does NOT require a fitted rsparrow model.
These tests mirror Plan 06B's internal hydseq tests but exercise the exported public API.
Most of this logic was already covered in Plan 06B (Test 5-7 in test-hydseq.R). This file
adds CRAN-facing export verification and documents the public API contract.

Test 1: "rsparrow_hydseq is exported and callable without model object"
  expect: exists("rsparrow_hydseq")
  expect: is.function(rsparrow_hydseq)
  expect: "from_col" %in% names(formals(rsparrow_hydseq))

Test 2: "rsparrow_hydseq returns data.frame with hydseq column"
  network &lt;- data.frame(waterid=1:3, fnode=c(1,2,3), tnode=c(2,3,99))
  result &lt;- rsparrow_hydseq(network)
  expect: is.data.frame(result)
  expect: "hydseq" %in% names(result)
  expect: nrow(result) == 3L

Test 3: "rsparrow_hydseq accepts custom column names via from_col/to_col"
  network &lt;- data.frame(waterid=1:3, upstream=c(1,2,3), downstream=c(2,3,99))
  result &lt;- rsparrow_hydseq(network, from_col="upstream", to_col="downstream")
  expect: is.data.frame(result)
  expect: "hydseq" %in% names(result)
  # Original column names preserved:
  expect: "upstream" %in% names(result)
  expect: "downstream" %in% names(result)

Test 4: "rsparrow_hydseq stops with informative error for non-data.frame input"
  expect_error(rsparrow_hydseq(list(fnode=1, tnode=2, waterid=1)))

Test 5: "rsparrow_hydseq stops when from_col not found in data"
  expect_error(rsparrow_hydseq(data.frame(waterid=1L, fnode=1L, tnode=99L), from_col="x"))

Test 6: "rsparrow_hydseq stops when waterid column missing"
  expect_error(rsparrow_hydseq(data.frame(fnode=1L, tnode=99L)))
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-rsparrow-hydseq.R</files_modified>
<success_criteria>
  - 6 tests pass
  - No Fortran dependency
  - All error messages are informative (contain relevant variable names)
</success_criteria>
</task>

<task id="06F-2" status="complete">
<subject>Write test-read-sparrow-data.R — data reading function</subject>
<description>
File: tests/testthat/test-read-sparrow-data.R

read_sparrow_data() reads the four CSV control files (data1.csv, parameters.csv,
design_matrix.csv, dataDictionary.csv) from a directory. Tests use temporary directories
with minimal valid CSV content to avoid relying on UserTutorial files.

Before writing: Read read_sparrow_data.R and read_dataDictionary.R to confirm:
  - Exact argument names (path_main? path_results? run_id?)
  - Required CSV column names for each file
  - What the function returns (file.output.list? list of data objects?)
  - Whether it copies dataDictionary.csv with run_id prefix (from Plan 04D-2 notes:
    "dataDictionary.csv copied with run_id prefix before read_dataDictionary() is called")

Test setup helper:
  make_minimal_sparrow_dir &lt;- function() {
    td &lt;- tempfile()
    dir.create(td)
    # Write minimal parameters.csv
    write.csv(data.frame(sparrowNames="s1", parmType="SOURCE", parmInit=1, parmMin=0,
                         parmMax=10, parmCorrGroup=1L, parmConstant=0L),
              file.path(td, "run1_parameters.csv"), row.names=FALSE)
    # Write minimal design_matrix.csv
    write.csv(data.frame(s1=1L), file.path(td, "run1_design_matrix.csv"), row.names=FALSE)
    # Write minimal dataDictionary.csv
    write.csv(data.frame(sparrowNames=c("waterid","fnode","tnode"),
                         data1UserNames=c("waterid","fnode","tnode"),
                         varType=c("integer","integer","integer")),
              file.path(td, paste0("run1_dataDictionary.csv")), row.names=FALSE)
    # Write minimal data1.csv
    write.csv(data.frame(waterid=1:3, fnode=c(1,2,3), tnode=c(2,3,99)),
              file.path(td, "data1.csv"), row.names=FALSE)
    td
  }

Adjust CSV content to match the actual column requirements in read_sparrow_data.R.

Test 1: "read_sparrow_data returns a list"
  td &lt;- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive=TRUE))
  result &lt;- read_sparrow_data(path_main=td, run_id="run1")
  expect: is.list(result)

Test 2: "read_sparrow_data result contains file.output.list with path info"
  expect_names_present(result, c("file.output.list"))
  OR expect "path_results" in names(result) — verify actual structure from source.

Test 3: "read_sparrow_data stops with clear error if path_main does not exist"
  expect_error(read_sparrow_data(path_main="/nonexistent/path", run_id="run1"),
               regexp="does not exist|not found|path_main")

Test 4: "read_sparrow_data stops with clear error if parameters.csv is missing"
  td &lt;- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive=TRUE))
  file.remove(file.path(td, "run1_parameters.csv"))  # or whatever the expected name is
  expect_error(read_sparrow_data(path_main=td, run_id="run1"))

Test 5: "read_sparrow_data creates run_id-prefixed dataDictionary.csv copy"
  (Per Plan 04D-2: dataDictionary is copied with run_id prefix before reading.)
  td &lt;- make_minimal_sparrow_dir()
  on.exit(unlink(td, recursive=TRUE))
  read_sparrow_data(path_main=td, run_id="run1")
  expected_copy &lt;- file.path(td, "run1_dataDictionary.csv")
  expect: file.exists(expected_copy)   # copy should be created
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-read-sparrow-data.R</files_modified>
<success_criteria>
  - 5 tests pass (or as many as valid given actual read_sparrow_data implementation)
  - Tests clean up temp directories via on.exit()
  - No reliance on UserTutorial data
</success_criteria>
<notes>
The minimal CSV content must match the exact column names expected by read_sparrow_data.
Read the source file carefully before writing test setup code. If the function requires
many mandatory columns, the make_minimal_sparrow_dir() helper will need to be more complete.
This is the most implementation-sensitive test in Plan 06F.
</notes>
</task>

<task id="06F-3" status="complete">
<subject>Write test-s3-methods.R — print, summary, coef, residuals, vcov</subject>
<description>
File: tests/testthat/test-s3-methods.R

Tests for S3 methods on the rsparrow class. All use make_mock_rsparrow() from helper.R.
These tests do NOT require a compiled model run.

mod &lt;- make_mock_rsparrow()

Test 1: "print.rsparrow returns invisibly without error"
  expect_silent(capture.output(print(mod)))
  # OR: expect that print.rsparrow returns invisibly
  result &lt;- print(mod)
  expect: is.null(result) || identical(result, mod)  # invisible return

Test 2: "print.rsparrow output contains coefficient names"
  output &lt;- capture.output(print(mod))
  expect: any(grepl("beta_s1", output))  # check a coefficient name appears

Test 3: "summary.rsparrow returns a summary object"
  s &lt;- summary(mod)
  expect: inherits(s, "summary.rsparrow")
  expect: is.list(s) || !is.null(s)

Test 4: "summary.rsparrow contains model statistics"
  s &lt;- summary(mod)
  # Should contain R2, RMSE, npar, nobs from fit_stats
  output &lt;- capture.output(print(s))
  expect: any(grepl("R2|R-squared|RMSE", output, ignore.case=TRUE))

Test 5: "coef.rsparrow returns named numeric vector"
  result &lt;- coef(mod)
  expect: is.numeric(result)
  expect: !is.null(names(result))
  expect: identical(result, mod$coefficients)

Test 6: "coef.rsparrow coefficient names match Parmnames"
  result &lt;- coef(mod)
  expect: identical(names(result), c("beta_s1", "beta_d1", "beta_k1"))

Test 7: "residuals.rsparrow returns numeric vector"
  result &lt;- residuals(mod)
  expect: is.numeric(result)
  expect: length(result) >= 1L

Test 8: "vcov.rsparrow returns NULL when no Hessian computed"
  # mock object has vcov=NULL (ifHess="no")
  result &lt;- vcov(mod)
  expect: is.null(result)

Test 9: "vcov.rsparrow returns matrix when Hessian available"
  mod_with_vcov &lt;- make_mock_rsparrow()
  n &lt;- length(mod_with_vcov$coefficients)
  mod_with_vcov$vcov &lt;- diag(n)  # 3x3 identity
  result &lt;- vcov(mod_with_vcov)
  expect: is.matrix(result)
  expect: nrow(result) == n &amp;&amp; ncol(result) == n

Test 10: "print.rsparrow does not modify the object"
  mod2 &lt;- make_mock_rsparrow()
  before &lt;- mod2$coefficients
  print(mod2)
  expect_identical(mod2$coefficients, before)

Test 11: "S3 dispatch is correct — methods are called for rsparrow class"
  expect: isS3method("print", "rsparrow")
  expect: isS3method("summary", "rsparrow")
  expect: isS3method("coef", "rsparrow")
  expect: isS3method("residuals", "rsparrow")
  expect: isS3method("vcov", "rsparrow")
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-s3-methods.R</files_modified>
<success_criteria>
  - 11 tests pass
  - No Fortran dependency; no CSV file I/O
  - All S3 methods dispatch correctly
  - vcov=NULL and vcov=matrix cases both handled
</success_criteria>
</task>

<task id="06F-4" status="complete">
<subject>Write test-plot-rsparrow.R — plot S3 method</subject>
<description>
File: tests/testthat/test-plot-rsparrow.R

plot.rsparrow() dispatches to one of three internal functions based on the `type=` argument:
  "residuals" → .rsparrow_plot_residuals() → diagnosticPlots_4panel_A/B
  "sensitivity" → .rsparrow_plot_sensitivity() → diagnosticSensitivity()
  "spatial" → .rsparrow_plot_spatial() → diagnosticSpatialAutoCorr()

The mock rsparrow object does not have the full data needed to run diagnostics. These tests
focus on argument validation and dispatch structure, not on plot correctness.

Test 1: "plot.rsparrow exists and is an S3 method"
  expect: isS3method("plot", "rsparrow")

Test 2: "plot.rsparrow stops with informative error for invalid type"
  mod &lt;- make_mock_rsparrow()
  expect_error(plot(mod, type="invalid_type"),
               regexp="type|residuals|sensitivity|spatial")

Test 3: "plot.rsparrow default type is 'residuals'"
  # If mod$data$DataMatrix.list is NULL, calling plot.residuals will error.
  # Verify that the error comes from within the diagnostic function (not arg parsing).
  mod &lt;- make_mock_rsparrow()
  err &lt;- tryCatch(plot(mod, type="residuals"), error = function(e) e)
  # The error should NOT be "invalid type" but rather a data-missing error
  expect: !grepl("invalid|type", conditionMessage(err), ignore.case=TRUE) ||
           is.null(err)  # if plot succeeds with NULL data, also acceptable

Test 4: "plot.rsparrow accepts type='sensitivity' without 'invalid type' error"
  Same pattern as Test 3 but for type="sensitivity".

Test 5: "plot.rsparrow accepts type='spatial' without 'invalid type' error"
  Same pattern as Test 3 but for type="spatial".

Test 6: "plot.rsparrow `...` are passed through to diagnostic function"
  Test that additional arguments in ... don't cause immediate errors in dispatch logic.
  mod &lt;- make_mock_rsparrow()
  # Calling with an unrecognized arg should not error at the dispatch level
  # (The error would only come from the downstream diagnostic function)
  err &lt;- tryCatch(plot(mod, type="residuals", unknown_arg=TRUE), error=function(e) e)
  expect: !grepl("unused argument.*unknown_arg", conditionMessage(err)) ||
           is.null(err)
  # This verifies ... are forwarded, not consumed at dispatch
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-plot-rsparrow.R</files_modified>
<success_criteria>
  - 6 tests pass
  - Invalid type argument produces clear error mentioning valid types
  - Valid types pass through dispatch without "invalid type" errors
  - No dependency on compiled Fortran or full model output
</success_criteria>
</task>

<task id="06F-5" status="complete">
<subject>Write test-rsparrow-wrappers.R — bootstrap, validate, scenario arg validation</subject>
<description>
File: tests/testthat/test-rsparrow-wrappers.R

rsparrow_bootstrap(), rsparrow_validate(), and rsparrow_scenario() are exported wrappers
around internal functions. They accept an rsparrow object and additional arguments.
Since running these on a mock object would fail at the internal function call level
(mock object lacks real DataMatrix.list etc.), these tests focus on:
  1. Argument validation (do functions check their required inputs correctly?)
  2. Function signatures match the documented API
  3. Error messages are informative when called with wrong argument types

Test 1: "rsparrow_bootstrap has correct formal arguments"
  args &lt;- names(formals(rsparrow_bootstrap))
  expect: "model" %in% args OR "object" %in% args  # verify arg name
  expect: "biters" %in% args   # bootstrap iterations
  expect: "iseed" %in% args OR "seed" %in% args  # RNG seed for reproducibility

Test 2: "rsparrow_bootstrap stops with informative error for non-rsparrow input"
  expect_error(rsparrow_bootstrap(list()), regexp="rsparrow|class")
  # Should check class(model) == "rsparrow"

Test 3: "rsparrow_bootstrap seed argument provides reproducibility (documented behavior)"
  # This test is skipped unless we have a fully fitted model.
  # Document the intended contract without executing:
  # Calling rsparrow_bootstrap(model, seed=42) twice should give identical bootstrap results.
  skip("reproducibility test requires fitted model — covered in integration tests")

Test 4: "rsparrow_validate has correct formal arguments"
  args &lt;- names(formals(rsparrow_validate))
  expect: "model" %in% args OR "object" %in% args

Test 5: "rsparrow_validate stops with informative error for non-rsparrow input"
  expect_error(rsparrow_validate(list()), regexp="rsparrow|class")

Test 6: "rsparrow_validate stops with informative error when model has no validation sites"
  mod &lt;- make_mock_rsparrow()  # mock has Vsites.list=NULL (no validation)
  # Expect an error stating validation requires if_validate="yes" at estimation time
  err &lt;- tryCatch(rsparrow_validate(mod), error=function(e) e)
  expect: !is.null(err)
  expect: grepl("validat|Vsites|if_validate", conditionMessage(err), ignore.case=TRUE)

Test 7: "rsparrow_scenario has correct formal arguments"
  args &lt;- names(formals(rsparrow_scenario))
  expect: "model" %in% args OR "object" %in% args
  expect: "source_changes" %in% args   # from Plan 04D-4 notes

Test 8: "rsparrow_scenario stops with informative error for non-rsparrow input"
  expect_error(rsparrow_scenario(list(), source_changes=list()), regexp="rsparrow|class")

Test 9: "rsparrow_model has correct formal arguments"
  args &lt;- names(formals(rsparrow_model))
  expect: "path_main" %in% args
  expect: "run_id" %in% args
  expect: "model_type" %in% args
  expect: "if_estimate" %in% args
  expect: "if_predict" %in% args
  expect: "if_validate" %in% args

Test 10: "rsparrow_model stops with clear error for non-existent path_main"
  expect_error(rsparrow_model("/nonexistent/path"), regexp="exist|path_main")

Test 11: "rsparrow_model model_type argument is validated"
  # model_type must be "static" or "dynamic"
  td &lt;- tempdir()
  expect_error(rsparrow_model(td, model_type="invalid"),
               regexp="model_type|static|dynamic|arg")
</description>
<files_modified>CREATE: RSPARROW_master/tests/testthat/test-rsparrow-wrappers.R</files_modified>
<success_criteria>
  - 10 tests pass (test 3 is skipped)
  - All three wrappers verify rsparrow class at entry
  - rsparrow_validate correctly detects missing Vsites.list
  - rsparrow_model validates path_main and model_type
  - No compiled Fortran required
</success_criteria>
</task>

</tasks>

<notes>
- make_mock_rsparrow() in helper.R must be complete before any of these tests run.
  All tests depend on Plan 06A completing task 06A-3.
- The read_sparrow_data tests (06F-2) are the most brittle — they depend on the exact
  CSV file structure and naming conventions. Read the source file before writing.
  If the function is substantially different from the documentation, update the test.
- For plot.rsparrow tests: the goal is NOT to test that diagnostic plots render correctly,
  but that the dispatch logic works and invalid types are rejected. Rendering tests require
  a fully fitted model and are integration-test territory.
- Argument name verification tests (Test 1, 4, 7, 9) guard against accidental signature
  changes. If a formal argument name changes, it's a breaking API change.
</notes>

<success_criteria>
<criterion>test-rsparrow-hydseq.R: 6 tests — exported API, custom column names, validation</criterion>
<criterion>test-read-sparrow-data.R: 5 tests — returns list, error handling, temp dir cleanup</criterion>
<criterion>test-s3-methods.R: 11 tests — all 5 S3 methods (print/summary/coef/residuals/vcov)</criterion>
<criterion>test-plot-rsparrow.R: 6 tests — dispatch validation, type checking</criterion>
<criterion>test-rsparrow-wrappers.R: 10 tests (1 skipped) — all wrapper signatures verified</criterion>
<criterion>All 38 tests run in under 10 seconds without Fortran</criterion>
<criterion>Zero tests rely on UserTutorial data or external files</criterion>
</success_criteria>

<failure_criteria>
<criterion>isS3method() returns FALSE for any of the 7 exported S3 methods</criterion>
<criterion>Invalid type= to plot.rsparrow does not produce an error</criterion>
<criterion>rsparrow_bootstrap or rsparrow_validate accept non-rsparrow objects without error</criterion>
<criterion>Temp directories not cleaned up (tests leave files on disk)</criterion>
</failure_criteria>

<estimated_test_count>38 new tests (1 skipped)</estimated_test_count>
<estimated_runtime>~5 seconds total</estimated_runtime>

</plan>
