<function_inventory>

<classification_key>
KEEP = Essential for core SPARROW modeling; include in CRAN package
REFACTOR = Needed but requires significant rework
REMOVE = Not needed for CRAN package (GUI, batch, infrastructure)
MERGE = Should be consolidated with related function to eliminate duplication
</classification_key>

<module name="Core Estimation">
<function name="estimateFeval" file="estimateFeval.R" lines="153" class="KEEP">
NLLS objective function. Computes weighted log-residuals via Fortran tnoder. Core SPARROW math.
Specification-string eval(parse()) replaced with inline R expressions (Plan 04B).
</function>
<function name="estimateFevalNoadj" file="estimateFevalNoadj.R" lines="139" class="MERGE">
Unconditioned variant of estimateFeval (ifadjust=0). ~95% identical code. Specification-string
eval(parse()) inlined (Plan 04B). Should be merged with estimateFeval via parameter flag.
</function>
<function name="estimateOptimize" file="estimateOptimize.R" lines="125" class="KEEP">
NLLS optimization wrapper around nlmrt::nlfb(). Sets up bounds, calls optimizer, saves results.
</function>
<function name="estimateNLLSmetrics" file="estimateNLLSmetrics.R" lines="832" class="REFACTOR">
Computes all diagnostic metrics (Jacobian SE, Hessian, leverage, ANOVA, eigenvalues).
Must be split into 5+ focused functions. 832 lines is unmanageable.
</function>
<function name="estimateNLLStable" file="estimateNLLStable.R" lines="692" class="REFACTOR">
Formats and writes text/CSV summary output. Uses sink() extensively. Should return structured
objects; let caller handle file output.
</function>
<function name="estimateWeightedErrors" file="estimateWeightedErrors.R" lines="97" class="KEEP">
Computes observation weights via power function regression. Standalone utility.
</function>
<function name="estimateBootstraps" file="estimateBootstraps.R" lines="197" class="KEEP">
Parametric bootstrap for coefficient uncertainty. Has recursive retry without depth limit.
</function>
<function name="estimate" file="estimate.R" lines="889" class="REFACTOR">
Master estimation orchestrator. Mixes estimation, diagnostics, validation, shapefile output.
All 4 assign(.GlobalEnv) removed (Plan 04B). Stale predict() call fixed to predict_sparrow()
(Plan 04B). Must be decomposed into focused functions.
</function>
<function name="validateMetrics" file="validateMetrics.R" lines="~200" class="KEEP">
Computes validation site metrics. Called from estimate.R when if_validate="yes".
</function>
<function name="validateFevalNoadj" file="validateFevalNoadj.R" lines="~140" class="MERGE">
Validation variant of FevalNoadj. Specification-string eval(parse()) inlined (Plan 04B).
data.index.list eval(parse()) loop replaced with direct $ prefixes (Plan 04C).
Another duplication candidate.
</function>
</module>

