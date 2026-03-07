<plan id="04" status="superseded">
<name>State Elimination and Skeleton Implementation</name>
<superseded_by>
This plan has been split into four executable sub-plans:
  PLAN_04A_WINDOWS_GLOBALENV_CORE.md       — tasks 1-3  [COMPLETE] Windows removal, startModelRun, controlFileTasksModel
  PLAN_04B_GLOBALENV_REMAINING_SPECSTRINGS.md — tasks 4-5  [COMPLETE] remaining assigns, spec-string eval/parse
  PLAN_04C_UNPACKLIST_REMOVAL.md           — tasks 6-7  [PENDING] unPackList + dynamic-column eval/parse
  PLAN_04D_API_IMPLEMENTATION.md           — tasks 8-13 [PENDING] skeleton implementations, R CMD check
This file is retained for reference only.
</superseded_by>

<context>
Plans 01-03 complete. Plans 04A and 04B complete. Package builds and loads; 13 exported
functions are stubs returning stop("Not yet implemented").
Resolved CRAN blockers:
  - 51 assign(..., envir=.GlobalEnv) — ALL ELIMINATED (28 in 04A, 23 in 04B; zero remain)
  - shell.exec() / Rscript.exe — ALL REMOVED (Plan 04A Task 1)
  - 21 specification-string eval(parse()) in 7 core math files — ALL INLINED (Plan 04B)
Remaining work:
  - ~318 dynamic-column eval(parse()) in ~54 files (Plan 04C)
  - ~80 unPackList() in ~35 core files (Plan 04C)
  - 13 skeleton implementations (Plan 04D)
</context>

<scope>
<in_scope>
- All 51 assign(.GlobalEnv) in 15 files — CRAN blocker
- shell.exec() and Windows/batch_mode code in 4 files — portability blocker
- Specification-string eval(parse()) in 7 core math files (21 occurrences) — security risk
- unPackList() from core estimation/prediction/data-prep chain — enables skeleton impl
- Implement all 13 exported function bodies (rsparrow_hydseq already done in Plan 03)
</in_scope>
<out_of_scope>
Files on the Plan 05 REMOVE list — do not modify (they will be deleted).
Function consolidation (predict/predictBoot/predictSensitivity merge) — Plan 05.
Full logical TRUE/FALSE conversion for "yes"/"no" strings — Plan 05.
Test suite — Plan 06.
<see_also>docs/PLAN_04_FILE_INVENTORY.md — REMOVE list and per-task file details</see_also>
</out_of_scope>
</scope>

<substitution_reference>
Four canonical replacement patterns govern all edits in this plan.
<see_also>docs/PLAN_04_SUBSTITUTION_PATTERNS.md</see_also>
Summary:
  global_assign     → return named list; caller captures value
  unpack_list       → direct list element access (list$element)
  specification_str → inline the fixed R expression directly
  dynamic_column    → df[[varname]] instead of eval(parse(text=paste0("df$",varname)))
</substitution_reference>

<tasks>

<task id="1" priority="critical">
<name>Remove Windows-only code</name>
Remove shell.exec(), Sys.which("Rscript.exe"), and all batch_mode=="yes" log branches.
batch_mode is a dead parameter (Windows batch launcher was deleted in Plan 01); remove it
from startModelRun() and controlFileTasksModel() signatures and all call sites.
<files>startModelRun.R, createInitialParameterControls.R, createInitialDataDictionary.R, addVars.R</files>
<success>grep -r "shell\.exec\|Rscript\.exe" RSPARROW_master/R/ returns 0 results</success>
</task>

<task id="2" priority="critical">
<name>Eliminate assign(.GlobalEnv) from startModelRun.R</name>
Convert the function to accumulate all 27 global assigns into sparrow_state <- list().
Return sparrow_state at the end. Also remove the unPackList() call at the top.
Remove enable_ShinyApp parameter (Shiny separated in Plan 02; no longer wired to package).
<files>startModelRun.R</files>
<result>sparrow_state named list — see docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md for field list</result>
<success>grep "assign.*\.GlobalEnv" RSPARROW_master/R/startModelRun.R returns 0 results</success>
</task>

<task id="3" priority="critical">
<name>Refactor controlFileTasksModel.R to accept explicit arguments</name>
Remove its 2 unPackList() calls and 1 assign(.GlobalEnv). Return
list(runTimes=runTimes, results=list(estimate_list=..., predict_list=...)).
Update startModelRun.R to capture this return value.
<files>controlFileTasksModel.R</files>
<success>grep "assign.*\.GlobalEnv\|unPackList" RSPARROW_master/R/controlFileTasksModel.R returns 0 results</success>
</task>

