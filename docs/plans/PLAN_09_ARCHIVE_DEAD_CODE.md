<plan id="09" label="Archive Unreachable Code" status="pending" blocked_by="07,08">

<objective>
Move the 31 internal functions that are unreachable from any exported function to
inst/archived/ with categorized subdirectories. After this plan the active R/ directory
contains only functions reachable from the 13 exported functions, removing approximately
4,000 lines of dead code that inflates package size and maintenance burden.
</objective>

<context>
Static call-graph analysis from all 13 exported functions (rsparrow_model, read_sparrow_data,
print/summary/coef/residuals/vcov/plot.rsparrow, predict.rsparrow, rsparrow_bootstrap,
rsparrow_scenario, rsparrow_validate, rsparrow_hydseq) identified 31 internal functions with
no reachable path from any export. These functions fall into four categories:

  1. Legacy data import (12 files) — superseded by read_sparrow_data() and startModelRun()
  2. Mapping/visualization (7 files) — removed from core package in Plans 05A/05D; the
     mapping functions that survived those plans are now confirmed unreachable
  3. Deferred utilities (7 files) — complex eval/parse patterns or orphaned utilities
     whose call sites were removed in earlier plans
  4. Plotting utilities (3 files) — helpers not called from any active plotting path

Note: setupDynamicMaps.R and aggDynamicMapdata.R from the original GH #14 list were already
archived in Plan 08 under inst/archived/dynamic/. They are excluded from this plan's scope.

Archive rather than delete: these files may be useful for future features (e.g., a data
preparation helper package, a mapping extension). inst/archived/ preserves them with
git history while removing them from the active package.
</context>

<gh_issues>GH #14</gh_issues>

<reference_documents>
  docs/plans/CRAN_ROADMAP.md — priority 2, GH #14
  docs/reference/FUNCTION_INVENTORY.md — unreachable function classifications
  R/ — current active functions
  inst/archived/dynamic/ — already-archived dynamic files (Plan 08)
</reference_documents>

<tasks>

<task id="09-1" status="pending">
<subject>Verify call graph — confirm 31 functions are unreachable from all exports</subject>
<description>
Before archiving, run a fresh static call-graph analysis to confirm that every candidate
function is still unreachable. Plans 08 may have changed the call graph by removing dynamic
code. Some functions may have become newly unreachable (e.g., helpers only called by dynamic
functions that are now archived).

Verification approach for each candidate function:
  grep -rn "functionName\b" R/
  # If the only hits are in the candidate file itself (its own definition), it is unreachable.
  # If hits appear in other R/ files, investigate whether those callers are themselves
  # reachable (they may be on the dead-code list too).

Additionally check tests/testthat/ — if a test directly calls a dead function by name,
note it. The test should be removed or redirected, but do not let this block archival.

Produce a final confirmed list of files to archive, categorized. If any candidate is
actually reachable, remove it from the list and document why.

This task is read-only.
</description>
<files_modified>None — verification only</files_modified>
<success_criteria>
  - Confirmed unreachable list matches or is a subset of the 31 original candidates
  - Any function found to be reachable is explicitly excluded with justification
</success_criteria>
</task>

<task id="09-2" status="pending">
<subject>Archive Category 1: Legacy data import functions (12 files)</subject>
<description>
These 12 functions were the original data preparation pipeline, superseded by
read_sparrow_data() and startModelRun() in Plan 04D.

Create directory: inst/archived/legacy_data_import/

Files to move (git mv):
  git mv R/addVars.R                        inst/archived/legacy_data_import/
  git mv R/calcDemtareaClass.R              inst/archived/legacy_data_import/
  git mv R/calcHeadflag.R                   inst/archived/legacy_data_import/
  git mv R/calcIncremLandUse.R              inst/archived/legacy_data_import/
  git mv R/checkData1NavigationVars.R       inst/archived/legacy_data_import/
  git mv R/checkDupVarnames.R               inst/archived/legacy_data_import/
  git mv R/checkMissingData1Vars.R          inst/archived/legacy_data_import/
  git mv R/createInitialDataDictionary.R    inst/archived/legacy_data_import/
  git mv R/createVerifyReachAttr.R          inst/archived/legacy_data_import/
  git mv R/dataInputPrep.R                  inst/archived/legacy_data_import/
  git mv R/replaceData1Names.R              inst/archived/legacy_data_import/
  git mv R/startEndmodifySubdata.R          inst/archived/legacy_data_import/

