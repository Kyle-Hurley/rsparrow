<plan id="04-A">
<name>Windows Code Removal and Core State Refactoring</name>

<status>ALL 3 TASKS COMPLETE
  Task 1 (Remove Windows-only code): COMPLETE
    - Removed shell.exec(), Rscript.exe, batch_mode from all non-REMOVE files
    - 0 shell.exec/Rscript.exe remaining in code; 0 batch_mode in non-REMOVE files
  Task 2 (Eliminate assign(.GlobalEnv) from startModelRun.R): COMPLETE
    - 27 assign(.GlobalEnv) replaced with sparrow_state$ assignments
    - unPackList replaced with direct $ extractions
    - enable_ShinyApp parameter removed; sparrow_state returned
  Task 3 (Refactor controlFileTasksModel.R): COMPLETE
    - Primary unPackList removed; 1 assign(.GlobalEnv) removed
    - min.sites.list parameter added; bare names replaced with $-extractions
  R CMD build succeeds; no new errors introduced
</status>
<part_of>Plan 04: State Elimination and Skeleton Implementation — tasks 1, 2, 3 of 13</part_of>
<next_plans>04-B (tasks 4-5), 04-C (tasks 6-7), 04-D (tasks 8-13)</next_plans>

<context>
Plans 01-03 complete. Package builds and installs. All 13 exported functions are stubs.
This is the foundational sub-plan: it removes all Windows-only code and converts
startModelRun.R from a GlobalEnv side-effector into a function that returns all state
in a named list (sparrow_state). Plans 04-B, 04-C, and 04-D all depend on these changes.
</context>

<prerequisites>
- Plans 01, 02, 03 complete
- R CMD build RSPARROW_master/ produces rsparrow_2.1.0.tar.gz without errors
- Baseline: R CMD check shows 0 errors (record warning/note count before starting)
</prerequisites>

<reference_documents>
Read before starting — these govern all edits in this plan:
  docs/PLAN_04_SUBSTITUTION_PATTERNS.md  pattern: global_assign (after_option_1), batch_mode_removal
  docs/PLAN_04_FILE_INVENTORY.md         task_files id="1", id="2", id="3"
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
- Task 1: Remove shell.exec(), Rscript.exe paths, and all batch_mode=="yes" branches (4+ files)
- Task 2: Convert all 27 assign(.GlobalEnv) in startModelRun.R to sparrow_state accumulator
- Task 3: Remove 2 unPackList() calls and 1 assign(.GlobalEnv) from controlFileTasksModel.R
</in_scope>
<out_of_scope>
- Remaining 13 files with assign(.GlobalEnv) — Plan 04-B Task 4
- unPackList removal from estimation/prediction/data-prep chains — Plans 04-B and 04-C
- Dynamic-column eval(parse()) — Plan 04-C
- Skeleton function implementations — Plan 04-D
- Files on REMOVE list — do not modify
</out_of_scope>
</scope>

<tasks>

<task id="1" priority="critical">
<name>Remove Windows-only code</name>
<description>
Remove shell.exec(), Sys.which("Rscript.exe"), and all batch_mode=="yes" log branches.
batch_mode is a dead parameter — the Windows batch launcher was deleted in Plan 01.
These branches write duplicate messages to Windows log files and have no effect on Linux/Mac.
</description>

<step_1 label="Audit full scope before any edits">
  grep -rn "shell\.exec\|Rscript\.exe" RSPARROW_master/R/
  grep -rn "batch_mode" RSPARROW_master/R/
Record every file returned. Skip any REMOVE-list files — they will be deleted in Plan 05.
</step_1>

<step_2 label="Remove shell.exec and Rscript.exe">
Primary files (confirmed):
  RSPARROW_master/R/startModelRun.R                  (~line 540)
  RSPARROW_master/R/createInitialParameterControls.R
  RSPARROW_master/R/createInitialDataDictionary.R
  RSPARROW_master/R/addVars.R
Action: Delete the if/else blocks containing shell.exec() or Sys.which("Rscript.exe") entirely.
</step_2>

<step_3 label="Remove batch_mode from every non-REMOVE file">
For each file returned by the grep in Step 1 (excluding REMOVE list):
  a. Delete every if (batch_mode == "yes") { ... } block
  b. Remove batch_mode from the function's parameter list
  c. Remove batch_mode from all internal call sites within RSPARROW_master/R/
Removing batch_mode from startModelRun() cascades — grep call sites before editing.
  grep -rn "startModelRun(" RSPARROW_master/R/
  grep -rn "controlFileTasksModel(" RSPARROW_master/R/
</step_3>

<success>
  grep -r "shell\.exec\|Rscript\.exe" RSPARROW_master/R/  → 0 results
  grep -r "batch_mode" RSPARROW_master/R/                  → 0 results (non-REMOVE files only)
</success>
</task>

<task id="2" priority="critical">
<name>Eliminate assign(.GlobalEnv) from startModelRun.R</name>
<description>
Convert all 27 assign(.GlobalEnv) calls to accumulate into a sparrow_state list.
Return sparrow_state at the end. Also remove the unPackList() call at the function top
and remove enable_ShinyApp from the parameter signature (Shiny separated in Plan 02).
</description>

<variables_to_capture label="All 27 become sparrow_state$varname">
  betavalues, SelParmValues, ifHess (conditional), dmatrixin, dlvdsgn,
  subdata, add_vars (conditional), Vsites.list (conditional),
  DataMatrix.list, Csites.weights.list, Cor.ExplanVars.list,
  sitedata.landuse, vsitedata.landuse, sitedata.demtarea.class,
  vsitedata.demtarea.class, numsites, nMoncalsites, vic, dynamic,
  min_lat, max_lat, min_lon, max_lon, nMon, Csites.list,
  sitedata, vsitedata
