<plan id="08" label="Remove Dynamic Model Infrastructure" status="pending" blocked_by="07">

<objective>
Archive the six dynamic-only R files to inst/archived/dynamic/ and strip all if_dynamic
conditional branches from the fourteen remaining files that contain them. After this plan
the package supports only the static (long-term mean annual) SPARROW model and contains
approximately 2,100 fewer lines of code.
</objective>

<context>
The "dynamic" model adds temporal diagnostic stratification — year/season-specific R², RMSE,
and plots — on top of the identical core SPARROW estimation. The parameter estimation itself
is unchanged: a single parameter set is fit across all observations regardless of model_type.
The only difference is diagnostic output sliced by time period.

Users who need temporal diagnostics can replicate this by including temporal columns in their
data and subsetting results by year/season. The infrastructure therefore adds complexity without
providing functionality that users cannot achieve themselves.

The dynamic infrastructure spans:
  - 6 dynamic-only R files (~1,907 lines total)
  - 175 references across 20 files (38 in estimateNLLSmetrics.R alone)
  - 2 parameters in the public API: model_type in rsparrow_model(), related settings in
    file.output.list (map_years, map_seasons, diagnosticPlots_timestep, etc.)

This plan archives rather than deletes. inst/archived/dynamic/ preserves the code for
potential future revival without cluttering the active package.
</context>

<gh_issues>GH #13</gh_issues>

<reference_documents>
  docs/plans/CRAN_ROADMAP.md — priority 2, GH #13
  R/estimateNLLSmetrics.R — 38 dynamic references (ANOVAdynamic.list computation)
  R/estimateNLLStable.R — 24 dynamic references (dynamic summary table sections)
  R/estimate.R — 21 dynamic references (dynamic diagnostic dispatch)
  R/diagnosticPlotsNLLS.R — 8 dynamic references (dynamic plot dispatch)
  R/diagnosticSpatialAutoCorr.R — 6 dynamic references
  R/predictScenariosPrep.R — 5 dynamic references
  R/controlFileTasksModel.R — 3 dynamic references
  R/startModelRun.R — 2 dynamic references
  R/rsparrow_model.R — 2 dynamic references (model_type parameter)
  R/diagnosticSensitivity.R — 2 dynamic references
  R/checkDrainageareaMapPrep.R — 2 dynamic references
  R/hline.R — 2 dynamic references
  R/replaceNAs.R — 1 dynamic reference
  R/hydseq.R — 1 dynamic reference
</reference_documents>

<tasks>

<task id="08-1" status="pending">
<subject>Audit dynamic references across all 20 affected files</subject>
<description>
Before touching any files, run a complete audit of all dynamic references to understand
exactly what needs to be removed vs. what is interleaved with static code.

Search commands:
  grep -rn "if_dynamic\|model_type\|dynamic\|ANOVAdynamic\|map_years\|map_seasons\|timestep\|timeSeries\|readForecast\|checkDynamic\|diagnosticPlotsNLLS_dyn\|diagnosticPlotsNLLS_timeSeries\|aggDynamicMapdata\|setupDynamicMaps" R/

For each reference, classify as:
  A — In a block that is ONLY dynamic (safe to delete the entire if block)
  B — Dynamic branch of an if/else where static branch must be kept
  C — Dynamic variable used in both branches (requires careful extraction)
  D — Function argument / signature reference (requires parameter removal)

Pay particular attention to estimateNLLSmetrics.R (38 refs) and estimateNLLStable.R (24 refs)
— these have the most dynamic interleaving. Note the exact line ranges of each dynamic block.

Also identify: does any test in tests/testthat/ reference if_dynamic, model_type="dynamic",
or any dynamic-only function? If so, those tests must be updated in this plan.

This task is read-only — produce a classified reference list before any modifications.
</description>
<files_modified>None — audit only</files_modified>
<success_criteria>
  - All 175 references classified as A/B/C/D
  - Exact line numbers recorded for each reference
  - Any test-file references identified
</success_criteria>
</task>

<task id="08-2" status="pending">
<subject>Create inst/archived/dynamic/ and move six dynamic-only files</subject>
<description>
Create the archive directory and move the six dynamic-only R files into it.

  mkdir -p inst/archived/dynamic/

