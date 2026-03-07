<plan id="05">
<title>Plan 05: Function Consolidation — Overview</title>
<status>PENDING (all sub-plans pending)</status>
<predecessor>Plan 04D (API implementation complete)</predecessor>
<successor>Plan 06 (test suite)</successor>

<goal>
Eliminate all REMOVE-list files from R/, merge heavily duplicated prediction functions,
and resolve all remaining eval(parse()) calls. After Plan 05, the package should have
a clean, consolidated R/ directory with ~118 files (down from 153), 0 REMOVE-list files,
and &lt;= 3 remaining eval(parse()) calls (all hardened user-expression sites).
</goal>

<sub_plans>
  <sub_plan id="05A" file="PLAN_05A_DEAD_CODE_REMOVAL.md">
    <title>Infrastructure and Map Dead Code Removal</title>
    <scope>Delete 16 REMOVE-list files. Fix callers in non-REMOVE files first.</scope>
    <files_deleted_approx>16</files_deleted_approx>
    <key_actions>
      - Replace errorOccurred() with stop() in 12 files
      - Replace exitRSPARROW() with stop() in startModelRun.R
      - Inline importCSVcontrol() into 5 callers
      - Remove dead batch-mapping block from controlFileTasksModel.R (kills outputSettings dep)
      - Remove modelCompare() call from startModelRun.R
      - Delete: errorOccurred.R, exitRSPARROW.R, importCSVcontrol.R, outputSettings.R, modelCompare.R
      - Delete: getCharSett.R, getNumSett.R, getOptionSett.R, getShortSett.R, getSpecialSett.R, getYesNoSett.R
      - Delete: diagnosticMaps.R, mapSiteAttributes.R, predictMaps.R, predictMaps_single.R, unPackList.R
    </key_actions>
    <eval_parse_reduction>eliminates 59+23+19+15 = 116 eval/parse in deleted files</eval_parse_reduction>
    <risk>Low — mechanical caller substitutions. Check diagnosticPlotsNLLS_dyn.R for unPackList call.</risk>
  </sub_plan>

  <sub_plan id="05B" file="PLAN_05B_PREDICT_CONSOLIDATION.md">
    <title>Predict Function Consolidation</title>
    <scope>Extract shared prediction kernel; fix 15–18 dynamic source variable eval/parse calls.</scope>
    <files_added>predict_core.R (new)</files_added>
    <files_deleted>estimateFevalNoadj.R (merged into estimateFeval.R)</files_deleted>
    <key_actions>
      - New R/predict_core.R with shared decay/delivery/accumulation kernel
      - Refactor predict.R: 574 → ~200 lines; 0 eval/parse in source-load section
      - Refactor predictBoot.R: 475 → ~150 lines; 0 eval/parse in source-load section
      - Refactor predictScenarios.R: 842 → ~650 lines; 0 eval/parse in source-load section
      - Merge estimateFeval.R + estimateFevalNoadj.R via ifadjust parameter
      - Named list pattern: pload_src[[name]] replaces assign/eval(paste0("pload_",name))
    </key_actions>
    <eval_parse_reduction>15–18 dynamic source variable eval/parse eliminated</eval_parse_reduction>
    <risk>Medium — must validate predict.list column structure matches pre-refactor output.</risk>
  </sub_plan>

  <sub_plan id="05C" file="PLAN_05C_EVAL_PARSE_CLEANUP.md">
    <title>Remaining eval(parse()) Elimination</title>
    <scope>Fix all remaining eval/parse in 6 non-REMOVE, non-make_*, non-makeReport_* files.</scope>
    <key_actions>
      - diagnosticPlots_4panel_A/B.R: inline plotly marker specs, strip plotTitle over-quotes
      - predictScenariosPrep.R: replace S_ variable pattern with scenario_mods named list
      - applyUserModify.R: redesign user modification API (modify_fn parameter)
      - diagnosticSensitivity.R + diagnosticSpatialAutoCorr.R: inline plotParam specs from
        create_diagnosticPlotList.R (makes them independent before Plan 05D deletes it)
      - createSubdataSorted.R: harden eval() with tryCatch + envir restriction
    </key_actions>
    <eval_parse_reduction>~35 eliminated; 3 or fewer remain (all hardened)</eval_parse_reduction>
    <risk>Medium — applyUserModify API change; S_ named list must propagate fully.</risk>
  </sub_plan>

  <sub_plan id="05D" file="PLAN_05D_DIAGNOSTIC_PLOT_INFRASTRUCTURE.md">
    <title>Diagnostic Plot Infrastructure and plot.rsparrow()</title>
    <scope>Delete 19-file make_*/makeReport_*/create_diagnosticPlotList cluster; implement plot.rsparrow().</scope>
    <files_deleted_approx>19 (create_diagnosticPlotList.R + 8 makeReport_* + 10 make_*)</files_deleted_approx>
    <key_actions>
      - Fix unPackList() in diagnosticPlotsNLLS_dyn.R (pre-condition)
      - Inline create_diagnosticPlotList plot specs into diagnosticPlotsNLLS_dyn.R
      - Remove HTML report rendering from diagnosticPlotsNLLS.R (makeReport_* calls)
      - Inline make_*.R content into callers or keep as internal helpers
      - Delete: create_diagnosticPlotList.R, all makeReport_*.R, all make_*.R
      - Implement plot.rsparrow(type = c("residuals","sensitivity","spatial"))
      - Update plot.rsparrow.Rd man page
    </key_actions>
    <eval_parse_reduction>removes remaining infrastructure eval/parse (all in deleted files)</eval_parse_reduction>
    <risk>High — complex dependency chain; delete only after confirming 0 references per grep.</risk>
  </sub_plan>
</sub_plans>

<execution_order>
  05A must complete before 05B (unPackList.R deletion may affect predictBoot callers).
  05B must complete before 05C (predictScenarios eval/parse reduction scopes 05C correctly).
  05C must complete before 05D (05C decouples sensitivity/spatial from create_diagnosticPlotList,
    which is a prerequisite for 05D deleting create_diagnosticPlotList.R safely).
  05D must complete before Plan 06 (clean file count needed for test coverage planning).
</execution_order>

<aggregate_metrics>
  <metric name="Files deleted from R/">approx 35 (16 in 05A + 1 in 05B + 19 in 05D)</metric>
  <metric name="Files added to R/">1 (predict_core.R in 05B)</metric>
  <metric name="Net R/ file count">153 → approx 118</metric>
  <metric name="eval(parse()) eliminated">approx 160+ (116 in deleted files + 18 predict + 38 explicit)</metric>
  <metric name="eval(parse()) remaining">&lt;= 3 (all hardened user-expression sites)</metric>
  <metric name="Lines of code removed">approx 5000+ (deleted files) + 1000 (deduplication)</metric>
  <metric name="DESCRIPTION Collate entries removed">approx 35</metric>
</aggregate_metrics>

<overall_success_criteria>
  <criterion>0 REMOVE-list files remain in RSPARROW_master/R/ after Plan 05D</criterion>
  <criterion>eval(parse()) total in R/ &lt;= 3 after Plan 05D</criterion>
  <criterion>predict.list structure unchanged for UserTutorial model run</criterion>
  <criterion>plot.rsparrow(type="residuals") dispatches without error</criterion>
  <criterion>R CMD build succeeds after each sub-plan</criterion>
  <criterion>R CMD check shows no new errors beyond pre-existing dep-not-installed warnings</criterion>
</overall_success_criteria>

</plan>
