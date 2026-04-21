<architecture>

<overview>
rsparrow (formerly RSPARROW) package lives at the repo root (moved from RSPARROW_master/ in
Plan 07). Version 2.1.0. R CMD build produces rsparrow_2.1.0.tar.gz. Package is CRAN-ready
after Plans 01–16 (as of 2026-04-21).

Key API change (Plan 13): rsparrow_model() now accepts 4 data frames directly — no CSV files
required. output_dir=NULL (default) → pure in-memory run, no disk I/O.

Dependency state (Plans 14–16):
  Imports (2): nlmrt, numDeriv
  Suggests (8): car, stringi, knitr, leaflet, rmarkdown, sf, spdep, testthat
  Removed from Suggests (Plans 14–16): plyr, dplyr, data.table, plotly, ggplot2, gridExtra,
    gplots, mapview, magrittr (9 packages removed total from Plans 14–16)
</overview>

<directory_structure>
<dir path="[repo root]/">
  <dir path="R/">~78 active R source files (post Plan 16 removals; 13 exported + ~65 internal)</dir>
  <dir path="src/">6 Fortran source files (.f) only</dir>
  <dir path="man/">15 roxygen2 .Rd files (13 exported functions + package doc + sparrow_example dataset)</dir>
  <dir path="tests/testthat/">22 test files + fixtures/ + helper.R (163 passing tests post-Plan 13)</dir>
  <dir path="vignettes/">1 vignette (RSPARROW_vignette.Rmd)</dir>
  <dir path="inst/doc/">Full PDF documentation (RSPARROW_docV2.1.pdf)</dir>
  <dir path="inst/archived/">~40 archived R files in dynamic/ legacy_api/ legacy_data_import/ mapping/ utilities/</dir>
  <dir path="inst/legacy/">runRsparrow.R (preserved for reference)</dir>
  <dir path="inst/shiny_dss/">33 Shiny/GUI files (excluded from build)</dir>
  <file path="DESCRIPTION">Package: rsparrow, Version: 2.1.0, License: CC0, 2 Imports, 8 Suggests, R >= 4.4.0, LazyData: true</file>
  <file path="NAMESPACE">6 export() + 7 S3method() + selective importFrom() + useDynLib(rsparrow, .registration = TRUE)</file>
  <file path=".Rbuildignore">Excludes UserTutorial/, UserTutorialDynamic/, docs/, scripts/, inst/legacy/, inst/shiny_dss/</file>
