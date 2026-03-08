<plan id="10" label="Separate Computation from I/O" status="pending" blocked_by="07,08,09">

<objective>
Refactor estimation and prediction functions to return R objects instead of writing files as
side effects. All file I/O — save(), fwrite(), dir.create(), sink(), pdf() — is removed from
computation functions. An optional write_rsparrow_results() convenience function is created
for users who want file output. This plan also resolves the <<- anti-pattern in rsparrow_model.R
and the assign(parent.frame()) in diagnosticPlots_4panel_B.R and upstream.R.
</objective>

<context>
CRAN policy: packages must not write to the user's home filespace or anywhere outside the R
session's temporary directory, except when the user has explicitly requested file output.

Currently, estimation and prediction functions perform file I/O as side effects of computation:
  - ~35 dir.create() calls scattered across computation functions
  - ~22 save() calls writing .RData files mid-computation
  - ~22 fwrite() calls writing CSV reports
  - 5 sink() calls writing text reports
  - 1 pdf() call writing a plot file

The architectural goal is simple: core functions return R objects; file I/O is opt-in.

This plan also fixes two assign(parent.frame()) anti-patterns that survive Plan 09 archival:
  - rsparrow_model.R:380 — <<- to extract predict.list from load() inside local()
  - diagnosticPlots_4panel_B.R:134 — assign to parent.frame for Resids2
  - upstream.R:52 — assign to parent.frame for ifproc

applyUserModify.R (3x assign parent.frame) is complex and deferred to Plan 11.
</context>

<gh_issues>GH #15, GH #18 (partial: rsparrow_model.R <<-, diagnosticPlots_4panel_B.R, upstream.R)</gh_issues>

<reference_documents>
  docs/plans/CRAN_ROADMAP.md — priority 1 blockers B4, B5
  R/estimate.R — 7 save(), 10 dir.create(); estimation orchestrator (~890 lines)
  R/startModelRun.R — 5 save(); data preparation
  R/estimateNLLStable.R — sink() + ~20 fwrite(); summary table (~763 lines)
  R/estimateOptimize.R — sink() for optimization log; keep but add on.exit()
  R/correlationMatrix.R — pdf() + sink() for correlation report
  R/controlFileTasksModel.R — 4 save() + sink() for spatial autocorr diagnostics
  R/predictScenarios.R — 2 save() + dir.create()
  R/predictScenariosOutCSV.R — metadata sink(); explicit I/O function
  R/predictBootstraps.R — save() for bootstrap results
  R/rsparrow_model.R — <<- anti-pattern at line 380 (predict.list extraction)
  R/diagnosticPlots_4panel_B.R — assign(parent.frame()) at line 134
  R/upstream.R — assign(parent.frame()) at line 52
</reference_documents>

<tasks>

<task id="10-1" status="pending">
<subject>Audit all file I/O in computation functions</subject>
<description>
Before refactoring, produce a complete inventory of file I/O in active computation functions.

Search commands:
  grep -rn "dir\.create\|save(\|fwrite(\|sink(\|pdf(" R/ | grep -v "^R/rsparrow-package"

For each hit, classify:
  REMOVE — side effect of computation; return the data instead
  KEEP   — legitimate I/O that the user explicitly invoked (e.g., write_rsparrow_results)
  PROTECT — legitimate I/O (e.g., estimateOptimize.R optimization log) but needs on.exit()

Record:
  - File and line number
  - What is written (variable name, file path pattern)
  - What the written data is used for downstream
  - Classification (REMOVE/KEEP/PROTECT)

Also audit:
  grep -rn "<<-\|assign.*parent\.frame\|assign.*envir.*parent" R/

This read-only audit produces the work list for Tasks 10-2 through 10-8.
</description>
<files_modified>None — audit only</files_modified>
<success_criteria>
  - Complete classified inventory of all file I/O in R/ computation functions
  - <<- and assign(parent.frame) instances located and classified
</success_criteria>
</task>

<task id="10-2" status="pending">
<subject>Refactor estimate.R — remove save() and dir.create() side effects</subject>
<description>
estimate.R is the estimation orchestrator (~890 lines). It currently writes intermediate
results to disk via save() and creates output directories with dir.create() as side effects
of running the NLLS estimation.

