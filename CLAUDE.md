<rsparrow_guide>
<project_overview>
rsparrow is an R implementation of the USGS SPARROW water-quality model that uses spatially
referenced regression to relate water measurements to watershed attributes. Version 2.1.0
contains 118 R files (105 internal + 13 exported), 6 Fortran subroutines, and 3
Imports (data.table, nlmrt, numDeriv). The package lives in RSPARROW_master/ and is undergoing
refactoring for CRAN submission. Plans 01-05D are complete (package structure, non-core code
separation, API design, GlobalEnv/eval elimination, all 13 exported functions implemented,
dead-code removal, predict consolidation, eval/parse cleanup, diagnostic plot infrastructure).
Plan 05A removed 15 dead-code files (error handling stubs, settings getters, mapping wrappers)
and inlined their callers. Plan 05B consolidated the three predict functions around a shared
predict_core.R kernel, merged estimateFeval/estimateFevalNoadj into a single ifadjust-
parameterized function, fixed a pre-existing dlvdsgn missing-parameter bug in predictScenarios,
and eliminated all 18 dynamic source variable eval(parse()) calls (65→47 remaining across 11
files). Plan 05C eliminated 20 more eval(parse()) calls across 4panel diagnostics, scenario
prep, applyUserModify, sensitivity/spatial autocorrelation diagnostics. Plan 05D deleted 20
REMOVE-list files (create_diagnosticPlotList.R 2132 lines, 8 makeReport_*.R, 10 make_*.R,
render_report.R); implemented plot.rsparrow() with type= dispatch. NAMESPACE uses selective
importFrom() (zero blanket imports). 25 Shiny/GUI files are preserved in inst/shiny_dss/.
Remaining work: test suite creation (Plan 06).
</project_overview>

<key_concepts>
SPARROW models three watershed processes: (1) contaminant source generation, (2) land-to-water
delivery via surficial/subsurface pathways, and (3) in-stream/reservoir transport and decay.
Estimation uses nonlinear least squares (NLLS) on log-transformed loads with monitoring load
substitution. Reaches are ordered by hydrological sequence; loads accumulate downstream via
Fortran subroutines. Both static (long-term mean annual) and dynamic (seasonal/annual
time-varying) model specifications are supported.
<see_also>docs/reference/SPARROW_METHODOLOGY.md</see_also>
</key_concepts>