<task id="4" priority="critical">
<name>Eliminate assign(.GlobalEnv) from remaining 13 files</name>
Each file has 1–4 calls. For each: make the function return the value instead of pushing
to GlobalEnv; update all call sites to capture the return value.
Before changing any signature: grep -r "functionName(" RSPARROW_master/R/ to find callers.
<files_detail>docs/PLAN_04_FILE_INVENTORY.md — task_files id="4"</files_detail>
<success>grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/ returns 0 results</success>
</task>

<task id="5" priority="high">
<name>Replace specification-string eval(parse()) in 7 core math files</name>
The three model specification strings (reach_decay, reservoir_decay, incr_delivery) are
always fixed SPARROW standard expressions. Inline them directly; remove the character
string variables from estimate.input.list and getCharSett.R/getShortSett.R.
<files_detail>docs/PLAN_04_FILE_INVENTORY.md — task_files id="5"</files_detail>
<replacements_detail>docs/PLAN_04_SUBSTITUTION_PATTERNS.md — pattern name="specification_string"</replacements_detail>
<success>grep -r "reach_decay_specification\|reservoir_decay_specification\|incr_delivery_specification" RSPARROW_master/R/ returns 0 results</success>
</task>

<task id="6" priority="high">
<name>Remove unPackList() from core estimation/prediction chain</name>
Replace with direct list element access in the 12 files that form the core math path.
These are the files Plan 06 will unit-test — they must use explicit argument passing.
For data.index.list (~20 column indices): accept as one argument; use data.index.list$jstaid
throughout rather than adding 20 individual parameters.
<files_detail>docs/PLAN_04_FILE_INVENTORY.md — task_files id="6"</files_detail>
<success>grep "unPackList" RSPARROW_master/R/estimateFeval.R returns 0 results (repeat for each file)</success>
</task>

<task id="7" priority="high">
<name>Remove unPackList() from core data preparation chain</name>
Same substitution as Task 6 applied to 24 data-prep files. Also replace dynamic-column
eval(parse()) with df[[varname]] in all files touched in this task.
<files_detail>docs/PLAN_04_FILE_INVENTORY.md — task_files id="7"</files_detail>
<success>grep "unPackList\|eval(parse" RSPARROW_master/R/hydseq.R returns 0 results (spot-check 5 files)</success>
</task>

<task id="8" priority="high">
<name>Implement S3 method bodies: print, summary, coef, residuals, vcov, plot</name>
Extract named fields from the rsparrow S3 object. No internal function calls required
except for plot.rsparrow (diagnostic plots deferred; use informative stop() for now).
<files>print.rsparrow.R, summary.rsparrow.R, coef.rsparrow.R, residuals.rsparrow.R, vcov.rsparrow.R, plot.rsparrow.R</files>
<implementations_detail>docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md — implementation name="S3_methods"</implementations_detail>
<success>
mock_rsparrow <- structure(list(...), class="rsparrow")  # see test scaffold in child doc
print(mock_rsparrow); coef(mock_rsparrow); residuals(mock_rsparrow); vcov(mock_rsparrow)
summary(mock_rsparrow)  # all execute without error
</success>
</task>

<task id="9" priority="high">
<name>Implement rsparrow_model() — main entry point</name>
Wire to refactored startModelRun() and controlFileTasksModel(). Packages their return
values into an rsparrow S3 object. Verify estimate.list field names before coding:
  grep -n "estimate\.list\[" RSPARROW_master/R/estimate.R
<files>rsparrow_model.R</files>
<implementations_detail>docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md — implementation name="rsparrow_model"</implementations_detail>
<success>rsparrow_model(path_UserTutorial, run_id="Model1") returns object with class "rsparrow"</success>
</task>

<task id="10" priority="high">
<name>Implement read_sparrow_data()</name>
Validates path_main, constructs file.output.list, calls read_dataDictionary() and
readData() to return a named list suitable for rsparrow_model().
<files>read_sparrow_data.R</files>
<implementations_detail>docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md — implementation name="read_sparrow_data"</implementations_detail>
<success>data <- read_sparrow_data(path_UserTutorial); is.data.frame(data$data1)</success>
</task>

<task id="11" priority="medium">
<name>Implement rsparrow_bootstrap(), rsparrow_scenario(), rsparrow_validate()</name>
Thin wrappers: validate the rsparrow input object, call the corresponding internal
function (estimateBootstraps, predictScenarios, validateMetrics), store results in
model$bootstrap / model$predictions$scenarios / model$validation, return updated model.
<files>rsparrow_bootstrap.R, rsparrow_scenario.R, rsparrow_validate.R</files>
<implementations_detail>docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md — implementation names="rsparrow_bootstrap/scenario/validate"</implementations_detail>
<success>No stop("Not yet implemented") remains in any of the three files</success>
</task>