Refactoring approach:
  1. Remove all dir.create() calls. Directories should be created only if the user
     explicitly requests file output (via write_rsparrow_results(), Task 10-9).
  2. Remove all save() calls. Instead, accumulate results in the estimate.list return value.
     Any data currently saved to .RData files must instead be returned as named list elements.
  3. The function signature and return type must not change from the caller's perspective —
     estimate.R must still return the complete estimate.list that startModelRun.R expects.

For each save() call, identify:
  - What data is saved (variable name)
  - Where it is loaded back (if anywhere in the computation chain)
  - If it is loaded back in the same run, replace save/load with in-memory passing

The pattern in rsparrow_model.R:380 (<<-) is caused by controlFileTasksModel() saving
predict.list to disk and rsparrow_model() loading it back. This cross-function save/load
cycle must be eliminated here or in Task 10-5 (controlFileTasksModel.R).

After refactoring:
  grep -n "dir\.create\|save(" R/estimate.R
  Expected: 0 matches
</description>
<files_modified>EDIT: R/estimate.R</files_modified>
<success_criteria>
  - 0 dir.create() calls in estimate.R
  - 0 save() calls in estimate.R
  - estimate.list return value contains all data previously saved to disk
  - Estimation tests pass (test-estimation.R, test-fortran.R)
</success_criteria>
</task>

<task id="10-3" status="pending">
<subject>Refactor startModelRun.R — remove save() side effects</subject>
<description>
startModelRun.R currently calls save() ~5 times to write intermediate state objects to disk.
These saves are side effects of the data preparation step.

Refactoring approach:
  - Remove all save() calls
  - Any data previously saved must be included in the sparrow_state return value
  - If the saved data is consumed by a subsequent function in the same run, pass it
    as a function argument rather than loading from disk

startModelRun.R is called internally by rsparrow_model() and returns sparrow_state (a named
list with 27 elements as documented in CLAUDE.md). Adding additional elements to this list
is the correct way to pass data forward without file I/O.

After refactoring:
  grep -n "save(" R/startModelRun.R
  Expected: 0 matches
</description>
<files_modified>EDIT: R/startModelRun.R</files_modified>
<success_criteria>
  - 0 save() calls in startModelRun.R
  - sparrow_state return value contains all previously-saved data
  - API tests pass (test-rsparrow-wrappers.R, test-s3-methods.R)
</success_criteria>
</task>

<task id="10-4" status="pending">
<subject>Refactor estimateNLLStable.R — remove sink() and fwrite() side effects</subject>
<description>
estimateNLLStable.R generates the NLLS summary table and currently writes it to disk via
sink() (for a text report) and ~20 fwrite() calls (for CSV outputs). This is the largest
I/O problem in the package — a computation function that writes ~20 CSV files as side effects.

Refactoring approach:
  1. Remove the sink() call. The text report content should be returned as a character
     vector or data.frame element of the return value.
  2. Remove all fwrite() calls. Each fwrite() writes a named table that should instead
     be a named element of the return list:
       e.g., fwrite(parmtable, ...) becomes return_list$parmtable <- parmtable
  3. The function should return a structured list containing all the tables it previously
     wrote to disk. The caller (estimate.R) accumulates these into estimate.list.

options(width=500, max.print=50000) on line 189 is also removed here (it was only needed
for sink output). If the option is needed for any remaining purpose, wrap it with on.exit().

After refactoring:
  grep -n "sink(\|fwrite(\|options(" R/estimateNLLStable.R
  Expected: 0 matches (or only on.exit-protected options())

Note: This is a large refactor. estimateNLLStable.R is ~763 lines. Take care not to change
the data content of any table — only the delivery mechanism changes from file to return value.
</description>
<files_modified>EDIT: R/estimateNLLStable.R</files_modified>
<success_criteria>
  - 0 sink() calls in estimateNLLStable.R
  - 0 fwrite() calls in estimateNLLStable.R
  - options() only used with on.exit() protection (or not at all)
  - Return value is a named list containing all tables previously written to disk
  - Estimation tests pass
</success_criteria>
</task>

