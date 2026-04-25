<technical_debt>

<severity_critical>

<issue name="Pervasive Global State Management" status="RESOLVED">
All 51 assign(..., envir=.GlobalEnv) calls eliminated across Plans 04A and 04B. Zero remain in R/.
Plan 04A (28 assigns): startModelRun.R (27) now returns sparrow_state named list; unPackList
replaced with direct $ extractions. controlFileTasksModel.R (1) refactored.
Plan 04B (23 assigns across 13 files): predict.R, correlationMatrix.R, diagnosticSensitivity.R,
estimateWeightedErrors.R, setNLLSWeights.R, estimateBootstraps.R (simple removal — already
return value); predictBootstraps.R (2), predictScenarios.R (2), checkDrainageareaMapPrep.R (2),
estimate.R (4) removed; findMinMaxLatLon.R (4) now returns list; replaceData1Names.R (1) and
dataInputPrep.R (2) now return lists with callers updated.
executeRSPARROW.R (6) and generateInputLists.R (6) were deleted in Plan 02.
Plan 04C: All actionable unPackList() calls removed from non-REMOVE files. 3 files refactored
(predictSensitivity.R, diagnosticSensitivity.R, checkDrainageareaMapPrep.R) with direct $
extractions + data.index.list$ prefixes. 1 unPackList call remains in applyUserModify.R inside
a dynamically constructed function string. Roxygen \item unPackList.R references cleaned from
~48 non-REMOVE files. .GlobalEnv rm() calls removed from predictScenariosPrep.R.
replaceNAs.R parent.frame() injection antipattern flagged TODO Plan 05.
Plan 05C: The remaining unPackList() in applyUserModify.R's generated function string was
removed and replaced with explicit assign() loops (Option B). The string itself still uses
outer eval(parse()) to evaluate the user-supplied function — unavoidable without API redesign.
Plan 05D: All REMOVE-list files that called unPackList() deleted (create_diagnosticPlotList.R,
make_*.R, makeReport_*.R, render_report.R). unPackList.R itself remained in R/ with 3 COMPLEX/
deferred callers (mapLoopStr.R, replaceNAs.R, applyUserModify.R); deletion deferred beyond Plan 05D.
Plan 09: unPackList.R and mapLoopStr.R (its last active caller) both archived to
inst/archived/utilities/ and inst/archived/mapping/ respectively. replaceNAs.R retains a TODO
comment; applyUserModify.R replaced its unPackList call with explicit assign loops in Plan 05C.
Zero unPackList() calls remain in R/.
</issue>