Files to move (use git mv to preserve history):
  git mv R/diagnosticPlotsNLLS_dyn.R        inst/archived/dynamic/
  git mv R/checkDynamic.R                    inst/archived/dynamic/
  git mv R/aggDynamicMapdata.R               inst/archived/dynamic/
  git mv R/setupDynamicMaps.R                inst/archived/dynamic/
  git mv R/diagnosticPlotsNLLS_timeSeries.R  inst/archived/dynamic/
  git mv R/readForecast.R                    inst/archived/dynamic/

File sizes for reference:
  diagnosticPlotsNLLS_dyn.R         ~935 lines
  readForecast.R                     ~306 lines
  aggDynamicMapdata.R                ~226 lines
  diagnosticPlotsNLLS_timeSeries.R   ~200 lines
  setupDynamicMaps.R                 ~190 lines
  checkDynamic.R                     ~50 lines

After moving, create inst/archived/dynamic/README.md:
  # Archived: Dynamic Model Infrastructure

  These files implemented the "dynamic" (seasonal/annual time-varying) variant of the
  SPARROW model. Dynamic mode performed temporal diagnostic stratification over a single
  unified parameter set — users can replicate this by including temporal columns in their
  data and subsetting results. The infrastructure was removed in Plan 08 (2026-03-xx).

  Files archived:
  - diagnosticPlotsNLLS_dyn.R: Dynamic diagnostic plots (loop over timesteps)
  - readForecast.R: Read forecast/dynamic data
  - aggDynamicMapdata.R: Aggregate map data across time periods
  - diagnosticPlotsNLLS_timeSeries.R: Time series diagnostic plots
  - setupDynamicMaps.R: Dynamic map configuration
  - checkDynamic.R: Check if data has dynamic columns

Note: setupDynamicMaps.R and aggDynamicMapdata.R may also appear on the Plan 09 dead-code
archive list. Moving them here (under Plan 08) takes priority — Plan 09 should skip them.
</description>
<files_modified>
  CREATE: inst/archived/dynamic/
  git mv: R/diagnosticPlotsNLLS_dyn.R -> inst/archived/dynamic/
  git mv: R/checkDynamic.R -> inst/archived/dynamic/
  git mv: R/aggDynamicMapdata.R -> inst/archived/dynamic/
  git mv: R/setupDynamicMaps.R -> inst/archived/dynamic/
  git mv: R/diagnosticPlotsNLLS_timeSeries.R -> inst/archived/dynamic/
  git mv: R/readForecast.R -> inst/archived/dynamic/
  CREATE: inst/archived/dynamic/README.md
</files_modified>
<success_criteria>
  - Six files in inst/archived/dynamic/
  - R/ contains none of the six moved files
  - README.md present in inst/archived/dynamic/
  - R CMD build succeeds (archived files are not in the active package)
</success_criteria>
</task>

<task id="08-3" status="pending">
<subject>Strip if_dynamic branches from estimateNLLSmetrics.R (38 references)</subject>
<description>
estimateNLLSmetrics.R has the highest dynamic reference count. The dynamic code here computes
ANOVAdynamic.list — a list of per-timestep ANOVA tables parallel to the static ANOVAtable.list.

Strategy: Remove all code blocks guarded by if (if_dynamic ...) or equivalent. The static
ANOVA computation remains untouched. The function must still return the same static metrics.

After stripping:
  - ANOVAdynamic.list is no longer computed or returned
  - All if_dynamic parameter references are removed from the function signature (if present)
    or from the function body's internal use of the sparrow_state/file.output.list

Verify: grep -n "dynamic\|if_dynamic\|ANOVAdynamic" R/estimateNLLSmetrics.R
Expected result: 0 matches.

Run tests after this change to confirm estimation metrics still work:
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_file('tests/testthat/test-estimation.R')"
</description>
<files_modified>EDIT: R/estimateNLLSmetrics.R</files_modified>
<success_criteria>
  - 0 dynamic references remain in estimateNLLSmetrics.R
  - Static ANOVA computation unchanged
  - Estimation tests pass
</success_criteria>
</task>

