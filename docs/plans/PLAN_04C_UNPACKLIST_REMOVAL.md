<plan id="04-C">
<name>unPackList Removal from Estimation and Data-Preparation Chains</name>
<part_of>Plan 04: State Elimination and Skeleton Implementation — tasks 6, 7 of 13</part_of>
<previous_plan>04-B (tasks 4-5: remaining assigns + specification-string eval/parse)</previous_plan>
<next_plan>04-D (tasks 8-13: skeleton implementations + verification)</next_plan>

<context>
Plans 04-A and 04-B complete: 0 assign(.GlobalEnv) remain anywhere; specification-string
eval(parse()) replaced in all 7 core math files.
This plan replaces unPackList() with direct list element access across two chains:
  - 12 core estimation/prediction files (Task 6)
  - 24 core data-preparation files + dynamic-column eval(parse()) (Task 7)
Plan 04-D (skeleton implementations) depends on these functions having clean,
explicit argument passing.
</context>

<prerequisites>
- Plans 04-A and 04-B complete and verified
- grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/ → 0 results confirmed
- R CMD check: 0 errors before starting
</prerequisites>

<reference_documents>
Read before starting:
  docs/PLAN_04_SUBSTITUTION_PATTERNS.md  patterns: unpack_list, dynamic_column
  docs/PLAN_04_FILE_INVENTORY.md         task_files id="6", id="7"
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
- Task 6: Remove unPackList() from 12 core estimation/prediction files
- Task 7: Remove unPackList() from 24 data-prep files AND replace dynamic-column
          eval(parse()) with df[[varname]] in all files touched in this task
          (plus 5 additional eval/parse-only files)
</in_scope>
<out_of_scope>
- assign(.GlobalEnv) — fully eliminated in Plans 04-A and 04-B
- Specification-string eval(parse()) — eliminated in Plan 04-B
- Skeleton implementations — Plan 04-D
- Complex multi-statement eval(parse()) in applyUserModify.R that cannot be
  mechanically replaced — requires case-by-case analysis (see risk below)
- Files on REMOVE list — do not modify
</out_of_scope>
</scope>

<substitution_summary>
<unpack_list_pattern>
# BEFORE — variables appear as bare names after unPackList():
myFunction <- function(DataMatrix.list, estimate.input.list) {
  unPackList(
    lists     = list(data.index.list = DataMatrix.list$data.index.list,
                     estimate.input.list = estimate.input.list),
    parentObj = list(NA, NA)
  )
  x <- data[, jstaid]               # jstaid injected by unPackList
  if (ifHess == "yes") { ... }       # ifHess injected by unPackList
}

# AFTER — access list elements directly:
myFunction <- function(DataMatrix.list, estimate.input.list) {
  data.index.list <- DataMatrix.list$data.index.list
  x <- data[, data.index.list$jstaid]
  if (estimate.input.list$ifHess == "yes") { ... }
}
</unpack_list_pattern>

<data_index_list_note>
data.index.list contains ~20 column index variables (jstaid, jfnode, jtnode, jdepvar,
jiftran, jsrcvar, jbsrcvar, jdlvvar, jbdlvvar, jresvar, jbresvar, jdecvar, jbdecvar,
jfrac, jstaidseq, jcalsites, jload, etc.).
Do NOT add these as 20 individual function parameters.
Accept data.index.list as one argument and use data.index.list$jstaid throughout.
</data_index_list_note>

<dynamic_column_pattern>
# BEFORE:
eval(parse(text = paste0("subdata$", varname)))
eval(parse(text = paste0("data1$", colname)))
eval(parse(text = paste0("betavalues$", parmname)))

# AFTER:
subdata[[varname]]
data1[[colname]]
betavalues[[parmname]]

# Assignment form:
# BEFORE: eval(parse(text = paste0(settname, "<-input$`", settname, "`")))
# AFTER:  invalue[[settname]] <- input[[settname]]
</dynamic_column_pattern>
</substitution_summary>

<tasks>

<task id="6" priority="high">
<name>Remove unPackList() from 12 core estimation/prediction files</name>
<description>
These files form the core math path that Plan 06 will unit-test. They must use
explicit argument passing with no hidden state injection.
</description>

<files>
  estimateFeval.R        1 unPackList — unpacks data.index.list, estimate.input.list
  estimateFevalNoadj.R   1 unPackList — unpacks data.index.list, estimate.input.list
  estimateOptimize.R     1 unPackList — unpacks estimate.input.list
  estimateNLLSmetrics.R  2 unPackList — unpacks various
  estimateNLLStable.R    5 unPackList — highest count; read carefully
  estimateWeightedErrors.R  1 unPackList
  estimateBootstraps.R   1 unPackList
  estimate.R             1 unPackList
  predict.R              1 unPackList — unpacks JacobResults, datalstCheck, SelParmValues,
                                        estimate.input.list, DataMatrix.list$data.index.list
  predictBoot.R          1 unPackList
  predictBootstraps.R    1 unPackList
  validateMetrics.R      1 unPackList