<task id="10-5" status="pending">
<subject>Refactor controlFileTasksModel.R — remove save() and sink() side effects</subject>
<description>
controlFileTasksModel.R is the master task dispatcher. It currently:
  - Calls save() ~4 times to write intermediate results to disk
  - Calls sink() for spatial autocorrelation diagnostics
  - Most critically: saves predict.list to an .RData file, which rsparrow_model.R then
    loads back using load() + <<- at line 380

The <<- anti-pattern in rsparrow_model.R exists because predict.list is currently passed
via the file system rather than return value. The fix requires eliminating the save/load cycle:

  Current flow:
    controlFileTasksModel() --(save to .RData)--> file system --(load + <<-)--> rsparrow_model()

  Target flow:
    controlFileTasksModel() --(return value)--> rsparrow_model()

To accomplish this:
  1. Remove save(predict.list, ...) from controlFileTasksModel.R
  2. Add predict.list to the return value of controlFileTasksModel()
  3. In rsparrow_model.R, remove the local() + load() + <<- block (line ~380)
  4. Instead, assign the returned predict.list from controlFileTasksModel() directly

Also:
  - Remove other save() calls; add their data to the return value
  - Remove sink() for spatial autocorrelation diagnostics; return the diagnostic data instead
  - Remove any dir.create() calls

After refactoring:
  grep -n "save(\|sink(\|<<-\|dir\.create" R/controlFileTasksModel.R
  grep -n "<<-\|local().*load\|load.*predict" R/rsparrow_model.R
  Expected: 0 matches in both files
</description>
<files_modified>
  EDIT: R/controlFileTasksModel.R
  EDIT: R/rsparrow_model.R (remove <<- and local/load block)
</files_modified>
<success_criteria>
  - 0 save() calls in controlFileTasksModel.R
  - 0 sink() calls in controlFileTasksModel.R
  - 0 <<- occurrences in rsparrow_model.R
  - predict.list flows via return value, not file system
  - API tests pass (test-rsparrow-wrappers.R)
</success_criteria>
</task>

<task id="10-6" status="pending">
<subject>Refactor prediction I/O — predictScenarios.R, predictBootstraps.R</subject>
<description>
predictScenarios.R and predictBootstraps.R write results to disk as side effects of running
the prediction computations.

predictScenarios.R:
  - Remove ~2 save() calls; return the scenario predictions in the function's return value
  - Remove dir.create() calls; directory creation belongs in write_rsparrow_results()
  - predictScenariosOutCSV.R is an explicit I/O function (its purpose is writing CSV files)
    and should be kept as-is, but the metadata sink() should be removed from it (return
    metadata as a character string or list instead)

predictBootstraps.R:
  - Remove save() call; return bootstrap results directly
  - The return value flows back to rsparrow_bootstrap(), which can hold results in memory
    for the user to access via the returned rsparrow object