Note: calcHeadflag.R has a known bug (GH #2 — cross-index bug in sorted-array comparison)
and checkData1NavigationVars.R has a boolean condition bug (GH #1). These bugs are noted in
their respective GitHub issues. Archival does not fix or close those issues; they remain open
as documentation of the bugs for anyone who retrieves these files from the archive.

Create inst/archived/legacy_data_import/README.md:
  # Archived: Legacy Data Import Pipeline

  These files implemented the original data preparation pipeline, which was superseded
  by read_sparrow_data() and startModelRun() in Plan 04D (2026). They are preserved
  here for reference. Known bugs: calcHeadflag.R (GH #2), checkData1NavigationVars.R (GH #1).
</description>
<files_modified>
  CREATE: inst/archived/legacy_data_import/
  git mv: 12 files from R/ to inst/archived/legacy_data_import/
  CREATE: inst/archived/legacy_data_import/README.md
</files_modified>
<success_criteria>
  - 12 files moved; R/ no longer contains any of them
  - R CMD build succeeds after move
  - grep -rn "addVars\|calcDemtareaClass\|calcHeadflag\|calcIncremLandUse\|checkData1NavigationVars\|checkDupVarnames\|checkMissingData1Vars\|createInitialDataDictionary\|createVerifyReachAttr\|dataInputPrep\|replaceData1Names\|startEndmodifySubdata" R/ returns 0 real function calls
</success_criteria>
</task>

<task id="09-3" status="pending">
<subject>Archive Category 2: Mapping/visualization functions (7 files)</subject>
<description>
These 7 mapping functions survived Plans 05A/05D but have been confirmed unreachable from
all exported functions. Note: setupDynamicMaps.R was archived in Plan 08 and is excluded here.

Create directory: inst/archived/mapping/

Files to move (git mv):
  git mv R/checkBinaryMaps.R               inst/archived/mapping/
  git mv R/checkDrainageareaErrors.R       inst/archived/mapping/
  git mv R/checkDrainageareaMapPrep.R      inst/archived/mapping/
  git mv R/g_legend.R                      inst/archived/mapping/
  git mv R/mapBreaks.R                     inst/archived/mapping/
  git mv R/mapLoopStr.R                    inst/archived/mapping/
  git mv R/set_unique_breaks.R             inst/archived/mapping/
  git mv R/verifyDemtarea.R               inst/archived/mapping/

Note: checkDrainageareaMapPrep.R had dynamic references removed in Plan 08. Confirm it is
now empty of meaningful content (other than the static map-prep function) before archiving.
If it is now entirely empty after Plan 08 stripping, it is an even stronger archive candidate.

Create inst/archived/mapping/README.md:
  # Archived: Mapping and Visualization Helpers

  These files implemented spatial mapping functionality that was removed from the core
  package in Plans 05A, 05D, and 08. They are preserved for reference and potential
  future use in a separate mapping extension package.
</description>
<files_modified>
  CREATE: inst/archived/mapping/
  git mv: 8 files from R/ to inst/archived/mapping/
  CREATE: inst/archived/mapping/README.md
</files_modified>
<success_criteria>
  - 8 files moved; R/ contains none of them
  - R CMD build succeeds
  - grep across R/ for moved function names returns 0 real calls
</success_criteria>
</task>

<task id="09-4" status="pending">
<subject>Archive Category 3: Deferred utility functions (5 files)</subject>
<description>
These utility functions had complex eval/parse patterns or were orphaned when their call
sites were removed in Plans 04B, 04C, 05A, and 08. Note: aggDynamicMapdata.R was archived
in Plan 08 and is excluded here.

Create directory: inst/archived/utilities/

Files to move (git mv):
  git mv R/unPackList.R               inst/archived/utilities/
  git mv R/naOmitFuncStr.R            inst/archived/utilities/
  git mv R/test_addPlotlyvars.R       inst/archived/utilities/
  git mv R/syncVarNames.R             inst/archived/utilities/
  git mv R/estimateWeightedErrors.R   inst/archived/utilities/
  git mv R/copyStructure.R            inst/archived/utilities/

Note: unPackList.R was the global-state injector removed in Plans 04A/04B. Its archival
closes the last action item on the unPackList removal effort started in Plan 04C.
estimateWeightedErrors.R contains a pdf() without on.exit() (GH #16) — this is a
pre-existing bug that archival implicitly resolves for this file.
test_addPlotlyvars.R is a standalone utility that was apparently never integrated into
the test suite; it is not in tests/testthat/ and is not callable from any export.

Create inst/archived/utilities/README.md:
  # Archived: Deferred Utility Functions

  These utility functions were either orphaned when their call sites were removed
  (unPackList, naOmitFuncStr, copyStructure) or were never integrated into the active
  package (test_addPlotlyvars, syncVarNames). estimateWeightedErrors was a diagnostic
  utility for weight function visualization with a known pdf() resource leak (GH #16).
</description>
<files_modified>
  CREATE: inst/archived/utilities/
  git mv: 6 files from R/ to inst/archived/utilities/
  CREATE: inst/archived/utilities/README.md
</files_modified>
<success_criteria>
  - 6 files moved; R/ contains none of them
  - R CMD build succeeds
  - unPackList is confirmed absent from R/ (final closure of Plan 04C goal)
</success_criteria>
</task>

<task id="09-5" status="pending">
<subject>Archive Category 4: Unused plotting utilities (3 files)</subject>
<description>
Three plotting helper functions are not called from any active plotting path.

Files to move (git mv) — place in inst/archived/mapping/ (they are plot-related):
  git mv R/hline.R          inst/archived/mapping/
  git mv R/makeAESvector.R  inst/archived/mapping/
  git mv R/areColors.R      inst/archived/mapping/

Note: hline.R had dynamic references removed in Plan 08. After stripping, it may contain
only the static hline() function (a horizontal-line plot helper). Confirm it is unreachable
before archiving. areColors.R had a roxygen @examples reference to getSpecialSett cleaned
in Plan 05A — verify it is still present (if not already deleted) and unreachable.

Update inst/archived/mapping/README.md to include these three files.
</description>
<files_modified>
  git mv: R/hline.R, R/makeAESvector.R, R/areColors.R -> inst/archived/mapping/
  EDIT: inst/archived/mapping/README.md (add entries for the three files)
</files_modified>
<success_criteria>
  - 3 files moved; R/ contains none of them
  - R CMD build succeeds
  - grep across R/ for hline, makeAESvector, areColors returns 0 real calls
</success_criteria>
</task>

<task id="09-6" status="pending">
<subject>Create master inst/archived/README.md and run full verification</subject>
<description>
Create a top-level README for the archived collection:

  inst/archived/README.md:
  # Archived Functions

  This directory preserves functions removed from the active rsparrow package.
  Files are organized by reason for removal:

  - dynamic/           — Dynamic model infrastructure (Plan 08)
  - legacy_data_import/ — Legacy data prep pipeline superseded by read_sparrow_data()
  - mapping/           — Spatial mapping helpers removed from core package
  - utilities/         — Orphaned or never-integrated utility functions

  These files are NOT part of the installed package's active namespace. They are
  included in inst/ to preserve them for reference and potential future use.

Then run full verification:

  # Confirm no dead function is called from R/
  for f in addVars calcDemtareaClass calcHeadflag calcIncremLandUse \
            checkData1NavigationVars checkDupVarnames checkMissingData1Vars \
            createInitialDataDictionary createVerifyReachAttr dataInputPrep \
            replaceData1Names startEndmodifySubdata checkBinaryMaps \
            checkDrainageareaErrors checkDrainageareaMapPrep g_legend \
            mapBreaks mapLoopStr set_unique_breaks verifyDemtarea unPackList \
            naOmitFuncStr test_addPlotlyvars syncVarNames estimateWeightedErrors \
            copyStructure hline makeAESvector areColors; do
    count=$(grep -rn "\b${f}\b" R/ 2>/dev/null | grep -v "^R/.*#" | wc -l)
    [ $count -gt 0 ] && echo "WARNING: $f still referenced in R/: $count hits"
  done

  # Build and check
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz

  # Run tests
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

Expected:
  - 0 real calls to archived functions in R/
  - 0 ERRORs, no new WARNINGs beyond Plan 08 baseline
  - All tests pass

Close GH #14 after the check passes.
</description>
<files_modified>
  CREATE: inst/archived/README.md
</files_modified>
<success_criteria>
  - inst/archived/README.md present and accurate
  - 0 real calls to any archived function in R/
  - R CMD check: 0 new ERRORs
  - All tests pass
  - GH #14 closed
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>~31 files moved to inst/archived/ (minus those handled in Plan 08)</criterion>
<criterion>~4,000 lines removed from active R/</criterion>
<criterion>0 real calls to archived functions remain in R/</criterion>
<criterion>inst/archived/ has README files at the top level and in each subdirectory</criterion>
<criterion>R CMD check: 0 new ERRORs beyond Plan 08 baseline</criterion>
<criterion>All tests pass</criterion>
<criterion>GH #14 closed</criterion>
</success_criteria>

<failure_criteria>
<criterion>R CMD build fails — indicates a missed call to an archived function; grep for the function name</criterion>
<criterion>Any test fails that previously passed — indicates a dependency on archived behavior</criterion>
<criterion>A function archived here was actually reachable (caught by grep verification in Task 09-6)</criterion>
</failure_criteria>

<risks>
<risk level="low">
  A function may be referenced in R/ via eval(parse()) or via a string variable (dynamic
  dispatch). The grep-based verification will miss these. Check the 49 remaining
  eval(parse()) instances to confirm none of them dispatch to functions being archived.
</risk>
<risk level="low">
  applyUserModify.R builds function calls via string concatenation. Verify it does not
  dynamically call any function in the archive list (particularly unPackList, syncVarNames).
  After Plan 04C, applyUserModify.R's unPackList reference should be a string literal
  (not a real call) — confirm this before archiving unPackList.R.
</risk>
<risk level="low">
  Tests in tests/testthat/ may call some archived functions directly (especially
  calcHeadflag, which has an open bug report in GH #2). If a test calls an archived
  function, either delete that test or skip it with a comment explaining the function
  was archived and the test should be rewritten if the function is revived.
</risk>
</risks>

<notes>
- The 31-function count from the CRAN roadmap is the starting estimate. Plan 08 archived
  setupDynamicMaps.R and aggDynamicMapdata.R, so those are excluded from this plan's count.
  The actual count here may be 29 (31 minus 2 already archived). Verify in Task 09-1.
- Archive structure mirrors the categorization in GH #14 with the addition of the dynamic/
  subdirectory created in Plan 08.
- Plans 10 and 11 will fix remaining issues in the active R/ files. After Plan 09,
  the active package should contain only reachable functions with clean interfaces.
</notes>

</plan>
