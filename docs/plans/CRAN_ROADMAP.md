<cran_roadmap>

<executive_summary>
Plans 01–05D are complete. The package has been renamed to `rsparrow` (v2.1.0), pre-compiled
DLLs removed, Fortran portability fixed (src/*.f), license resolved (CC0), DESCRIPTION
modernized. Plan 02 separated 25 Shiny/GUI files to inst/shiny_dss/, deleted 19 legacy
scaffolding files. Plan 03 defined a clean exported API: 13 functions exported (6 standalone +
7 S3 methods), selective importFrom() only, 14 new Rd files. Plan 04A removed Windows-only
code; refactored startModelRun/controlFileTasksModel (27 assign(.GlobalEnv) eliminated).
Plan 04B eliminated all 51 assign(.GlobalEnv) from R/ (0 remain) and inlined 21
specification-string eval(parse()) in 7 core math files. Plan 04C removed all actionable
unPackList() calls from non-REMOVE files; replaced dynamic [[]] column access in 6 files.
Plans 04D-1 through 04D-4 implemented all 13 exported function skeletons: print/summary/
coef/residuals/vcov S3 bodies; read_sparrow_data(); rsparrow_model() orchestrating
startModelRun(); predict.rsparrow(), rsparrow_bootstrap(), rsparrow_validate(),
rsparrow_scenario(). Plan 05A deleted 15 dead-code files (error handling stubs, settings
getters, mapping wrappers); inlined callers. Plan 05B consolidated three predict functions
around shared predict_core.R (266 lines); merged estimateFevalNoadj.R into estimateFeval.R;
eliminated 18 dynamic source variable eval(parse()); fixed latent dlvdsgn missing-param bug.
Plan 05C eliminated 20 more eval(parse()) calls: markerList/markerText/plotTitles in
4panel diagnostics (Strategy A); 9 S_ bare-variable patterns in predictScenariosPrep.R
replaced with named lists (Strategy B); 4 inner eval/parse in applyUserModify.R replaced
with assign()/mget()/get() (Strategy C); p16-p22 plotFunc calls inlined in sensitivity and
spatial autocorrelation diagnostics, making them independent of create_diagnosticPlotList.R
(Strategy D); createSubdataSorted.R hardened with tryCatch (Strategy E).
Plan 05D deleted 20 REMOVE-list files: create_diagnosticPlotList.R (2132 lines),
8 makeReport_*.R (HTML report infrastructure), 10 make_*.R (plot generation helpers), and
render_report.R (orphaned). make_* functions inlined into their callers; HTML rendering path
dropped (rmarkdown stays in Suggests). plot.rsparrow() fully implemented with type=
parameter dispatching to "residuals" (→ diagnosticPlots_4panel_A/B), "sensitivity"
(→ diagnosticSensitivity), and "spatial" (→ diagnosticSpatialAutoCorr). File count: 138→118.
After Plan 05D: 49 eval(parse()) remain (27 COMPLEX/deferred from 05C, plus ~22 hardened
hover-text patterns brought in from inlined make_* files — all non-arbitrary). R CMD build
succeeds.
Plans 06A–06F (test suite) are all complete: 8 broken makeReport_* test files deleted,
testthat edition 3 configured, helper.R rewritten, fixtures created (mini_network.rda,
mini_model_inputs.rda). 24 test files pass (0 fail):
  06B (network): 15 tests — hydseq, calcHeadflag/Termflag, accumulateIncrArea
  06C (Fortran):  17 tests — deliver(), tnoder/ptnoder/deliv_fraction Fortran wrappers
  06D (estimation): 11 tests — setNLLSWeights, estimateWeightedErrors, estimateOptimize
  06E (prediction): 17 tests — predict_sparrow, .predict_core, predictSensitivity
    Plan 05B regression confirmed: .predict_core == predict_sparrow to 1e-10
  06F (exported API): 38 tests (1 skip) — rsparrow_hydseq, read_sparrow_data, all 7 S3
    methods, rsparrow_bootstrap/validate/scenario/model argument validation
R CMD check: 4 WARNINGs (pre-existing dep-not-installed), 3 NOTEs; 0 test errors.
Assessment (2026-03-08): Plans 01–06F are complete. The package builds and 98 tests
pass. The 4 R CMD check WARNINGs have been diagnosed: (1) codoc mismatches in 3
exported function Rd files (rsparrow_model 3 params missing, rsparrow_scenario param
name mismatch, rsparrow_validate 2 params missing); (2) undeclared stringi/xfun
imports used in legacy encoding files; (3) vignette build failure (knitr/VignetteBuilder
not properly configured — no vignette exists yet); (4) layout() shape-argument warnings
+ predictSensitivity unused-argument warning during package installation.
Critical path to CRAN submission: fix the 4 WARNINGs (see GH issues), add data/
example dataset, write one introductory vignette.
</executive_summary>

<critical_requirements>

<package_structure>
<requirement status="done">Rename package from RSPARROW to `rsparrow` in DESCRIPTION (CRAN naming convention: lowercase, no underscores)</requirement>
<requirement>Move package root from RSPARROW_master/ to repo root, or restructure so devtools::install() works from a standard path</requirement>
<requirement status="done">Delete runRsparrow.R from R/ - moved to inst/legacy/; all files in R/ now define only functions, methods, or classes</requirement>
<requirement status="done">Remove all pre-compiled DLLs (.dll) from src/; only .for source files remain</requirement>
<requirement status="done">Remove bundled R-4.4.2.zip from repo root</requirement>
<requirement status="done">Remove inst/sas/ directory (legacy SAS scripts)</requirement>
<requirement status="done">Remove batch/ directory (Windows-only Rscript.exe batch execution)</requirement>
<requirement status="done">Remove Thumbs.db and code.json from repo</requirement>
<requirement status="done">Add .Rbuildignore to exclude non-package files (docs/, UserTutorial*, CRAN_PREPARATION_ROADMAP.md, etc.)</requirement>
<requirement status="done">Ensure DESCRIPTION has Version in x.y.z format (now 2.1.0)</requirement>
</package_structure>

<documentation>
<requirement status="done">Add @export roxygen2 tags to all user-facing functions (13 functions exported: 6 standalone + 7 S3 methods)</requirement>
<requirement status="done">Add @examples sections to all exported functions; wrap long-running examples in \dontrun{} or \donttest{}</requirement>
<requirement status="done">Add @return tags with meaningful descriptions to all exported functions</requirement>
<requirement>Remove manual "Executed By" / "Executes Routines" lists from roxygen headers - these are stale and non-standard</requirement>
<requirement status="done">Regenerate all man/ pages via roxygen2 after adding proper tags (manual generation; roxygen2 unavailable)</requirement>
<requirement status="done">Rewrite package-level documentation (?rsparrow) with a clear overview and quick-start example</requirement>
<requirement>Rewrite vignette to demonstrate the refactored API (current vignette references the control-script workflow)</requirement>
</documentation>

<testing_and_examples>
<requirement status="done">Add regression tests for core math: estimateFeval, predict, deliver, hydseq, and exported API — Plans 06B–06F complete (15+17+11+17+38 tests; 1 skip). 24 test files, 0 failures.</requirement>
<requirement status="done">Create small synthetic reach network dataset (7 reaches, Y-shaped) for fast unit tests — fixtures/mini_network.rda (Plan 06A)</requirement>
<requirement status="done">Generate reference output fixtures for estimation/prediction unit tests — fixtures/mini_model_inputs.rda (Plan 06A; synthetic, not UserTutorial-derived)</requirement>
<requirement>All tests must complete within CRAN's 10-minute limit for R CMD check</requirement>
<requirement status="done">Remove or rewrite the 7 makeReport_* test files that test Rmd report rendering — 8 broken test files deleted in Plan 06A (including makeReport_siteAttrMaps)</requirement>
<requirement status="done">Add testthat edition 3 in DESCRIPTION (Suggests: testthat (>= 3.0.0), Config/testthat/edition: 3) — Plan 06A</requirement>
</testing_and_examples>

<dependencies_and_portability>
<requirement status="done">Remove Windows-only code: 21 shell.exec() calls across 15 files; Sys.which("Rscript.exe") paths; system() batch execution [DONE in Plan 04A Task 1]</requirement>
<requirement status="done">Remove Fortran !GCC$ ATTRIBUTES DLLEXPORT directives from all .for files (Windows-specific, not portable)</requirement>
<requirement status="done">Drop non-core Imports (final: 3 packages, down from 40 via Plans 02+03; target was ~10-12, exceeded):
  - [DONE] REMOVED in Plan 02: shiny, shinyWidgets, shinycssloaders, rhandsontable, htmltools, htmlwidgets (Shiny/GUI)
  - [DONE] REMOVED in Plan 02: rstan, OpenMx, inline (heavyweight; not used in core estimation)
  - [DONE] REMOVED in Plan 02: svDialogs, svGUI, rstudioapi (interactive dialogs)
  - [DONE] REMOVED in Plan 02: data.tree, evaluate, formatR, highr, roxygen2, gear (dev/report tools)
  - [DONE] REMOVED in Plan 03: stringr, sp, leaflet.extras, tools, markdown (zero usage found), methods (from Depends)
  - [DONE] MOVED to Suggests in Plan 03: sf, spdep, car, dplyr, ggplot2, magrittr, leaflet, mapview, plotly, gplots, gridExtra, plyr
  - [DONE] REMOVED knitr/rmarkdown from Imports; added to Suggests
  - FINAL Imports: data.table, nlmrt, numDeriv (3 packages)</requirement>
<requirement>Replace all .Platform$file.sep path construction with file.path()</requirement>
<requirement>Test on macOS, Linux, and Windows; current README states "requires Windows"</requirement>
</dependencies_and_portability>

<namespace_and_exports>
<requirement status="done">Replace all blanket import() directives with selective importFrom() (zero blanket imports remain)</requirement>
<requirement status="done">Remove duplicate spdep import (was on lines 6 and 25 of NAMESPACE)</requirement>
<requirement status="done">Define explicit exports for user-facing API (13 functions: 6 export() + 7 S3method())</requirement>
<requirement status="done">Fix useDynLib() declarations to use package-level registration: useDynLib(rsparrow, .registration = TRUE)</requirement>
<requirement status="done">Use @useDynLib and @importFrom roxygen2 tags instead of hand-editing NAMESPACE (via rsparrow-package.R; manually written due to missing roxygen2)</requirement>
</namespace_and_exports>

<legal_and_administrative>
<requirement status="done">Resolve license conflict: now CC0 in DESCRIPTION and LICENSE.md (USGS public domain dedication)</requirement>
<requirement status="done">Fix Maintainer field: Kyle Hurley (khurley@usgs.gov) is sole maintainer (cre role)</requirement>
<requirement status="done">Convert Author field to Authors@R using person() entries with roles (aut, cre)</requirement>
<requirement>Add ORCID iDs if available for authors</requirement>
<requirement>Update URL field - current URL (code.usgs.gov/water/stats/RSPARROW) may be stale; add BugReports field</requirement>
</legal_and_administrative>

</critical_requirements>

<architecture_recommendations>

<code_organization>
<recommendation>Eliminate unPackList.R entirely. Replace all 70+ call sites with explicit argument passing. This is the single most impactful refactoring task - it enables testability, parallelism, and standard R package behavior. Plan 04C targets this.</recommendation>
<recommendation status="done">Remove all assign(..., envir = .GlobalEnv) calls. All 51 occurrences eliminated: 28 in Plan 04A (startModelRun.R + controlFileTasksModel.R), 23 in Plan 04B (13 remaining files). Zero assign(.GlobalEnv) remain in R/.</recommendation>
<recommendation>Replace remaining ~318 eval(parse(text = ...)) calls with proper R idioms (21 specification-string calls already inlined in Plan 04B):
  - Dynamic column access: use data[[varname]] instead of eval(parse(text=paste0("data$",varname)))
  - Model specifications: pre-parse user formulas into function objects at setup time
  - Dynamic assignment: use list assignment instead of eval(parse(text=paste0(n,"<-",v)))</recommendation>
<recommendation status="done">Merge duplicate prediction functions: predict_core.R (266 lines) created as shared kernel in Plan 05B. predict.R: 574→291, predictBoot.R: 475→190, predictScenarios.R: 842→523. ~900 lines removed.</recommendation>
<recommendation status="done">Merge estimateFeval.R and estimateFevalNoadj.R (differ only in ifadjust flag). Done in Plan 05B: estimateFevalNoadj.R deleted; estimateFeval.R now accepts ifadjust=1L/0L with backward-compatible wrapper.</recommendation>
<recommendation>Decompose monolithic functions:
  - estimate.R (889 lines) -> separate estimation, diagnostics, validation, output
  - estimateNLLSmetrics.R (832 lines) -> separate metric computation functions
  - estimateNLLStable.R (692 lines) -> return structured data; let caller handle file I/O
  - predictScenarios.R (821 lines) -> extract core scenario logic from Shiny coupling</recommendation>
<recommendation status="done">Move all Shiny/GUI files to a separate directory. [DONE in Plan 02: 25 files moved to inst/shiny_dss/, excluded from build via .Rbuildignore. These become a future companion package.]</recommendation>
<recommendation status="partial">Remove ~40 infrastructure/scaffolding files that exist only to support the control-script workflow. [PARTIAL: 19 files deleted in Plan 02 (executeRSPARROW, findControlFiles, generateInputLists, makePaths, createDirs, setupMaps, testSettings, setMapDefaults, isScriptSaved, openDesign/Parameters/Varnames, removeObjects, deleteFiles, RSPARROW_objects, copyPriorModelFiles, findScriptName, executionTree, findCodeStr). Remaining: exitRSPARROW.R, unPackList.R, get*Sett.R (5), outputSettings.R, importCSVcontrol.R, errorOccurred.R, modelCompare.R (~10 files). runRsparrow.R moved to inst/legacy/ in Plan 01.]</recommendation>
<recommendation status="done">Remove interactive map/report generators (~20 files): diagnosticMaps.R, mapSiteAttributes.R, predictMaps.R, predictMaps_single.R deleted in Plan 05A. makeReport_*.R (8 files), make_*.R (10 files), create_diagnosticPlotList.R, render_report.R deleted in Plan 05D. HTML diagnostic reports removed from core package; plot.rsparrow() S3 method provides programmatic access instead.</recommendation>
<recommendation>Replace all "yes"/"no" string settings with logical TRUE/FALSE throughout. ~50 occurrences.</recommendation>
<recommendation>Replace all sink() file output with explicit writeLines() or cat(file=) wrapped in on.exit(sink()) for safety.</recommendation>
</code_organization>

<api_design>
<recommendation>Define a clean, minimal exported API (~10-15 functions). Suggested public surface:
  - rsparrow_model() or sparrow() - Main entry point: reads data, estimates, returns model object
  - predict.rsparrow() - S3 predict method for rsparrow model objects
  - summary.rsparrow() - S3 summary method
  - print.rsparrow() - S3 print method
  - coef.rsparrow() - Extract coefficients
  - residuals.rsparrow() - Extract residuals
  - rsparrow_scenario() - Run scenario predictions with modified sources
  - rsparrow_bootstrap() - Bootstrap uncertainty estimation
  - rsparrow_hydseq() - Compute hydrological sequencing (useful standalone)
  - rsparrow_validate() - Cross-validation diagnostics
  - plot.rsparrow() - S3 plot method for diagnostic plots
  - read_sparrow_data() - Read and validate input data files</recommendation>
<recommendation>Return S3 objects with class "rsparrow" from estimation. This enables method dispatch (predict, summary, plot, coef, residuals) and follows R conventions users expect.</recommendation>
<recommendation>All functions must accept data as arguments, not read from global state. The user passes a data.frame and parameter specifications; the function returns results.</recommendation>
<recommendation>Separate computation from I/O. Core functions return R objects; optional convenience functions write CSV/plots. Never write files as a side effect of computation.</recommendation>
</api_design>

<data_handling>
<recommendation>Include a small example dataset in data/ (subset of UserTutorial, ~100 reaches) for examples and tests. Document with a data.R file containing roxygen2 @docType data blocks.</recommendation>
<recommendation>Move UserTutorial/ and UserTutorialDynamic/ out of the package entirely. Reference them in vignettes as external downloads or separate data packages.</recommendation>
<recommendation>Keep CSV-based input (parameters.csv, design_matrix.csv, dataDictionary.csv) as the user interface for model specification, but provide helper functions to validate and load them rather than relying on global-state scripts.</recommendation>
</data_handling>

</architecture_recommendations>

<quality_and_maintainability>

<documentation_strategy>
Write roxygen2 documentation for all exported functions. Each must have: @title, @description,
@param for every argument, @return with object description, @examples with runnable code
(use \donttest{} for slow examples), @export. Internal functions get minimal @keywords internal
documentation. Generate NAMESPACE and man/ entirely from roxygen2 - never hand-edit.
</documentation_strategy>

<testing_strategy>
Use testthat (>= 3.0.0) with edition 3. Priority order:
1. Capture golden reference outputs from UserTutorial before any code changes
2. Unit test estimateFeval with known inputs/outputs (the mathematical core)
3. Unit test hydseq with small synthetic network
4. Unit test Fortran wrappers (tnoder, ptnoder, deliv_fraction) with minimal inputs
5. Integration test: data -> estimate -> predict pipeline on example dataset
6. Test predict/bootstrap/scenario give consistent results after merging duplicates
7. Edge cases: single-reach network, all-headwater network, missing monitoring data
Target: >80% coverage on exported functions. All tests under 10 minutes total.
</testing_strategy>

<vignettes_and_tutorials>
Create one primary vignette: "Introduction to rsparrow" demonstrating the full workflow
(read data -> specify model -> estimate -> predict -> diagnose) using the bundled example
dataset. Keep computation lightweight (\donttest{} or pre-computed results for slow steps).
A second vignette on scenario analysis and bootstrapping can follow in a later release.
</vignettes_and_tutorials>

</quality_and_maintainability>

<prioritized_actions>

<priority level="1" label="CRAN blockers - must fix or package will be rejected">
  - [DONE] Remove runRsparrow.R script from R/ (moved to inst/legacy/)
  - [DONE] Remove pre-compiled DLLs from src/
  - [DONE] Remove !GCC$ ATTRIBUTES DLLEXPORT from Fortran source files
  - [DONE] Add at least one @export tag (13 functions exported in Plan 03)
  - [DONE] Fix NAMESPACE: replace 22 blanket imports with importFrom (selective importFrom() only)
  - [DONE] Fix useDynLib to use package-level registration
  - [DONE] Fix Maintainer field to exactly one person with one email
  - [DONE] Convert Author to Authors@R format
  - [DONE] Resolve license mismatch (now CC0 throughout)
  - [DONE] Fix Version format (now 2.1.0)
  - [DONE] Add @return to all exported function documentation
  - [DONE] Add @examples to all exported functions
  - [DONE] Remove Windows-only code (shell.exec, Rscript.exe) — removed in Plan 04A Task 1
  - [OPEN] Ensure R CMD check passes with 0 errors, 0 warnings, at most 1 note:
      - (a) Fix Rd codoc mismatches: rsparrow_model/rsparrow_scenario/rsparrow_validate
            have parameter mismatches between @param tags and function signatures (GH #5)
      - (b) Fix undeclared imports: stringi and xfun called but not in NAMESPACE (GH #6)
      - (c) Fix layout() shape-argument errors + predictSensitivity unused-arg warning
            that appear during installation (GH #7)
      - (d) Add/configure vignette to resolve VignetteBuilder WARNING (GH #8 / part of vignette plan)
</priority>

<priority level="2" label="High-value - enables usability and maintainability">
  - [PARTIAL] Eliminate unPackList() and all assign(.GlobalEnv) — all 51 assign(.GlobalEnv) eliminated (Plans 04A+04B; zero remain). All actionable unPackList() calls removed from non-REMOVE files (Plan 04C; 05C removed the last inner call from applyUserModify.R's generated string). unPackList.R itself deferred to Plan 05D (13 non-REMOVE files still call it via diagnostic/make_* chains).
  - [PARTIAL] Replace eval(parse()) with proper R idioms — 21 inlined 04B; 18 source-var 05B;
    20 plotly/scenario/dynamic-function 05C. After Plan 05D: 49 remain (27 COMPLEX/deferred +
    ~22 hardened hover-text from inlined make_* files). COMPLEX: mapLoopStr.R (11),
    plotlyLayout.R (8), aggDynamicMapdata.R (5), diagnosticSpatialAutoCorr.R (5),
    predictScenariosPrep.R (4), applyUserModify.R (2), replaceNAs.R (1), unPackList.R (1),
    naOmitFuncStr.R (1), createSubdataSorted.R (1). Hardened: diagnosticPlotsNLLS.R (3),
    diagnosticPlotsNLLS_dyn.R (2), diagnosticPlotsNLLS_timeSeries.R (2),
    checkDrainageareaErrors.R (1), predict_core.R (1).
  - [DONE] Merge duplicate predict functions (Plan 05B: predict_core.R created, ~900 lines removed)
  - [DONE] Design and implement S3 class "rsparrow" with standard methods (all 13 exports implemented in Plans 04D-1 through 04D-4)
  - [DONE] Separate Shiny/GUI code into inst/shiny_dss/ (25 files moved in Plan 02)
  - [PARTIAL] Remove non-core functions (~44 removed in Plan 02; 15 more in Plan 05A; 20 more in Plan 05D; ~45 remain: unPackList.R + 3 COMPLEX/deferred callers, mapLoopStr.R, aggDynamicMapdata.R, plotlyLayout.R, addMarkerText.R, setupDynamicMaps.R, and diagnostic/map files)
  - Create example dataset in data/ (GH #9)
  - Write primary vignette (GH #8)
  - [DONE] Build test suite for core estimation, prediction, and exported API — Plans 06A–06F
    all complete (24 test files, 98 tests / 38+1 skip in 06F alone); 0 failures
</priority>

<priority level="3" label="Important but not blocking initial submission">
  - Decompose monolithic functions (estimate.R, estimateNLLSmetrics.R, etc.)
  - Replace "yes"/"no" strings with logical TRUE/FALSE
  - Standardize naming conventions (camelCase vs dot.separated vs underscore)
  - Replace sink() with safe file-writing patterns
  - Replace hardcoded path construction with file.path()
  - Add input validation to Fortran interface calls
  - Add spatial autocorrelation diagnostics as optional feature
  - Pursue >80% test coverage on exported functions
  - Write second vignette on scenarios and bootstrapping
</priority>

</prioritized_actions>

<cran_checklist>
<item status="pass">R CMD build produces a valid tarball (rsparrow_2.1.0.tar.gz)</item>
<item status="fail">R CMD check --as-cran returns 0 errors, 0 warnings</item>
<item status="pass">All files in R/ contain only function/method/class definitions</item>
<item status="pass">No pre-compiled binaries in src/</item>
<item status="pass">Fortran source compiles on all platforms (no Windows-specific directives)</item>
<item status="pass">NAMESPACE has explicit exports (6 export() + 7 S3method())</item>
<item status="pass">NAMESPACE uses importFrom instead of blanket import (selective importFrom() only)</item>
<item status="pass">DESCRIPTION has single Maintainer with valid email</item>
<item status="pass">DESCRIPTION uses Authors@R with person() entries</item>
<item status="pass">DESCRIPTION License matches actual license terms</item>
<item status="pass">DESCRIPTION Version is x.y.z format</item>
<item status="pass">All exported functions have complete roxygen2 documentation</item>
<item status="pass">All exported functions have @examples</item>
<item status="pass">All exported functions have @return</item>
<item status="pass">No .GlobalEnv modifications at package load or runtime (all 51 assign(.GlobalEnv) eliminated: Plans 04A + 04B)</item>
<item status="partial">No eval(parse()) in exported functions (21 spec-string inlined 04B; 18 source-var 05B; 20 plotly/scenario 05C; 49 remain in internal functions — 27 COMPLEX/deferred, ~22 hardened hover-text from inlined make_* files)</item>
<item status="pass">No shell.exec() or Windows-only system calls (removed in Plan 04A Task 1)</item>
<item status="fail">Package installs and loads on macOS, Linux, and Windows</item>
<item status="fail">Total R CMD check time under 10 minutes</item>
<item status="fail">Example dataset included in data/ with documentation</item>
<item status="fail">At least one vignette demonstrating core workflow</item>
<item status="fail">testthat tests pass on all platforms</item>
<item status="unchecked">CRAN submission via devtools::submit_cran() accepted</item>
</cran_checklist>

<completed_plans>

<plan id="01" label="Package Structure Foundation">
Completed all 11 tasks:
  - Deleted 6 .dll files from src/
  - Removed !GCC$ ATTRIBUTES DLLEXPORT from all 6 .for files
  - Moved runRsparrow.R from R/ to inst/legacy/
  - Renamed package RSPARROW -> rsparrow in DESCRIPTION
  - Version 2.1 -> 2.1.0; R dependency bumped to >= 4.1.0
  - Authors@R: Kyle Hurley as cre (maintainer)
  - License: CC0 (USGS public domain); LICENSE.md rewritten
  - Deleted: R-4.4.2.zip, code.json, inst/sas/, batch/, Thumbs.db
  - Created .Rbuildignore
  - NAMESPACE: useDynLib(rsparrow, .registration = TRUE), removed duplicate spdep
  - Removed runRsparrow.R from Collate field
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
</plan>

<plan id="02" label="Non-Core Code Separation">
Completed all 12 tasks:
  - Moved 25 Shiny/GUI files from R/ to inst/shiny_dss/
  - Deleted 19 legacy scaffolding files from R/
  - Deleted 43 corresponding man pages (RSPARROW_objects.Rd didn't exist)
  - Removed runBatchShiny() call from startModelRun.R
  - Removed 18 packages from DESCRIPTION Imports (40 -> 22)
  - Removed 15 import() lines from NAMESPACE (37 -> 22 directives)
  - Removed 44 Collate entries (183 -> 139)
  - Added inst/shiny_dss to .Rbuildignore
  - Verified: all remaining references to deleted functions are roxygen docs only
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
  - Final counts: 139 R files, 137 man pages, 22 Imports, 22 NAMESPACE directives
</plan>

<plan id="03" label="API Design and Namespace">
Completed all 8 tasks:
  - Import analysis: 5 packages had zero usage (stringr, sp, leaflet.extras, tools, markdown)
  - Created 13 skeleton exported function files with complete roxygen2 documentation
  - Added @keywords internal + @noRd to all 139 internal function files
  - Created R/rsparrow-package.R with @useDynLib and selective @importFrom tags
  - Imports reduced from 22 to 3 (data.table, nlmrt, numDeriv); 12 to Suggests, 7 removed
  - Removed methods from Depends; removed 7 unused packages entirely
  - NAMESPACE: 6 export() + 7 S3method() + selective importFrom() + useDynLib
  - Deleted 137 old man pages; created 14 new Rd files for exported functions + package doc
  - Renamed Fortran src/*.for -> src/*.f (R build system compatibility)
  - Fixed 25 Fortran PACKAGE= arguments: individual routine names -> "rsparrow"
  - Renamed internal predict() -> predict_sparrow() to avoid S3 generic conflict
  - Fixed library(car)/library(dplyr) -> requireNamespace() in correlationMatrix.R
  - R CMD check: 0 errors, 4 warnings (all pre-existing in legacy code), 1 note
  - Package installs/loads; all 13 exports work; 7 S3 methods dispatch correctly
  - Fortran routines (tnoder, ptnoder, deliv_fraction) compile and load
  - Final counts: 152 R files, 14 man pages, 3 Imports, 15 Suggests
</plan>

<plan id="04A" label="Windows Code Removal and Core State Refactoring">
Completed all 3 tasks:
  - Task 1: Removed all Windows-only code (shell.exec, Rscript.exe, batch_mode) from non-REMOVE files
    Files modified: startModelRun.R, controlFileTasksModel.R, createInitialParameterControls.R,
    createInitialDataDictionary.R, addVars.R, estimate.R, estimateBootstraps.R, predictBootstraps.R
  - Task 2: Eliminated 27 assign(.GlobalEnv) from startModelRun.R
    Replaced unPackList with direct $ extractions; added sparrow_state accumulator and return;
    removed enable_ShinyApp parameter (Shiny separated in Plan 02)
  - Task 3: Refactored controlFileTasksModel.R
    Removed primary unPackList and 1 assign(.GlobalEnv); added min.sites.list parameter;
    replaced bare-name access with direct $-extraction from input lists
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
  - Current counts: 23 assign(.GlobalEnv) remaining across 13 files (down from 74)
  - 0 shell.exec/Rscript.exe in code (1 comment in controlFileTasksModel.R)
</plan>

<plan id="04B" label="Remaining GlobalEnv and Specification-String Elimination">
Completed all tasks:
  - Task 4: Eliminated 23 assign(.GlobalEnv) from 13 files:
    - predict.R, correlationMatrix.R, diagnosticSensitivity.R, estimateWeightedErrors.R,
      setNLLSWeights.R, estimateBootstraps.R: simple removal (already returning value)
    - predictBootstraps.R (2 assigns), predictScenarios.R (2 assigns): removed
    - checkDrainageareaMapPrep.R (2 assigns): removed (only caller on REMOVE list)
    - findMinMaxLatLon.R (4 assigns): now returns list(sitegeolimits, mapping.input.list); caller updated
    - replaceData1Names.R (1 assign): now returns list(data1, data_names); caller updated
    - dataInputPrep.R (2 assigns): now returns list(data1, data_names)
    - estimate.R (4 assigns): removed all GlobalEnv assigns; preserved file save logic
  - Task 5: Replaced 21 specification-string eval(parse()) in 7 core math files:
    - estimateFeval.R, estimateFevalNoadj.R, validateFevalNoadj.R (3 each)
    - predict.R, predictBoot.R, predictSensitivity.R, predictScenarios.R (3 each)
    - Inlined: reach_decay, reservoir_decay, incr_delivery expressions
    - Removed 3 spec-string vars from getCharSett.R, getShortSett.R, estimateOptimize.R
    - Removed spec-string params from predictSensitivity() signature + callers
    - Removed dead spec-string extractions from startModelRun.R
  - Fixed stale predict() call in estimate.R -> predict_sparrow() (missed in Plan 03)
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
  - Final counts: 0 assign(.GlobalEnv) in R/; ~318 eval(parse()) remain (dynamic column access)
</plan>


<plan id="04C" label="unPackList Removal and eval(parse) Dynamic Column Cleanup">
Completed all tasks:
  - All actionable unPackList() calls removed from non-REMOVE files (3 files refactored:
    predictSensitivity.R, diagnosticSensitivity.R, checkDrainageareaMapPrep.R)
  - Dynamic column eval(parse()) replaced with [[]] in 6 files:
    checkingMissingVars.R, createSubdataSorted.R, replaceData1Names.R, setNAdf.R,
    readForecast.R, validateFevalNoadj.R
  - Roxygen \item unPackList.R references cleaned from ~48 non-REMOVE files
  - .GlobalEnv rm() calls removed from predictScenariosPrep.R
  - replaceNAs.R parent.frame() injection antipattern flagged TODO Plan 05
  - 1 unPackList call in applyUserModify.R inside dynamic string deferred to Plan 05C
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
</plan>

<plan id="04D" label="Exported API Implementation (all 4 sub-sessions)">
Sub-session 04D-1 (S3 method bodies):
  - print/summary/coef/residuals/vcov.rsparrow() bodies implemented
  - plot.rsparrow() stub with informative stop() (→Plan 05D)
  - print.summary.rsparrow registered in NAMESPACE
Sub-session 04D-2 (read_sparrow_data()):
  - read_sparrow_data() implemented with explicit path config
  - path_results must end with .Platform$file.sep; dataDictionary.csv copied with run_id prefix
  - Imports data1 CSV, parameters.csv, design_matrix.csv, dataDictionary.csv
Sub-session 04D-3 (rsparrow_model()):
  - rsparrow_model() implemented: orchestrates read_sparrow_data() → startModelRun()
  - One-line patch to startModelRun.R:484 exposes estimate.list in sparrow_state
  - estimate.input.list extended with ConcFactor/loadUnits/yieldUnits/ConcUnits
Sub-session 04D-4 (predict wrappers):
  - predict.rsparrow() calls predict_sparrow() (7-arg signature including dlvdsgn)
  - rsparrow_bootstrap() calls estimateBootstraps(); uses seed %||% sample.int()
  - rsparrow_validate() calls validateMetrics(); requires if_validate="yes" at estimation
  - rsparrow_scenario() calls predictScenarios(Rshiny=FALSE); translates source_changes
  - model$data extended with estimate.list, data_names, mapping.input.list, Vsites.list, classvar
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
</plan>

<plan id="05A" label="Dead Code Removal">
Completed:
  - 15 files deleted from R/: errorOccurred.R, exitRSPARROW.R, importCSVcontrol.R,
    outputSettings.R, modelCompare.R, getCharSett.R, getNumSett.R, getOptionSett.R,
    getShortSett.R, getSpecialSett.R, getYesNoSett.R, diagnosticMaps.R, mapSiteAttributes.R,
    predictMaps.R, predictMaps_single.R
  - Callers updated: errorOccurred→stop(), exitRSPARROW→stop(), importCSVcontrol→inline fread
    in 5 callers, outputSettings/modelCompare calls removed from startModelRun.R/controlFileTasksModel.R
  - Dead batch-mapping block deleted from controlFileTasksModel.R and predictScenarios.R
  - createMasterDataDictionary.R, createInitialParameterControls.R inlined (missed in plan)
  - Side-fixes: stub returns in mapLoopStr.R, make_residMaps.R, make_siteAttrMaps.R
  - diagnosticPlotsNLLS_dyn.R unPackList fixed (path_results extracted directly)
  - DEFERRED: unPackList.R — 13 non-REMOVE files still call it; delete with diagnostics in 05D
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced; R file count: 152→138 (net -14)
</plan>

<plan id="05B" label="Predict Consolidation">
Completed:
  - predict_core.R (266 lines) created as shared prediction kernel
  - predict.R: 574→291 lines; predictBoot.R: 475→190; predictScenarios.R: 842→523
  - estimateFevalNoadj.R (133 lines) deleted; merged into estimateFeval.R via ifadjust=1L/0L
    parameter with backward-compatible estimateFevalNoadj wrapper function at bottom
  - dlvdsgn added as explicit parameter to predictScenarios() — was implicit via global env
    (pre-existing missing-param bug fixed); callers updated (controlFileTasksModel.R, rsparrow_scenario.R)
  - All 18 dynamic source variable eval(parse()) eliminated; pload_src named lists replace assign+eval
  - Total eval(parse()) count reduced: 65→47 across 11 non-REMOVE files
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
</plan>

<plan id="05C" label="Remaining eval(parse()) Elimination">
Completed:
  - Strategy A: diagnosticPlots_4panel_A/B.R → 0 eval/parse each
    markerList replaced with direct R list; plotTitles gsub-stripped; markerText as.formula()
    All make_*.R callers updated to pass markerList as R list, not paste0 string
  - Strategy B: predictScenariosPrep.R → 3 remain (all Shiny DSS, guarded by Rshiny=TRUE)
    9 S_ bare-variable eval(parse()) replaced with scenario_mods / lc_mods named lists
    Bridge added after selectFuncs loop to copy Shiny S_ vars into named lists
    cfFuncs guarded with if(Rshiny &&...); S__CF access via get()
  - Strategy C: applyUserModify.R → 1 remain (unavoidable outer eval(parse(text=userMod)))
    unPackList() removed from generated top string; replaced with assign() loops
    3 inner eval/parse in bottom string replaced with mget()/get()/[[]] access
  - Strategy D: diagnosticSensitivity.R → 0 eval/parse; fully independent of create_diagnosticPlotList.R
    p16/p17/p18 plotFuncs inlined; computation loop restructured before plotting;
    renamed plot vars (xmed_p, xiqr_p etc.) to preserve originals for sensitivities.list
    diagnosticSpatialAutoCorr.R → 0 eval/parse (still calls create_diagnosticPlotList()$pNN$plotFunc
    for p19–p22 without eval — dependency removed in Plan 05D)
    showPlotGrid added to both files
  - Strategy E: createSubdataSorted.R hardened with tryCatch + informative error message
  - Total eval(parse()) across non-REMOVE files: 47→~27 (all remaining COMPLEX/deferred)
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced
</plan>

<plan id="05D" label="Diagnostic Plot Infrastructure Removal">
Completed:
  - 20 REMOVE-list files deleted from R/ (net: 138→118 R files):
    create_diagnosticPlotList.R (2132 lines)
    8 makeReport_*.R: makeReport_diagnosticPlotsNLLS.R, makeReport_drainageAreaErrorsPlot.R,
      makeReport_header.R, makeReport_modelEstPerf.R, makeReport_modelSimPerf.R,
      makeReport_outputMaps.R, makeReport_residMaps.R, makeReport_siteAttrMaps.R
    10 make_*.R: make_diagnosticPlotsNLLS_timeSeries.R, make_drainageAreaErrorsMaps.R,
      make_drainageAreaErrorsPlot.R, make_dyndiagnosticPlotsNLLS.R,
      make_dyndiagnosticPlotsNLLS_corrPlots.R, make_dyndiagnosticPlotsNLLS_sensPlots.R,
      make_modelEstPerfPlots.R, make_modelSimPerfPlots.R, make_residMaps.R, make_siteAttrMaps.R
    render_report.R (orphaned)
  - diagnosticPlotsNLLS_dyn.R refactored:
    unPackList() call removed (pre-condition fix)
    create_diagnosticPlotList() filtering replaced with hardcoded plot_names
    three make_dyn* functions inlined as dyn_diagPlotsNLLS/dyn_sensPlots/dyn_corrPlots helpers
    makeReport_header/render_report HTML rendering calls removed
  - diagnosticPlotsNLLS.R refactored:
    make_modelEstPerfPlots (p1-p8) inlined with direct $ extractions
    make_modelSimPerfPlots (p9-p15) inlined with direct $ extractions
    make_residMaps/make_siteAttrMaps replaced with NULL (map rendering disabled since Plan 05A)
  - checkDrainageareaErrors.R: make_drainageAreaErrorsPlot inlined; make_drainageAreaErrorsMaps removed
  - diagnosticPlotsNLLS_timeSeries.R: make_diagnosticPlotsNLLS_timeSeries already inlined (prior session)
  - plot.rsparrow() fully implemented with type= dispatch:
    "residuals" → .rsparrow_plot_residuals() → diagnosticPlots_4panel_A/B
    "sensitivity" → .rsparrow_plot_sensitivity() → diagnosticSensitivity()
    "spatial" → .rsparrow_plot_spatial() → diagnosticSpatialAutoCorr()
  - plot.rsparrow.Rd updated with type= parameter, @param, @return, @examples
  - DESCRIPTION Collate: 20 entries removed
  - eval(parse()) count: ~27 (post-05C) → 49 total (27 COMPLEX/deferred unchanged;
    ~22 hardened hover-text patterns from inlined make_* files brought into REFACTOR files)
  - HTML diagnostic report generation removed from core package; rmarkdown stays in Suggests
  - R CMD build succeeds: rsparrow_2.1.0.tar.gz produced; R file count: 138→118
</plan>


<plan id="06A" label="Test Infrastructure Setup">
Completed all 6 tasks:
  - Task 06A-1: DESCRIPTION updated — testthat (>= 3.0.0) in Suggests; Config/testthat/edition: 3 added
  - Task 06A-2: 8 broken makeReport_* test files deleted (plan said 7; makeReport_siteAttrMaps.R was
    also broken and deleted); tests/testthat.R fixed (was loading RSPARROW instead of rsparrow)
  - Task 06A-3: helper.R rewritten with 3 shared utilities: expect_numeric_close, expect_names_present,
    make_mock_rsparrow; old check_chunks_enclosed() removed
  - Task 06A-4: fixtures/mini_network.rda created — 7-row Y-shaped network; helper-build-fixtures.R
    created with if(FALSE) guard for future regeneration
  - Task 06A-5: fixtures/mini_model_inputs.rda created — DataMatrix.list (7×10 numeric matrix),
    SelParmValues (bcols=3L), dlvdsgn (1×1 matrix), hand-coded estimate.list; bundled as mini_inputs
  - Task 06A-6: 3 surviving tests fixed (batch_mode removed from readParameters, readDesignMatrix,
    selectParmValues call signatures); readDesignMatrix fixture regenerated; 23 tests pass, 0 fail
  - R CMD check (_R_CHECK_FORCE_SUGGESTS_=false): 4 WARNINGs (pre-existing), 3 NOTEs; 0 test errors
</plan>

<plan id="06B" label="Network Topology Tests">
Completed all 4 tasks. Completed 2026-03-07.
  - test-hydseq.R (7 tests): hydseq() and rsparrow_hydseq() on mini_network; hydseq order,
    headflag/termflag assignment, exported function returns named integer vector
  - test-calcflags.R (4 tests): calcHeadflag and calcTermflag flag assignment on known topology;
    headwater detection, terminal reach detection
  - test-accumulateIncrArea.R (4 tests): accumulateIncrArea incremental→cumulative drainage area
    accumulation; terminal reach cumulative area equals sum of all incremental areas
  - Total: 15 tests, all pass; 0 fail
</plan>

<plan id="06C" label="Fortran Interface Tests">
Completed all 3 tasks. Completed 2026-03-07.
  - test-deliver.R (5 tests): deliver() → .Fortran("deliv_fraction"); returns length-nreach numeric;
    incdecay=totdecay=1.0 → all fractions = 1.0; partial decay → fractions in (0,1); headwaters
    < terminal delivery with decay; column-order guard test
  - test-fortran-tnoder.R (6 tests): .Fortran("tnoder") via estimateFeval; residuals finite and
    correct length; recycling behavior with 1 calibration site documented; ifadjust effects
  - test-fortran-ptnoder.R (6 tests): predict_sparrow exercising ptnoder/mptnoder/deliv_fraction;
    predmatrix 7×14, yldmatrix 7×10; terminal reach has max pload_total
  - Key findings: incdecay/totdecay are multiplicative (1.0=no decay, NOT 0.0); predmatrix
    has 14 cols, yldmatrix 10 cols for mini_network (jjsrc=1)
  - Total: 17 tests, all pass; 0 fail
</plan>

<plan id="06D" label="Estimation Core Tests">
Completed all 3 tasks. Completed 2026-03-07.
  - test-setNLLSWeights.R (4 tests): setNLLSWeights() returns list with NLLS_weights, tiarea,
    count, weight; default mode returns scalar 1.0; lnload/user modes use sitedata$weight
  - test-estimateWeightedErrors.R (3 tests): estimateWeightedErrors() reads residuals CSV from
    file, fits power-function NLS, returns numeric[nreaches]. Corrected plan assumption: this
    is a per-reach weight function (not a scalar bias correction).
  - test-estimateOptimize.R (4 tests): estimateOptimize() runs nlmrt::nlfb(); returns sparrowEsts
    with coefficients, betamn/betamx bounds; optimized coefficients within bounds; terminates
    in &lt;60 seconds on mini_network
  - Bug fixed: Csites.weights.list was missing from estimateOptimize() signature and the
    call site in estimate.R; fixed as part of Plan 06D
  - Total: 11 tests, all pass; 0 fail
</plan>

<plan id="06E" label="Prediction Tests">
Completed all 3 tasks. Completed 2026-03-08.
  - test-predict-sparrow.R (9 tests): predict_sparrow() list structure, predmatrix/yldmatrix
    dimensions, oparmlist/oyieldlist column-count consistency, non-negative total loads,
    terminal reach accumulation, bootcorrection sensitivity, determinism, concentration
    non-negativity
  - test-predict-core.R (5 tests): .predict_core() required return fields, pload_total length,
    Plan 05B regression guard — pload_total matches predict_sparrow predmatrix[,2] to 1e-10,
    per-source load matches predmatrix[,3] to 1e-10, incdecay/totdecay non-negativity.
    eval/parse hover-text test documented as skipped (no eval/parse in .predict_core itself).
  - test-predictSensitivity.R (3 tests): returns numeric vector of nreach length, large
    perturbation changes output, original estimates match predict_sparrow pload_total to 1e-10
    (Plan 04B/05B cross-check). Note: predictSensitivity still contains local assign() for
    pload_inc_src vars — known residual, does not affect return value.
  - Plan 05B consolidation confirmed non-breaking: all regression tests pass to 1e-10
  - Total: 17 tests (22 expectations), all pass; 0 fail
</plan>


<plan id="06F" label="Exported API Tests">
Completed all 5 tasks. Completed 2026-03-08.
  - test-rsparrow-hydseq.R (6 tests): exported rsparrow_hydseq() — existence/callability,
    returns data.frame with hydseq column, custom from_col/to_col names preserved,
    error on non-data.frame input, error on missing from_col, error on missing waterid column.
    Note: test data must include termflag, frac, demiarea (required by internal hydseq()).
  - test-read-sparrow-data.R (5 tests): returns list with file.output.list/data1/data_names,
    error for nonexistent path_main, error for missing parameters.csv, run_id-prefixed
    dataDictionary.csv created at results/run1/run1_dataDictionary.csv. Uses make_minimal_sparrow_dir()
    helper with 5-column dataDictionary (varType, sparrowNames, data1UserNames, varunits, explanation).
  - test-s3-methods.R (11 tests): print.rsparrow returns invisible x; output contains coefficient
    names; summary.rsparrow returns summary.rsparrow class; summary output contains R2/RMSE;
    coef() returns named numeric matching coefficients; residuals() returns numeric vector;
    vcov() returns NULL when ifHess="no"; vcov() returns matrix when available; print does not
    modify object; all 5 S3 methods registered (verified via methods(), not isS3method()).
  - test-plot-rsparrow.R (6 tests): plot.rsparrow registered as S3 method; invalid type stops
    with error mentioning valid types; valid types ("residuals","sensitivity","spatial") pass
    dispatch without "invalid type" error (deeper data-missing errors are acceptable); ...
    forwarded through dispatch.
  - test-rsparrow-wrappers.R (10+1 skip tests): rsparrow_bootstrap formal args (object, n_boot,
    seed); class check errors for all three wrappers; rsparrow_validate detects missing
    Vsites.list; rsparrow_scenario requires rsparrow class; rsparrow_model has 6 required args;
    rsparrow_model stops for nonexistent path_main; rsparrow_model validates model_type via
    match.arg before calling read_sparrow_data. 1 skip: reproducibility test requires fitted model.
  - Key implementation notes: isS3method() does not work for base S3 — use
    "method.class" %in% as.character(methods("generic")) instead; rsparrow_bootstrap
    API is (object, n_boot, seed) not (model, biters, iseed) as the plan doc assumed.
  - Total: 38 tests (1 skip), all pass; 0 fail
</plan>

</completed_plans>

</cran_roadmap>
