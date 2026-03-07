<plan id="04-D-3">
<name>rsparrow_model() — Main Estimation Entry Point</name>
<part_of>Plan 04-D sub-session 3 of 4 — implements Task 9 from PLAN_04D_API_IMPLEMENTATION.md</part_of>
<previous_plans>04-A through 04-C, 04-D-1 (S3 methods), 04-D-2 (read_sparrow_data)</previous_plans>

<context>
This is the CRITICAL PATH sub-session. rsparrow_model() is the main public entry point
that orchestrates data reading, model estimation, and S3 object construction. It must:
  1. Call read_sparrow_data() (implemented in 04D-2)
  2. Call startModelRun() — captures sparrow_state (refactored in Plan 04A)
  3. Call controlFileTasksModel() — captures run_output (refactored in Plan 04A)
  4. Extract estimate.list from run_output
  5. Package everything into the rsparrow S3 object

HIGH COMPLEXITY. Risk of field name mismatches from Plans 04A/B/C refactors.
Multiple grep/read/debug cycles should be expected.
Expected context: ~100-150K tokens.

Key refactoring done in prior plans:
  Plan 04A: startModelRun() now returns sparrow_state named list (removed 27 GlobalEnv assigns)
  Plan 04A: controlFileTasksModel() now returns list(runTimes, results)
  Plan 04B: estimate.R no longer uses assign(.GlobalEnv); estimate.list is returned normally
  Plan 04C: unPackList removed from all non-REMOVE files
</context>

<prerequisites>
- Plans 04-A through 04-D-2 ALL complete and verified
- R CMD check: 0 errors before starting
- Confirm stub:
    grep -n "Not yet implemented" RSPARROW_master/R/rsparrow_model.R
- Confirm 04D-1 and 04D-2 complete:
    grep -n "Not yet implemented" RSPARROW_master/R/print.rsparrow.R    # 0 results
    grep -n "Not yet implemented" RSPARROW_master/R/read_sparrow_data.R # 0 results
</prerequisites>

<reference_documents>
Read before starting:
  docs/implementation/PLAN_04_SKELETON_IMPLEMENTATIONS.md  — implementation name="rsparrow_model"
  docs/plans/PLAN_04D_API_IMPLEMENTATION.md               — task id="9", rsparrow_object_structure
  RSPARROW_master/R/startModelRun.R                       — sparrow_state return structure
  RSPARROW_master/R/controlFileTasksModel.R               — run_output return structure
  RSPARROW_master/R/estimate.R                            — estimate.list field names
</reference_documents>

<verify_field_names label="CRITICAL — Run ALL of these before writing any code">
The estimate.list pseudocode uses field names inferred from earlier grep searches.
Actual names may differ from Plans 04A/B/C edits. Verify every name before coding:

  # 1. What does startModelRun() return?
  grep -n "sparrow_state\$" RSPARROW_master/R/startModelRun.R | head -40
  grep -n "return.*sparrow_state" RSPARROW_master/R/startModelRun.R

  # 2. What does controlFileTasksModel() return?
  grep -n "return\|list(runTimes\|results" RSPARROW_master/R/controlFileTasksModel.R | head -20

  # 3. What is in estimate.list?
  grep -n "estimate\.list\$" RSPARROW_master/R/estimate.R | head -40
  grep -n "estimate\.list\[" RSPARROW_master/R/estimate.R | head -20

  # 4. What fields does JacobResults have?
  grep -n "\$JacobResults\|JacobResults\$" RSPARROW_master/R/estimateNLLSmetrics.R | head -20

  # 5. Is Csites.weights.list in sparrow_state?
  grep -n "Csites\.weights\.list" RSPARROW_master/R/startModelRun.R | head -10

  # 6. What is the actual signature of startModelRun()?
  grep -n "^startModelRun <- function" RSPARROW_master/R/startModelRun.R
  head -40 RSPARROW_master/R/startModelRun.R

  # 7. What is the actual signature of controlFileTasksModel()?
  grep -n "^controlFileTasksModel <- function" RSPARROW_master/R/controlFileTasksModel.R
  head -40 RSPARROW_master/R/controlFileTasksModel.R