</dir>
<dir path="UserTutorial/">Static TN model tutorial (gitignored): data/data1.csv, gis/*.shp</dir>
<dir path="UserTutorialDynamic/">Dynamic TP model tutorial (gitignored)</dir>
<note>Removed in Plan 01: batch/, inst/sas/, R-4.4.2.zip, code.json.
Removed in Plan 02: 19 legacy scaffolding files, 25 Shiny/GUI files moved to inst/shiny_dss/.
Moved to repo root in Plan 07 (was in RSPARROW_master/).
Archived in Plans 08-16: ~40 files in inst/archived/.</note>
</directory_structure>

<execution_flow>
<stage name="Entry (Legacy)">
User sources sparrow_control.R in RStudio, which set ~100 global variables and called
runRsparrow.R. This was a SCRIPT (not a function) that checked global state, loaded Fortran DLLs
via dyn.load(), and called executeRSPARROW(). Moved to inst/legacy/ in Plan 01.
</stage>

<stage name="Entry (New API — Plan 13, post Plans 14-16)">
rsparrow_model(reaches, parameters, design_matrix, data_dictionary,
               run_id="run1", output_dir=NULL, if_estimate=TRUE, if_predict=TRUE, if_validate=FALSE) →
  prep_sparrow_inputs() [validates + transforms 4 data frames] →
  startModelRun() [receives betavalues/dmatrixin directly; skips CSV reads] →
  controlFileTasksModel() → rsparrow S3 object

output_dir=NULL (default): pure in-memory run; no file I/O. All 35 dir.create/save/fwrite
calls are gated on output_dir != NULL (Plan 10).

All 13 exported functions implemented (read_sparrow_data removed in Plan 13):
  rsparrow_model()       — full estimation entry point (4-data-frame API)
  print/summary/coef/residuals/vcov.rsparrow() — S3 accessor methods
  predict.rsparrow()     — calls predict_sparrow() for reach-level load/yield predictions
  rsparrow_bootstrap()   — calls estimateBootstraps() for Monte Carlo uncertainty
  rsparrow_validate()    — calls validateMetrics() (requires if_validate="yes" at estimation)
  rsparrow_scenario()    — calls predictScenarios(Rshiny=FALSE) with source multipliers
  plot.rsparrow()        — base R graphics (Plans 05D + 16); type="residuals"/"sensitivity"/"spatial"
  write_rsparrow_results() — opt-in file output function (Plan 10)
  rsparrow_hydseq()      — hydrological sequencing helper

Plotting pipeline (Plan 16 — base R graphics; no Suggests required):
  plot.rsparrow(type="residuals")  → diagnosticPlotsNLLS → diagnosticPlots_4panel_A/B
  plot.rsparrow(type="sensitivity") → diagnosticSensitivity
  plot.rsparrow(type="spatial")    → diagnosticSpatialAutoCorr (requires spdep Suggests)

Wrapper functions access internal state via model$data, which stores estimate.list, data_names,
mapping.input.list, Vsites.list, classvar, and all other objects needed by internal functions.
</stage>

<stage name="Setup (executeRSPARROW)" status="DELETED">
executeRSPARROW.R was deleted in Plan 02 along with its supporting files (testSettings,
createDirs, makePaths, findControlFiles, generateInputLists, etc.). A replacement entry point
needs to be created as part of API design (Plan 03).
</stage>

<stage name="Data Preparation + Execution (startModelRun)">
Reads parameters.csv -> selectParmValues(). Reads design_matrix.csv -> selectDesignMatrix().
Filters data1 -> createSubdataSorted(). Applies user modifications -> applyUserModify().
Selects calibration/validation sites. Creates DataMatrix.list for optimization. Then
internally calls controlFileTasksModel() for estimation and prediction. Returns sparrow_state
named list containing ~30 fields (refactored from assign(.GlobalEnv) in Plan 04A; Plan 04D-3
added sparrow_state$estimate.list at line 484 to expose results to rsparrow_model()).
unPackList replaced with direct $ extractions. All downstream assign(.GlobalEnv) also
eliminated in Plan 04B (13 files, 23 assigns).
NOTE: rsparrow_model() calls startModelRun() only — not controlFileTasksModel() separately.
</stage>

<stage name="Model Execution (controlFileTasksModel)" note="called internally by startModelRun">
Dispatches to: estimate() -> estimateOptimize() -> estimateFeval() [calls Fortran tnoder].
Then: estimateNLLSmetrics() for diagnostics, diagnosticPlotsNLLS() for plots,
diagnosticSensitivity() for parameter sensitivity, predict_sparrow() for reach predictions
(renamed from predict() in Plan 03), estimateBootstraps() / predictBootstraps() for uncertainty,
predictScenarios() for scenarios. Finally: prediction maps and CSV output.
Returns runTimes named list containing estimate.list (passed back via sparrow_state in Plan 04D-3).
Core math files (estimateFeval, predict, predictBoot, predictSensitivity, predictScenarios,
estimateFevalNoadj, validateFevalNoadj) have specification-string eval(parse()) inlined as
direct R expressions (Plan 04B). No assign(.GlobalEnv) in any R/ file (Plan 04B).
All actionable unPackList() calls removed from non-REMOVE files (Plan 04C); replaced with
direct $ extractions and data.index.list$ prefixes. Fixable eval(parse()) for dynamic column
access replaced with [[]] in 6 data-prep files (Plan 04C). 65 COMPLEX eval(parse()) flagged
TODO Plan 05 across 14 files. Roxygen unPackList refs cleaned from ~48 files.
</stage>

<stage name="Interactive (Shiny)" status="SEPARATED">
Shiny app code (25 files) moved to inst/shiny_dss/ in Plan 02. shinyMap2.R launches the Shiny
app with interactive leaflet maps, scenario evaluation, site attribute display, and plot controls.
Depends on saved shinyArgs object from startModelRun. The runBatchShiny() call was removed from
startModelRun.R; shinyArgs save block retained for future companion package use.
</stage>
</execution_flow>

<module_classification>
<module name="Core Estimation" files="8">
estimateFeval.R, estimateFevalNoadj.R, estimateOptimize.R, estimateNLLSmetrics.R,
estimateNLLStable.R, estimateWeightedErrors.R, estimateBootstraps.R, estimate.R
Purpose: NLLS optimization, residual computation, diagnostics, uncertainty
Essential for CRAN: YES
</module>

<module name="Core Prediction" files="8">
predict.R, predictBoot.R, predictScenarios.R, predictScenariosPrep.R,
predictSensitivity.R, predictOutCSV.R, predictScenariosOutCSV.R, predictBootsOutCSV.R,
predictSummaryOutCSV.R, predictMaps.R, predictMaps_single.R, predictBootstraps.R
Purpose: Load/yield predictions, scenario analysis, CSV/map output
Essential for CRAN: YES (predict, scenarios); CSV output and maps are optional
</module>

<module name="Network Processing" files="5">
hydseq.R, hydseqTerm.R, upstream.R, deliver.R, accumulateIncrArea.R
(streamCatch.R moved to inst/shiny_dss/ in Plan 02 — was Shiny UI, not core network code)
Purpose: Hydrological sequencing, upstream accumulation, delivery fractions
Essential for CRAN: YES
</module>

<module name="Data Preparation" files="~20 active">
Active R/ files: createSubdataSorted.R, createDataMatrix.R, selectParmValues.R,
selectDesignMatrix.R, selectCalibrationSites.R, selectValidationSites.R, setNLLSWeights.R,
checkAnyMissingSubdataVars.R, checkMissingSubdataVars.R, checkClassificationVars.R,
checkFileEncoding.R, checkingMissingVars.R, startEndmodifySubdata.R,
createMasterDataDictionary.R, createInitialParameterControls.R, assignIncremSiteIDs.R, etc.
Purpose: Data validation, filtering, matrix construction (Plan 13: reads from data frames)
Essential for CRAN: YES
Archived (Plans 13+09): readData, readParameters, readDesignMatrix, read_dataDictionary,
  applyUserModify, dataInputPrep, checkData1NavigationVars, createVerifyReachAttr, etc.
</module>

<module name="Diagnostics and Visualization" files="7 active">
Active R/ files: diagnosticPlotsNLLS.R, diagnosticPlots_4panel_A/B.R,
diagnosticSensitivity.R, diagnosticSpatialAutoCorr.R, correlationMatrix.R, plot.rsparrow.R
Purpose: Diagnostic plots (base R graphics; no Suggests required except spdep for spatial)
Essential for CRAN: YES
Plan 16 changes: plotlyLayout.R/hline.R/addMarkerText.R deleted; all plotly code replaced
with base R (par/plot/abline/boxplot/qqnorm/qqline).
Archived: diagnosticPlotsValidate.R (Plan 16 — inlined into estimate.R),
  diagnosticPlotsNLLS_dyn.R (Plan 08), diagnosticMaps.R/mapSiteAttributes.R/predictMaps.R
  (Plan 05D), create_diagnosticPlotList.R/make_*.R/makeReport_*.R (Plan 05D),
  mapBreaks.R/mapLoopStr.R (Plan 09)
</module>

<module name="Shiny / GUI" files="25" location="inst/shiny_dss/ (MOVED in Plan 02)">
shinyMap2.R, shinyScenarios.R, shinyScenariosMod.R, shinySiteAttr.R, shinySavePlot.R,
shinyErrorTrap.R, handsOnMod.R, handsOnUI.R, goShinyPlot.R, runBatchShiny.R,
compileALL.R, compileInput.R, streamCatch.R, selectAll.R, updateVariable.R,
dropFunc.R, shapeFunc.R, createInteractiveChoices.R, convertHotTables.R,
sourceRedFunc.R, createRTables.R, testCosmetic.R, testRedTbl.R, validCosmetic.R,
allowRemoveRow.R
Purpose: Interactive Decision Support System
Status: MOVED to inst/shiny_dss/ in Plan 02. Excluded from package build via .Rbuildignore.
Preserved for future companion package rsparrow.dss.
</module>

<module name="Infrastructure / Orchestration" files="~12 remaining">
Remaining in R/: startModelRun.R, controlFileTasksModel.R, exitRSPARROW.R, unPackList.R
(only REMOVE-list callers remain; non-REMOVE calls eliminated in Plan 04C),
named.list.R, outputSettings.R, get*Sett.R (5 files: getCharSett, getNumSett, getOptionSett,
getShortSett, getSpecialSett, getYesNoSett), importCSVcontrol.R, errorOccurred.R
Deleted in Plan 02: executeRSPARROW.R, executionTree.R, generateInputLists.R,
findControlFiles.R, makePaths.R, createDirs.R, findCodeStr.R, findScriptName.R,
isScriptSaved.R, removeObjects.R, RSPARROW_objects.R, deleteFiles.R,
copyPriorModelFiles.R, testSettings.R, setMapDefaults.R, setupMaps.R,
openDesign.R, openParameters.R, openVarnames.R
Moved to inst/legacy/ in Plan 01: runRsparrow.R
Purpose: File management, settings parsing, global state management
Essential for CRAN: startModelRun and controlFileTasksModel need REFACTOR; rest should be REMOVED
</module>

<module name="Fortran Subroutines" files="6">
tnoder.f - Load accumulation returning residuals (estimation)
ptnoder.f - Load accumulation returning predictions (all reaches)
mptnoder.f - Monitoring-adjusted source load predictions
deliv_fraction.f - Delivery fraction computation
sites_incr.f - Incremental site attribute accumulation
sum_atts.f - Upstream attribute summation
Purpose: Numerically intensive network traversal
Essential for CRAN: YES
Status: DLLs removed, DLLEXPORT directives removed, renamed .for->.f (Plan 03), compiles
cleanly with gfortran on Linux. PACKAGE= args updated to "rsparrow" (Plan 03).
Registered via useDynLib(rsparrow, .registration = TRUE) in NAMESPACE.
</module>

<module name="Batch Mode" files="8" location="batch/ (DELETED)">
batchRun.R, batchMaps.R, batchGeoLines.R, batchlineShape.R,
batchpolyShape.R, batchMaps_checkDrain.R, interactiveBatchRun.R, shinyBatch.R
Purpose: Background execution via system(Rscript.exe) for large models
Status: DELETED in Plan 01 (Windows-only, used shell execution)
</module>
</module_classification>

<fortran_interface>
All Fortran subroutines use .Fortran() calls with PACKAGE="rsparrow" matching useDynLib in NAMESPACE.
Status: Pre-compiled DLLs removed; !GCC$ ATTRIBUTES DLLEXPORT directives removed. Source files
renamed from .for to .f (Plan 03). PACKAGE= arguments updated from individual routine names to
"rsparrow" (Plan 03). NAMESPACE uses useDynLib(rsparrow, .registration = TRUE). Fortran source
compiles cleanly with gfortran on Linux. The Fortran code is simple (30-45 lines each) and
implements efficient network traversal.
</fortran_interface>

<namespace_issues status="RESOLVED">
Resolved in Plan 01: Duplicate spdep import removed. useDynLib updated to package-level registration.
Resolved in Plan 02: 15 import() lines removed (packages no longer in Imports). Down from 37 to 22 directives.
Resolved in Plan 03: All blanket imports replaced with selective importFrom(). 13 functions
exported (6 export() + 7 S3method()). Imports reduced from 22 to 3 packages (data.table, nlmrt,
numDeriv); 12 moved to Suggests, 7 removed. NAMESPACE now has selective importFrom() directives
+ useDynLib(rsparrow, .registration = TRUE). Zero blanket imports remain.
</namespace_issues>

</architecture>