</variables_to_capture>

<replacement_pattern>
# At function start (after signature cleanup):
sparrow_state <- list()

# Replace each assign():
#   BEFORE: assign("betavalues", betavalues, envir = .GlobalEnv)
#   AFTER:  sparrow_state$betavalues <- betavalues

# Conditional assigns — preserve the condition, change the assign:
#   BEFORE: if (if_userModifyData == "yes") assign("add_vars", add_vars, envir = .GlobalEnv)
#   AFTER:  if (if_userModifyData == "yes") sparrow_state$add_vars <- add_vars

# At function end, before any existing return():
return(sparrow_state)
</replacement_pattern>

<callers label="Update call sites after signature change">
  grep -rn "startModelRun(" RSPARROW_master/R/
controlFileTasksModel.R calls startModelRun() — capture its return in Task 3:
  sparrow_state <- startModelRun(...)
</callers>

<success>
  grep -c "assign.*\.GlobalEnv" RSPARROW_master/R/startModelRun.R  → 0
  grep -c "unPackList" RSPARROW_master/R/startModelRun.R            → 0
</success>
</task>

<task id="3" priority="critical">
<name>Refactor controlFileTasksModel.R</name>
<description>
Remove 2 unPackList() calls and 1 assign(.GlobalEnv).
Accept sparrow_state (the named list returned by Task 2's startModelRun()) as an argument
instead of relying on unpacked globals. Return a structured list at the end.
</description>

<step_1 label="Read and audit before editing">
Read the full file first. Identify:
  - What each unPackList() unpacks (file.output.list? estimate.input.list? other?)
  - Which variable is pushed with assign(.GlobalEnv) and where it is used downstream
  - Which internal functions are called and what arguments they receive
Use: grep -n "unPackList\|assign.*GlobalEnv\|estimate\.list\|predict\.list" RSPARROW_master/R/controlFileTasksModel.R
</step_1>

<step_2 label="Replace unPackList with direct access">
# BEFORE:
unPackList(lists = list(x = file.output.list), parentObj = list(NA))
# then uses: x (bare name)

# AFTER:
# use file.output.list$x directly throughout the function
</step_2>

<step_3 label="Replace assign(.GlobalEnv) with return value">
Identify the single assign(.GlobalEnv) variable; include it in the return list.
Add at function end:
  return(list(
    runTimes = runTimes,
    results  = list(
      estimate_list = estimate_list,
      predict_list  = predict_list
    )
  ))
</step_3>

<step_4 label="Update callers">
  grep -rn "controlFileTasksModel(" RSPARROW_master/R/
Update startModelRun.R (or its caller) to capture the return value:
  run_output <- controlFileTasksModel(...)
  # then: run_output$results$estimate_list, run_output$runTimes, etc.
REMOVE-list files may call old signatures — acceptable; they are deleted in Plan 05.
</step_4>

<success>
  grep "assign.*\.GlobalEnv\|unPackList" RSPARROW_master/R/controlFileTasksModel.R  → 0 results
</success>
</task>

</tasks>

<execution_order>
1. Task 1 (shell.exec/batch_mode) — run audit greps first; then edit; no dependencies
2. Task 2 (startModelRun.R) — read full file before editing; add sparrow_state accumulator
3. Task 3 (controlFileTasksModel.R) — depends on Task 2 signature; update call sites last
</execution_order>

<risks>
<risk name="batch_mode_cascade">
batch_mode may be passed through more than the 4 primary files. The Step 1 grep in
Task 1 determines the full scope. Each non-REMOVE file that accepts batch_mode as
a parameter must have it removed from the signature and all internal call sites.
</risk>
<risk name="startModelRun_length">
startModelRun.R is ~800+ lines. Read it entirely before editing. All conditional
assigns (inside if (x == "yes") blocks) must still assign to sparrow_state — do not
drop the conditional logic, only change the target from GlobalEnv to sparrow_state.
</risk>
<risk name="controlFileTasksModel_callers">
Find all callers before changing the signature:
  grep -rn "controlFileTasksModel(" RSPARROW_master/R/
REMOVE-list files calling old signatures are acceptable — Plan 05 deletes them.
</risk>
</risks>

<success_criteria>
- grep -r "shell\.exec\|Rscript\.exe" RSPARROW_master/R/  → 0 results
- grep -r "batch_mode" RSPARROW_master/R/                  → 0 results (non-REMOVE files)
- grep -c "assign.*\.GlobalEnv" RSPARROW_master/R/startModelRun.R  → 0
- grep -c "unPackList" RSPARROW_master/R/startModelRun.R            → 0
- grep "assign.*\.GlobalEnv\|unPackList" RSPARROW_master/R/controlFileTasksModel.R  → 0 results
- R CMD build --no-build-vignettes RSPARROW_master/ succeeds
- R CMD check rsparrow_2.1.0.tar.gz introduces no new errors vs Plan 03 baseline
</success_criteria>

<failure_criteria>
- Any shell.exec or Rscript.exe remains in non-REMOVE files → plan incomplete
- startModelRun.R still pushes any variable to GlobalEnv → plan incomplete
- R CMD check introduces new errors compared to Plan 03 baseline → fix before declaring done
</failure_criteria>

</plan>