</files>

<procedure label="Apply to each file">
Step 1 — Read the file. Identify exactly what each unPackList() unpacks by inspecting
         the `lists` argument. Note which bare variable names are used after the call.
Step 2 — For each bare variable name introduced by unPackList():
           - If it comes from a plain list  → replace with list$variable
           - If it comes from a data.frame  → replace with df[[varname]]
Step 3 — Remove the unPackList() call entirely once all uses are updated.
Step 4 — If the function signature needs new parameters to carry lists that were
         previously injected globally, add them AND update callers:
           grep -rn "functionName(" RSPARROW_master/R/
Step 5 — grep -c "unPackList" RSPARROW_master/R/filename.R  → must be 0
</procedure>

<priority_order>
Process in this order to follow the call chain bottom-up:
  estimateFeval.R, estimateFevalNoadj.R (called by estimateOptimize.R)
  estimateOptimize.R (called by estimate.R)
  estimateNLLSmetrics.R, estimateNLLStable.R, estimateWeightedErrors.R
  estimate.R
  predict.R, predictBoot.R
  estimateBootstraps.R, predictBootstraps.R, validateMetrics.R
</priority_order>

<success>
  grep -c "unPackList" RSPARROW_master/R/estimateFeval.R     → 0
  grep -c "unPackList" RSPARROW_master/R/estimateNLLStable.R → 0
  grep -c "unPackList" RSPARROW_master/R/predict.R           → 0
  (spot-check all 12 files)
</success>
</task>

<task id="7" priority="high">
<name>Remove unPackList() and dynamic-column eval(parse()) from data-prep chain</name>
<description>
Apply both unpack_list and dynamic_column substitutions to 24 data-prep files.
Also fix 5 additional files that contain dynamic-column eval(parse()) but no unPackList().
</description>

<files_with_unpacklist>
  readData.R                   1 unPackList
  readParameters.R             1 unPackList  + eval(parse) x2
  readDesignMatrix.R           1 unPackList
  readForecast.R               1 unPackList  + eval(parse) x6
  createDataMatrix.R           2 unPackList  + eval(parse) x7
  createSubdataSorted.R        0 unPackList  + eval(parse) x2  (eval/parse only)
  selectCalibrationSites.R     1 unPackList
  selectValidationSites.R      1 unPackList
  setNLLSWeights.R             1 unPackList
  correlationMatrix.R          1 unPackList  + eval(parse) x4
  hydseq.R                     1 unPackList
  hydseqTerm.R                 1 unPackList
  calcHeadflag.R               1 unPackList
  calcTermflag.R               1 unPackList
  checkClassificationVars.R    1 unPackList
  checkMissingSubdataVars.R    2 unPackList
  checkAnyMissingSubdataVars.R 1 unPackList
  checkMissingData1Vars.R      1 unPackList
  checkData1NavigationVars.R   0 unPackList  + eval(parse) x4  (eval/parse only)
  applyUserModify.R            2 unPackList  + eval(parse) x6  (see warning below)
  syncVarNames.R               1 unPackList
  addVars.R                    1 unPackList
  createMasterDataDictionary.R 1 unPackList
  read_dataDictionary.R        1 unPackList
</files_with_unpacklist>

<additional_eval_parse_only label="No unPackList, fix eval(parse) only">
  verifyDemtarea.R         eval(parse) x2
  createVerifyReachAttr.R  eval(parse) x2
  accumulateIncrArea.R     eval(parse) x2
  importCSVcontrol.R       eval(parse) x2
  checkingMissingVars.R    eval(parse) x4
</additional_eval_parse_only>

<applyUserModify_warning>
applyUserModify.R contains complex multi-statement eval(parse()) blocks — these are
user-defined data modification scripts, not simple column lookups. Before replacing,
read each eval(parse()) call in full. Replace only the simple column-access forms
(paste0("df$", varname)) with df[[varname]]. Do NOT attempt to replace blocks that
execute user-supplied R expressions — flag those for Plan 05 review.
</applyUserModify_warning>

<procedure label="Apply to each file">
Same 5-step procedure as Task 6, plus:
Step 2b — For each eval(parse(text = paste0(...))) call:
  a. Read the full expression inside parse(text = ...)
  b. If it is a simple column access  → replace with df[[varname]]
  c. If it is a complex expression    → do NOT replace; add a comment: # TODO Plan 05
Step 5 — grep "unPackList\|eval(parse" RSPARROW_master/R/filename.R  → 0 (or only flagged TODOs)
</procedure>

<success>
  grep "unPackList" RSPARROW_master/R/hydseq.R           → 0 results
  grep "unPackList" RSPARROW_master/R/readData.R          → 0 results
  grep "unPackList" RSPARROW_master/R/createDataMatrix.R  → 0 results
  grep "eval(parse" RSPARROW_master/R/correlationMatrix.R → 0 results
  (spot-check 5 files from different sub-groups)
</success>
</task>

