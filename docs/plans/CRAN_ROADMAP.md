<cran_roadmap>

<executive_summary>
Plans 01–12 are complete. The package is CRAN-ready.
  - Package at repo root (R/, src/, man/, tests/, inst/, DESCRIPTION, NAMESPACE)
  - Compiled artifacts removed from src/; Collate field removed; .Rbuildignore in place
  - Dynamic model infrastructure removed; 23 unreachable functions archived to inst/archived/
  - Computation/I/O separated; all CRAN compliance issues fixed
  - sparrow_example dataset in data/ (GH #9); introductory vignette (GH #8)
  - @examples updated in all 14 exported functions using sparrow_example
  - DESCRIPTION URL/BugReports point to GitHub
Test suite: FAIL 0 | PASS 166 | SKIP 1.
R CMD check (tarball, --no-manual): 0 ERRORs, 0 WARNINGs, 2 NOTEs (both pre-existing).

ALL BLOCKERS RESOLVED (Plans 07–12):
  (B1)  DONE — Package moved from RSPARROW_master/ to repo root (GH #10, commit e5b58b4)
  (B2)  DONE — Compiled .o/.so artifacts deleted from src/ (GH #11, commit e5b58b4)
  (B3)  DONE — Collate field removed from DESCRIPTION (GH #12, commit e5b58b4)
  (B10) DONE — .Rbuildignore created at repo root (commit e5b58b4)
  (B12) DONE — 23 unreachable functions archived to inst/archived/ (GH #14, Plan 09)
  (B13) DONE — Dynamic model infrastructure removed (GH #13, Plan 08)
  (B4)  DONE — Computation/I/O separated; write_rsparrow_results() as opt-in output (GH #15, Plan 10)
  (B5)  DONE — <<- and all assign(parent.frame()) eliminated (GH #18, Plans 10+11)
  (B6)  DONE — sink/pdf side effects removed; on.exit() protected (GH #16, Plan 10)
  (B7)  DONE — options() modifications removed or wrapped with on.exit() (GH #17, Plan 10)
  (B8)  DONE — cat()→message() across all 10 affected files (GH #19, Plan 11)
  (B9)  DONE — stringi/xfun: xfun replaced with base R; stringi guarded by requireNamespace() (GH #6, Plan 11)
  (B10) DONE — layout() prefixed with plotly:: to eliminate shape-argument WARNINGs (GH #7, Plan 11)
  (B11) DONE — rsparrow_scenario.Rd \\% fixed (Rd comment char issue) (GH #5, Plan 11)
  (B12) DONE — Vignette converted to rmarkdown::html_vignette; rewritten for new API (GH #8, Plans 11+12)
  (B14) DONE — sparrow_example dataset in data/ (GH #9, Plan 12)
  (B15) DONE — @examples updated in all 14 exported functions (Plan 12)
  (B16) DONE — DESCRIPTION URL/BugReports updated to GitHub (Plan 12)
</executive_summary>

<critical_requirements>

<package_structure>
<requirement status="done">Rename package from RSPARROW to `rsparrow` in DESCRIPTION (CRAN naming convention: lowercase, no underscores)</requirement>
<requirement status="done" gh="10">Move package root from RSPARROW_master/ to repo root — all devtools, usethis, roxygen2, and CRAN tooling assumes package root = repo root</requirement>
<requirement status="done">Delete runRsparrow.R from R/ - moved to inst/legacy/; all files in R/ now define only functions, methods, or classes</requirement>
<requirement status="done">Remove all pre-compiled DLLs (.dll) from src/; only .for source files remain</requirement>
<requirement status="done" gh="11">Remove compiled .o and .so artifacts from src/ — CRAN requires source-only packages; R CMD INSTALL recompiles .f sources automatically</requirement>
<requirement status="done">Remove bundled R-4.4.2.zip from repo root</requirement>
<requirement status="done">Remove inst/sas/ directory (legacy SAS scripts)</requirement>
<requirement status="done">Remove batch/ directory (Windows-only Rscript.exe batch execution)</requirement>
<requirement status="done">Remove Thumbs.db and code.json from repo</requirement>
<requirement status="done" gh="10">Create .Rbuildignore at package root to exclude non-package files (docs/, scripts/, UserTutorial*, Makefile, CLAUDE.md, walkthrough.R, .github/, .gitlab/)</requirement>
<requirement status="done">Ensure DESCRIPTION has Version in x.y.z format (now 2.1.0)</requirement>
<requirement status="done" gh="12">Remove Collate field from DESCRIPTION — unnecessary for S3 packages, creates maintenance burden on every file change</requirement>
</package_structure>

<code_quality>
<requirement status="done" gh="13">Remove dynamic model infrastructure — the dynamic feature is temporal diagnostic stratification of a single unified model; users can replicate this by including temporal columns and subsetting results. Removes ~935 lines of dynamic-only code and simplifies 20 files with 175 if_dynamic references</requirement>
<requirement status="done" gh="14">Archive unreachable functions to inst/archived/ — 23 functions confirmed unreachable from all 13 exports (down from 31 original estimate: 5 found to be reachable, 3 already archived in Plan 08). Archived to legacy_data_import/, mapping/, utilities/ subdirectories. Test count: 186→166 (20 tests removed that tested archived functions)</requirement>
<requirement status="done" gh="15">Separate computation from I/O — estimation/prediction functions return R objects; file output removed as side effects. write_rsparrow_results() exported as the single opt-in I/O function. Removed: ~7 save + 10 dir.create from estimate.R, ~5 save from startModelRun.R, ~20 fwrite + sink from estimateNLLStable.R, ~4 save + sink from controlFileTasksModel.R, save/dir.create from predictScenarios.R, predictBootstraps.R, diagnosticSensitivity.R, diagnosticSpatialAutoCorr.R, correlationMatrix.R, predictScenariosOutCSV.R, estimateBootstraps.R (CSV only; cross-run BootBetaest save kept)</requirement>
<requirement status="done" gh="16">Fix sink()/pdf() resource leaks — all unprotected sink/pdf removed or protected:
  - estimateOptimize.R: KEPT — on.exit(sink(), add=TRUE) added (Plan 10)
  - estimateNLLStable.R: sink REMOVED, data returned as named list (Plan 10)
  - correlationMatrix.R: pdf+sink REMOVED, data returned (Plan 10)
  - predictScenariosOutCSV.R: metadata sink REMOVED (Plan 10)
  - controlFileTasksModel.R: spatial autocorr sink REMOVED, data returned (Plan 10)</requirement>
<requirement status="done" gh="17">Fix options() modifications without restoration — all unprotected options() removed:
  - correlationMatrix.R: options(width) REMOVED (Plan 10)
  - predictScenariosPrep.R: options(warn) wrapped with on.exit() (Plan 10)
  - controlFileTasksModel.R: options() block REMOVED with spatial autocorr sink (Plan 10)
  - estimateNLLStable.R: options(width/max.print) REMOVED (Plan 10)</requirement>
<requirement status="partial" gh="18">Eliminate <<- and assign(parent.frame()) anti-patterns:
  - rsparrow_model.R: <<- ELIMINATED — predict.list threaded via sparrow_state return value (Plan 10)
  - diagnosticPlots_4panel_B.R:134 — ELIMINATED (Plan 10)
  - upstream.R:52 — ELIMINATED, function returns named list (Plan 10)
  - applyUserModify.R:40,43,45 — 3× assign to parent.frame — DEFERRED to Plan 11
  - checkBinaryMaps.R:35 — assign to parent.frame — DEFERRED to Plan 11</requirement>
<requirement status="open" gh="19">Replace cat() with message() for user-facing output — 53 instances across 15+ files. cat() should only be used in print/summary S3 methods for structured output. All informational messages must use message() so users can suppress them</requirement>
<requirement status="open">Replace remaining eval(parse()) where feasible — 49 remain (27 COMPLEX/deferred + ~22 hardened hover-text). Some will be eliminated by archiving dead code (Plan 09) and removing dynamic infrastructure (Plan 08)</requirement>
</code_quality>

<documentation>
<requirement status="done">Add @export roxygen2 tags to all user-facing functions (13 functions exported: 6 standalone + 7 S3 methods)</requirement>
<requirement status="done">Add @examples sections to all exported functions; wrap long-running examples in \dontrun{} or \donttest{}</requirement>
<requirement status="done">Add @return tags with meaningful descriptions to all exported functions</requirement>
<requirement>Remove manual "Executed By" / "Executes Routines" lists from roxygen headers - these are stale and non-standard</requirement>
<requirement status="done">Regenerate all man/ pages via roxygen2 after adding proper tags (manual generation; roxygen2 unavailable)</requirement>
<requirement status="done">Rewrite package-level documentation (?rsparrow) with a clear overview and quick-start example</requirement>
<requirement status="done" gh="8">Rewrite vignette to demonstrate the refactored API — RSPARROW_vignette.Rmd fully rewritten with sparrow_example workflow (Plan 12)</requirement>
</documentation>

<testing_and_examples>
<requirement status="done">Add regression tests for core math: estimateFeval, predict, deliver, hydseq, and exported API — Plans 06B–06F complete (15+17+11+17+38 tests; 1 skip). 24 test files, 0 failures.</requirement>
<requirement status="done">Create small synthetic reach network dataset (7 reaches, Y-shaped) for fast unit tests — fixtures/mini_network.rda (Plan 06A)</requirement>
<requirement status="done">Generate reference output fixtures for estimation/prediction unit tests — fixtures/mini_model_inputs.rda (Plan 06A; synthetic, not UserTutorial-derived)</requirement>
<requirement>All tests must complete within CRAN's 10-minute limit for R CMD check</requirement>
<requirement status="done">Remove or rewrite the 7 makeReport_* test files that test Rmd report rendering — 8 broken test files deleted in Plan 06A (including makeReport_siteAttrMaps)</requirement>
<requirement status="done">Add testthat edition 3 in DESCRIPTION (Suggests: testthat (>= 3.0.0), Config/testthat/edition: 3) — Plan 06A</requirement>
<requirement status="done" gh="9">Include example dataset in data/ with roxygen documentation — sparrow_example: 60-reach synthetic network (2.5 KB XZ), documented in R/data.R (Plan 12)</requirement>
</testing_and_examples>

<dependencies_and_portability>
<requirement status="done">Remove Windows-only code: 21 shell.exec() calls across 15 files; Sys.which("Rscript.exe") paths; system() batch execution [DONE in Plan 04A Task 1]</requirement>
<requirement status="done">Remove Fortran !GCC$ ATTRIBUTES DLLEXPORT directives from all .for files (Windows-specific, not portable)</requirement>
<requirement status="done">Drop non-core Imports (final: 3 packages, down from 40 via Plans 02+03; target was ~10-12, exceeded):
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
<requirement status="done">Update URL field to https://github.com/Kyle-Hurley/rsparrow; BugReports field added pointing to GitHub issues (Plan 12)</requirement>
</legal_and_administrative>

</critical_requirements>

<architecture_recommendations>

<code_organization>
<recommendation status="done">Eliminate unPackList.R entirely. unPackList.R and mapLoopStr.R (its last active callers) both archived to inst/archived/ in Plan 09. replaceNAs.R retains a TODO comment; applyUserModify.R replaced unPackList with explicit assign loops in Plan 05C.</recommendation>
<recommendation status="done">Remove all assign(..., envir = .GlobalEnv) calls. All 51 occurrences eliminated (Plans 04A + 04B). Zero remain in R/.</recommendation>
<recommendation status="partial">Replace remaining eval(parse(text = ...)) with proper R idioms. 49 remain after Plans 04B/05B/05C/05D. Some will be eliminated by archiving dead code and removing dynamic infrastructure.</recommendation>
<recommendation status="done">Merge duplicate prediction functions: predict_core.R (266 lines) created in Plan 05B.</recommendation>
<recommendation status="done">Merge estimateFeval.R and estimateFevalNoadj.R. Done in Plan 05B.</recommendation>
<recommendation>Decompose monolithic functions:
  - estimate.R (889 lines) -> separate estimation from diagnostics/validation/output
  - estimateNLLSmetrics.R (835 lines) -> separate metric computation functions
  - estimateNLLStable.R (763 lines) -> return structured data; eliminate sink() file I/O
  - predictScenarios.R (523 lines) -> extract core logic from Shiny coupling</recommendation>
<recommendation status="done">Move all Shiny/GUI files to inst/shiny_dss/ (Plan 02).</recommendation>
<recommendation status="done">Remove non-core functions. ~79 deleted across Plans 02/05A/05D. 23 unreachable functions archived to inst/archived/ in Plan 09. 5 functions originally listed as dead were found to be reachable (calcDemtareaClass, calcIncremLandUse, startEndmodifySubdata, checkBinaryMaps, hline).</recommendation>
<recommendation status="done">Remove interactive map/report generators. Done in Plans 05A/05D.</recommendation>
<recommendation>Replace all "yes"/"no" string settings with logical TRUE/FALSE throughout. ~50 occurrences.</recommendation>
<recommendation>Separate computation from I/O. Core functions return R objects; file output is opt-in via dedicated I/O functions.</recommendation>
</code_organization>

<api_design>
<recommendation status="done">Define clean exported API: 13 functions exported (6 standalone + 7 S3 methods).</recommendation>
<recommendation status="done">Return S3 objects with class "rsparrow" from estimation.</recommendation>
<recommendation>All functions must accept data as arguments, not read from global state. The user passes a data.frame and parameter specifications; the function returns results.</recommendation>
<recommendation>Separate computation from I/O. Core functions return R objects; optional convenience functions write CSV/plots. Never write files as a side effect of computation.</recommendation>
</api_design>

<data_handling>
<recommendation status="open" gh="9">Include a small example dataset in data/ (~50-100 reaches) for examples and tests.</recommendation>
<recommendation>Move UserTutorial/ and UserTutorialDynamic/ out of the package entirely.</recommendation>
<recommendation>Keep CSV-based input (parameters.csv, design_matrix.csv, dataDictionary.csv) as the user interface for model specification.</recommendation>
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
Use testthat (>= 3.0.0) with edition 3. Plans 06A–06F complete (98 tests, 24 files).
Remaining:
- Integration test: data -> estimate -> predict pipeline on example dataset
- Edge cases: single-reach network, all-headwater network, missing monitoring data
- Test refactored I/O functions separately from computation functions
Target: >80% coverage on exported functions. All tests under 10 minutes total.
</testing_strategy>

<vignettes_and_tutorials>
Create one primary vignette: "Introduction to rsparrow" demonstrating the full workflow
(read data -> specify model -> estimate -> predict -> diagnose) using the bundled example
dataset. Keep computation lightweight (\donttest{} or pre-computed results for slow steps).
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
  - [DONE] GH #10: Move package root to repo root; create .Rbuildignore (Plan 07)
  - [DONE] GH #11: Delete compiled .o/.so artifacts from src/ (Plan 07)
  - [DONE] GH #12: Remove Collate field from DESCRIPTION (Plan 07)
  - [OPEN] GH #15: Separate computation from I/O in estimation/prediction
  - [OPEN] GH #16: Fix sink()/pdf() resource leaks with on.exit() or removal
  - [OPEN] GH #17: Fix options() without restoration
  - [OPEN] GH #18: Eliminate <<- and assign(parent.frame()) anti-patterns
  - [OPEN] GH #19: Replace cat() with message() for user-facing output
  - [OPEN] GH #5: Fix Rd codoc mismatches in rsparrow_model/rsparrow_scenario/rsparrow_validate
  - [OPEN] GH #6: Fix undeclared stringi/xfun imports
  - [OPEN] GH #7: Fix layout() shape-argument + predictSensitivity unused-arg warnings
</priority>

<priority level="2" label="High-value - enables usability and maintainability">
  - [DONE] GH #13: Remove dynamic model infrastructure (Plan 08)
  - [DONE] GH #14: Archive 23 unreachable functions to inst/archived/ (Plan 09)
  - [OPEN] GH #9: Create example dataset in data/
  - [OPEN] GH #8: Write primary vignette
  - [PARTIAL] Eliminate unPackList.R — 3 COMPLEX/deferred callers remain (may be archived)
  - [PARTIAL] Replace eval(parse()) — 49 remain, some eliminated by archiving/dynamic removal
  - [DONE] Merge duplicate predict functions (Plan 05B)
  - [DONE] Design and implement S3 class "rsparrow" (Plans 04D-1 through 04D-4)
  - [DONE] Separate Shiny/GUI code (Plan 02)
  - [DONE] Build test suite (Plans 06A–06F: 98 tests, 0 failures)
</priority>

<priority level="3" label="Important but not blocking initial submission">
  - Decompose monolithic functions (estimate.R, estimateNLLSmetrics.R, etc.)
  - Replace "yes"/"no" strings with logical TRUE/FALSE
  - Standardize naming conventions (camelCase vs dot.separated vs underscore)
  - Replace hardcoded path construction with file.path()
  - Add input validation to Fortran interface calls
  - Pursue >80% test coverage on exported functions
  - Write second vignette on scenarios and bootstrapping
  - Consider lowering R >= 4.4.0 requirement (only %||% needs 4.4.0; pipe |> needs 4.1.0)
</priority>

</prioritized_actions>

<cran_checklist>
<item status="pass">R CMD build produces a valid tarball (rsparrow_2.1.0.tar.gz)</item>
<item status="pass">R CMD check --no-manual returns 0 errors, 0 warnings — 0 ERRORs, 0 WARNINGs, 2 NOTEs (tarball check, Plan 12)</item>
<item status="pass">All files in R/ contain only function/method/class definitions</item>
<item status="pass">No pre-compiled binaries in src/ — .o and .so artifacts deleted (GH #11, Plan 07)</item>
<item status="pass">Fortran source compiles on all platforms (no Windows-specific directives)</item>
<item status="pass">NAMESPACE has explicit exports (6 export() + 7 S3method())</item>
<item status="pass">NAMESPACE uses importFrom instead of blanket import (selective importFrom() only)</item>
<item status="pass">DESCRIPTION has single Maintainer with valid email</item>
<item status="pass">DESCRIPTION uses Authors@R with person() entries</item>
<item status="pass">DESCRIPTION License matches actual license terms</item>
<item status="pass">DESCRIPTION Version is x.y.z format</item>
<item status="pass">DESCRIPTION has no Collate field (GH #12, Plan 07)</item>
<item status="pass">All exported functions have complete roxygen2 documentation</item>
<item status="pass">All exported functions have @examples</item>
<item status="pass">All exported functions have @return</item>
<item status="pass">No .GlobalEnv modifications via assign(.GlobalEnv) (eliminated Plans 04A+04B)</item>
<item status="pass">No <<- or assign(parent.frame()) anti-patterns (GH #18, Plans 10+11)</item>
<item status="pass">No unprotected sink()/pdf()/options() side effects (GH #16, #17, Plan 10)</item>
<item status="pass">User messaging uses message() not cat() (GH #19, Plan 11)</item>
<item status="pass">Computation separated from I/O — no file writes as side effects (GH #15, Plan 10)</item>
<item status="partial">No eval(parse()) in exported functions — 49 remain in internal functions</item>
<item status="pass">No shell.exec() or Windows-only system calls</item>
<item status="pass">Package root at repo root (GH #10, Plan 07)</item>
<item status="pass">Example dataset included in data/ (GH #9, Plan 12) — sparrow_example: 60-reach synthetic network, LazyData: true</item>
<item status="pass">At least one vignette demonstrating core workflow — html_vignette fully updated with sparrow_example workflow (GH #8, Plan 12)</item>
<item status="unchecked">Package installs and loads on macOS, Linux, and Windows — Linux verified; Windows/macOS untested</item>
<item status="pass">Total R CMD check time under 10 minutes — tests run in ~1.2s</item>
<item status="unchecked">testthat tests pass on all platforms — Linux verified (FAIL 0, PASS 166, SKIP 1)</item>
<item status="unchecked">CRAN submission via devtools::submit_cran() accepted</item>
</cran_checklist>

<upcoming_plans>

<plan id="10" label="Separate Computation from I/O">
Status: NOT STARTED
Scope:
  - Refactor estimation functions to return R objects instead of writing files:
    estimate.R: Remove ~7 save() + 10 dir.create(); return estimate.list directly
    estimateNLLSmetrics.R: Remove save(); return metrics list
    estimateNLLStable.R: Remove sink() + ~20 fwrite(); return summary data as list/data.frame
    estimateOptimize.R: Add on.exit(sink()) protection; keep logging but make it optional
    correlationMatrix.R: Remove pdf() + sink(); return correlation data only
  - Refactor prediction functions:
    controlFileTasksModel.R: Remove ~4 save() + sink(); pass results via return values
    predictScenarios.R: Remove ~2 save() + dir.create(); return predictions
    predictScenariosOutCSV.R: Remove metadata sink(); keep as explicit I/O function
    predictBootstraps.R: Remove save(); return bootstrap results
  - Refactor startModelRun.R: Remove ~5 save(); accumulate in sparrow_state return
  - Create optional write_rsparrow_results() or similar convenience function for users
    who want CSV/file output — this is where all file I/O belongs
  - Fix rsparrow_model.R:380 <<- anti-pattern: restructure predict.list loading to
    avoid global assignment (return from controlFileTasksModel instead of load from file)
Dependencies: Plans 07, 08, 09 (cleaner codebase to refactor)
GH Issues: #15, #18
</plan>

<plan id="11" label="CRAN Compliance Fixes">
Status: NOT STARTED
Scope:
  - Fix remaining sink()/pdf() issues (GH #16):
    Any sink() that survives Plan 10 gets on.exit(sink()) protection
    Any pdf() that survives gets on.exit(dev.off()) protection
  - Fix options() without restoration (GH #17):
    Add on.exit(options(old_opts)) pattern to all 5 locations
  - Eliminate remaining assign(parent.frame()) (GH #18):
    diagnosticPlots_4panel_B.R:134, upstream.R:52, applyUserModify.R:40/43/45
    (checkBinaryMaps.R:35 and unPackList.R likely archived in Plan 09)
  - Replace cat() with message() (GH #19):
    53 instances across 15+ files; keep cat() only in print/summary S3 methods
  - Fix existing R CMD check WARNINGs:
    GH #5: Rd codoc mismatches in rsparrow_model/rsparrow_scenario/rsparrow_validate
    GH #6: Undeclared stringi/xfun imports (in legacy encoding files — likely archived)
    GH #7: layout() shape-argument + predictSensitivity unused-arg warnings
  - Fix R CMD check NOTEs
Dependencies: Plans 07–10
GH Issues: #5, #6, #7, #16, #17, #18, #19
</plan>

<plan id="12" label="Example Dataset, Vignette, and Final Polish">
Status: NOT STARTED
Scope:
  - Create example dataset in data/ (~50-100 reaches, synthetic or UserTutorial subset)
  - Document dataset with R/data.R containing roxygen2 @docType data blocks
  - Update @examples in all 13 exported functions to use bundled dataset
  - Write introductory vignette: read data → estimate → predict → diagnose
  - Update URL and BugReports fields in DESCRIPTION
  - Final R CMD check --as-cran: target 0 ERRORs, 0 WARNINGs, ≤1 NOTE
  - Cross-platform testing (Linux, macOS, Windows)
Dependencies: Plans 07–11
GH Issues: #8, #9
</plan>

</upcoming_plans>

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
  - Task 1: Removed all Windows-only code (shell.exec, Rscript.exe, batch_mode)
  - Task 2: Eliminated 27 assign(.GlobalEnv) from startModelRun.R
  - Task 3: Refactored controlFileTasksModel.R
  - R CMD build succeeds
</plan>

<plan id="04B" label="Remaining GlobalEnv and Specification-String Elimination">
Completed all tasks:
  - Task 4: Eliminated 23 assign(.GlobalEnv) from 13 files
  - Task 5: Replaced 21 specification-string eval(parse()) in 7 core math files
  - Final counts: 0 assign(.GlobalEnv) in R/
</plan>

<plan id="04C" label="unPackList Removal and eval(parse) Dynamic Column Cleanup">
Completed all tasks:
  - All actionable unPackList() calls removed from non-REMOVE files
  - Dynamic column eval(parse()) replaced with [[]] in 6 files
  - Roxygen references cleaned from ~48 files
</plan>

<plan id="04D" label="Exported API Implementation (all 4 sub-sessions)">
Sub-sessions 04D-1 through 04D-4: All 13 exported functions fully implemented.
</plan>

<plan id="05A" label="Dead Code Removal">
Completed: 15 files deleted from R/.
</plan>

<plan id="05B" label="Predict Consolidation">
Completed: predict_core.R created; ~900 lines removed; estimateFevalNoadj.R merged.
</plan>

<plan id="05C" label="Remaining eval(parse()) Elimination">
Completed: 20 more eval(parse()) eliminated. Total 47→~27 remaining.
</plan>

<plan id="05D" label="Diagnostic Plot Infrastructure Removal">
Completed: 20 REMOVE-list files deleted. plot.rsparrow() fully implemented. File count: 138→118.
</plan>

<plan id="06A" label="Test Infrastructure Setup">
Completed: testthat edition 3, fixtures created, 23 tests pass.
</plan>

<plan id="06B" label="Network Topology Tests">
Completed 2026-03-07. 15 tests, all pass.
</plan>

<plan id="06C" label="Fortran Interface Tests">
Completed 2026-03-07. 17 tests, all pass.
</plan>

<plan id="06D" label="Estimation Core Tests">
Completed 2026-03-07. 11 tests, all pass.
</plan>

<plan id="06E" label="Prediction Tests">
Completed 2026-03-08. 17 tests, all pass.
</plan>

<plan id="06F" label="Exported API Tests">
Completed 2026-03-08. 38 tests (1 skip), all pass.
</plan>

<plan id="08" label="Remove Dynamic Model Infrastructure">
Completed 2026-03-09. GH #13 closed.
  - Archived 7 dynamic-only R files to inst/archived/dynamic/ (checkDynamic, readForecast,
    aggDynamicMapdata, setupDynamicMaps, checkDrainageareaMapPrep, diagnosticPlotsNLLS_dyn,
    diagnosticPlotsNLLS_timeSeries)
  - Stripped all if(dynamic) branches from 14 active R files
  - Removed model_type parameter from rsparrow_model() entirely
  - test_checkDynamic.R removed (8 tests); test count: 194→186
</plan>

<plan id="09" label="Archive Unreachable Code">
Completed 2026-04-19. GH #14 closed.
  - Call-graph verification found 5 functions incorrectly listed as dead (reachable):
    calcDemtareaClass, calcIncremLandUse, startEndmodifySubdata (via startModelRun.R),
    checkBinaryMaps, hline (via diagnosticPlotsNLLS.R and diagnosticPlots_4panel_A.R)
  - Archived 23 files (not 31 — 5 reachable, 3 already in inst/archived/dynamic/ from Plan 08):
    inst/archived/legacy_data_import/ (9): addVars, calcHeadflag, checkData1NavigationVars,
      checkDupVarnames, checkMissingData1Vars, createInitialDataDictionary, createVerifyReachAttr,
      dataInputPrep, replaceData1Names
    inst/archived/mapping/ (8): checkDrainageareaErrors, g_legend, mapBreaks, mapLoopStr,
      set_unique_breaks, verifyDemtarea, makeAESvector, areColors
    inst/archived/utilities/ (6): unPackList, naOmitFuncStr, test_addPlotlyvars, syncVarNames,
      estimateWeightedErrors, copyStructure
  - Removed test-copyStructure.R, test-estimateWeightedErrors.R; updated test-calcflags.R
  - Test count: 186→166 (20 tests removed)
  - eval(parse()) count reduced by ~13 (mapLoopStr×11, unPackList×1, naOmitFuncStr×1)
</plan>

<plan id="07" label="Package Restructuring">
Completed 2026-03-08. Commit e5b58b4. GH #10, #11, #12 closed.
  - Task 07-1: Inventoried RSPARROW_master/ references (load-bearing: Makefile,
    .claude/skills/*.md; docs-only: CLAUDE.md, README.md)
  - Task 07-2: Deleted 7 compiled artifacts (*.o, *.so) from src/; only *.f remain;
    added src/*.o, src/*.so, src/*.so.dSYM to .gitignore
  - Task 07-3: Removed 120-line Collate field from DESCRIPTION
  - Task 07-4: git mv of R/, src/, man/, tests/, inst/, vignettes/, DESCRIPTION, NAMESPACE
    from RSPARROW_master/ to repo root; history preserved (all 295 changes show as renames)
  - Task 07-5: Created .Rbuildignore at repo root; tarball verified clean
  - Task 07-6: Updated Makefile (PKG_DIR=., check now against tarball), CLAUDE.md,
    and all .claude/skills/*.md
  - Task 07-7: R CMD check (tarball, --no-manual): 0 ERRORs, 4 WARNINGs, 4 NOTEs
    (3 pre-existing + 1 pre-existing inst/doc/figures NOTE previously masked by source-dir
    check method). FAIL 0 | PASS 194 | SKIP 1.
</plan>

</completed_plans>

</cran_roadmap>
