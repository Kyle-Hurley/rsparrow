<plan id="16" label="Function Audit — Simplification, eval/parse, and Monolith Review" status="pending" blocked_by="15">

<objective>
Perform a complete audit of all R/ files post-Plans 13–15. Classify each function as
KEEP / SIMPLIFY / MERGE / REMOVE. Address residual complexity: remove newly obsolete
functions, document or eliminate remaining eval(parse()) calls, flag monolithic functions,
and bring all reference documentation up to date. This plan closes remaining technical
debt items from Plans 10–15 and prepares the package for long-term maintainability.
</objective>

<context>
After Plans 13–15:
  - CSV readers and applyUserModify are archived (Plan 13)
  - plyr/dplyr/data.table are removed (Plan 14)
  - plotly/ggplot2/gridExtra/gplots are removed (Plan 15)
  - plotlyLayout.R is deleted (Plan 15)

Residual issues from earlier plans (per MEMORY.md TECHNICAL_DEBT section):
  - eval(parse()): ~25 total remaining in internal functions
    COMPLEX/deferred: plotlyLayout.R (8, now deleted), diagnosticSpatialAutoCorr.R (5),
    predictScenariosPrep.R (4), applyUserModify.R (2, now archived), replaceNAs.R (1),
    createSubdataSorted.R (1)
    Hardened hover-text: diagnosticPlotsNLLS.R (3), predict_core.R (1)
  - Monolithic functions: estimate.R (~890 lines), estimateNLLSmetrics.R (~835 lines),
    estimateNLLStable.R (~763 lines)
  - diagnosticPlotsValidate.R: 57-line wrapper — evaluate MERGE into diagnosticPlotsNLLS.R
  - startEndmodifySubdata.R: possibly dead post-Plan 13 (if_userModifyData removed)
  - createMasterDataDictionary.R: possibly dead if not called in new in-memory API

Post-Plan 15, the actual eval(parse()) count changes:
  - plotlyLayout.R (8): DELETED (Plan 15) — reduce by 8
  - applyUserModify.R (2): ARCHIVED (Plan 13) — reduce by 2
  - Remaining: ~15 eval(parse()) in active R/ files

This plan does a targeted pass: remove clearly obsolete functions, evaluate merges,
document the unavoidable eval(parse()) calls with GitHub issues, and leave the three
monolithic functions flagged for a future decomposition plan.
</context>

<gh_issues>
New issues to open during this plan (one per refactorable eval/parse instance group):
  "Plan 16: refactor eval(parse()) in diagnosticSpatialAutoCorr.R (5 instances)"
  "Plan 16: refactor eval(parse()) in predictScenariosPrep.R (4 instances)"
  "Plan 16: refactor eval(parse()) in replaceNAs.R + createSubdataSorted.R (2 instances)"
  "Plan 16: decompose estimate.R monolith (~890 lines)"
  "Plan 16: decompose estimateNLLSmetrics.R + estimateNLLStable.R monoliths"
</gh_issues>

<reference_documents>
  R/ directory — all ~75 active R files post-Plan 15
  docs/reference/FUNCTION_INVENTORY.md — to be fully updated
  docs/reference/TECHNICAL_DEBT.md — to be updated (mark resolved items; add new items)
  docs/reference/ARCHITECTURE.md — update data-flow to reflect Plans 13–15 changes
  docs/plans/CRAN_ROADMAP.md — add Plan 16 entry; update counts
  memory/MEMORY.md — update eval(parse()) count, archived files list
</reference_documents>

<tasks>

<task id="16-1" status="pending">
<subject>Full function inventory pass — classify each R/ file</subject>
<description>
Read all files in R/ (use Glob to list, then Read each). For each file, assign one of:
  KEEP       — correct, well-scoped, no issues
  SIMPLIFY   — correct but can be shortened without API change
  MERGE      — should be merged with another file (identify target)
  REMOVE     — dead code or made obsolete by Plans 13–15

Specific targets flagged in advance:

