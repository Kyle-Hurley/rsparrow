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
make_*.R, makeReport_*.R, render_report.R). unPackList.R itself remains in R/ with 3 COMPLEX/
deferred callers (mapLoopStr.R, replaceNAs.R, applyUserModify.R); deletion deferred beyond Plan 05D.
</issue>

<issue name="eval(parse(text=...)) Anti-Pattern" status="PARTIALLY_RESOLVED">
49 occurrences remain across R files (down from 339 across 61 files; 47 post-05B; ~27 post-05C).
Post-05D the count is 49 because inlining make_*.R files into REFACTOR callers brought their
~22 hardened hover-text eval(parse()) patterns along. All remaining are either COMPLEX/deferred
or hardened non-arbitrary patterns. Remaining by file:
COMPLEX/deferred (deferred to future plans):
- mapLoopStr.R (11) — dynamic plotly subplot construction; deferred.
- plotlyLayout.R (8) — plotly layout spec evaluation; deferred.
- aggDynamicMapdata.R (5) — dynamic FUN= aggregation; deferred.
- diagnosticSpatialAutoCorr.R (5) — spatial autocorrelation diagnostics; deferred.
- predictScenariosPrep.R (4) — 3 guarded Shiny DSS, 1 deferred.
- applyUserModify.R (2) — outer eval of user-supplied function; hardened with tryCatch.
- replaceNAs.R (1) — parent.frame() injection antipattern; deferred.
- unPackList.R (1) — still in R/ (3 COMPLEX callers remain); deferred.
- naOmitFuncStr.R (1) — helper returning eval expression; deferred.
- createSubdataSorted.R (1) — user filter string; hardened with tryCatch.
Hardened hover-text (non-arbitrary; brought in from inlined make_*.R files):
- diagnosticPlotsNLLS.R (3), diagnosticPlotsNLLS_dyn.R (2),
  diagnosticPlotsNLLS_timeSeries.R (2), checkDrainageareaErrors.R (1), predict_core.R (1)
Resolved in Plan 04B: 21 specification-string calls inlined in 7 core math files.
Resolved in Plan 04C: dynamic column access replaced with [[]] in 6 files
  (checkingMissingVars.R, replaceData1Names.R, setNAdf.R, readForecast.R, validateFevalNoadj.R,
  checkDrainageareaMapPrep.R).
Resolved in Plan 05B: 18 dynamic source variable calls (predict.R×6, predictBoot.R×6,
  predictScenarios.R×6) eliminated; pload_src named lists replace assign+eval.
Resolved in Plan 05C: 20 calls in diagnosticPlots_4panel_A/B.R (markerList/markerText/plotTitles
  replaced with direct list construction / gsub / as.formula); 9 S_ bare-variable patterns in
  predictScenariosPrep.R replaced with scenario_mods/lc_mods named lists; 4 inner eval/parse in
  applyUserModify.R replaced with assign() loops + mget()/get()/[[]] access; 3+1 plotFunc
  dispatch calls in diagnosticSensitivity.R + diagnosticSpatialAutoCorr.R inlined as direct
  plotly code (diagnosticSensitivity.R now fully independent of create_diagnosticPlotList.R).
Resolved in Plan 05D: REMOVE-list files (diagnosticMaps.R×59, predictMaps_single.R×23,
  mapSiteAttributes.R×19, make_*.R/makeReport_*.R/create_diagnosticPlotList.R) all deleted;
  those eval/parse calls are gone. Hardened hover-text patterns from make_*.R were preserved
  when inlined into diagnosticPlotsNLLS.R and related REFACTOR files.
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

<issue name="Monolithic Functions">
estimate.R: 889 lines (estimation + diagnostics + validation + shapefile output)
estimateNLLSmetrics.R: 832 lines (all diagnostic metric computation)
estimateNLLStable.R: 692 lines (text/CSV output formatting)
predictScenarios.R: 523 lines (scenario logic + embedded prediction + maps; was 821, reduced in Plan 05B)
controlFileTasksModel.R: 525 lines (task dispatch)
Impact: Impossible to test individual behaviors. Nesting depth up to 8 levels.
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

<issue name="sink() for File Output">
Multiple files redirect console output via sink() to write text files. If an error occurs
between sink() and sink() close, console output is permanently redirected. No tryCatch/on.exit
protection. estimateOptimize.R, estimateNLLStable.R, controlFileTasksModel.R affected.
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

<issue name="Shiny Code Entangled with Core" status="PARTIALLY_RESOLVED">
25 Shiny/GUI files moved to inst/shiny_dss/ in Plan 02 (including shinyMap2.R, streamCatch.R,
and all UI/server modules). runBatchShiny() call removed from startModelRun.R.
Remaining entanglement: predictScenarios.R still handles both Shiny and batch scenarios in one
function. The Rshiny parameter in predictMaps.R, make_residMaps.R, and ~9 other core files
becomes dead code (always FALSE) but doesn't break anything.
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

</technical_debt>
