<file_inventory>
<overview>
Complete per-task file listing for Plan 04. Files on the REMOVE list (Plan 05) are excluded
from all tasks — do not modify them. They will be deleted before CRAN submission.
</overview>

<remove_list label="Do NOT modify these files in Plan 04 — Plan 05 deletes them">
diagnosticMaps.R, predictMaps.R, predictMaps_single.R, mapSiteAttributes.R,
create_diagnosticPlotList.R, mapLoopStr.R, plotlyLayout.R, addMarkerText.R,
aggDynamicMapdata.R, mapBreaks.R, modelCompare.R, outputSettings.R,
diagnosticPlotsNLLS.R, diagnosticPlotsNLLS_dyn.R, diagnosticPlotsValidate.R,
make_residMaps.R, make_dyndiagnosticPlotsNLLS.R, make_dyndiagnosticPlotsNLLS_corrPlots.R,
make_dyndiagnosticPlotsNLLS_sensPlots.R, make_drainageAreaErrorsPlot.R,
make_drainageAreaErrorsMaps.R, make_diagnosticPlotsNLLS_timeSeries.R,
make_modelEstPerfPlots.R, make_modelSimPerfPlots.R, make_siteAttrMaps.R
</remove_list>

<task_files id="1" name="Remove Windows-only code" subplan="04-A" status="complete">
<file path="startModelRun.R" issues="shell.exec() near line 540; batch_mode branches throughout"/>
<file path="createInitialParameterControls.R" issues="shell.exec()"/>
<file path="createInitialDataDictionary.R" issues="shell.exec()"/>
<file path="addVars.R" issues="shell.exec()"/>
Also modified: controlFileTasksModel.R, estimate.R, estimateBootstraps.R, predictBootstraps.R
</task_files>

<task_files id="2" name="startModelRun.R global assigns" subplan="04-A" status="complete">
<file path="startModelRun.R" assign_count="27">
All 27 assigns converted to sparrow_state$varname accumulator pattern.
</file>
</task_files>

<task_files id="3" name="controlFileTasksModel.R refactoring" subplan="04-A" status="complete">
<file path="controlFileTasksModel.R" assign_count="1" unpacklist_count="2">
  Primary unPackList removed; 1 assign(.GlobalEnv) removed; min.sites.list parameter added.
</file>
</task_files>

<task_files id="4" name="Remaining assign(.GlobalEnv) in 13 files" subplan="04-B" status="complete">
All 23 assign(.GlobalEnv) eliminated from 13 files:
  - predict.R, correlationMatrix.R, diagnosticSensitivity.R, estimateWeightedErrors.R,
    setNLLSWeights.R, estimateBootstraps.R: simple removal (already returning value)
  - predictBootstraps.R (2), predictScenarios.R (2): removed
  - checkDrainageareaMapPrep.R (2): removed (only caller on REMOVE list)
  - findMinMaxLatLon.R (4): now returns list(sitegeolimits, mapping.input.list); caller updated
  - replaceData1Names.R (1): now returns list(data1, data_names); caller updated
  - dataInputPrep.R (2): now returns list(data1, data_names)
  - estimate.R (4): removed all GlobalEnv assigns; preserved file save logic
Verification: grep -rn "assign.*\.GlobalEnv" RSPARROW_master/R/ returns 0 lines
</task_files>

<task_files id="5" name="Specification string eval(parse()) — 7 files, 21 occurrences" subplan="04-B" status="complete">
All 21 specification-string eval(parse()) calls inlined as direct R expressions:
  - estimateFeval.R, estimateFevalNoadj.R, validateFevalNoadj.R (3 each)
  - predict.R, predictBoot.R, predictSensitivity.R, predictScenarios.R (3 each)
  - Inlined: reach_decay (exp(-data[,jdecvar[i]] * beta1[,jbdecvar[i]])),
    reservoir_decay (1/(1 + data[,jresvar[i]] * beta1[,jbresvar[i]])),
    incr_delivery (exp(ddliv1 %*% t(dlvdsgn)))
Cleanup completed:
  - getCharSett.R: 3 spec-string variable names removed
  - getShortSett.R: 3 spec-string variable names removed
  - estimateOptimize.R: spec-string storage lines removed
  - predictSensitivity.R: 3 dead spec-string params removed from signature + callers
  - startModelRun.R: dead spec-string extractions removed
</task_files>

