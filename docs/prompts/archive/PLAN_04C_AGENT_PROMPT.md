# Plan 04C — unPackList Removal Agent Prompt
# For use with Opus 4.5+ in a fresh session

<task>
Execute Plan 04C of the rsparrow CRAN refactor: remove all unPackList() calls and
dynamic-column eval(parse()) from the core estimation/prediction chain (Task 6, 4 files
remaining) and the data-preparation chain (Task 7, 29 files). Finish with grep verification
and R CMD build.
</task>

<project_context>
- R package directory: RSPARROW_master/  (relative to repo root)
- Build command: R CMD build --no-build-vignettes RSPARROW_master/
- Plans 04A and 04B are complete: 0 assign(.GlobalEnv) remain anywhere; spec-string
  eval(parse()) have been inlined in 7 core math files.
- unPackList() is a legacy function that injects variables into parent.frame() via assign().
  It makes data flow invisible. The goal is to replace it with direct list element access.
- After this plan: grep -r "unPackList" RSPARROW_master/R/ should return results ONLY in
  unPackList.R itself (and REMOVE-list files which Plan 05 will delete).
</project_context>

<working_directory>
All file paths are relative to the repo root. The package lives at RSPARROW_master/.
R source files are at RSPARROW_master/R/*.R
Do NOT change directory — use absolute-style paths from repo root.
</working_directory>

<efficiency_rules>
To minimize context window growth:
1. Use Grep to locate the unPackList() call and the bare variable names it injects BEFORE
   reading the whole file. This tells you exactly what to look for.
2. Use Read with offset+limit to read only the relevant section of large files (e.g., the
   first 50 lines to see the function signature + unPackList call, then the body).
3. Make all edits with the Edit tool (surgical replacement), not Write (full rewrite).
4. Process files in the order given. Do not re-read files you have already finished.
5. Run grep verification once per task batch (not after every single file).
6. If a file has multiple unPackList calls, map ALL of them before making the first edit.
</efficiency_rules>

<substitution_patterns>

<pattern name="unpack_list">
unPackList() is called with two arguments: `lists` (named list of lists to unpack) and
`parentObj` (describes the type of each list element).

parentObj = list(NA)         → unpacking a plain list  → replace with list$element
parentObj = list(data_frame) → unpacking data.frame cols → replace with df[[colname]]

BEFORE:
```r
myFunction <- function(DataMatrix.list, estimate.input.list) {
  unPackList(
    lists = list(
      data.index.list     = DataMatrix.list$data.index.list,
      estimate.input.list = estimate.input.list
    ),
    parentObj = list(NA, NA)
  )
  x <- data[, jstaid]           # bare name — injected by unPackList
  if (ifHess == "yes") { ... }  # bare name — injected by unPackList
}
```

AFTER:
```r
myFunction <- function(DataMatrix.list, estimate.input.list) {
  data.index.list <- DataMatrix.list$data.index.list  # local alias for convenience
  x <- data[, data.index.list$jstaid]
  if (estimate.input.list$ifHess == "yes") { ... }
}
```

IMPORTANT — data.index.list contains ~20 column-index variables (jstaid, jfnode, jtnode,
jdepvar, jiftran, jsrcvar, jbsrcvar, jdlvvar, jbdlvvar, jresvar, jbresvar, jdecvar,
jbdecvar, jfrac, jstaidseq, jcalsites, jload, etc.).
Do NOT add these 20 variables as individual function parameters.
Assign data.index.list once at the top of the function and use data.index.list$jXXX.
</pattern>

<pattern name="dynamic_column">
Dynamic data frame column access via eval(parse(text=paste0("df$",varname))) is equivalent
to df[[varname]] in base R.

BEFORE (various forms):
```r
eval(parse(text = paste0("subdata$", varname)))
eval(parse(text = paste0("data1$", colname)))
eval(parse(text = paste0("betavalues$", parmname)))
# Assignment form:
eval(parse(text = paste0(settname, "<-input$`", settname, "`")))
```

AFTER:
```r
subdata[[varname]]
data1[[colname]]
betavalues[[parmname]]
# Assignment form:
invalue[[settname]] <- input[[settname]]
```

WARNING — applyUserModify.R also has eval(parse()) blocks that execute multi-statement
user-supplied R expressions. These are NOT simple column access and must NOT be replaced.
Read each eval(parse()) in full. Replace only paste0("df$", varname) forms.
Flag complex blocks with: # TODO Plan 05 — user-expression eval, do not replace
</pattern>

</substitution_patterns>

<procedure label="Per-file procedure (apply to every file)">
Step 1 — Grep the file to see every unPackList() call and every eval(parse() call:
         Grep pattern: "unPackList|eval\(parse" in RSPARROW_master/R/filename.R
Step 2 — Read the function signature + unPackList() calls (first ~60 lines usually).
         For each unPackList call, record:
           - Which lists are being unpacked (the `lists` argument)
           - Whether parentObj is NA (plain list) or a data.frame (column extraction)
Step 3 — Grep for all bare variable names introduced by each unpack to find all use sites:
         e.g., Grep "jstaid\b" in RSPARROW_master/R/filename.R to find all uses
Step 4 — Edit the file:
           a. Remove the unPackList() call (or replace with a local alias assignment)
           b. Prefix all bare names with their list: jstaid → data.index.list$jstaid
           c. Replace eval(parse()) column-access forms with df[[varname]]
Step 5 — If new explicit parameters are needed (rare — most lists are already in scope),
         update the function signature AND grep for all callers to update call sites:
         Grep: "functionName\s*\(" in RSPARROW_master/R/
Step 6 — Verify: Grep "unPackList" in the file → 0 results
</procedure>

<constraints>
DO NOT modify any file on this list — Plan 05 will delete them:
  diagnosticMaps.R, predictMaps.R, predictMaps_single.R, mapSiteAttributes.R,
  create_diagnosticPlotList.R, mapLoopStr.R, plotlyLayout.R, addMarkerText.R,
  aggDynamicMapdata.R, mapBreaks.R, modelCompare.R, outputSettings.R,
  diagnosticPlotsNLLS.R, diagnosticPlotsNLLS_dyn.R, diagnosticPlotsValidate.R,
  make_residMaps.R, make_dyndiagnosticPlotsNLLS.R, make_dyndiagnosticPlotsNLLS_corrPlots.R,
  make_dyndiagnosticPlotsNLLS_sensPlots.R, make_drainageAreaErrorsPlot.R,
  make_drainageAreaErrorsMaps.R, make_diagnosticPlotsNLLS_timeSeries.R,
  make_modelEstPerfPlots.R, make_modelSimPerfPlots.R, make_siteAttrMaps.R

DO NOT replace complex eval(parse()) in applyUserModify.R — flag with # TODO Plan 05.
DO NOT add data.index.list's 20 j-variables as individual function parameters.
DO NOT rewrite functions beyond what is needed to remove unPackList / eval(parse()).
DO NOT add docstrings, comments, or type annotations to code you did not change.
</constraints>

<current_progress>
Task 6 — estimation/prediction chain (12 files total):
  DONE (8 files): estimateFeval.R, estimateFevalNoadj.R, estimateOptimize.R,
    estimateNLLSmetrics.R, estimateNLLStable.R, estimateWeightedErrors.R,
    estimateBootstraps.R, estimate.R

  REMAINING (4 files — start here):
    predict.R         1 unPackList unpacking: JacobResults, datalstCheck, SelParmValues,
                                              estimate.input.list, DataMatrix.list$data.index.list
    predictBoot.R     1 unPackList
    predictBootstraps.R  1 unPackList unpacking: JacobResults, subdata columns, SelParmValues,
                                                  predict.source.list, file.output.list
    validateMetrics.R 1 unPackList + 2 eval(parse()) (~lines 35 and 39)

Task 7 — data-prep chain (29 files): NOT STARTED
Task 3 — Verification: NOT STARTED
</current_progress>

<task_6_remaining label="Finish Task 6 — 4 files">
Process in this order (call chain, deeper callee first):

1. predict.R
2. predictBoot.R
3. predictBootstraps.R
4. validateMetrics.R

Apply the per-file procedure above to each.
After all 4: Grep "unPackList" in each → 0 results.
</task_6_remaining>

<task_7 label="Task 7 — 29 data-prep files (not started)">
Two sub-groups. Apply both unpack_list AND dynamic_column patterns to each file.

<group_a label="24 files with unPackList (some also have eval/parse)">
Process in any order — these files are not deeply interdependent:

  File                           unPackList  eval(parse)
  readData.R                         1           0
  readParameters.R                   1           2
  readDesignMatrix.R                 1           0
  readForecast.R                     1           6
  createDataMatrix.R                 2           7
  createSubdataSorted.R              0           2    ← eval/parse only
  selectCalibrationSites.R           1           0
  selectValidationSites.R            1           0
  setNLLSWeights.R                   1           0
  correlationMatrix.R                1           4
  hydseq.R                           1           0
  hydseqTerm.R                       1           0
  calcHeadflag.R                     1           0
  calcTermflag.R                     1           0
  checkClassificationVars.R          1           0
  checkMissingSubdataVars.R          2           0
  checkAnyMissingSubdataVars.R       1           0
  checkMissingData1Vars.R            1           0
  checkData1NavigationVars.R         0           4    ← eval/parse only
  applyUserModify.R                  2           6    ← see WARNING below
  syncVarNames.R                     1           0
  addVars.R                          1           0
  createMasterDataDictionary.R       1           0
  read_dataDictionary.R              1           0

applyUserModify.R WARNING:
  Read ALL 6 eval(parse()) calls before editing.
  Replace only paste0("df$", varname) column-access forms.
  For any multi-statement or user-expression eval(parse()) block, add:
    # TODO Plan 05 — user-expression eval, do not replace
  and leave the block unchanged.
</group_a>

<group_b label="5 eval/parse-only files (no unPackList)">
Fix dynamic-column eval(parse()) only:

  verifyDemtarea.R          2 eval(parse)
  createVerifyReachAttr.R   2 eval(parse)
  accumulateIncrArea.R      2 eval(parse)
  importCSVcontrol.R        2 eval(parse)
  checkingMissingVars.R     4 eval(parse)
</group_b>
</task_7>

<verification>
After completing both tasks, run these checks in order:

1. Count remaining unPackList references (should be 1 file only — unPackList.R itself,
   plus any REMOVE-list files):
   Bash: grep -rl "unPackList" RSPARROW_master/R/

2. Count remaining eval(parse()) in the Task 7 files (spot-check 5):
   Bash: grep -c "eval(parse" RSPARROW_master/R/correlationMatrix.R
   Bash: grep -c "eval(parse" RSPARROW_master/R/createDataMatrix.R
   Bash: grep -c "eval(parse" RSPARROW_master/R/readForecast.R
   Bash: grep -c "eval(parse" RSPARROW_master/R/checkingMissingVars.R
   Bash: grep -c "eval(parse" RSPARROW_master/R/applyUserModify.R
   (applyUserModify.R may show >0 for # TODO Plan 05 flagged blocks — that is acceptable)

3. Build the package:
   Bash: R CMD build --no-build-vignettes RSPARROW_master/

4. Run check (warnings are pre-existing; look for new errors only):
   Bash: R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz
</verification>

<success_criteria>
- grep -rl "unPackList" RSPARROW_master/R/ → returns only unPackList.R (and REMOVE-list files)
- grep -c "eval(parse" RSPARROW_master/R/estimateFeval.R → 0
- grep -c "eval(parse" RSPARROW_master/R/correlationMatrix.R → 0
- grep -c "eval(parse" RSPARROW_master/R/createDataMatrix.R → 0
- R CMD build --no-build-vignettes RSPARROW_master/ → produces rsparrow_2.1.0.tar.gz
- R CMD check introduces no new errors compared to Plan 04B baseline
  (4 pre-existing warnings are acceptable)
</success_criteria>

<failure_criteria>
- Any non-REMOVE, non-unPackList.R file still contains unPackList() → plan incomplete
- R CMD build fails → diagnose and fix before declaring done
- R CMD check introduces new errors → fix before declaring done
- applyUserModify.R complex eval(parse()) was removed incorrectly → revert those changes;
  mark with # TODO Plan 05
- A function signature was changed without updating its callers → find callers with grep
  and update them
</failure_criteria>

<completion>
When done, report:
- List of files modified
- Final grep counts (unPackList and eval(parse) remaining)
- R CMD build result (success / error)
- Any files where eval(parse()) was flagged # TODO Plan 05 rather than replaced
</completion>