<issue name="eval(parse(text=...)) Anti-Pattern" status="PARTIALLY_RESOLVED">
6 occurrences remain across R/ (down from 339 across 61 files originally; 25 post-Plan 09;
10 post-Plan 15; 9 after Plan 16 archives replaceNAs.R; 6 after Plan 18D removes 3 Shiny-only calls).
Remaining in active R/ (all NECESSARY or DEFERRED — each has a GH issue):
- diagnosticSpatialAutoCorr.R (5, GH #21): MoranDistanceWeightFunc is a user-supplied R
  expression string for spatial weight computation. Cannot remove without API change.
  Suggested fix: accept function object as alternative to string.
- createSubdataSorted.R (1, GH #23): filter_data1_conditions is a user-supplied character
  vector of R filter expressions. Hardened with tryCatch (Plan 05C).
  Suggested fix: accept function(data1) as alternative form.
- GH #22 RESOLVED (Plan 18D): 3 Shiny DSS eval/parse calls in predictScenariosPrep.R removed.
Archived/Resolved (Plans 08–16):
- replaceNAs.R (1): ARCHIVED Plan 16 — 0 active callers (applyUserModify + mapSiteAttributes both archived)
- plotlyLayout.R (8): DELETED Plan 16 (base R plotting) — file deleted
- applyUserModify.R (2): ARCHIVED Plan 13 — file archived to legacy_data_import/
- diagnosticPlotsNLLS.R hover-text (3) + predict_core.R (1): REMOVED Plan 15/16 — plotly removed
- mapLoopStr.R (11), unPackList.R (1), naOmitFuncStr.R (1): ARCHIVED Plan 09
- aggDynamicMapdata.R (5), diagnosticPlotsNLLS_dyn.R (2), _timeSeries.R (2): ARCHIVED Plan 08
- checkDrainageareaErrors.R (1): ARCHIVED Plan 09
- diagnosticMaps.R (59), predictMaps_single.R (23), mapSiteAttributes.R (19): DELETED Plan 05D
Resolved in Plans 04B/04C/05B/05C/05D: 300+ calls eliminated across all core math files.
</issue>

<issue name="Exported API Functions Were Stubs" status="RESOLVED">
Plan 03 created 13 exported function skeletons with stop("Not yet implemented"). Plans 04D-1
through 04D-4 implemented all 13. Plan 05D implemented plot.rsparrow() fully. Key decisions:
04D-1: print/summary/coef/residuals/vcov S3 bodies; plot.rsparrow() informative stub (→Plan 05D);
print.summary.rsparrow registered in NAMESPACE.
Plan 05D: plot.rsparrow() fully implemented with type= dispatch: "residuals" →
diagnosticPlots_4panel_A/B, "sensitivity" → diagnosticSensitivity, "spatial" →
diagnosticSpatialAutoCorr. All 13 exported functions are fully implemented.
04D-2: read_sparrow_data() with explicit path config; path_results/path_data must end with
.Platform$file.sep; dataDictionary.csv copied to path_results with run_id prefix.
04D-3: rsparrow_model() orchestrates read_sparrow_data() → startModelRun(); estimate.list
exposed from sparrow_state via one-line patch at startModelRun.R:484; estimate.input.list
extended with ConcFactor/loadUnits/yieldUnits/ConcUnits; all rsparrow object field names
verified against actual estimateNLLSmetrics.R output structure.
04D-4: predict.rsparrow() calls predict_sparrow() (7-arg signature including dlvdsgn);
object_to_estimate_list() returns model$data$estimate.list directly; rsparrow_bootstrap()
calls estimateBootstraps(); rsparrow_validate() calls validateMetrics() (requires model
estimated with if_validate="yes"); rsparrow_scenario() calls predictScenarios(Rshiny=FALSE)
with source_changes translated to scenario_sources/scenario_factors; model$data extended with
estimate.list, data_names, mapping.input.list, Vsites.list, classvar.
</issue>

<issue name="No NAMESPACE Exports" status="RESOLVED">
NAMESPACE previously contained 21 blanket import() directives and zero exported functions.
Resolution: Plan 03 created 13 exported functions (6 standalone + 7 S3 methods for class
"rsparrow"), replaced all blanket imports with selective importFrom() directives, created
R/rsparrow-package.R with @useDynLib and @importFrom tags. NAMESPACE now has 6 export() +
7 S3method() + ~60 importFrom() + 1 useDynLib(). Imports reduced from 22 to 3 packages.
</issue>

<issue name="runRsparrow.R Is a Script, Not a Function" status="RESOLVED">
R/runRsparrow.R contained top-level executable code (if/exists checks, dyn.load calls, global
option setting) rather than a function definition. This is invalid for R packages; all files
in R/ must contain only function/method/class definitions.
Resolution: Moved to inst/legacy/runRsparrow.R in Plan 01. Removed from Collate field.
</issue>

<issue name="Pre-compiled Windows DLLs in src/" status="RESOLVED">
src/ contained 6 .dll files alongside .for source. CRAN requires source-only; binaries must be
compiled during R CMD INSTALL. The Fortran files contained Windows-specific directives:
!GCC$ ATTRIBUTES DLLEXPORT::subroutine_name
Resolution: All 6 DLLs deleted, all DLLEXPORT directives removed in Plan 01. Fortran compiles
cleanly from source with gfortran.
</issue>

<issue name="License Incompatibility" status="RESOLVED">
DESCRIPTION declared License: GPL (>= 2), but LICENSE.md contained USGS Software User Rights
Notice which is a different license. CRAN requires the declared license to match actual terms.
Resolution: License changed to CC0 in DESCRIPTION. LICENSE.md rewritten with CC0 1.0 Universal
text and USGS public domain disclaimer. Resolved in Plan 01.
</issue>

</severity_critical>

<severity_high>

<issue name="Windows-Only Code" status="RESOLVED">
All shell.exec(), Sys.which("Rscript.exe"), and batch_mode references removed from non-REMOVE
files in Plan 04A Task 1. Remaining batch_mode references exist only in 7 REMOVE-list files
(to be deleted in Plan 05). README still states "requires a 64-bit processor on a Windows
platform" — needs update.
Resolution: Plan 04A Task 1 removed all Windows-only code from startModelRun.R,
controlFileTasksModel.R, createInitialParameterControls.R, createInitialDataDictionary.R,
addVars.R, and other non-REMOVE files.
</issue>

<issue name="Massive Code Duplication" status="RESOLVED">
predict.R (573 lines), predictBoot.R (476 lines), and predictScenarios.R (821 lines) shared
~80% identical logic for load accumulation, source attribution, and yield computation.
estimateFeval.R and estimateFevalNoadj.R differed only in ifadjust flag and weight handling.
Resolution (Plan 05B): predict_core.R (266 lines) created as shared kernel; predict.R reduced
to 291 lines, predictBoot.R to 190, predictScenarios.R to 523. estimateFevalNoadj.R deleted;
estimateFeval.R now accepts ifadjust=1L/0L with backward-compatible estimateFevalNoadj wrapper.
dlvdsgn added as explicit parameter to predictScenarios() (was implicit via global env — bug).
All 18 dynamic source variable eval(parse()) calls eliminated; pload_src named lists used.
</issue>

<issue name="Monolithic Functions" status="PARTIALLY_RESOLVED">
Post-Plan 16 line counts (Plans 05B+10 reduced these from original sizes):
- estimate.R: 693 lines — seam comments added Plan 16; GH #24 opened for Plan 17+ decomposition
  6 natural seams documented: setup → estimateOptimize → metrics/table → diagnostic plots →
  simulation loop → prediction pathway. Extraction candidate: estimateDiagnostics().
- estimateNLLSmetrics.R: 661 lines — seam comments added Plan 16; GH #25 opened
  5 seams: setup → Jacobian/leverage/VIF → residual diagnostics → ANOVA → assembly
- estimateNLLStable.R: 550 lines — seam comments added Plan 16; GH #25 opened
  4 seams: header/ANOVA → parameter table → residuals table → Jacobian derivatives
- predictScenarios.R: 523 lines — reduced from 821 in Plan 05B; no further action this cycle
- controlFileTasksModel.R: ~525 lines — task dispatch; acceptable for orchestrator role
Impact: Individual seams untestable. Addressed in Plan 17+.
</issue>

<issue name="Blanket Package Imports" status="RESOLVED">
NAMESPACE previously imported entire namespaces of 21 packages with many except= conflict resolutions.
Resolution: Duplicate spdep import removed, useDynLib fixed in Plan 01. 15 import() lines
removed in Plan 02. All remaining blanket imports replaced with selective importFrom() in Plan 03.
Imports reduced from 40 to 3 (data.table, nlmrt, numDeriv); 12 moved to Suggests, 7 removed.
NAMESPACE now uses selective importFrom() only. Zero blanket imports remain.
</issue>

<issue name="No Input Validation">
Functions do not validate input dimensions, types, or ranges. .Fortran() calls pass data
without checking matrix dimensions or NA patterns. estimateFeval converts NAs to 0 silently.
Division by zero risks in predict.R (source shares) and estimateNLLSmetrics.R (ratio.obs.pred).
Impact: Silent incorrect results. Cryptic Fortran crashes. Data quality issues go undetected.
</issue>

<issue name="Maintainer Field Format" status="RESOLVED">
DESCRIPTION listed multiple maintainers. CRAN requires exactly one Maintainer with a single
email address. The Author field should use Authors@R with person() entries.
Resolution: Converted to Authors@R format with Kyle Hurley as cre (maintainer) in Plan 01.
</issue>

</severity_high>

<severity_medium>

<issue name="sink() for File Output" status="RESOLVED">
Plan 10 (GH #16): All sink() calls now protected with on.exit(sink(), add=TRUE).
estimateOptimize.R, estimateNLLStable.R, controlFileTasksModel.R all fixed.
Note: sink() calls only execute when output_dir is set; pure in-memory runs skip them.
</issue>

<issue name="Hardcoded Path Construction">
Paths built via paste0(path_results, .Platform$file.sep, "estimate", ...) throughout.
No centralized path management. path_results comes from global state.
</issue>

<issue name="Magic Numbers and Strings">
Unexplained numeric thresholds: leverageCrit=(3*npar)/mobs, NLS initial values a=1/b1=-0.1,
column indices like data[,10] for jdepvar, data[,13] for calsites. String comparisons
like if_estimate=="yes" instead of logical TRUE/FALSE.
</issue>

<issue name="Yes/No String Settings Instead of Logical">
All control settings use character "yes"/"no" instead of logical TRUE/FALSE. Comparison
via == "yes" is fragile (case sensitivity, whitespace). ~50 such settings throughout.
</issue>

<issue name="File I/O Side Effects in Modeling Functions">
estimate.R creates directories and writes shapefiles (ESRI output). Functions mix computation
with I/O. predict.R's assign(.GlobalEnv) side effect removed in Plan 04B; function now returns
predict.list directly without global side effects.
</issue>

<issue name="Recursive Bootstrap Without Depth Limit">
estimateBootstraps.R uses Recall() recursion when Jacobian is singular. No maximum recursion
depth. Could infinite loop on pathological data.
</issue>

<issue name="Test Coverage Gaps">
16 test files cover: report generation (7), data reading (3), dynamic model checking (1),
data sorting (1), file copying (1), parameter handling (3). No tests for: estimateFeval,
predict, deliver, hydseq, estimateOptimize, bootstrap estimation, scenario predictions.
Core mathematical functions have zero test coverage.
</issue>

<issue name="Shiny Code Entangled with Core" status="RESOLVED">
25 Shiny/GUI files moved to inst/shiny_dss/ in Plan 02 (including shinyMap2.R, streamCatch.R,
and all UI/server modules). runBatchShiny() call removed from startModelRun.R.
Plan 18A: All 25 shiny_dss files archived to inst/archived/shiny_dss/. stringi/leaflet removed.
Plan 18D: Rshiny/input parameters removed from predictScenarios.R, predictScenariosPrep.R, and
predictScenariosOutCSV.R. 3 eval/parse calls (GH #22) eliminated. Zero Rshiny references remain
in any active R/ file.
</issue>

<issue name="roxygen2 Documentation Inconsistencies">
roxygen headers contain manual "Executed By" and "Executes Routines" lists that may be stale.
No @examples sections. No @export tags. @return descriptions are often vague. Some files have
extensive but non-standard documentation; others have minimal headers.
</issue>

<issue name="Bundled R Installation" status="RESOLVED">
R-4.4.2.zip was included in the repo root. This was a ~413MB zip of an entire R installation
with pre-installed libraries. Not appropriate for a CRAN package.
Resolution: Deleted in Plan 01.
</issue>

</severity_medium>

<severity_low>

<issue name="Inconsistent Naming Conventions">
Mix of camelCase (estimateFeval), dot.separated (estimate.list), underscore_separated
(file.output.list), and no convention (dddliv, ddliv1, rchdcayf). Variable names from
original SAS code preserved without modernization.
</issue>

<issue name="Legacy SAS Files" status="RESOLVED">
inst/sas/ contained import_data1.sas and output_SAS_labels.sas. Irrelevant for R package.
Resolution: Directory deleted in Plan 01.
</issue>

<issue name="Thumbs.db in inst/" status="RESOLVED">
inst/doc/figures_readme/Thumbs.db was a Windows thumbnail cache file.
Resolution: Deleted in Plan 01.
</issue>

<issue name="code.json in Repo Root" status="RESOLVED">
Was USGS software metadata. Not part of R package structure.
Resolution: Deleted in Plan 01.
</issue>

</severity_low>

<resolved_plans_13_16>

<issue name="CSV API — read_sparrow_data + CSV readers" status="RESOLVED">
Plan 13: rsparrow_model() now accepts 4 data frames (reaches, parameters, design_matrix,
data_dictionary). read_sparrow_data() archived to inst/archived/legacy_api/.
readData, readParameters, readDesignMatrix, read_dataDictionary, applyUserModify
archived to inst/archived/legacy_data_import/. if_userModifyData pathway removed.
prep_sparrow_inputs() added as public API boundary for data validation + transformation.
</issue>

<issue name="plyr/dplyr/data.table in active code" status="RESOLVED">
Plan 14 (GH #20): 6 plyr::ddply → aggregate(); 3 dplyr::sample_n → sample();
all data.table::fwrite/fread → utils::write.csv/read.csv.
DESCRIPTION Imports: nlmrt, numDeriv only (2 packages — data.table removed).
</issue>

<issue name="plotly/ggplot2/gridExtra/gplots required for any plot" status="RESOLVED">
Plan 15: Removed ggplot2, gridExtra, gplots, magrittr from Suggests.
Plan 16 (base R plotting): plotly removed from Suggests; plotlyLayout.R (8 eval/parse)
deleted; hline.R and addMarkerText.R deleted.
All 4 diagnostic plot functions (diagnosticPlotsNLLS, diagnosticPlots_4panel_A/B,
diagnosticSensitivity, diagnosticSpatialAutoCorr) rewrote to use base R graphics
(par/plot/abline/boxplot/qqnorm/qqline). plot(model) works with zero Suggests installed.
8 Suggests remain: car, stringi, knitr, leaflet, rmarkdown, sf, spdep, testthat.
</issue>

<issue name="Dead functions with 0 active callers (Plan 16 audit)" status="RESOLVED">
Plan 16 (Function Audit): 3 functions archived after 0-caller verification:
- checkBinaryMaps.R → inst/archived/utilities/ (callers: checkDrainageareaErrors, mapSiteAttributes,
  predictMaps — all previously archived; only docstring ref in diagnosticPlotsNLLS.R, not call)
- replaceNAs.R → inst/archived/utilities/ (callers: applyUserModify — archived Plan 13;
  mapSiteAttributes — archived Plan 09; eval(parse(envir=parent.frame()) antipattern never fixed)
- diagnosticPlotsValidate.R → inst/archived/utilities/ (merged: thin wrapper inlined into
  estimate.R as direct diagnosticPlotsNLLS(..., validation=TRUE) call)
</issue>

<issue name="Remaining technical debt (post Plan 18D)" status="OPEN">
The following items are known but not blocking CRAN submission:
- eval(parse()): 6 remaining (5+1, all NECESSARY); GH #22 resolved Plan 18D, GH #21/#23 deferred
- Monolith decomposition: estimate.R (693L), estimateNLLSmetrics.R (661L),
  estimateNLLStable.R (550L); seam comments added Plan 16; GH issues opened
- "yes"/"no" string flags: ~50 control settings use character not logical; converting them
  would touch ~20 files and is a Plan 17+ item; isolated from public API by prep_sparrow_inputs()
- .Platform$file.sep path construction: should be file.path(); scattered throughout
- Missing ORCID iDs for authors in DESCRIPTION
- Cross-platform testing (macOS, Windows untested)
- Test coverage: core math (estimateFeval, predict, deliver, hydseq) has zero unit tests
</issue>

</resolved_plans_13_16>

</technical_debt>
