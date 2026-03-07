<plan id="04-B" status="complete">
<name>Remaining Global Assigns and Specification-String eval/parse</name>
<part_of>Plan 04: State Elimination and Skeleton Implementation — tasks 4, 5 of 13</part_of>
<previous_plan>04-A (tasks 1-3: Windows removal + startModelRun/controlFileTasksModel)</previous_plan>
<next_plans>04-C (tasks 6-7), 04-D (tasks 8-13)</next_plans>

<completion_summary>
All tasks completed successfully. Results:
  - Task 4: Eliminated 23 assign(.GlobalEnv) from 13 files (zero remain in R/)
    Files: predict.R, correlationMatrix.R, diagnosticSensitivity.R, estimateWeightedErrors.R,
    setNLLSWeights.R, estimateBootstraps.R, predictBootstraps.R, predictScenarios.R,
    checkDrainageareaMapPrep.R, findMinMaxLatLon.R, replaceData1Names.R, dataInputPrep.R, estimate.R
  - Task 5: Replaced 21 specification-string eval(parse()) in 7 core math files
    Files: estimateFeval.R, estimateFevalNoadj.R, validateFevalNoadj.R, predict.R,
    predictBoot.R, predictSensitivity.R, predictScenarios.R
    Cleanup: getCharSett.R, getShortSett.R, estimateOptimize.R, predictSensitivity() signature,
    startModelRun.R dead extractions
  - Additional fix: stale predict() call in estimate.R → predict_sparrow() (missed in Plan 03)
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
  - Final counts: 0 assign(.GlobalEnv) in R/; ~318 eval(parse()) remain (dynamic column access)
</completion_summary>

<context>
Plan 04-A complete: startModelRun.R returns sparrow_state, controlFileTasksModel.R
returns list(runTimes, results), all Windows-only code removed.
This plan eliminates assign(.GlobalEnv) from the remaining 13 files and replaces
the 21 specification-string eval(parse()) calls in the 7 core math files.
After this plan, zero assign(.GlobalEnv) will remain anywhere in RSPARROW_master/R/.
</context>

<prerequisites>
- Plan 04-A complete and verified (0 errors from R CMD check)
- Confirm starting state: grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/
  Expected: 13 files still showing results (not startModelRun.R or controlFileTasksModel.R)
</prerequisites>

<reference_documents>
Read before starting:
  docs/PLAN_04_SUBSTITUTION_PATTERNS.md  patterns: global_assign (after_option_2), specification_string
  docs/PLAN_04_FILE_INVENTORY.md         task_files id="4", id="5"
</reference_documents>

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

<scope>
<in_scope>
- Task 4: 13 files still containing assign(.GlobalEnv) — 1-4 calls each, ~24 total
- Task 5: 7 core math files with specification-string eval(parse()) — 21 occurrences
           + cleanup in getCharSett.R, getShortSett.R, estimateOptimize.R
</in_scope>
<out_of_scope>
- unPackList() removal — Plan 04-C
- Skeleton function implementations — Plan 04-D
- Files on REMOVE list — do not modify
</out_of_scope>
</scope>

<tasks>

<task id="4" priority="critical">
<name>Eliminate assign(.GlobalEnv) from the remaining 13 files</name>
<description>
Each file uses the explicit-return pattern (after_option_2 in substitution_patterns.md):
make the function return the value instead of pushing it to GlobalEnv, then update all
call sites to capture the return value.
</description>

<files_and_actions>
  findMinMaxLatLon.R      (4 assigns) → return list(min_lat, max_lat, min_lon, max_lon)
  estimate.R              (4 assigns) → include variables in estimate.list return value
  checkDrainageareaMapPrep.R (2)      → return named list; update callers
  dataInputPrep.R         (2 assigns) → return processed data list; update callers
  predictBootstraps.R     (2 assigns) → return bootstrap results list
  predictScenarios.R      (2 assigns) → return scenario results list
  correlationMatrix.R     (1 assign)  → return Cor.ExplanVars.list
  diagnosticSensitivity.R (1 assign)  → verify value unused downstream; remove assign only
  estimateBootstraps.R    (1 assign)  → return bootstrap object
  estimateWeightedErrors.R (1 assign) → return weight object
  predict.R               (1 assign)  → function already returns predict.list; remove assign
  replaceData1Names.R     (1 assign)  → return data frame
  setNLLSWeights.R        (1 assign)  → return Csites.weights.list
</files_and_actions>

<procedure label="Apply to each file in order">
Step 1 — Discover all callers before touching the signature:
  grep -rn "functionName(" RSPARROW_master/R/
  Note: REMOVE-list callers are acceptable — they will be deleted in Plan 05.

Step 2 — Read the file to confirm the assign target variable name and type.

Step 3 — Make the function return the value:
  # BEFORE:
  result <- compute_something(data)
  assign("result", result, envir = .GlobalEnv)

  # AFTER:
  result <- compute_something(data)
  result   # explicit return (or add to existing return list)

Step 4 — Update every non-REMOVE call site to capture the return value:
  # BEFORE: functionName(args)   # caller relied on GlobalEnv side-effect
  # AFTER:  result <- functionName(args)
</procedure>

<special_cases>
estimate.R (4 assigns): These variables must be added to the estimate.list that
estimate.R already returns. Do not add a second return(); extend the existing list.

predict.R (1 assign): predict.R already returns predict.list. The assign() is a
redundant side-effect. Remove the assign() line; no return change needed.