</tasks>

<execution_order>
1. Task 6 — process estimation files bottom-up (feval → optimize → estimate → predict)
2. Task 7 — independent of Task 6; can be interleaved if convenient
3. After both tasks: grep -r "unPackList" RSPARROW_master/R/ → check residual count
   (remaining hits should be only unPackList.R itself and any REMOVE-list files)
4. R CMD build + check before closing
</execution_order>

<risks>
<risk name="signature_cascade">
If a function currently receives unpacked globals via unPackList(), it may need new
explicit parameters after the refactor. Grep all callers before changing any signature.
The estimation chain (estimateFeval → estimateOptimize → estimate) has the deepest
call stack — changes at the bottom propagate upward.
</risk>
<risk name="estimateNLLStable_complexity">
estimateNLLStable.R has 5 unPackList() calls — the highest count. Read the whole file
before editing to understand the full set of injected variables before touching any.
</risk>
<risk name="applyUserModify_complexity">
applyUserModify.R uses eval(parse()) to execute user-supplied data modification
expressions. These are fundamentally different from simple column access. Replacing
them requires understanding the user modification API. Flag with # TODO Plan 05 rather
than guessing.
</risk>
<risk name="parentObj_determination">
Some unPackList() calls use parentObj = list(data_frame) — these unpack data.frame
columns, not list elements. Use df[[colname]] for these, not list$element.
Check the parentObj argument for each call before choosing the replacement.
</risk>
</risks>

<success_criteria>
- grep -r "unPackList" RSPARROW_master/R/  → results only in unPackList.R itself
  (and any REMOVE-list files — those are acceptable)
- grep "eval(parse" RSPARROW_master/R/estimateFeval.R    → 0 results
- grep "eval(parse" RSPARROW_master/R/correlationMatrix.R → 0 results
- grep "eval(parse" RSPARROW_master/R/createDataMatrix.R  → 0 results
- R CMD build --no-build-vignettes RSPARROW_master/ succeeds
- R CMD check introduces no new errors vs Plan 04-B baseline
</success_criteria>

<failure_criteria>
- unPackList() calls remain in any non-REMOVE, non-unPackList.R file → plan incomplete
- R CMD check introduces new errors → fix before declaring done
- applyUserModify.R complex eval(parse() removed incorrectly → revert; mark # TODO Plan 05
</failure_criteria>

<execution_results status="COMPLETE">
Plan 04C executed successfully across two sessions.

Task 6: All 12 estimation/prediction files were verified clean — unPackList() calls had
already been removed in Plans 04A and 04B. Only roxygen documentation references remained,
which were cleaned.

Task 7: Actual unPackList() calls removed from 3 non-REMOVE files:
  - predictSensitivity.R: unPackList → direct $ extractions + data.index.list$ prefixes
  - diagnosticSensitivity.R: unPackList → 6 direct extractions + 1 eval(parse()) fixed
  - checkDrainageareaMapPrep.R: unPackList → 6 direct extractions + 4 eval(parse()) fixed

Fixable eval(parse()) replaced with [[]] access in 6 additional files:
  - checkingMissingVars.R: 4 eval(parse()) → data[[varname]] access patterns
  - createSubdataSorted.R: 1 unnecessary eval removed, 1 flagged TODO Plan 05
  - replaceData1Names.R: 1 eval(parse()) → data1[[varname]] <- NA
  - setNAdf.R: 1 eval(parse()) → df[[names[i]]] <- ifelse(...)
  - readForecast.R: 6 eval(parse()) → named list + vectorized ifelse + [[]] access
  - validateFevalNoadj.R: 1 eval(parse()) loop → data.index.list$ prefix pattern

COMPLEX eval(parse()) flagged TODO Plan 05 in 8 files:
  - predict.R, predictBoot.R, predictScenarios.R (5 each: dynamic source variable assign/eval)
  - diagnosticPlots_4panel_A.R (12), _B.R (6) (plotly marker/text/title dispatch)
  - predictScenariosPrep.R (12: Shiny DSS expressions + S_ bare vars)
  - diagnosticSpatialAutoCorr.R (1: plotParam dispatch via REMOVE-list infrastructure)
  - replaceNAs.R (1: parent.frame injection, same antipattern as unPackList)
  - importCSVcontrol.R (1: caller-supplied expression string)

Additional cleanup:
  - Removed .GlobalEnv rm() from predictScenariosPrep.R (2 occurrences)
  - Cleaned roxygen \item unPackList.R references from ~48 non-REMOVE files
  - applyUserModify.R: roxygen ref removed; actual unPackList call inside dynamic function
    string left as-is with existing TODO Plan 05 comment

Final verified counts:
  - unPackList() calls in non-REMOVE files: 1 (applyUserModify.R, inside dynamic string)
  - eval(parse()) in non-REMOVE files: 65 across 14 files (all flagged TODO Plan 05)
  - R CMD build: succeeds (rsparrow_2.1.0.tar.gz produced)
</execution_results>

</plan>
