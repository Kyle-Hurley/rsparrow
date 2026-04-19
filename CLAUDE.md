<rsparrow_guide>
<project_overview>
rsparrow is an R implementation of the USGS SPARROW water-quality model that uses spatially
referenced regression to relate water measurements to watershed attributes. Version 2.1.0
contains 118 R files (105 internal + 13 exported), 6 Fortran subroutines, and 3
Imports (data.table, nlmrt, numDeriv). The package lives at the repo root (moved from
RSPARROW_master/ in Plan 07) and is undergoing refactoring for CRAN submission.

Plans 01–09 are complete: package structure, non-core code separation, API design,
GlobalEnv/eval elimination, all 13 exported functions implemented, dead-code removal, predict
consolidation, eval/parse cleanup, diagnostic plot infrastructure, test suite (166 tests pass),
package restructuring to repo root, dynamic model removal, and 23 unreachable functions archived.

A critical code review (2026-03-08) identified fundamental issues blocking CRAN submission:
package not at repo root, compiled artifacts in src/, uncontrolled file I/O in estimation/
prediction, sink/pdf/options without on.exit(), <<- and assign(parent.frame()) anti-patterns,
cat() instead of message(), 31 unreachable functions, unnecessary Collate field, and dynamic
model infrastructure that adds complexity for a feature users can replicate themselves.

Remaining work: Plans 10–12 (computation/I/O separation, CRAN compliance fixes,
example dataset + vignette).
</project_overview>

<key_concepts>
SPARROW models three watershed processes: (1) contaminant source generation, (2) land-to-water
delivery via surficial/subsurface pathways, and (3) in-stream/reservoir transport and decay.
Estimation uses nonlinear least squares (NLLS) on log-transformed loads with monitoring load
substitution. Reaches are ordered by hydrological sequence; loads accumulate downstream via
Fortran subroutines. Only static (long-term mean annual) model specification is supported;
dynamic (seasonal/annual time-varying) infrastructure is being removed in Plan 08.
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

COMPLETED (Plans 07–09):
- Package moved to repo root; compiled artifacts deleted; Collate removed (GH #10, #11, #12)
- Dynamic model infrastructure removed (Plan 08, GH #13)
- 23 unreachable functions archived to inst/archived/ (Plan 09, GH #14)

REMAINING ISSUES (Plans 10–12):
- Computation must be separated from I/O (Plan 10, GH #15)
- sink/pdf/options need on.exit(); cat→message; <<-/assign(parent.frame()) eliminated
  (Plan 11, GH #16-19)
<see_also>docs/reference/ARCHITECTURE.md</see_also>
</architecture>

<critical_files>
<file path="R/estimateFeval.R">NLLS objective function; core SPARROW math</file>
<file path="R/estimateOptimize.R">NLLS optimization via nlmrt::nlfb()</file>
<file path="R/predict.R">Reach-level load/yield predictions</file>
<file path="R/estimate.R">Estimation orchestrator (~890 lines); needs I/O separation</file>
<file path="R/deliver.R">Delivery fraction calculation (Fortran wrapper)</file>
<file path="R/hydseq.R">Hydrological sequencing of reach network</file>
<file path="R/controlFileTasksModel.R">Master task dispatcher; needs I/O separation</file>
<file path="R/startModelRun.R">Data prep and calibration site setup; needs I/O separation</file>
<file path="R/rsparrow_model.R">Main exported function; has <<- anti-pattern at line 380</file>
<file path="src/tnoder.f">Fortran load accumulation for estimation</file>
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
Remaining issues (post-Plan 09):
- I/O COUPLING: ~35 dir.create, ~22 save, ~22 fwrite in computation functions (GH #15)
- RESOURCE LEAKS: 5 sink + 1 pdf without on.exit() (GH #16)
- OPTIONS: 5 options() without restoration (GH #17)
- ANTI-PATTERNS: 1 <<- + 5 assign(parent.frame()) (GH #18; unPackList×2 archived in Plan 09)
- MESSAGING: 53 cat() instead of message() (GH #19)
- EVAL/PARSE: ~25 eval(parse()) remain (~21 COMPLEX/deferred + ~4 hardened hover-text;
  reduced from 49 by Plans 08+09 archiving mapLoopStr×11, unPackList×1, naOmitFuncStr×1,
  aggDynamicMapdata×5, dynamic diag files×4, checkDrainageareaErrors×1)
- MONOLITHS: functions exceeding 800 lines (estimate.R, estimateNLLSmetrics.R, estimateNLLStable.R)
- CODOC: Rd mismatches in 3 exported functions (GH #5)
- IMPORTS: undeclared stringi/xfun in legacy encoding files (GH #6)
- WARNINGS: layout() shape-argument + predictSensitivity unused-arg (GH #7)
<see_also>docs/reference/TECHNICAL_DEBT.md</see_also>
</technical_debt>

<development_workflow>
Legacy usage: User sets paths in sparrow_control.R, sources it in RStudio, which triggered
runRsparrow.R (now in inst/legacy/). Package builds successfully via R CMD build (--no-build-
vignettes due to missing deps). Tests exist at tests/testthat/ (98 tests, 24 files, 0 failures).
Tutorial models in UserTutorial/ (static TN) and UserTutorialDynamic/ (dynamic TP).
Build: R CMD build --no-build-vignettes . -> rsparrow_2.1.0.tar.gz

Git and GitHub workflow:
- Remote: https://github.com/Kyle-Hurley/rsparrow (branch: main)
- Use `gh` CLI for all GitHub operations (issues, PRs, etc.)
- When signing commits as co-author, use: Co-Authored-By: Claude
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
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz

  # Build package tarball
  R CMD build --no-build-vignettes .

  # Run testthat tests (after install)
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

  # Run a single test file
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_file('tests/testthat/<file>.R')"

  # Rebuild roxygen docs + NAMESPACE
  R_LIBS=/home/kp/R/libs Rscript -e "roxygen2::roxygenise('.')"

  # Or use Make targets: check | test | build | document | install | clean
  make check

Baseline (Plan 06A): R CMD check produces 4 WARNINGs, 3 NOTEs, 0 ERRORs, 98 tests pass.
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
