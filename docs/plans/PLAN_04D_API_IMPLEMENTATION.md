<plan id="04-D">
<name>Exported API Implementation and Final Verification</name>
<part_of>Plan 04: State Elimination and Skeleton Implementation — tasks 8-13 of 13</part_of>
<previous_plans>04-A (tasks 1-3), 04-B (tasks 4-5), 04-C (tasks 6-7)</previous_plans>

<context>
Plans 04-A through 04-C complete:
  - 0 assign(.GlobalEnv) anywhere in RSPARROW_master/R/
  - 0 shell.exec / batch_mode references
  - Specification-string eval(parse()) eliminated from all 7 core math files
  - unPackList() removed from all 36 core estimation and data-prep files
  - startModelRun() returns sparrow_state (named list)
  - controlFileTasksModel() returns list(runTimes, results)
This plan implements all 12 exported function stubs and runs final R CMD check.
</context>

<prerequisites>
- Plans 04-A, 04-B, 04-C all complete and verified
- R CMD check: 0 errors before starting
- Confirm stubs: grep -r "Not yet implemented" RSPARROW_master/R/ → shows 12 files
</prerequisites>

<reference_documents>
Read before starting:
  docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md  rsparrow S3 structure, all pseudocode
  docs/PLAN_04_FILE_INVENTORY.md            task_files id="8_to_12"
</reference_documents>

<verify_field_names label="Run these greps before writing any code">
The skeleton implementations reference estimate.list fields by name. Verify actual
names in the refactored estimate.R before coding rsparrow_model() or predict.rsparrow():
  grep -n "estimate\.list\$" RSPARROW_master/R/estimate.R | head -40
  grep -n "\$JacobResults" RSPARROW_master/R/estimateNLLSmetrics.R | head -20
  grep -n "oEstimate\|Parmnames\|Residuals\|Pload_meas" RSPARROW_master/R/estimate.R
</verify_field_names>

<remove_list>
Do NOT modify any of these 25 files — Plan 05 deletes them:
  diagnosticMaps.R, predictMaps.R, predictMaps_single.R, mapSiteAttributes.R,
  create_diagnosticPlotList.R, mapLoopStr.R, plotlyLayout.R, addMarkerText.R,
  aggDynamicMapdata.R, mapBreaks.R, modelCompare.R, outputSettings.R,
  diagnosticPlotsNLLS.R, diagnosticPlotsNLLS_dyn.R, diagnosticPlotsValidate.R,
  make_residMaps.R, make_dyndiagnosticPlotsNLLS.R, make_dyndiagnosticPlotsNLLS_corrPlots.R,
  make_dyndiagnosticPlotsNLLS_sensPlots.R, make_drainageAreaErrorsPlot.R,
  make_drainageAreaErrorsMaps.R, make_diagnosticPlotsNLLS_timeSeries.R,
  make_modelEstPerfPlots.R, make_modelSimPerfPlots.R, make_siteAttrMaps.R
</remove_list>

<rsparrow_object_structure label="S3 object layout — all exported functions use this">
  $call           — match.call() from rsparrow_model()
  $coefficients   — named numeric; names=Parmnames, values=oEstimate
  $std_errors     — named numeric; from JacobResults$Jacobse
  $vcov           — numeric matrix; from JacobResults$covar
  $residuals      — numeric vector; from estimate.list$Residuals
  $fitted_values  — numeric vector; from estimate.list$Pload_meas
  $fit_stats      — list: R2, RMSE, npar, nobs, convergence (logical)
  $data           — list: subdata, sitedata, vsitedata, DataMatrix.list,
                          SelParmValues, dlvdsgn, Csites.weights.list,
                          estimate.input.list, scenario.input.list, file.output.list
  $predictions    — NULL initially; populated by predict.rsparrow()
  $bootstrap      — NULL initially; populated by rsparrow_bootstrap()
  $validation     — NULL initially; populated by rsparrow_validate()
  $metadata       — list: version, timestamp, run_id, model_type, path_main
Note: Csites.weights.list must be stored in $data — it is required by
rsparrow_bootstrap() and rsparrow_validate() but is NOT in estimate.list.
</rsparrow_object_structure>

<scope>
<in_scope>
- Task  8: Implement S3 method bodies: print, summary, coef, residuals, vcov, plot
- Task  9: Implement rsparrow_model() — main entry point
- Task 10: Implement read_sparrow_data()
- Task 11: Implement rsparrow_bootstrap(), rsparrow_scenario(), rsparrow_validate()
- Task 12: Implement predict.rsparrow() + object_to_estimate_list() helper
- Task 13: Final R CMD check --as-cran
</in_scope>
<out_of_scope>
- Diagnostic plot implementation in plot.rsparrow() — deferred to Plan 05
- Full logical TRUE/FALSE conversion for "yes"/"no" strings — Plan 05
- Function consolidation (predict/predictBoot/predictScenarios merge) — Plan 05
- Test suite — Plan 06
</out_of_scope>
</scope>

<tasks>