<task_files id="6" name="unPackList — core estimation/prediction chain (12 files)" subplan="04-C" status="complete">
All 12 files verified clean — unPackList() calls had already been removed in Plans 04A/04B.
Only roxygen documentation references remained, which were cleaned. Additionally:
  - predictSensitivity.R: unPackList replaced with direct $ extractions + data.index.list$ prefixes
  - diagnosticSensitivity.R: unPackList replaced with 6 direct extractions + 1 eval(parse()) fixed
  - checkDrainageareaMapPrep.R: unPackList replaced with 6 direct extractions + 4 eval(parse()) fixed
  - validateFevalNoadj.R: data.index.list eval(parse()) loop → data.index.list$ prefix pattern
</task_files>

<task_files id="7" name="unPackList — core data preparation chain (24 files)" subplan="04-C">
<file path="readData.R" unpacklist="1"/>
<file path="readParameters.R" unpacklist="1" also_fix="eval(parse) x2"/>
<file path="readDesignMatrix.R" unpacklist="1"/>
<file path="readForecast.R" unpacklist="1" also_fix="eval(parse) x6"/>
<file path="createDataMatrix.R" unpacklist="2" also_fix="eval(parse) x7"/>
<file path="createSubdataSorted.R" unpacklist="0" also_fix="eval(parse) x2"/>
<file path="selectCalibrationSites.R" unpacklist="1"/>
<file path="selectValidationSites.R" unpacklist="1"/>
<file path="setNLLSWeights.R" unpacklist="1"/>
<file path="correlationMatrix.R" unpacklist="1" also_fix="eval(parse) x4"/>
<file path="hydseq.R" unpacklist="1"/>
<file path="hydseqTerm.R" unpacklist="1"/>
<file path="calcHeadflag.R" unpacklist="1"/>
<file path="calcTermflag.R" unpacklist="1"/>
<file path="checkClassificationVars.R" unpacklist="1"/>
<file path="checkMissingSubdataVars.R" unpacklist="2"/>
<file path="checkAnyMissingSubdataVars.R" unpacklist="1"/>
<file path="checkMissingData1Vars.R" unpacklist="1"/>
<file path="checkData1NavigationVars.R" unpacklist="0" also_fix="eval(parse) x4"/>
<file path="applyUserModify.R" unpacklist="2" also_fix="eval(parse) x6"/>
<file path="syncVarNames.R" unpacklist="1"/>
<file path="addVars.R" unpacklist="1"/>
<file path="createMasterDataDictionary.R" unpacklist="1"/>
<file path="read_dataDictionary.R" unpacklist="1"/>
<additional_eval_parse_only>
  verifyDemtarea.R (x2), createVerifyReachAttr.R (x2), accumulateIncrArea.R (x2),
  importCSVcontrol.R (x2), checkingMissingVars.R (x4)
</additional_eval_parse_only>
</task_files>

<task_files id="8_to_12" name="Skeleton implementations" subplan="04-D" status="complete">
<file path="print.rsparrow.R" task="8" status="implemented"/>
<file path="summary.rsparrow.R" task="8" status="implemented"/>
<file path="coef.rsparrow.R" task="8" status="implemented"/>
<file path="residuals.rsparrow.R" task="8" status="implemented"/>
<file path="vcov.rsparrow.R" task="8" status="implemented"/>
<file path="plot.rsparrow.R" task="8" status="stub → partial (diagnostics deferred to Plan 05)"/>
<file path="rsparrow_model.R" task="9" status="implemented"/>
<file path="read_sparrow_data.R" task="10" status="implemented"/>
<file path="rsparrow_bootstrap.R" task="11" status="implemented"/>
<file path="rsparrow_scenario.R" task="11" status="implemented"/>
<file path="rsparrow_validate.R" task="11" status="implemented"/>
<file path="predict.rsparrow.R" task="12" status="implemented"/>
</task_files>

<total_counts>
Files with assign(.GlobalEnv) to fix: 15 files, 51 occurrences — ALL RESOLVED (Plans 04A + 04B)
Files with unPackList to fix (Tasks 6+7): ~35 files, ~80 occurrences — ALL RESOLVED (Plan 04C)
Files with spec-string eval/parse to fix (Task 5): 7 files, 21 occurrences — ALL RESOLVED (Plan 04B)
Files with dynamic-column eval/parse to fix (Task 7): ~19 files, ~55 occurrences — ALL RESOLVED (Plan 04C)
Files with shell.exec to fix (Task 1): 4+ files — ALL RESOLVED (Plan 04A)
Skeleton files to implement (Tasks 8-12): 13 files — ALL IMPLEMENTED (Plans 04D-1 through 04D-4)
REMOVE list files (skip entirely): 25 files
</total_counts>

</file_inventory>