<module name="Core Prediction">
<function name="predict_sparrow" file="predict.R" lines="573" class="REFACTOR">
Core prediction function (renamed from predict() in Plan 03). Computes all load/yield metrics.
Specification-string eval(parse()) inlined (Plan 04B). assign(.GlobalEnv) removed (Plan 04B).
5 dynamic source variable eval(parse()) remain (flagged TODO Plan 05). unPackList roxygen refs
cleaned (Plan 04C). Heavy duplication with predictBoot. Should be refactored to share common
prediction engine.
</function>
<function name="predictBoot" file="predictBoot.R" lines="476" class="MERGE">
Bootstrap prediction variant. ~95% duplicate of predict.R. Specification-string eval(parse())
inlined (Plan 04B). 5 dynamic source variable eval(parse()) remain (flagged TODO Plan 05).
Must be merged with predict_sparrow().
</function>
<function name="predictBootstraps" file="predictBootstraps.R" lines="~150" class="KEEP">
Bootstrap prediction loop calling predictBoot for each iteration.
</function>
<function name="predictScenarios" file="predictScenarios.R" lines="821" class="REFACTOR">
Scenario analysis. Contains embedded prediction logic duplicated from predict.R plus
Shiny coupling. Specification-string eval(parse()) inlined, 2 assign(.GlobalEnv) removed
(Plan 04B). 5 dynamic source variable eval(parse()) remain (flagged TODO Plan 05).
Must extract core scenario logic from UI code.
</function>
<function name="predictScenariosPrep" file="predictScenariosPrep.R" lines="~300" class="REFACTOR">
Prepares scenario data modifications. 12 eval(parse()) remain (3 COMPLEX Shiny DSS expressions,
9 S_ bare-variable patterns). .GlobalEnv rm() removed, 1 fixable eval replaced (Plan 04C).
All flagged TODO Plan 05.
</function>
<function name="predictSensitivity" file="predictSensitivity.R" lines="179" class="MERGE">
Parameter sensitivity predictions. Another predict.R variant. Specification-string eval(parse())
inlined, dead spec-string params removed from signature (Plan 04B). unPackList replaced with
direct $ extractions + data.index.list$ prefixes (Plan 04C).
</function>
<function name="deliver" file="deliver.R" lines="31" class="KEEP">
Fortran wrapper for delivery fraction computation. Clean, minimal.
</function>
</module>

<module name="Network Processing">
<function name="hydseq" file="hydseq.R" lines="193" class="KEEP">
Hydrological sequencing (topological sort). Foundational reach ordering algorithm.
</function>
<function name="hydseqTerm" file="hydseqTerm.R" lines="~80" class="KEEP">
Terminal reach identification for hydseq.
</function>
<function name="upstream" file="upstream.R" lines="55" class="KEEP">
Recursive upstream reach identification. Modifies parent.frame - needs cleanup.
</function>
<function name="accumulateIncrArea" file="accumulateIncrArea.R" lines="~60" class="KEEP">
Incremental area accumulation via Fortran sum_atts.
</function>
<function name="sumIncremAttributes" file="sumIncremAttributes.R" lines="~50" class="KEEP">
Upstream attribute summation via Fortran sites_incr.
</function>
<function name="calcHeadflag" file="calcHeadflag.R" lines="~40" class="KEEP">
Computes headwater flags for reaches.
</function>
<function name="calcTermflag" file="calcTermflag.R" lines="~40" class="KEEP">
Computes terminal reach flags.
</function>
</module>

<module name="Data Preparation">
<function name="readData" file="readData.R" lines="~200" class="REFACTOR">
Reads data1.csv with encoding detection. Complex but necessary.
</function>
<function name="readParameters" file="readParameters.R" lines="~100" class="KEEP">
Reads parameters.csv. Straightforward.
</function>
<function name="readDesignMatrix" file="readDesignMatrix.R" lines="~80" class="KEEP">
Reads design_matrix.csv. Straightforward.
</function>
<function name="readForecast" file="readForecast.R" lines="~150" class="KEEP">
Reads forecast data for dynamic scenarios. 6 eval(parse()) replaced with named list +
vectorized ifelse + [[]] access (Plan 04C).
</function>
<function name="read_dataDictionary" file="read_dataDictionary.R" lines="~80" class="KEEP">
Reads dataDictionary.csv variable mapping.
</function>
<function name="createSubdataSorted" file="createSubdataSorted.R" lines="~80" class="KEEP">
Filters data1 by user conditions, sorts by hydseq. Unnecessary eval(parse()) removed;
1 remains for user-supplied filter_data1_conditions (flagged TODO Plan 05, Plan 04C).
</function>
<function name="createDataMatrix" file="createDataMatrix.R" lines="~200" class="REFACTOR">
Builds numeric DataMatrix.list for optimization. Complex index mapping.
</function>
<function name="selectParmValues" file="selectParmValues.R" lines="~100" class="KEEP">
Extracts active parameters from parameters.csv.
</function>
<function name="selectDesignMatrix" file="selectDesignMatrix.R" lines="~60" class="KEEP">
Subsets design matrix to active parameters.
</function>
<function name="selectCalibrationSites" file="selectCalibrationSites.R" lines="~150" class="KEEP">
Filters monitoring sites by area/distance criteria.
</function>
<function name="selectValidationSites" file="selectValidationSites.R" lines="~120" class="KEEP">
Selects validation site subset.
</function>
<function name="setNLLSWeights" file="setNLLSWeights.R" lines="~80" class="KEEP">
Computes NLLS regression weights.
</function>
<function name="dataInputPrep" file="dataInputPrep.R" lines="~150" class="REFACTOR">
Orchestrates data reading and navigation variable checking.
</function>
<function name="checkData1NavigationVars" file="checkData1NavigationVars.R" lines="~200" class="KEEP">
Validates reach network connectivity.
</function>
<function name="createVerifyReachAttr" file="createVerifyReachAttr.R" lines="~150" class="KEEP">
Computes/verifies reach attributes (hydseq, headflag, termflag, demtarea).
</function>
</module>