<task id="08-4" status="pending">
<subject>Strip if_dynamic branches from estimateNLLStable.R (24 references)</subject>
<description>
estimateNLLStable.R generates the NLLS summary table. Its 24 dynamic references produce
alternative table sections for dynamic output (per-timestep coefficient tables, etc.).

Remove all dynamic-conditional sections. The function must still produce a valid static
summary table. ANOVAdynamic.list references are removed (it is no longer available after
Task 08-3).

Verify: grep -n "dynamic\|if_dynamic\|ANOVAdynamic" R/estimateNLLStable.R
Expected result: 0 matches.
</description>
<files_modified>EDIT: R/estimateNLLStable.R</files_modified>
<success_criteria>
  - 0 dynamic references remain
  - Static summary table generation unchanged
  - R CMD build succeeds
</success_criteria>
</task>

<task id="08-5" status="pending">
<subject>Strip if_dynamic branches from estimate.R (21 references)</subject>
<description>
estimate.R is the estimation orchestrator. Its 21 dynamic references dispatch to dynamic
diagnostic functions (diagnosticPlotsNLLS_dyn, etc.) that are now archived.

Remove:
  - All calls to diagnosticPlotsNLLS_dyn()
  - All calls to diagnosticPlotsNLLS_timeSeries()
  - All if (if_dynamic) blocks that dispatch to those functions
  - Any dynamic-specific variable setup (e.g., timestep lists)

The static diagnostic dispatch (diagnosticPlotsNLLS()) remains.

Verify: grep -n "dynamic\|if_dynamic\|_dyn\|timeSeries\|timestep" R/estimate.R
Expected result: 0 matches.
</description>
<files_modified>EDIT: R/estimate.R</files_modified>
<success_criteria>
  - 0 dynamic references remain in estimate.R
  - Static diagnostic dispatch (diagnosticPlotsNLLS) still called correctly
  - Estimation tests pass
</success_criteria>
</task>

<task id="08-6" status="pending">
<subject>Strip if_dynamic branches from the remaining 11 files</subject>
<description>
Handle the remaining 11 files, each with 1–8 dynamic references. These are smaller changes.
Process each file, then verify with grep.

Files and approach:

diagnosticPlotsNLLS.R (8 refs):
  Remove dispatch to diagnosticPlotsNLLS_dyn() and diagnosticPlotsNLLS_timeSeries().
  The function should only call static diagnostic plot helpers.

diagnosticSpatialAutoCorr.R (6 refs):
  Remove dynamic-stratified spatial autocorrelation loops.
  Static spatial autocorrelation computation remains.

predictScenariosPrep.R (5 refs):
  Remove dynamic scenario preparation branches.
  Static scenario prep remains.

controlFileTasksModel.R (3 refs):
  Remove dynamic task dispatch blocks.
  Static task dispatch remains.

startModelRun.R (2 refs):
  Remove dynamic data preparation steps (likely calls to readForecast() which is now archived).
  Static data prep remains.

rsparrow_model.R (2 refs):
  Remove model_type parameter or make it a no-op with a deprecation warning.
  If model_type is kept in the signature for compatibility, add:
    if (!is.null(model_type) && model_type != "static")
      warning("model_type='dynamic' is no longer supported; using 'static'")
  Preferred: remove model_type entirely and update man/rsparrow_model.Rd.

diagnosticSensitivity.R (2 refs):
  Remove dynamic sensitivity branches.

checkDrainageareaMapPrep.R (2 refs):
  Remove dynamic map prep branches.
  Note: this file may itself be a dead-code candidate for Plan 09.

hline.R (2 refs):
  Remove dynamic plot helper branches.
  Note: this file may itself be a dead-code candidate for Plan 09.

replaceNAs.R (1 ref):
  Remove single dynamic NA handling branch.
  Note: this file may itself be a dead-code candidate for Plan 09.

hydseq.R (1 ref):
  Remove single dynamic hydseq check (likely an is_dynamic guard around forecast data handling).

After all 11 files are updated, verify globally:
  grep -rn "if_dynamic\|checkDynamic\|readForecast\|diagnosticPlotsNLLS_dyn\|diagnosticPlotsNLLS_timeSeries\|aggDynamicMapdata\|setupDynamicMaps\|ANOVAdynamic" R/
  Expected result: 0 matches.