<task id="12" priority="critical">
<name>Implement predict.rsparrow()</name>
Calls predict_sparrow() (internal function renamed from predict() in Plan 03) with
arguments extracted from the rsparrow object. Populates object$predictions. Requires
object_to_estimate_list() helper to reconstruct the estimate.list structure.
<files>predict.rsparrow.R</files>
<implementations_detail>docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md — implementation name="predict.rsparrow"</implementations_detail>
<success>predict(model) returns rsparrow object with $predictions populated</success>
</task>

<task id="13" priority="critical">
<name>Final verification: R CMD check --as-cran</name>
<commands>
R CMD build --no-build-vignettes RSPARROW_master/
R CMD check --as-cran rsparrow_2.1.0.tar.gz
</commands>
<grep_checks>
grep -r "assign.*\.GlobalEnv"  RSPARROW_master/R/     # must be 0 results
grep -r "shell\.exec\|Rscript\.exe" RSPARROW_master/R/ # must be 0 results
grep    "eval(parse"  RSPARROW_master/R/estimateFeval.R # must be 0 results
grep    "eval(parse"  RSPARROW_master/R/predict.R        # must be 0 results
</grep_checks>
<success>0 errors, ≤1 warning, ≤1 note. All 13 exports callable. S3 dispatch correct.</success>
</task>

</tasks>

<execution_order>
  1. Task 1  — shell.exec/batch_mode removal (no dependencies; quick win)
  2. Task 2  — startModelRun.R (foundational; everything else builds on this)
  3. Task 3  — controlFileTasksModel.R (depends on Task 2)
  4. Task 4  — remaining 13 files with assign(.GlobalEnv) (parallel with Task 3)
  5. Task 5  — specification-string eval/parse in 7 math files (independent)
  6. Tasks 6+7 — unPackList removal (independent of each other; run in parallel)
  7. Task 8  — S3 methods (depends only on agreed rsparrow object structure)
  8. Task 10 — read_sparrow_data() (depends on Task 7)
  9. Tasks 9, 11, 12 — skeleton implementations (depend on Tasks 2–7 and Task 8)
 10. Task 13 — final verification (last)
</execution_order>

<risks>
<risk name="call_site_discovery">
grep -r "functionName(" RSPARROW_master/R/ before any signature change. REMOVE-list files
may call old signatures — acceptable; they are deleted in Plan 05.
</risk>
<risk name="estimate.list_field_names">
Verify actual fields before Task 9. grep -n "estimate\.list\[" RSPARROW_master/R/estimate.R
</risk>
<risk name="yes_no_strings">
Internal functions still use if_x=="yes". Pass "yes"/"no" strings from skeletons for now.
Full logical conversion is Plan 05 scope.
</risk>
</risks>

<success_criteria>
<item>grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/ → 0 results</item>
<item>grep -r "shell\.exec\|Rscript\.exe" RSPARROW_master/R/ → 0 results</item>
<item>Specification-string eval/parse replaced in all 7 core math files</item>
<item>unPackList removed from all 12 core estimation files and 24 data-prep files</item>
<item>No exported function body contains stop("Not yet implemented")</item>
<item>rsparrow_model(path_UserTutorial, run_id="Model1") returns class "rsparrow"</item>
<item>print/summary/coef/residuals/vcov/predict all dispatch correctly on rsparrow object</item>
<item>R CMD check --as-cran: 0 errors, ≤1 warning, ≤1 note</item>
</success_criteria>

<failure_criteria>
<item>Any assign(.GlobalEnv) remains → plan incomplete</item>
<item>Any exported function still calls stop("Not yet implemented") → plan incomplete</item>
<item>R CMD check introduces new errors vs Plan 03 baseline → fix before declaring done</item>
<item>rsparrow_model() errors on UserTutorial data → skeleton not functional</item>
</failure_criteria>

<child_documents>
<doc>docs/PLAN_04_SUBSTITUTION_PATTERNS.md — canonical before/after for all 4 antipatterns</doc>
<doc>docs/PLAN_04_FILE_INVENTORY.md — per-task file lists, grep commands, REMOVE exclusion list</doc>
<doc>docs/PLAN_04_SKELETON_IMPLEMENTATIONS.md — rsparrow S3 structure, full pseudocode for all 12 skeletons</doc>
</child_documents>

</plan>