<module name="Data Validation">
<function name="checkAnyMissingSubdataVars" file="checkAnyMissingSubdataVars.R" class="KEEP">Check for missing data in subdata.</function>
<function name="checkMissingSubdataVars" file="checkMissingSubdataVars.R" class="KEEP">Check missing model variables.</function>
<function name="checkMissingData1Vars" file="checkMissingData1Vars.R" class="KEEP">Check missing data1 variables.</function>
<function name="checkClassificationVars" file="checkClassificationVars.R" class="KEEP">Validate classification variables.</function>
<function name="checkDrainageareaErrors" file="checkDrainageareaErrors.R" class="KEEP">Check drainage area consistency.</function>
<function name="checkDupVarnames" file="checkDupVarnames.R" class="KEEP">Check for duplicate variable names.</function>
<function name="verifyDemtarea" file="verifyDemtarea.R" class="KEEP">Verify total drainage area.</function>
<function name="checkingMissingVars" file="checkingMissingVars.R" class="KEEP">Generic missing variable checker.</function>
</module>

<module name="Diagnostics and Visualization">
<function name="diagnosticPlotsNLLS" file="diagnosticPlotsNLLS.R" class="KEEP">Master diagnostic plots orchestrator. Draws estimation/simulation performance panels (p1–p15) using base R graphics. plotly removed in Plan 16.</function>
<function name="diagnosticPlotsNLLS_dyn" file="archived/dynamic/" class="REMOVE" status="DELETED_08">Dynamic model diagnostic plots. Archived in Plan 08.</function>
<function name="diagnosticPlotsValidate" file="diagnosticPlotsValidate.R" class="KEEP">Thin wrapper calling diagnosticPlotsNLLS with validation=TRUE. No plotly references.</function>
<function name="diagnosticPlots_4panel_A" file="diagnosticPlots_4panel_A.R" class="KEEP">4-panel obs/pred and residuals scatter plots. Base R graphics (par/plot/abline). plotly removed in Plan 16.</function>
<function name="diagnosticPlots_4panel_B" file="diagnosticPlots_4panel_B.R" class="KEEP">4-panel boxplot/Q-Q/squared-resid plots. Base R graphics (boxplot/qqnorm/qqline/plot). plotly removed in Plan 16.</function>
<function name="diagnosticMaps" file="diagnosticMaps.R" class="REMOVE" status="DELETED_05A">Interactive diagnostic maps (59 eval/parse). Deleted in Plan 05A.</function>
<function name="diagnosticSensitivity" file="diagnosticSensitivity.R" class="KEEP">Parameter sensitivity analysis. Per-parameter boxplots and error-bar summary charts in base R. plotly removed in Plan 16.</function>
<function name="diagnosticSpatialAutoCorr" file="diagnosticSpatialAutoCorr.R" class="KEEP">Moran's I spatial autocorrelation. CDF plots (p19/p20) and Moran's I panels (p21/p22) in base R. eval(parse()) for MoranDistanceWeightFunc preserved (deferred to Plan 16). plotly removed in Plan 16.</function>
<function name="plotlyLayout" file="plotlyLayout.R" class="REMOVE" status="DELETED_16">plotly layout helper (8 eval/parse). Deleted in Plan 16 (base R plotting plan).</function>
<function name="hline" file="hline.R" class="REMOVE" status="DELETED_16">plotly horizontal-line shape helper. Deleted in Plan 16.</function>
<function name="addMarkerText" file="addMarkerText.R" class="REMOVE" status="DELETED_16">plotly hover-text builder. Deleted in Plan 16.</function>
<function name="correlationMatrix" file="correlationMatrix.R" class="KEEP">Explanatory variable correlation computation.</function>
<function name="mapSiteAttributes" file="mapSiteAttributes.R" class="REMOVE" status="DELETED_05A">Interactive site attribute maps (19 eval/parse). Deleted in Plan 05A.</function>
<function name="predictMaps" file="predictMaps.R" class="REMOVE" status="DELETED_05A">Prediction mapping. Deleted in Plan 05A.</function>
<function name="predictMaps_single" file="predictMaps_single.R" class="REMOVE" status="DELETED_05A">Single-variable prediction maps (23 eval/parse). Deleted in Plan 05A.</function>
<function name="create_diagnosticPlotList" file="create_diagnosticPlotList.R" class="REMOVE" status="DELETED_05D">2132-line named list of plot specs. Deleted in Plan 05D; callers inlined.</function>
<function name="makeReport_*" file="makeReport_*.R (8 files)" class="REMOVE" status="DELETED_05D">Rmd report generation for HTML diagnostics. All 8 deleted in Plan 05D.</function>
<function name="make_*" file="make_*.R (10 files)" class="REMOVE" status="DELETED_05D">Plot generation helpers. All 10 deleted in Plan 05D; bodies inlined into callers.</function>
<function name="render_report" file="render_report.R" class="REMOVE" status="DELETED_05D">Orphaned report renderer. Deleted in Plan 05D.</function>
</module>