</description>
<files_modified>
  EDIT: R/diagnosticPlotsNLLS.R
  EDIT: R/diagnosticSpatialAutoCorr.R
  EDIT: R/predictScenariosPrep.R
  EDIT: R/controlFileTasksModel.R
  EDIT: R/startModelRun.R
  EDIT: R/rsparrow_model.R
  EDIT: R/diagnosticSensitivity.R
  EDIT: R/checkDrainageareaMapPrep.R
  EDIT: R/hline.R
  EDIT: R/replaceNAs.R
  EDIT: R/hydseq.R
  EDIT (if applicable): man/rsparrow_model.Rd
</files_modified>
<success_criteria>
  - 0 dynamic references remain in any R/ file
  - grep for all dynamic keywords returns empty across all of R/
  - If model_type is removed from rsparrow_model(), man page updated accordingly
</success_criteria>
</task>

<task id="08-7" status="pending">
<subject>Update tests and run full verification</subject>
<description>
Check whether any tests reference dynamic functionality and update them.

  grep -rn "dynamic\|if_dynamic\|model_type.*dynamic\|readForecast\|checkDynamic" tests/

For each match:
  - If a test specifically tests dynamic behavior, remove it (the feature is gone)
  - If a test uses model_type="static" explicitly and still applies, keep it
  - If a test uses model_type="dynamic" to exercise a code path, remove or replace with
    a warning-expectation test (if model_type parameter is kept as a no-op with warning)

After updating tests, run the full suite:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

Expected: all remaining tests pass. The count may be slightly lower if dynamic-specific tests
are removed, but no test that exercises static functionality should fail.

Also run R CMD check to confirm the WARNING/NOTE baseline is unchanged or improved:
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz

Close GH #13 after the check passes.
</description>
<files_modified>
  EDIT (if needed): tests/testthat/*.R files referencing dynamic functionality
</files_modified>
<success_criteria>
  - All remaining tests pass (0 failures)
  - No new R CMD check ERRORs
  - grep across R/ for dynamic keywords returns 0 matches
  - GH #13 closed
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>Six dynamic-only files moved to inst/archived/dynamic/ with README</criterion>
<criterion>0 occurrences of if_dynamic, checkDynamic, ANOVAdynamic, diagnosticPlotsNLLS_dyn, readForecast in R/</criterion>
<criterion>~1,900 lines removed from R/ (6 files archived + conditionals stripped)</criterion>
<criterion>All remaining tests pass</criterion>
<criterion>R CMD check produces 0 new ERRORs beyond Plan 07 baseline</criterion>
<criterion>GH #13 closed</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any R/ file still contains if_dynamic or similar dynamic keywords</criterion>
<criterion>Static estimation or prediction behavior changed (test regression)</criterion>
<criterion>R CMD build fails — indicates a missed call to an archived function</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  estimateNLLSmetrics.R has 38 dynamic references, the most of any file. Some dynamic
  branches may be deeply interleaved with static computation. Read the file carefully
  before making changes; static code must be preserved exactly.
</risk>
<risk level="low">
  rsparrow_model() currently accepts model_type as a documented parameter. If tests in
  Plan 06F check for model_type in formals(rsparrow_model), those tests will fail if
  model_type is removed. Either keep as a no-op or update the test.
</risk>
<risk level="low">
  checkDrainageareaMapPrep.R, hline.R, and replaceNAs.R are candidates for Plan 09
  dead-code archival. If they become entirely empty after stripping, archive them now
  (under inst/archived/dynamic/ or a separate category) rather than leaving empty stubs.
</risk>
</risks>

<notes>
- "Dynamic" refers strictly to the temporal stratification diagnostic feature, not to any
  Fortran-level functionality. The Fortran subroutines are unaffected.
- aggDynamicMapdata.R and setupDynamicMaps.R appear on both the Plan 08 archive list and
  the Plan 09 dead-code list. They are handled here (Plan 08) to avoid duplication.
- After Plan 08, the package should build and pass all tests without any reference to
  dynamic model functionality. The UserTutorialDynamic/ directory at repo root is
  unaffected — it is not part of the package.
</notes>

</plan>