<task id="8" priority="high" status="COMPLETE">
<name>Implement S3 method bodies</name>
<files>
  print.rsparrow.R, summary.rsparrow.R, coef.rsparrow.R,
  residuals.rsparrow.R, vcov.rsparrow.R, plot.rsparrow.R
</files>
<description>
Replace stop("Not yet implemented") in each file. Full pseudocode is in
docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md under implementation name="S3_methods".
Key implementations:
  print.rsparrow    → cat model summary (run_id, type, R2, RMSE, coef table)
  summary.rsparrow  → returns summary.rsparrow object with coef_table (t/p values) + fit_stats
                      also implement print.summary.rsparrow
  coef.rsparrow     → object$coefficients
  residuals.rsparrow → object$residuals
  vcov.rsparrow     → object$vcov
  plot.rsparrow     → stop() with informative message (diagnostics deferred to Plan 05)
</description>
<null_coalescing label="Add to rsparrow-package.R before Task 11">
  `%||%` <- function(a, b) if (!is.null(a)) a else b
This operator is used in rsparrow_bootstrap() and rsparrow_validate().
</null_coalescing>
<verification label="Use mock object — no real data needed">
From docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md: copy the mock_rsparrow scaffold and run:
  print(mock_rsparrow)
  summary(mock_rsparrow)
  coef(mock_rsparrow)
  residuals(mock_rsparrow)
  vcov(mock_rsparrow)
All must execute without error.
</verification>
<success>No stop("Not yet implemented") remains in any of the 6 files.</success>
</task>

<task id="10" priority="high" status="COMPLETE">
<name>Implement read_sparrow_data()</name>
<files>read_sparrow_data.R</files>
<description>
Validates path_main, checks for required CSVs, constructs file.output.list,
calls read_dataDictionary() and readData() to return a named list.
Full pseudocode in docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md under implementation name="read_sparrow_data".
</description>
<note>
betavalues and dmatrixin are NOT read here — they depend on estimation settings
that belong to startModelRun(). read_sparrow_data() reads only the data and control files.
The file.output.list structure may need to grow once startModelRun() is wired up in Task 9.
</note>
<success>No stop("Not yet implemented") remains in the file.</success>
</task>

<task id="9" priority="critical" status="COMPLETE">
<name>Implement rsparrow_model() — main entry point</name>
<files>rsparrow_model.R</files>
<description>
Implemented in Plan 04D-3. Key architectural discovery: startModelRun() already calls
controlFileTasksModel() internally — rsparrow_model() calls only startModelRun().
One-line addition to startModelRun.R (line 484) exposes estimate.list in sparrow_state:
  sparrow_state$estimate.list &lt;- estimate.list

Verified estimate.list field names (plan pseudocode was wrong):
  estimate.list$JacobResults$oEstimate  (not oEstimate at top level)
  estimate.list$JacobResults$Parmnames
  estimate.list$JacobResults$oSEj       (not Jacobse)
  estimate.list$HesResults$cov2         (not JacobResults$covar)
  estimate.list$Mdiagnostics.list$Resids   (not estimate.list$Residuals)
  estimate.list$Mdiagnostics.list$predict  (not Pload_meas)
  estimate.list$ANOVA.list$RSQ          (not JacobResults$R2)
  estimate.list$ANOVA.list$RMSE         (not JacobResults$RMSE)

Csites.weights.list confirmed in sparrow_state$Csites.weights.list and stored
in rsparrow$data$Csites.weights.list for 04D-4 bootstrap/validate wrappers.

file.output.list must contain ALL settings from getCharSett/getNumSett/getYesNoSett/
getShortSett because outputSettings() calls unPackList then get(setting_name).
</description>
<yes_no_note>
Internal functions still use if_x == "yes" / "no" strings. Pass string values
("yes"/"no") from rsparrow_model() for now. Full logical conversion is Plan 05.
</yes_no_note>
<success>No stop("Not yet implemented") remains in the file.</success>
</task>

<task id="12" priority="critical">
<name>Implement predict.rsparrow() and object_to_estimate_list()</name>
<files>predict.rsparrow.R</files>
<description>
predict.rsparrow() calls predict_sparrow() (the internal function renamed from predict()
in Plan 03) with arguments extracted from the rsparrow object. Returns the updated object
with $predictions populated.

Also implement the object_to_estimate_list() helper in the same file (or a small
internal utils file) — it reconstructs the estimate.list structure from the rsparrow
S3 object fields for use by predict_sparrow(), estimateBootstraps(), and validateMetrics().

Full pseudocode in docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md under implementation name="predict.rsparrow".
</description>
<verify_predict_sparrow_signature>
Before implementing, verify predict_sparrow()'s argument names match what was
refactored in Plan 04-C:
  grep -n "^predict_sparrow <- function" RSPARROW_master/R/predict.R
</verify_predict_sparrow_signature>
<success>
  predict(mock_rsparrow)  # with mock spiking $data fields → returns rsparrow object
No stop("Not yet implemented") remains in the file.
</success>
</task>