<module name="CSV Output">
<function name="predictOutCSV" file="predictOutCSV.R" class="REFACTOR">Write load/yield prediction CSVs.</function>
<function name="predictScenariosOutCSV" file="predictScenariosOutCSV.R" class="REFACTOR">Write scenario prediction CSVs.</function>
<function name="predictBootsOutCSV" file="predictBootsOutCSV.R" class="REFACTOR">Write bootstrap prediction CSVs.</function>
<function name="predictSummaryOutCSV" file="predictSummaryOutCSV.R" class="REFACTOR">Write summary prediction CSVs.</function>
</module>

<module name="Shiny / GUI (MOVED to inst/shiny_dss/ in Plan 02)" status="SEPARATED">
All 25 files moved from R/ to inst/shiny_dss/. Excluded from package build via .Rbuildignore.
Preserved for future companion package rsparrow.dss.
Files: shinyMap2.R, goShinyPlot.R, runBatchShiny.R, shinyScenarios.R, shinySiteAttr.R,
streamCatch.R, dropFunc.R, handsOnUI.R, shapeFunc.R, createInteractiveChoices.R,
shinyScenariosMod.R, handsOnMod.R, compileALL.R, compileInput.R, selectAll.R,
updateVariable.R, shinyErrorTrap.R, shinySavePlot.R, testCosmetic.R, testRedTbl.R,
validCosmetic.R, allowRemoveRow.R, convertHotTables.R, sourceRedFunc.R, createRTables.R
</module>