correlationMatrix.R:
  - Remove pdf() call (was in dead code estimateWeightedErrors.R, but verify if a separate
    pdf() call exists in correlationMatrix.R itself — GH #16 identifies one at line 263)
  - Remove sink() call (line ~309); return the correlation report as a character vector
  - Remove options(width=200) or wrap with on.exit()

After refactoring:
  grep -n "save(\|dir\.create\|sink(\|pdf(" R/predictScenarios.R R/predictBootstraps.R \
       R/predictScenariosOutCSV.R R/correlationMatrix.R
  Expected: 0 matches (except in predictScenariosOutCSV.R where fwrite() is intentional)
</description>
<files_modified>
  EDIT: R/predictScenarios.R
  EDIT: R/predictBootstraps.R
  EDIT: R/predictScenariosOutCSV.R
  EDIT: R/correlationMatrix.R
</files_modified>
<success_criteria>
  - save(), dir.create(), sink(), pdf() removed from these four files (except fwrite in predictScenariosOutCSV.R)
  - All prediction tests pass (test-prediction.R)
</success_criteria>
</task>

<task id="10-7" status="pending">
<subject>Add on.exit() protection to estimateOptimize.R sink()</subject>
<description>
estimateOptimize.R uses sink() to log NLLS optimization progress to a file. This is a
legitimate use case — the user may want to see the optimization trajectory even if the
run is interrupted. It should be KEPT but made safe with on.exit().

Current pattern (lines ~58, 98-99):
  sink(logfile)
  # ... optimization code ...
  sink()

Replace with:
  sink(logfile)
  on.exit(sink(), add = TRUE)
  # ... optimization code ...
  # sink() at end is now redundant but harmless; remove it for clarity

The on.exit() ensures the sink is closed even if nlmrt::nlfb() throws an error.

Also check if the logfile path is derived from file.output.list (which will no longer contain
dir-created paths after Tasks 10-2 and 10-3). If so, the logfile path must be derived from
a path the user provides or a tempfile(). Consider:
  - If file.output.list$path_results is available and writable, use it
  - Otherwise use tempfile(fileext=".log") and message() the path to the user

After fix:
  grep -n "sink(" R/estimateOptimize.R
  All sink() calls must be paired with on.exit(sink(), add=TRUE) in the same scope.
</description>
<files_modified>EDIT: R/estimateOptimize.R</files_modified>
<success_criteria>
  - Every sink() in estimateOptimize.R has a paired on.exit(sink(), add=TRUE)
  - No sink() resource leak is possible even if nlmrt::nlfb() throws
  - Optimization log behavior unchanged for successful runs
</success_criteria>
</task>

<task id="10-8" status="pending">
<subject>Fix assign(parent.frame()) in diagnosticPlots_4panel_B.R and upstream.R</subject>
<description>
Two surviving assign(parent.frame()) patterns need to be refactored to use return values.

diagnosticPlots_4panel_B.R (line 134):
  - Currently assigns Resids2 into the parent frame
  - Refactor: return a named list from the function; the caller unpacks Resids2 directly
    (e.g., result <- fn(...); Resids2 <- result$Resids2)
  - Or: add Resids2 as an explicit return value and update the call site in the caller

upstream.R (line 52):
  - Currently assigns ifproc into the parent frame
  - Refactor: return ifproc as a return value; update the call site

For each:
  1. Identify the caller(s) of the function
  2. Change the function to return the value explicitly
  3. Update the caller to receive it from the return value
  4. Confirm no other callers expect the parent-frame assignment behavior

applyUserModify.R (3x assign parent.frame) is NOT addressed here — it uses assign to
implement user-supplied modifications evaluated in parent context, which requires a more
significant architectural redesign. It is deferred to Plan 11.

After fixes:
  grep -rn "assign.*parent\.frame\|assign.*envir.*parent" R/
  Expected: only applyUserModify.R matches (deferred to Plan 11)
</description>
<files_modified>
  EDIT: R/diagnosticPlots_4panel_B.R
  EDIT: R/upstream.R
  EDIT: caller files that use the return values
</files_modified>
<success_criteria>
  - 0 assign(parent.frame()) in diagnosticPlots_4panel_B.R and upstream.R
  - Callers correctly receive return values
  - Plot tests pass (test-plot-rsparrow.R)
</success_criteria>
</task>

<task id="10-9" status="pending">
<subject>Create write_rsparrow_results() convenience function for file output</subject>
<description>
After removing all file I/O from computation functions, users who want CSV/RData output
need an explicit function to call. Create R/write_rsparrow_results.R:

  #' Write rsparrow model results to disk
  #'
  #' @param model An rsparrow object returned by rsparrow_model()
  #' @param path Directory to write results into. Created if it does not exist.
  #' @param what Character vector of result types to write. Options: "estimates",
  #'   "predictions", "diagnostics", "all". Default: "all".
  #' @return Invisibly returns the paths of written files.
  #' @export
  write_rsparrow_results <- function(model, path, what = "all") {
    stopifnot(inherits(model, "rsparrow"))
    stopifnot(is.character(path), length(path) == 1L)
    if (!dir.exists(path)) dir.create(path, recursive = TRUE)
    written <- character(0)

    all_what <- c("estimates", "predictions", "diagnostics")
    if (identical(what, "all")) what <- all_what
    what <- match.arg(what, all_what, several.ok = TRUE)

    if ("estimates" %in% what) {
      # Write estimate tables from model$data$estimate.list
      # Use data.table::fwrite() for CSV output
      # ... implementation ...
    }
    if ("predictions" %in% what) {
      # Write prediction tables from model$data$predict.list (if available)
      # ... implementation ...
    }
    if ("diagnostics" %in% what) {
      # Write correlation matrix, ANOVA tables, etc.
      # ... implementation ...
    }

    invisible(written)
  }

Add to NAMESPACE via @export tag. Add minimal @examples using \dontrun{}.

This function is the ONLY place in the active package where dir.create() and fwrite()
are called on user-specified paths.
</description>
<files_modified>
  CREATE: R/write_rsparrow_results.R
  EDIT: NAMESPACE (add export via roxygen2 rebuild)
  EDIT: man/ (new Rd file generated by roxygen2)
</files_modified>
<success_criteria>
  - write_rsparrow_results() is exported and documented
  - It is the only function in R/ that calls dir.create() on a user-specified path
  - Calling it on a mock rsparrow object with a tempdir() does not error
</success_criteria>
</task>

<task id="10-10" status="pending">
<subject>Run full verification after all I/O refactoring</subject>
<description>
After completing Tasks 10-2 through 10-9, verify that:

1. No computation function writes to the file system:
   grep -rn "dir\.create\|save(\|fwrite(\|sink(\|pdf(\|<<-\|assign.*parent\.frame" R/ \
     | grep -v "write_rsparrow_results\|estimateOptimize\|predictScenariosOutCSV"
   Expected: 0 matches

2. The only on.exit(sink()) is in estimateOptimize.R.

3. write_rsparrow_results.R is the only file with dir.create() outside of tempdir() usage.

4. Run full test suite:
   R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
   R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"
   Expected: all tests pass

5. Run R CMD check:
   R CMD build --no-build-vignettes .
   R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
     R CMD check --no-build-vignettes rsparrow_2.1.0.tar.gz
   Expected: 0 ERRORs, no new WARNINGs beyond Plan 09 baseline

Close GH #15 and GH #18 (partial — remaining assign pattern in applyUserModify.R is Plan 11).
</description>
<files_modified>None — verification only</files_modified>
<success_criteria>
  - grep for I/O anti-patterns returns 0 unexpected matches
  - All tests pass
  - 0 new R CMD check ERRORs
  - GH #15 closed, GH #18 partially closed (applyUserModify.R deferred)
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>All save(), dir.create(), unprotected sink(), pdf() removed from computation functions</criterion>
<criterion><<- eliminated from rsparrow_model.R (predict.list flows via return value)</criterion>
<criterion>assign(parent.frame()) eliminated from diagnosticPlots_4panel_B.R and upstream.R</criterion>
<criterion>write_rsparrow_results() exported and documented as the single opt-in I/O function</criterion>
<criterion>estimateOptimize.R sink() protected with on.exit()</criterion>
<criterion>All tests pass after refactoring</criterion>
<criterion>0 new R CMD check ERRORs</criterion>
<criterion>GH #15 closed, GH #18 partially closed</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any computation function still writes to a user-specified path without explicit user request</criterion>
<criterion><<- still present in rsparrow_model.R</criterion>
<criterion>Test regression — any previously-passing test now fails</criterion>
<criterion>R CMD build fails — indicates a broken function signature or missing return value</criterion>
</failure_criteria>

<risks>
<risk level="high">
  estimate.R and estimateNLLStable.R are the two largest files in the package (~890 and ~763
  lines). The I/O refactoring requires understanding every data dependency before removing
  save() and fwrite() calls. Test after each file to catch regressions early.
</risk>
<risk level="medium">
  The controlFileTasksModel.R → rsparrow_model.R save/load/<<- cycle is the most
  architecturally complex I/O pattern. Eliminating it requires changing function return
  types and call sites in a coordinated way. Read both files in full before starting Task 10-5.
</risk>
<risk level="low">
  Some save() calls may write data that is never loaded back in the same run — they exist
  only for post-hoc user inspection of intermediate results. These can simply be removed;
  the data is available in the returned estimate.list or sparrow_state.
</risk>
</risks>

<notes>
- predictScenariosOutCSV.R is a legitimate I/O function (writing scenario predictions to CSV
  is its explicit purpose). It should be kept. Only the metadata sink() inside it is removed.
- The refactoring in this plan is the single largest behavioral change in Plans 07–12.
  It requires careful attention to data flow between functions. Consider refactoring one
  function at a time and running tests after each.
- applyUserModify.R's assign(parent.frame()) pattern remains after this plan. It implements
  user-supplied code evaluation where the results are injected into the calling environment.
  This is architecturally complex and addressed in Plan 11.
</notes>

</plan>