<task id="11" priority="high">
<name>Implement rsparrow_bootstrap(), rsparrow_scenario(), rsparrow_validate()</name>
<files>rsparrow_bootstrap.R, rsparrow_scenario.R, rsparrow_validate.R</files>
<description>
Thin wrappers: validate the rsparrow input, call the internal function, store results
in model$bootstrap / model$predictions$scenarios / model$validation, return updated model.
Full pseudocode in docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md under respective names.

rsparrow_bootstrap:  calls estimateBootstraps(); requires Csites.weights.list from $data
rsparrow_scenario:   calls predictScenarios(); requires model$predictions to be populated
rsparrow_validate:   calls validateMetrics(); requires Csites.weights.list from $data

Verify the refactored signatures of the internal functions before wiring (Plans 04-B/C
may have changed them):
  grep -n "^estimateBootstraps <- function" RSPARROW_master/R/estimateBootstraps.R
  grep -n "^predictScenarios <- function"   RSPARROW_master/R/predictScenarios.R
  grep -n "^validateMetrics <- function"    RSPARROW_master/R/validateMetrics.R
</description>
<success>No stop("Not yet implemented") remains in any of the three files.</success>
</task>

<task id="13" priority="critical">
<name>Final verification</name>
<commands>
  R CMD build --no-build-vignettes RSPARROW_master/
  R CMD check --as-cran rsparrow_2.1.0.tar.gz
</commands>
<grep_checks label="All must return 0 results">
  grep -r "assign.*\.GlobalEnv"    RSPARROW_master/R/
  grep -r "shell\.exec\|Rscript\.exe" RSPARROW_master/R/
  grep -r "batch_mode"             RSPARROW_master/R/
  grep    "eval(parse"             RSPARROW_master/R/estimateFeval.R
  grep    "eval(parse"             RSPARROW_master/R/predict.R
  grep -r "Not yet implemented"    RSPARROW_master/R/
</grep_checks>
<s3_dispatch_check label="All must dispatch and return without error">
  library(rsparrow)
  mock_rsparrow <- structure(list(...), class = "rsparrow")  # scaffold from skeleton doc
  print(mock_rsparrow)
  summary(mock_rsparrow)
  coef(mock_rsparrow)
  residuals(mock_rsparrow)
  vcov(mock_rsparrow)
</s3_dispatch_check>
<success>0 errors, ≤1 warning, ≤1 note from R CMD check --as-cran</success>
</task>

</tasks>

<execution_order>
1. Task  8 — S3 methods (depends only on agreed rsparrow object structure; no internal calls)
             Add %||% to rsparrow-package.R before Task 11
2. Task 10 — read_sparrow_data() (depends only on read_dataDictionary, readData)
3. Task  9 — rsparrow_model() (depends on Tasks 8, 10, and refactored startModelRun)
4. Task 12 — predict.rsparrow() (depends on Task 9 for object structure clarity)
5. Task 11 — rsparrow_bootstrap/scenario/validate (depends on Task 12 for object_to_estimate_list)
6. Task 13 — Final verification (last; depends on all above)
</execution_order>

<risks>
<risk name="estimate_list_field_mismatch">
The pseudocode in PLAN_04_SKELETON_IMPLEMENTATIONS.md uses field names inferred from
grep. Actual names may differ from Plans 04-B/C edits. Always run the verify_field_names
greps above before coding rsparrow_model() or predict.rsparrow().
</risk>
<risk name="csites_weights_list_location">
Csites.weights.list is assigned in startModelRun.R (now sparrow_state$Csites.weights.list).
It is NOT in estimate.list. It must be stored in rsparrow$data$Csites.weights.list or
rsparrow_bootstrap() and rsparrow_validate() will fail with a missing argument error.
</risk>
<risk name="internal_function_signatures_changed">
Plans 04-B and 04-C will have modified the signatures of estimateBootstraps,
predictScenarios, validateMetrics, and predict_sparrow. Always grep the current
function signature before wiring up the skeleton wrappers.
</risk>
<risk name="yes_no_strings">
All internal functions still expect "yes"/"no" character strings for boolean flags.
Pass string values from the skeleton functions for now. Do not convert to TRUE/FALSE
(that is Plan 05 scope) — mixing the two will cause silent incorrect behavior.
</risk>
</risks>

<success_criteria>
- grep -r "Not yet implemented" RSPARROW_master/R/  → 0 results
- grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/  → 0 results
- grep -r "shell\.exec\|Rscript\.exe\|batch_mode" RSPARROW_master/R/  → 0 results
- grep "eval(parse" RSPARROW_master/R/estimateFeval.R  → 0 results
- print/summary/coef/residuals/vcov all dispatch correctly on rsparrow mock object
- R CMD check --as-cran: 0 errors, ≤1 warning, ≤1 note
</success_criteria>

<failure_criteria>
- Any exported function still calls stop("Not yet implemented") → plan incomplete
- R CMD check introduces new errors vs Plan 04-C baseline → fix before declaring done
- Any assign(.GlobalEnv) or shell.exec remains → earlier sub-plan incomplete; stop and fix
</failure_criteria>

</plan>