<module name="Infrastructure (partially cleaned in Plans 01-02)">
<function name="startModelRun" file="startModelRun.R" class="REFACTOR">Data prep orchestrator. Global assigns eliminated; now returns sparrow_state list (Plan 04A Task 2). unPackList replaced with direct $ extractions. runBatchShiny() call removed in Plan 02. Dead spec-string extractions removed (Plan 04B).</function>
<function name="controlFileTasksModel" file="controlFileTasksModel.R" class="REFACTOR">Task dispatcher; extract clean API. unPackList and assign(.GlobalEnv) removed (Plan 04A Task 3). min.sites.list parameter added.</function>
<function name="unPackList" file="unPackList.R" class="REMOVE">Global state injector; must be eliminated entirely.</function>
<function name="named.list" file="named.list.R" class="KEEP">Creates named list from variable names. Simple utility.</function>
<function name="get*Sett (6 files)" file="getCharSett.R, getNumSett.R, getOptionSett.R, getShortSett.R, getSpecialSett.R, getYesNoSett.R" class="REMOVE" status="DELETED_05A">Setting name enumerators. Deleted in Plan 05A.</function>
<function name="outputSettings" file="outputSettings.R" class="REMOVE" status="DELETED_05A">Settings dump. Deleted in Plan 05A.</function>
<function name="importCSVcontrol" file="importCSVcontrol.R" class="REMOVE" status="DELETED_05A">CSV control file importer. Deleted in Plan 05A; callers inlined with fread.</function>
<function name="errorOccurred" file="errorOccurred.R" class="REMOVE" status="DELETED_05A">Error handler. Deleted in Plan 05A; callers use stop().</function>
<function name="exitRSPARROW" file="exitRSPARROW.R" class="REMOVE" status="DELETED_05A">Cleanup and exit. Deleted in Plan 05A; callers use stop().</function>

Deleted in Plan 02 (19 files):
  executeRSPARROW.R, findControlFiles.R, generateInputLists.R, makePaths.R, createDirs.R,
  setupMaps.R, testSettings.R, setMapDefaults.R, isScriptSaved.R, openDesign.R,
  openParameters.R, openVarnames.R, removeObjects.R, deleteFiles.R, RSPARROW_objects.R,
  copyPriorModelFiles.R, findScriptName.R, executionTree.R, findCodeStr.R
Moved to inst/legacy/ in Plan 01: runRsparrow.R
</module>

<module name="Miscellaneous Utilities">
<function name="getVarList" file="getVarList.R" class="KEEP">Returns standard SPARROW variable names.</function>
<function name="calcDemtareaClass" file="calcDemtareaClass.R" class="KEEP">Drainage area classification.</function>
<function name="calcIncremLandUse" file="calcIncremLandUse.R" class="KEEP">Incremental land use calculation.</function>
<function name="calcClassLandusePercent" file="calcClassLandusePercent.R" class="KEEP">Land use percent by class.</function>
<function name="eigensort" file="eigensort.R" class="KEEP">Eigenvalue sorting utility.</function>
<function name="getdindx/getuindx" file="getdindx.R, getuindx.R" class="KEEP">Index helpers for hydseq.</function>
<function name="replaceNAs" file="replaceNAs.R" class="KEEP">NA replacement utility.</function>
<function name="syncVarNames" file="syncVarNames.R" class="KEEP">Variable name synchronization.</function>
<function name="addVars" file="addVars.R" class="REFACTOR">Add variables to data dictionary.</function>
<function name="applyUserModify" file="applyUserModify.R" class="REFACTOR">Apply user data modifications.</function>
<function name="checkDynamic" file="checkDynamic.R" class="KEEP">Check if model is dynamic (has year/season).</function>
<function name="modelCompare" file="modelCompare.R" class="REMOVE">Model comparison (file-based).</function>
</module>

<summary>
After Plan 02: 139 R files in R/ + 25 in inst/shiny_dss/ + 6 Fortran = 170
  (44 files removed from R/: 25 moved to inst/shiny_dss/, 19 deleted)
Remaining classification: KEEP ~45, REFACTOR ~25, MERGE ~5, REMOVE ~65
Estimated CRAN package size: ~50-60 functions (down from original 184)
</summary>

</function_inventory>