</verify_field_names>

<scope>
<in_scope>
- Task 9: Implement rsparrow_model() in RSPARROW_master/R/rsparrow_model.R
- Wire read_sparrow_data() → startModelRun() → controlFileTasksModel()
- Extract estimate.list from run_output (verify actual field path)
- Construct rsparrow S3 object with all fields from rsparrow_object_structure
- Include Csites.weights.list in $data (required by 04D-4's bootstrap/validate wrappers)
</in_scope>
<out_of_scope>
- predict.rsparrow(), rsparrow_bootstrap/scenario/validate — sub-session 04D-4
- Full logical TRUE/FALSE conversion for "yes"/"no" strings — Plan 05
- Function consolidation (predict/predictBoot/predictScenarios merge) — Plan 05
- Implementing or modifying startModelRun() or controlFileTasksModel()
</out_of_scope>
</scope>

<rsparrow_object_structure label="Build this in step 5 of rsparrow_model()">
  $call           = match.call()
  $coefficients   = stats::setNames(estimate_list$oEstimate, estimate_list$Parmnames)
  $std_errors     = estimate_list$JacobResults$Jacobse  [verify field name]
  $vcov           = estimate_list$JacobResults$covar    [verify field name]
  $residuals      = estimate_list$Residuals             [verify field name]
  $fitted_values  = estimate_list$Pload_meas            [verify field name]
  $fit_stats      = list(
      R2          = estimate_list$JacobResults$R2,      [verify]
      RMSE        = estimate_list$JacobResults$RMSE,    [verify]
      npar        = length(estimate_list$oEstimate),
      nobs        = nrow(sparrow_state$sitedata),
      convergence = isTRUE(estimate_list$convergence)
  )
  $data = list(
      subdata             = sparrow_state$subdata,
      sitedata            = sparrow_state$sitedata,
      vsitedata           = sparrow_state$vsitedata,
      DataMatrix.list     = sparrow_state$DataMatrix.list,
      SelParmValues       = sparrow_state$SelParmValues,
      dlvdsgn             = sparrow_state$dlvdsgn,
      Csites.weights.list = sparrow_state$Csites.weights.list,  [CRITICAL — verify location]
      estimate.input.list = sparrow_state$estimate.input.list,
      scenario.input.list = sparrow_state$scenario.input.list,
      file.output.list    = sparrow_state$file.output.list
  )
  $predictions    = run_output$results$predict_list   [verify field path]
  $bootstrap      = NULL
  $validation     = NULL
  $metadata = list(
      version    = utils::packageVersion("rsparrow"),
      timestamp  = Sys.time(),
      run_id     = run_id,
      model_type = model_type,
      path_main  = path_main
  )
  class = "rsparrow"
</rsparrow_object_structure>

<tasks>

<task id="9a" priority="critical">
<name>Verify all field names before coding</name>
<description>
Run all greps listed in verify_field_names above. Record the actual field names found.
Common mismatches to watch for:
  - estimate.list$oEstimate may be named estimate.list$ovals or similar
  - JacobResults fields (Jacobse, covar, R2, RMSE) may be spelled differently
  - sparrow_state$vsitedata may not exist if if_validate=FALSE was assumed
  - Csites.weights.list may NOT be in sparrow_state if Plan 04A stored it differently
  - predict_list location in run_output may differ (run_output$results vs run_output$predict_list)

Document the verified field names here before implementing Task 9b.
</description>
<success>All field names confirmed from live source code; pseudocode field names updated.</success>
</task>

<task id="9b" priority="critical">
<name>Implement rsparrow_model()</name>
<file>RSPARROW_master/R/rsparrow_model.R</file>
<description>
Replace stop("Not yet implemented") with the implementation. Use field names verified in 9a.
Pseudocode (adjust to actual signatures):

  rsparrow_model <- function(path_main, run_id = "run1", model_type = "static", ...) {
    # Input validation
    stopifnot(is.character(path_main), length(path_main) == 1)
    if (!dir.exists(path_main)) stop("path_main does not exist: ", path_main)
    model_type <- match.arg(model_type, c("static", "dynamic"))

    # Step 1: Read data files
    sparrow_data <- read_sparrow_data(path_main, run_id = run_id)

    # Step 2: Data preparation and calibration setup
    # startModelRun() returns sparrow_state (after Plan 04A refactoring)
    # IMPORTANT: pass "yes"/"no" strings, not TRUE/FALSE (Plan 05 converts these)
    sparrow_state <- startModelRun(
      file.output.list       = sparrow_data$file.output.list,
      if_estimate            = "yes",
      if_estimate_simulation = "no",
      if_boot_estimate       = "no",
      if_boot_predict        = "no",
      data1                  = sparrow_data$data1,
      data_names             = sparrow_data$data_names,
      if_userModifyData      = "no",
      if_predict             = "yes",
      if_validate            = "no",
      ...
    )

    # Step 3: Run estimation and prediction
    # controlFileTasksModel() returns list(runTimes, results) (after Plan 04A refactoring)
    run_output <- controlFileTasksModel(
      sparrow_state  = sparrow_state,
      if_estimate    = "yes",
      if_predict     = "yes",
      if_validate    = "no",
      ...
    )

    # Step 4: Extract estimate.list from results
    # ADJUST this field path based on verified field names from task 9a
    estimate_list <- run_output$results$estimate_list

    # Step 5: Construct rsparrow S3 object
    structure(
      list(
        call          = match.call(),
        coefficients  = stats::setNames(estimate_list$oEstimate, estimate_list$Parmnames),
        std_errors    = estimate_list$JacobResults$Jacobse,
        vcov          = estimate_list$JacobResults$covar,
        residuals     = estimate_list$Residuals,
        fitted_values = estimate_list$Pload_meas,
        fit_stats = list(
          R2          = estimate_list$JacobResults$R2,
          RMSE        = estimate_list$JacobResults$RMSE,
          npar        = length(estimate_list$oEstimate),
          nobs        = nrow(sparrow_state$sitedata),
          convergence = isTRUE(estimate_list$convergence)
        ),
        data = list(
          subdata             = sparrow_state$subdata,
          sitedata            = sparrow_state$sitedata,
          vsitedata           = sparrow_state$vsitedata,
          DataMatrix.list     = sparrow_state$DataMatrix.list,
          SelParmValues       = sparrow_state$SelParmValues,
          dlvdsgn             = sparrow_state$dlvdsgn,
          Csites.weights.list = sparrow_state$Csites.weights.list,
          estimate.input.list = sparrow_state$estimate.input.list,
          scenario.input.list = sparrow_state$scenario.input.list,
          file.output.list    = sparrow_state$file.output.list
        ),
        predictions = run_output$results$predict_list,
        bootstrap   = NULL,
        validation  = NULL,
        metadata = list(
          version    = utils::packageVersion("rsparrow"),
          timestamp  = Sys.time(),
          run_id     = run_id,
          model_type = model_type,
          path_main  = path_main
        )
      ),
      class = "rsparrow"
    )
  }
</description>
<yes_no_note>
Internal functions (startModelRun, controlFileTasksModel, estimate, estimateBootstraps, etc.)
still expect "yes"/"no" character strings for boolean flags (e.g., if_estimate == "yes").
Pass string values from rsparrow_model() for now. Do NOT convert to TRUE/FALSE —
mixing the two causes silent incorrect behavior. Full logical conversion is Plan 05.
</yes_no_note>
<note>
Keep @examples wrapped in \dontrun{} in the roxygen doc — real CSV files are required.
If startModelRun()'s signature requires additional required arguments not listed above,
add them with their legacy default values from sparrow_control.R in UserTutorial/.
</note>
<success>
- No stop("Not yet implemented") in file
- rsparrow_model(UserTutorial_path) returns an object of class "rsparrow"
- print(model) and summary(model) work on the returned object
</success>
</task>

</tasks>

<verification label="Use UserTutorial as integration test">
After implementing, test with the example project (adjust path):

  library(rsparrow)
  model <- rsparrow_model("/path/to/UserTutorial")
  class(model)        # should be "rsparrow"
  print(model)        # should dispatch to print.rsparrow (from 04D-1)
  summary(model)      # should dispatch to summary.rsparrow (from 04D-1)
  coef(model)         # should return named numeric vector of estimated parameters
  names(model$data)   # should include: subdata, sitedata, DataMatrix.list, Csites.weights.list

<grep_checks label="Must return 0 results">
  grep -n "Not yet implemented" RSPARROW_master/R/rsparrow_model.R
</grep_checks>
<build_check>
  R CMD build --no-build-vignettes RSPARROW_master/
  R CMD check rsparrow_2.1.0.tar.gz
  # Must produce 0 new errors vs 04D-2 baseline
</build_check>
</verification>

<risks>
<risk name="estimate_list_field_mismatch" severity="HIGH">
The pseudocode field names (oEstimate, Parmnames, Residuals, Pload_meas, JacobResults,
convergence) are inferred from grep searches on estimate.R. Plans 04A/B may have renamed
or reorganised these. ALWAYS run verify_field_names greps before coding task 9b.
Mitigation: grep -n "estimate\.list\$\|estimate\.list\[" RSPARROW_master/R/estimate.R
</risk>
<risk name="csites_weights_list_location" severity="HIGH">
Csites.weights.list is assigned in startModelRun.R (sparrow_state$Csites.weights.list
after Plan 04A). It is NOT in estimate.list. If it is missing from sparrow_state,
rsparrow_bootstrap() and rsparrow_validate() (04D-4) will fail with missing argument.
Verify: grep -n "Csites\.weights\.list" RSPARROW_master/R/startModelRun.R
</risk>
<risk name="startModelRun_signature_changed" severity="MEDIUM">
Plan 04A significantly refactored startModelRun.R. Its current signature may require
different or additional arguments. Check the actual function head before calling it.
Mitigation: head -50 RSPARROW_master/R/startModelRun.R
</risk>
<risk name="vsitedata_null_when_no_validation" severity="LOW">
sparrow_state$vsitedata may not exist if if_validate="no". Use NULL as default:
  vsitedata = sparrow_state[["vsitedata"]]  # returns NULL if not present
</risk>
<risk name="predict_list_field_path_in_run_output" severity="MEDIUM">
run_output$results$predict_list is an assumed path. controlFileTasksModel() may store
predictions differently. Verify the return structure before coding.
Mitigation: grep -n "return\|predict_list" RSPARROW_master/R/controlFileTasksModel.R | tail -20
</risk>
</risks>

<success_criteria>
- grep -n "Not yet implemented" RSPARROW_master/R/rsparrow_model.R → 0 results
- rsparrow_model(UserTutorial_path) returns class "rsparrow" object without error
- print/summary/coef all dispatch correctly on returned object
- model$data$Csites.weights.list is not NULL (required for 04D-4)
- R CMD check introduces no new errors vs 04D-2 baseline
</success_criteria>

<failure_criteria>
- File still contains "Not yet implemented" → sub-session incomplete
- model$data$Csites.weights.list is NULL → bootstrap/validate will fail in 04D-4;
  trace Csites.weights.list through startModelRun.R and fix before proceeding
- Field name mismatches cause NULL coefficients or NULL residuals → re-run verify_field_names
- R CMD check introduces new errors → fix before proceeding to 04D-4
</failure_criteria>

<next_session>04D-4: predict.rsparrow + bootstrap/scenario/validate wrappers + final R CMD check</next_session>

</plan>