diagnosticSensitivity.R (1 assign): Confirm the assigned variable is not read by
any non-REMOVE caller before deleting. Use:
  grep -rn "variableName" RSPARROW_master/R/
</special_cases>

<success>
  grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/  → 0 results (across all R/ files)
</success>
</task>

<task id="5" priority="high">
<name>Replace specification-string eval(parse()) in 7 core math files</name>
<description>
Three fixed SPARROW mathematical expressions are stored as character strings in
estimate.input.list and eval(parse())'d on every NLLS iteration. Replace all 21
occurrences with inline R expressions. Then remove the string variables from the
settings infrastructure (getCharSett.R, getShortSett.R, estimateOptimize.R).
</description>

<canonical_replacements>
# --- reach_decay_specification ---
# BEFORE:
rchdcayf[, 1] <- rchdcayf[, 1] * eval(parse(text = reach_decay_specification))
# AFTER:
rchdcayf[, 1] <- rchdcayf[, 1] * exp(-data[, jdecvar[i]] * beta1[, jbdecvar[i]])

# --- reservoir_decay_specification ---
# BEFORE:
resdcayf[, 1] <- resdcayf[, 1] * eval(parse(text = reservoir_decay_specification))
# AFTER:
resdcayf[, 1] <- resdcayf[, 1] * (1 / (1 + data[, jresvar[i]] * beta1[, jbresvar[i]]))

# --- incr_delivery_specification ---
# BEFORE:
ddliv2 <- eval(parse(text = incr_delivery_specification))
# AFTER:
ddliv2 <- exp(ddliv1 %*% t(dlvdsgn))
</canonical_replacements>

<files label="3 occurrences per file, 21 total">
  estimateFeval.R       lines ~71, 82, 100
  estimateFevalNoadj.R  lines ~59, 70, 86
  validateFevalNoadj.R  lines ~55, 66, 82
  predict.R             lines ~77, 88, 105
  predictBoot.R         lines ~74, 85, 102
  predictSensitivity.R  lines ~73, 84, 100
  predictScenarios.R    lines ~227, 238, 255
</files>

<cleanup label="After all 21 replacements, clean the settings infrastructure">
Step 1 — Remove three variable names from getCharSett.R's character settings list.
Step 2 — Remove three variable names from getShortSett.R's settings list.
Step 3 — Remove the three lines in estimateOptimize.R (~lines 111-113) that copy
          these specification strings into sparrowEsts / estimate.input.list.
Step 4 — Verify no references remain:
  grep -r "reach_decay_specification\|reservoir_decay_specification\|incr_delivery_specification" RSPARROW_master/R/
  → must return 0 results
</cleanup>

<note>
The specification strings are NOT user-configurable in practice — they represent fixed
SPARROW mathematical forms. No published SPARROW application has overridden them via
the control file. Inlining them eliminates 21 eval(parse()) calls on the hot path of
the NLLS optimizer (called thousands of times per model run).
</note>

<success>
  grep "eval(parse" RSPARROW_master/R/estimateFeval.R    → 0 results
  grep "eval(parse" RSPARROW_master/R/predict.R          → 0 results
  grep -r "reach_decay_specification\|reservoir_decay_specification\|incr_delivery_specification" RSPARROW_master/R/
                                                          → 0 results
</success>
</task>

</tasks>

<execution_order>
1. Task 4 — process files in order listed; do one file at a time (grep callers, edit, verify)
2. Task 5 — independent of Task 4; can be done in any order relative to Task 4's files
            but do all 7 math files before the cleanup step
3. Verify: grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/ → 0 results (final check)
4. R CMD build + check before closing
</execution_order>

<risks>
<risk name="caller_discovery">
For each file in Task 4, grep for callers before changing the signature.
estimate.R, estimateBootstraps.R, predictBootstraps.R, predictScenarios.R are called
by controlFileTasksModel.R (now returning structured output from Plan 04-A) — verify
the updated call chain is consistent.
</risk>
<risk name="estimate_list_extension">
estimate.R already builds and returns estimate.list. The 4 assign(.GlobalEnv) variables
must be added to that list, not returned separately. Read estimate.R's existing return
statement before editing: grep -n "return(" RSPARROW_master/R/estimate.R
</risk>
<risk name="unpacklist_interference">
Several Task 4 files (correlationMatrix.R, setNLLSWeights.R, etc.) also contain
unPackList() calls. Do NOT remove unPackList() in this plan — that is Plan 04-C scope.
Only remove assign(.GlobalEnv) in this plan.
</risk>
<risk name="specification_string_context">
Before inlining, verify the variable names (jdecvar, jbdecvar, etc.) are in scope at
each eval(parse()) call site. They should be — but confirm by reading each function.
</risk>
</risks>

<success_criteria>
- grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/  → 0 results (all 15 files clean)
- grep "eval(parse" RSPARROW_master/R/estimateFeval.R    → 0 results
- grep "eval(parse" RSPARROW_master/R/predict.R          → 0 results
- grep -r "reach_decay_specification\|reservoir_decay_specification\|incr_delivery_specification" RSPARROW_master/R/  → 0 results
- R CMD build --no-build-vignettes RSPARROW_master/ succeeds
- R CMD check introduces no new errors vs Plan 04-A baseline
</success_criteria>

<failure_criteria>
- Any assign(.GlobalEnv) remains in any non-REMOVE file → plan incomplete
- Any specification-string variable name still referenced in R/ → Task 5 cleanup incomplete
- R CMD check introduces new errors → fix before declaring done
</failure_criteria>

</plan>