<architecture>
New API flow (Plan 04D): rsparrow_model(path_main, run_id) -> read_sparrow_data() ->
startModelRun() [internally calls controlFileTasksModel(); returns sparrow_state with
estimate.list at line 484] -> rsparrow S3 object. Legacy flow preserved in inst/legacy/.
All 13 exported functions are fully implemented: rsparrow_model(), read_sparrow_data(),
print/summary/coef/residuals/vcov.rsparrow(), predict.rsparrow(), plot.rsparrow() [type=
"residuals"/"sensitivity"/"spatial" dispatch implemented in Plan 05D], rsparrow_bootstrap(),
rsparrow_scenario(), rsparrow_validate(), rsparrow_hydseq(). Fortran subroutines (tnoder,
ptnoder, mptnoder, deliv_fraction, sites_incr, sum_atts) handle load accumulation and are
compiled from src/*.f via useDynLib(rsparrow, .registration = TRUE). NAMESPACE is
auto-generated with selective importFrom() directives (no blanket imports). Shiny DSS code
(25 files) in inst/shiny_dss/. startModelRun.R returns sparrow_state named list (27 assigns
eliminated in Plan 04A; includes estimate.list via one-line addition in Plan 04D-3);
startModelRun() calls controlFileTasksModel() internally — do not call both from
rsparrow_model(). model$data stores: subdata, sitedata, vsitedata, DataMatrix.list,
SelParmValues, dlvdsgn, Csites.weights.list, Vsites.list, classvar, estimate.list,
estimate.input.list (with ConcFactor/loadUnits/yieldUnits/ConcUnits added in Plan 04D-4),
scenario.input.list, mapping.input.list, data_names, file.output.list.
All assign(.GlobalEnv) eliminated from R/ (0 remain). 21 specification-string eval(parse())
inlined in 7 core math files (Plan 04B). All actionable unPackList() calls removed from
non-REMOVE files (Plans 04C+05C); 3 COMPLEX/deferred remain (mapLoopStr.R, replaceNAs.R,
applyUserModify.R). predict_core.R (shared kernel, 266 lines) added in Plan 05B; predict.R/
predictBoot.R/predictScenarios.R reduced by ~60% each; estimateFevalNoadj.R merged into
estimateFeval.R (ifadjust parameter); dlvdsgn added to predictScenarios() signature.
49 eval(parse()) remain: 27 COMPLEX/deferred (mapLoopStr.R×11, plotlyLayout.R×8,
aggDynamicMapdata.R×5, diagnosticSpatialAutoCorr.R×5, predictScenariosPrep.R×4,
applyUserModify.R×2, replaceNAs.R×1, unPackList.R×1, naOmitFuncStr.R×1,
createSubdataSorted.R×1) plus ~22 hardened hover-text patterns in REFACTOR diagnostic files.
Roxygen unPackList references cleaned from ~48 non-REMOVE files.
<see_also>docs/reference/ARCHITECTURE.md</see_also>
</architecture>

<critical_files>
<file path="RSPARROW_master/R/estimateFeval.R">NLLS objective function; core SPARROW math</file>
<file path="RSPARROW_master/R/estimateOptimize.R">NLLS optimization via nlmrt::nlfb()</file>
<file path="RSPARROW_master/R/predict.R">Reach-level load/yield predictions</file>
<file path="RSPARROW_master/R/estimate.R">Estimation orchestrator (~890 lines)</file>
<file path="RSPARROW_master/R/deliver.R">Delivery fraction calculation (Fortran wrapper)</file>
<file path="RSPARROW_master/R/hydseq.R">Hydrological sequencing of reach network</file>
<file path="RSPARROW_master/R/controlFileTasksModel.R">Master task dispatcher</file>
<file path="RSPARROW_master/R/startModelRun.R">Data prep and calibration site setup</file>
<file path="RSPARROW_master/R/unPackList.R">Global state unpacking (3 COMPLEX/deferred callers: mapLoopStr.R, replaceNAs.R, applyUserModify.R)</file>
<file path="RSPARROW_master/src/tnoder.f">Fortran load accumulation for estimation</file>
</critical_files>

<data_structures>
Key objects passed between functions: subdata (filtered reach data.frame), DataMatrix.list
(numeric matrices for optimization), SelParmValues (parameter config from CSV), estimate.list
(estimation results), predict.list (prediction matrices), file.output.list (paths/settings),
Csites.weights.list (NLLS weights), sitedata (calibration site subset of subdata).
User inputs come from CSV control files: parameters.csv, design_matrix.csv, dataDictionary.csv.
<see_also>docs/reference/DATA_STRUCTURES.md</see_also>
</data_structures>

<dependencies>
<required_packages>
Imports (3): data.table (CSV I/O), nlmrt (NLLS optimizer), numDeriv (Jacobian/Hessian)
Suggests (15): car, dplyr, ggplot2, gplots, gridExtra, knitr, leaflet, magrittr, mapview,
plotly, plyr, rmarkdown, sf, spdep, testthat
Removed (7): sp, stringr, leaflet.extras, tools, markdown (zero usage); methods from Depends
</required_packages>
<external_dependencies>
Fortran compiler (gfortran) for src/*.f — compiled from source during R CMD INSTALL
R >= 4.4.0 (pipe |> syntax detected in 10 files; %||% available from base R)
</external_dependencies>
</dependencies>

<technical_debt>
Remaining issues: 49 eval(parse()) (27 COMPLEX/deferred + ~22 hardened hover-text; see
architecture section for breakdown), functions exceeding 800 lines (estimate.R,
estimateNLLSmetrics.R, estimateNLLStable.R), layout() conflict (plotly vs graphics in
diagnostic files), undeclared stringi/xfun imports in legacy encoding files, 16 test files
covering only peripheral functions.
Resolved in Plan 01: Pre-compiled DLLs removed, Fortran DLLEXPORT directives removed,
runRsparrow.R moved to inst/legacy/, license resolved (CC0), version/maintainer/Authors@R fixed,
.Rbuildignore created, useDynLib registration fixed, duplicate spdep import removed.
Resolved in Plan 02: 25 Shiny/GUI files moved to inst/shiny_dss/, 19 legacy scaffolding files
deleted, 18 packages removed from Imports (40->22), 15 import() lines removed from NAMESPACE,
runBatchShiny() call removed from startModelRun.R. Stale roxygen refs remain (docs-only).
Resolved in Plan 03: 13 functions exported (6 standalone + 7 S3 methods for class "rsparrow").
NAMESPACE auto-generated with selective importFrom() (zero blanket imports). Imports reduced
from 22 to 3 (data.table, nlmrt, numDeriv); 12 moved to Suggests, 7 removed entirely.
Fortran .for files renamed to .f. Internal predict() renamed to predict_sparrow() to avoid
S3 generic conflict. 137 old man pages deleted; 14 new Rd files for exported API.
All internal functions tagged @keywords internal @noRd.
Resolved in Plan 04A: All Windows-only code removed (shell.exec, Rscript.exe, batch_mode).
startModelRun.R refactored: 27 assign(.GlobalEnv) eliminated, unPackList replaced with direct
$ extractions, sparrow_state accumulator returned. controlFileTasksModel.R refactored: primary
unPackList and 1 assign(.GlobalEnv) removed, min.sites.list parameter added.
Resolved in Plan 04B: All remaining 23 assign(.GlobalEnv) eliminated from 13 files (zero
remain in R/). 21 specification-string eval(parse()) inlined in 7 core math files
(estimateFeval, estimateFevalNoadj, validateFevalNoadj, predict, predictBoot,
predictSensitivity, predictScenarios). Spec-string variables removed from settings
infrastructure (getCharSett, getShortSett, estimateOptimize). predictSensitivity() signature
cleaned (3 dead params removed). Stale predict() call in estimate.R fixed to predict_sparrow().
Resolved in Plan 04C: All actionable unPackList() calls removed from non-REMOVE files (3 files
refactored: predictSensitivity.R, diagnosticSensitivity.R, checkDrainageareaMapPrep.R). Fixable
eval(parse()) replaced with [[]] access in 6 files (checkingMissingVars.R, createSubdataSorted.R,
replaceData1Names.R, setNAdf.R, readForecast.R, validateFevalNoadj.R). Roxygen \item unPackList.R
references cleaned from ~48 non-REMOVE files. .GlobalEnv rm() removed from predictScenariosPrep.R.
65 COMPLEX eval(parse()) flagged TODO Plan 05 across 14 non-REMOVE files.
Resolved in Plan 04D (all 4 sub-sessions): All 13 exported functions fully implemented.
04D-1: print/summary/coef/residuals/vcov S3 method bodies; plot.rsparrow() stub with
informative stop(). print.summary.rsparrow registered in NAMESPACE. 04D-2: read_sparrow_data()
implemented; path_results must end with .Platform$file.sep; dataDictionary.csv copied with
run_id prefix before read_dataDictionary() is called. 04D-3: rsparrow_model() implemented;
one-line patch to startModelRun.R exposes estimate.list in sparrow_state; estimate.input.list
extended with ConcFactor/loadUnits/yieldUnits/ConcUnits. 04D-4: predict.rsparrow() calls
predict_sparrow() (7-arg signature including dlvdsgn); object_to_estimate_list() returns
model$data$estimate.list directly; rsparrow_bootstrap() calls estimateBootstraps();
rsparrow_validate() calls validateMetrics() (requires if_validate="yes" at estimation time);
rsparrow_scenario() calls predictScenarios(Rshiny=FALSE) translating source_changes to
scenario_sources/factors; model$data extended with estimate.list, data_names,
mapping.input.list, Vsites.list, classvar for wrapper access.
Resolved in Plan 05A: 15 dead-code files deleted from R/: errorOccurred.R, exitRSPARROW.R,
importCSVcontrol.R, outputSettings.R, modelCompare.R, getCharSett.R, getNumSett.R,
getOptionSett.R, getShortSett.R, getSpecialSett.R, getYesNoSett.R, diagnosticMaps.R,
mapSiteAttributes.R, predictMaps.R, predictMaps_single.R. Callers updated: errorOccurred→stop(),
exitRSPARROW→stop(), importCSVcontrol fread inlined in 5 callers, outputSettings/modelCompare
calls removed from startModelRun.R/controlFileTasksModel.R. Stub returns added in mapLoopStr.R,
make_residMaps.R, make_siteAttrMaps.R. unPackList.R deferred (3 COMPLEX callers remain in
mapLoopStr.R, replaceNAs.R, applyUserModify.R).
Resolved in Plan 05B: predict.R (574→291 lines), predictBoot.R (475→190), predictScenarios.R
(842→523) consolidated around new predict_core.R (266 lines). estimateFevalNoadj.R (133 lines)
deleted; merged into estimateFeval.R via ifadjust=1L/0L parameter with backward-compatible
wrapper. dlvdsgn added as explicit parameter to predictScenarios() (was populated via global
env in legacy — pre-existing missing-param bug). All 18 dynamic source variable eval(parse())
eliminated (0 eval/parse in all three predict files); pload_src named lists replace assign+eval.
Total eval(parse()) count: 65→47 across 11 non-REMOVE files.
Resolved in Plan 05C: 20 more eval(parse()) eliminated. diagnosticPlots_4panel_A/B.R → 0;
predictScenariosPrep.R → 3 remain (Shiny DSS, guarded); applyUserModify.R → 1 remain
(unavoidable outer eval); diagnosticSensitivity.R + diagnosticSpatialAutoCorr.R decoupled
from create_diagnosticPlotList.R. Total: 47→~27 remaining (all COMPLEX/deferred).
Resolved in Plan 05D: 20 REMOVE-list files deleted (create_diagnosticPlotList.R,
8 makeReport_*.R, 10 make_*.R, render_report.R). make_* bodies inlined into callers.
HTML report generation removed from core package (rmarkdown stays in Suggests).
diagnosticPlotsNLLS_dyn.R: unPackList() removed, create_diagnosticPlotList() replaced with
hardcoded plot_names, three make_dyn* helpers inlined. plot.rsparrow() fully implemented.
File count: 138→118. eval/parse count: ~27→49 (22 hardened hover-text from inlined make_* files).
<see_also>docs/reference/TECHNICAL_DEBT.md</see_also>
</technical_debt>

<development_workflow>
Legacy usage: User sets paths in sparrow_control.R, sources it in RStudio, which triggered
runRsparrow.R (now in inst/legacy/). Package builds successfully via R CMD build (--no-build-
vignettes due to missing deps). Tests exist at tests/testthat/ but require fixtures. Tutorial models in
UserTutorial/ (static TN) and UserTutorialDynamic/ (dynamic TP) serve as working examples.
Build: R CMD build --no-build-vignettes RSPARROW_master/ -> rsparrow_2.1.0.tar.gz

Git and GitHub workflow:
- Remote: https://github.com/Kyle-Hurley/rsparrow (branch: main)
- Use `gh` CLI for all GitHub operations (issues, PRs, etc.)
- When signing commits as co-author, use: Co-Authored-By: Claude Sonnet 4.6
  (no email address — omit the angle-bracket email entirely)
- Bugs discovered incidentally during a task but outside its scope must NOT be silently
  ignored or fixed without permission. Instead, open a GitHub issue via `gh issue create`
  with a descriptive title and body explaining the bug, then continue the current task.
</development_workflow>

<commands>
Common commands (working directory: repo root rsparrow-master/; source scripts/renv.sh or prefix with env vars):

  # Set environment (once per shell session)
  source scripts/renv.sh
  # or prefix commands with: R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false

  # R CMD check (CRAN compliance + tests)
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-build-vignettes RSPARROW_master/

  # Build package tarball
  R CMD build --no-build-vignettes RSPARROW_master/

  # Run testthat tests (after install)
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch RSPARROW_master/
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

  # Run a single test file
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_file('RSPARROW_master/tests/testthat/<file>.R')"

  # Rebuild roxygen docs + NAMESPACE
  R_LIBS=/home/kp/R/libs Rscript -e "roxygen2::roxygenise('RSPARROW_master/')"

  # Or use Make targets: check | test | build | document | install | clean
  make check

Baseline (Plan 06A): R CMD check produces 4 WARNINGs, 3 NOTEs, 0 ERRORs, 23 tests pass.
</commands>

<related_documentation>
<doc>docs/reference/ARCHITECTURE.md - Detailed module structure and execution flow</doc>
<doc>docs/reference/SPARROW_METHODOLOGY.md - Scientific background on SPARROW modeling</doc>
<doc>docs/reference/DATA_STRUCTURES.md - Key data objects, CSV formats, and schemas</doc>
<doc>docs/reference/TECHNICAL_DEBT.md - Comprehensive catalog of code issues</doc>
<doc>docs/reference/FUNCTION_INVENTORY.md - All functions grouped by module with classification</doc>
<doc>docs/reference/TESTING_STRATEGY.md - Current test coverage and gaps</doc>
<doc>docs/INDEX.md - Navigation hub for all documentation</doc>
</related_documentation>
</rsparrow_guide>