startEndmodifySubdata.R:
  Was called via if_userModifyData pathway (removed in Plan 13, task 13-2). Verify with:
    grep -rn "startEndmodifySubdata" R/
  If 0 callers remain: REMOVE → archive to inst/archived/utilities/

createMasterDataDictionary.R:
  Was called by the old CSV-based workflow. Verify with:
    grep -rn "createMasterDataDictionary" R/
  If 0 callers in active R/ (only inst/archived/ references): REMOVE → archive

diagnosticPlotsValidate.R:
  57-line wrapper around diagnosticPlotsNLLS.R. Evaluate:
  - If it adds no logic beyond a different data path (validation sites vs calibration sites),
    MERGE: inline its logic into diagnosticPlotsNLLS.R with an `if_validate` parameter.
  - If the validation vs calibration distinction requires separate flow: KEEP as SIMPLIFY.

hline.R:
  Per Plan 09, hline() was found reachable via diagnosticPlotsNLLS.R and
  diagnosticPlots_4panel_A.R. After Plan 15's plotly removal, verify:
    grep -rn "hline(" R/
  If hline() was a plotly helper (plotly horizontal line shape): REMOVE → archive.
  If hline() is a base R helper that survived the rewrite: KEEP.

checkBinaryMaps.R:
  Per Plan 09, was found reachable. Per CRAN_ROADMAP.md Plan 11 notes, it had an
  assign(parent.frame()) that was deferred. Verify the assign is gone (Plan 11 fixed GH #18).
  Verify it is still reachable post-Plans 13–15.
    grep -rn "checkBinaryMaps" R/
  If still reachable: KEEP (or SIMPLIFY if assign is still present).
  If unreachable: REMOVE → archive.

Document the classification of every file in a structured table appended to this plan's
notes section, then proceed with REMOVE actions in task 16-2.
</description>
<files_modified>None — audit only</files_modified>
<success_criteria>
  - Every R/ file has an assigned classification
  - REMOVE candidates verified to have 0 active callers
  - MERGE candidates have a clear target function identified
</success_criteria>
</task>

<task id="16-2" status="pending">
<subject>Archive or delete REMOVE-classified functions</subject>
<description>
For each function classified REMOVE in task 16-1:
  - Verify 0 callers in active R/ with grep
  - Move to appropriate inst/archived/ subdirectory
  - Add archival comment to top of file: # Archived Plan 16: [reason]

Expected candidates (to be confirmed by task 16-1):
  startEndmodifySubdata.R → inst/archived/utilities/ (if_userModifyData pathway removed)
  createMasterDataDictionary.R → inst/archived/utilities/ (if dead post-Plan 13)
  hline.R → inst/archived/utilities/ (if plotly-only helper, now obsolete)

For each archival:
  - Update man/ if an Rd file exists (delete the Rd)
  - Verify R CMD check passes after removal

After all removals:
  grep -rn "startEndmodifySubdata\|createMasterDataDictionary\|hline" R/
Expected: 0 results (or only comments in archived files).
</description>
<files_modified>
  MOVE: R/[candidates] → inst/archived/[subdirectory]/
  DELETE: man/[corresponding Rd files] (if any)
</files_modified>
<success_criteria>
  - Each removed function has 0 callers in active R/
  - R CMD check: 0 new ERRORs or WARNINGs after removal
  - inst/archived/ directories updated
</success_criteria>
</task>

<task id="16-3" status="pending">
<subject>Evaluate and execute MERGE-classified functions</subject>
<description>
For each function classified MERGE in task 16-1:

diagnosticPlotsValidate.R (likely MERGE):
  If merging: add an `if_validate` parameter to diagnosticPlotsNLLS.R that selects
  validation sites (vsitedata) instead of calibration sites (sitedata). The calling code
  in controlFileTasksModel.R or plot.rsparrow.R would pass if_validate = TRUE.
  After merging: archive diagnosticPlotsValidate.R to inst/archived/utilities/.

Only merge if the result is clearly simpler. If the merge introduces conditional complexity
that makes diagnosticPlotsNLLS.R harder to read, KEEP diagnosticPlotsValidate.R as-is.

Document the merge decision in a code comment at the top of diagnosticPlotsNLLS.R.
</description>
<files_modified>
  EDIT: R/diagnosticPlotsNLLS.R (if merge executed)
  MOVE: R/diagnosticPlotsValidate.R → inst/archived/utilities/ (if merged)
  EDIT: Any callers updated to use new parameter
</files_modified>
<success_criteria>
  - merge decision documented and executed (or explicitly deferred with reason)
  - R CMD check: 0 new ERRORs or WARNINGs
  - plot.rsparrow() type="residuals" still works for both calibration and validation
</success_criteria>
</task>

<task id="16-4" status="pending">
<subject>Audit and document remaining eval(parse()) calls</subject>
<description>
Run:
  grep -rn "eval(parse" R/

Enumerate every instance. For each, determine:
  NECESSARY  — no base R alternative; document why (e.g., dynamic column name from user input)
  REFACTOREABLE — can be replaced with [[ ]] indexing, match.arg(), or switch()
  DEFERRED   — complex but not blocking CRAN; open a GitHub issue

Expected breakdown post-Plans 13–15 (~15 remaining):

diagnosticSpatialAutoCorr.R (~5 instances):
  These likely build variable-name strings to index into subdata dynamically.
  Classification: REFACTOREABLE (use [[]] instead of eval(parse(text=paste("subdata$", varname))))
  Action: Open GH issue "refactor eval(parse) in diagnosticSpatialAutoCorr.R"
  If straightforward: fix in-place. If complex: defer to next plan.

predictScenariosPrep.R (~4 instances):
  These assemble scenario variable names dynamically.
  Classification: likely DEFERRED (complex scenario logic)
  Action: Open GH issue "refactor eval(parse) in predictScenariosPrep.R"

replaceNAs.R (~1 instance):
  Classification: REFACTOREABLE (use [[]])
  Action: fix in-place.

createSubdataSorted.R (~1 instance):
  Classification: REFACTOREABLE or DEFERRED
  Action: fix in-place or open GH issue.

diagnosticPlotsNLLS.R (~3 "hardened hover-text" instances):
  These assembled plotly hover-text strings. After Plan 15 removes plotly, these instances
  should be GONE. Verify they were removed during task 15-3.
  If any survive: remove them (they reference plotly variables that no longer exist).

predict_core.R (~1 "hardened hover-text" instance):
  Same as above — verify removed by Plan 15 or remove here.

For every DEFERRED instance: open a GitHub issue with title, file, line number, and
description of what the eval(parse()) does and why it is hard to remove.

Target: bring eval(parse()) count from ~15 to ≤ 8 after this plan.
</description>
<files_modified>
  EDIT: R/replaceNAs.R (if REFACTOREABLE instance fixed)
  EDIT: R/createSubdataSorted.R (if REFACTOREABLE instance fixed)
  EDIT: R/diagnosticSpatialAutoCorr.R (if REFACTOREABLE instances fixed)
  EDIT: R/diagnosticPlotsNLLS.R (remove any surviving plotly hover-text eval/parse)
  EDIT: R/predict_core.R (remove any surviving plotly hover-text eval/parse)
</files_modified>
<success_criteria>
  - Every eval(parse()) in R/ is either fixed or has a GH issue
  - Total eval(parse()) count documented in updated MEMORY.md
  - No new eval(parse()) introduced by this plan
  - R CMD check: 0 new ERRORs or WARNINGs
</success_criteria>
</task>

<task id="16-5" status="pending">
<subject>Flag monolithic functions and open decomposition issues</subject>
<description>
Read and assess the three monolithic functions:

estimate.R (~890 lines):
  Natural seams to document:
  1. Data validation (lines 1–~100)
  2. Weight computation setup (calls setNLLSWeights, setDataMatrix)
  3. NLLS optimization (calls estimateOptimize)
  4. Metric computation (calls estimateNLLSmetrics)
  5. Table formatting (calls estimateNLLStable)
  6. Diagnostic plot invocation (calls diagnosticPlotsNLLS)
  Note: seams 3–6 are already separate function calls; estimate.R is mostly orchestration.
  If >50% of lines are just passing arguments between sub-functions, the monolith label
  may be overstated. Document actual complexity level.

estimateNLLSmetrics.R (~835 lines):
  Computes ~20 metrics in sequence. Natural seams:
  1. Bootstrap residuals
  2. Leverage and influence
  3. ANOVA table (RSQ, RMSE, DF, SSE)
  4. PPCC / Shapiro-Wilk test
  5. VIF calculation
  Document seams. Evaluate whether extraction into 3–4 helper functions would reduce
  complexity without adding indirection.

estimateNLLStable.R (~763 lines):
  Formats the parameter table and writes it. After Plan 10 removed sink(), this file
  returns a data structure. Natural seams:
  1. Parameter coefficient table
  2. Confidence intervals
  3. t-statistics and p-values
  4. VIF table

For each monolith:
  - Document the natural seams in a code comment at the top of the file
  - If any seam is a trivial extraction (< 20 lines, clean interface): extract it now
  - For larger extractions: open a GitHub issue "decompose [filename]" with the seam plan
  - Do NOT attempt a full decomposition in this plan — that is a Plan 17+ scope item

Target: each monolith has documented seams and at least one GH issue.
</description>
<files_modified>
  EDIT: R/estimate.R (add seam-documentation comment block at top)
  EDIT: R/estimateNLLSmetrics.R (add seam-documentation comment block at top)
  EDIT: R/estimateNLLStable.R (add seam-documentation comment block at top)
</files_modified>
<success_criteria>
  - Each monolith has a seam-documentation comment block
  - GH issues opened for each major decomposition
  - No functional change to any monolith (comment-only edits unless trivial extraction done)
  - R CMD check: 0 new ERRORs or WARNINGs
</success_criteria>
</task>

<task id="16-6" status="pending">
<subject>Update FUNCTION_INVENTORY.md — full reclassification post-Plans 13–15</subject>
<description>
Rewrite docs/reference/FUNCTION_INVENTORY.md to reflect the current state of R/ after
Plans 13–16. The inventory should group functions by module and include:
  - Function name
  - File
  - Classification (KEEP / SIMPLIFIED / MERGED / ARCHIVED)
  - Brief description of what it does
  - Caller(s) / callee(s) (one level deep)

Update counts:
  - Total active R files (was ~79 post-Plan 09; subtract archived files from Plans 13–16)
  - Exported functions (13 after Plan 13 removes read_sparrow_data)
  - Archived functions total (30 from Plan 09 + Plan 13 additions + Plan 16 additions)

Remove all "plotly", "plyr", "dplyr", "data.table" tags from function descriptions.
Add "base R graphics" tags to the four diagnostic plot functions.

Mark applyUserModify, readData, readParameters, readDesignMatrix, read_dataDictionary,
read_sparrow_data as ARCHIVED (Plan 13).
Mark plotlyLayout as DELETED (Plan 15).
</description>
<files_modified>
  EDIT: docs/reference/FUNCTION_INVENTORY.md
</files_modified>
<success_criteria>
  - FUNCTION_INVENTORY.md accurately reflects current R/ contents
  - All archived functions correctly labelled
  - No references to removed dependencies (plotly, plyr, dplyr, data.table)
  - Function count matches actual file count in R/
</success_criteria>
</task>

<task id="16-7" status="pending">
<subject>Update TECHNICAL_DEBT.md — mark resolved items and add new items</subject>
<description>
Update docs/reference/TECHNICAL_DEBT.md:

MARK RESOLVED (Plans 13–15):
  - CSV API (file.output.list CSV readers) → Plan 13: in-memory API, CSV readers archived
  - plyr::ddply unguarded calls → Plan 14: replaced with base R aggregate()
  - dplyr::sample_n unguarded calls → Plan 14: replaced with base R sample()
  - data.table::fwrite in Imports → Plan 14: replaced with utils::write.csv
  - plotly required for any plot → Plan 15: replaced with base R graphics
  - ggplot2/gridExtra/gplots in Suggests → Plan 15: removed
  - plotlyLayout.R eval(parse()) ×8 → Plan 15: deleted with the file
  - applyUserModify.R eval(parse()) ×2 → Plan 13: archived with the file
  - hover-text eval(parse()) in diagnosticPlotsNLLS.R and predict_core.R → Plan 15/16

ADD NEW (from Plan 16 audit):
  - eval(parse()) instances deferred to next plan (with GH issue numbers)
  - Monolith decomposition deferred (with GH issue numbers)
  - Any new issues discovered during the audit

REMAINING TECHNICAL DEBT (post-Plan 16):
  - eval(parse()): document actual count and location of each remaining instance
  - Monolithic functions: estimate.R, estimateNLLSmetrics.R, estimateNLLStable.R
  - "yes"/"no" string flags (not converted to logical in Plan 13 boundary conversion)
  - .Platform$file.sep path construction (should be file.path())
  - Missing ORCID iDs for authors in DESCRIPTION
  - Cross-platform testing (macOS, Windows untested)
</description>
<files_modified>
  EDIT: docs/reference/TECHNICAL_DEBT.md
</files_modified>
<success_criteria>
  - All Plans 13–16 resolved items marked as such with plan number
  - Remaining items accurately describe current state
  - GH issue numbers linked where applicable
</success_criteria>
</task>

<task id="16-8" status="pending">
<subject>Update ARCHITECTURE.md data flow for Plans 13–15</subject>
<description>
Update docs/reference/ARCHITECTURE.md to reflect the new in-memory API and dependency state:

API flow (replace old CSV-based description):
  rsparrow_model(reaches, parameters, design_matrix, data_dictionary, output_dir=NULL)
    -> prep_sparrow_inputs()           # validates + reshapes four data frames
    -> startModelRun()                 # data prep; no if_userModifyData
    -> controlFileTasksModel()         # task dispatch
    -> [estimate / predict / validate] # computation
    -> rsparrow S3 object              # returned in-memory; file output only if output_dir set

Remove from the architecture description:
  - read_sparrow_data() (archived)
  - readData/readParameters/readDesignMatrix/read_dataDictionary (archived)
  - applyUserModify (archived)
  - CSV reader / CSV writer dependency on data.table
  - plotly diagnostic pipeline

Add to the architecture description:
  - prep_sparrow_inputs() as the validation/reshaping boundary
  - Base R graphics pipeline (graphics package; no external dependencies)
  - write_rsparrow_results() as the sole opt-in file output function

Update the dependency graph:
  - Imports: nlmrt, numDeriv (2)
  - Suggests: car, knitr, leaflet, magrittr, mapview, rmarkdown, sf, spdep, testthat (9)
</description>
<files_modified>
  EDIT: docs/reference/ARCHITECTURE.md
</files_modified>
<success_criteria>
  - ARCHITECTURE.md reflects the Plan 13 API signature accurately
  - No mention of archived functions or removed dependencies
  - Dependency counts accurate
</success_criteria>
</task>

<task id="16-9" status="pending">
<subject>Update CRAN_ROADMAP.md and run final R CMD check</subject>
<description>
Update docs/plans/CRAN_ROADMAP.md:
  - Move Plans 10–12 entries from <upcoming_plans> to <completed_plans> (verify already done)
  - Add Plans 13, 14, 15 to <completed_plans> section
  - Add Plan 16 to <completed_plans> section
  - Update <executive_summary>: reflect Plans 13–16 completion
  - Update DESCRIPTION dependency counts throughout
  - Update exported function count: 14 → 13 (read_sparrow_data removed in Plan 13)

Update CRAN checklist in CRAN_ROADMAP.md:
  - Add new checklist items for Plans 13–16:
    [pass] No CSV file setup required: rsparrow_model() accepts data frames directly
    [pass] No plyr/dplyr/data.table in DESCRIPTION (not even Suggests)
    [pass] No plotly/ggplot2/gridExtra/gplots in DESCRIPTION
    [pass] plot(model) works with zero Suggests installed (base R graphics)
    [pass] eval(parse()) count reduced to ≤ 8 (documented in TECHNICAL_DEBT.md)

Run final verification:
  source scripts/renv.sh
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-manual rsparrow_2.1.0.tar.gz

Target: 0 ERRORs, 0 WARNINGs, ≤ 2 NOTEs (same as Plan 12 baseline).

Run full test suite:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

Update MEMORY.md:
  - Mark Plans 13–16 complete
  - Update all counts (R files, archived files, eval/parse count, Imports, Suggests)
  - Update API description to new signature
</description>
<files_modified>
  EDIT: docs/plans/CRAN_ROADMAP.md
  EDIT: memory/MEMORY.md
</files_modified>
<success_criteria>
  - CRAN_ROADMAP.md <executive_summary> reflects Plans 13–16 completion
  - R CMD check: 0 ERRORs, 0 WARNINGs, ≤ 2 NOTEs
  - All tests pass
  - MEMORY.md fully updated
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>Every R/ file classified; all REMOVE candidates confirmed dead and archived</criterion>
<criterion>eval(parse()) count in R/ ≤ 8 (from ~15 after Plans 13–15); all remaining instances have GH issues</criterion>
<criterion>Monolithic functions (estimate.R, estimateNLLSmetrics.R, estimateNLLStable.R) have seam-documentation comments and GH decomposition issues</criterion>
<criterion>FUNCTION_INVENTORY.md, TECHNICAL_DEBT.md, ARCHITECTURE.md all updated</criterion>
<criterion>CRAN_ROADMAP.md reflects Plans 13–16 completion</criterion>
<criterion>R CMD check: 0 ERRORs, 0 WARNINGs, ≤ 2 NOTEs</criterion>
<criterion>All tests pass</criterion>
</success_criteria>

<failure_criteria>
<criterion>Archiving a function that is still called (0-caller verification skipped)</criterion>
<criterion>eval(parse()) count increases vs Plan 15 baseline</criterion>
<criterion>Any functional change to a monolith without test coverage</criterion>
<criterion>R CMD check introduces a new WARNING vs Plan 15 baseline</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  hline.R and checkBinaryMaps.R were found reachable in Plan 09 but may become unreachable
  after Plans 13–15 (if the callers were in the now-archived/deleted plotting code).
  Verify reachability carefully with grep before archiving. Do not assume the Plan 09
  reachability verdict still holds after three subsequent plans.
</risk>
<risk level="medium">
  The eval(parse()) calls in diagnosticSpatialAutoCorr.R may be entangled with the Moran's I
  computation logic, not just the plotting. If so, they cannot be removed in isolation from
  Plan 15's base R rewrite. Read the file carefully in task 16-4 before deciding
  REFACTOREABLE vs DEFERRED.
</risk>
<risk level="low">
  Opening multiple GitHub issues in task 16-4 and 16-5 creates permanent record of known
  technical debt. This is intentional. Ensure issue titles and bodies are precise enough
  that a future contributor can act on them without rereading this plan document.
</risk>
</risks>

<notes>
- Execution order: 16-1 (audit) must complete before 16-2 (archive) and 16-3 (merge).
  16-4 (eval/parse), 16-5 (monoliths), and 16-6/16-7/16-8 (docs) can run in parallel
  after 16-1.
- This plan does NOT change any public API. It is internal cleanup only.
- After Plan 16, the package is as clean as it can be without decomposing the three
  monolithic functions. Future plans (17+) can target those decompositions.
- The "yes"/"no" string flags scattered throughout internal functions are known technical
  debt but are not addressed here — converting them to logical would touch ~50 call sites
  across ~20 files and is a Plan 17+ item. The boundary conversion in prep_sparrow_inputs()
  (Plan 13) isolates this from the public API.
- CRAN submission can proceed after Plan 16. The remaining technical debt items
  (monolith decomposition, eval/parse reduction, yes/no strings, cross-platform testing)
  are improvements, not blockers.
</notes>

</plan>
