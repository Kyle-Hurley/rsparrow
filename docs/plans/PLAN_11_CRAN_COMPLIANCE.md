<plan id="11" label="CRAN Compliance Fixes" status="pending" blocked_by="07,08,09,10">

<objective>
Fix all remaining CRAN policy violations and R CMD check WARNINGs that survive after Plans 07–10:
on.exit() protection for any remaining sink()/pdf(); options() restoration; the assign(parent.frame())
pattern in applyUserModify.R; all 53 cat() → message() conversions; Rd codoc mismatches;
undeclared imports; and the layout() / predictSensitivity R CMD check WARNINGs.
After this plan R CMD check should produce 0 ERRORs and 0 WARNINGs.
</objective>

<context>
Plans 07–10 resolve the structural blockers (package root, compiled artifacts, Collate, dynamic
removal, dead code, I/O coupling, <<-, most assign(parent.frame())). This plan addresses the
remaining compliance issues that are mechanical but numerous:

  GH #16: Any sink()/pdf() that survive Plan 10 need on.exit() protection
  GH #17: 5 options() modifications without restoration
  GH #18: applyUserModify.R — 3x assign(parent.frame()) (deferred from Plan 10)
  GH #19: 53 cat() calls that should be message() across 15+ files
  GH #5:  Rd codoc mismatches in 3 exported functions
  GH #6:  stringi/xfun declared in NAMESPACE but not in DESCRIPTION Imports
  GH #7:  layout() shape-argument WARNING + predictSensitivity unused-argument WARNING

Most of these are straightforward find-and-replace operations. The applyUserModify.R refactor
is the most complex item.
</context>

<gh_issues>GH #5, #6, #7, #16 (remaining), #17, #18 (remaining), #19</gh_issues>

<reference_documents>
  docs/plans/CRAN_ROADMAP.md — priority 1 blockers
  R/estimateOptimize.R — sink() already protected in Plan 10; verify
  R/correlationMatrix.R — options(width=200) at lines 269, 286
  R/predictScenariosPrep.R — options(warn=-1)/options(warn=0) at lines 165, 175
  R/controlFileTasksModel.R — options(width=200, max.print=999999) at line 253
  R/estimateNLLStable.R — options(width=500, max.print=50000) at line 189 (may be fixed in Plan 10)
  R/applyUserModify.R — 3x assign(parent.frame())
  R/mod_read_utf8.R — correct options() pattern: old_opts <- options(...); on.exit(options(old_opts))
  man/rsparrow_model.Rd — codoc mismatch (GH #5)
  man/rsparrow_scenario.Rd — codoc mismatch (GH #5)
  man/rsparrow_validate.Rd — codoc mismatch (GH #5)
  NAMESPACE — stringi/xfun import declarations to remove (GH #6)
</reference_documents>

<tasks>

<task id="11-1" status="pending">
<subject>Fix remaining sink()/pdf() without on.exit() — GH #16</subject>
<description>
After Plan 10, most sink() and pdf() calls are removed from computation functions.
This task verifies and fixes any that remain.

Audit:
  grep -rn "sink(\|pdf(" R/

For each hit, verify:
  1. Is there an on.exit(sink(), add=TRUE) or on.exit(dev.off(), add=TRUE) in the
     same function scope?
  2. If not, add on.exit() protection.

Expected state after Plan 10:
  - estimateOptimize.R: sink() with on.exit() already added in Task 10-7
  - predictScenariosOutCSV.R: fwrite() calls only (legitimate I/O function); no sink()
  - All other R/ files: 0 sink() or pdf() calls

If any unprotected sink() or pdf() is found, apply the fix:
  # BEFORE:
  sink(filepath)
  # ... code ...
  sink()

  # AFTER:
  sink(filepath)
  on.exit(sink(), add = TRUE, after = FALSE)
  # ... code ...

Use after = FALSE to ensure sink is closed before any other on.exit handlers run,
preventing output from leaking into the next handler's execution.

After fixes:
  grep -rn "sink(" R/ | grep -v "on\.exit"
  Expected: 0 matches (all sink() calls either have on.exit or are preceded by one)
</description>
<files_modified>Any R/ file containing unprotected sink() or pdf() (verify list after Plan 10)</files_modified>
<success_criteria>
  - Every sink() call in R/ has a paired on.exit(sink(), add=TRUE)
  - Every pdf() call in R/ has a paired on.exit(dev.off(), add=TRUE)
  - GH #16 closed
</success_criteria>
</task>

<task id="11-2" status="pending">
<subject>Fix options() without restoration — GH #17</subject>
<description>
Fix all 5 locations where options() is modified without restoring the original values.
The correct pattern is used in mod_read_utf8.R and must be applied to all other locations.

Correct pattern:
  old_opts <- options(width = 200)
  on.exit(options(old_opts), add = TRUE)

Locations to fix (verify line numbers after Plans 08–10 may have changed them):

correlationMatrix.R — options(width = 200):
  Replace with old_opts <- options(width = 200); on.exit(options(old_opts), add = TRUE)
  The second options() call (line 286) that sets width back — remove it (on.exit handles it)

predictScenariosPrep.R — options(warn = -1) / options(warn = 0):
  Replace the pair with:
    old_opts <- options(warn = -1)
    on.exit(options(old_opts), add = TRUE)
  Remove the options(warn = 0) call (on.exit handles restoration)

controlFileTasksModel.R — options(width = 200, max.print = 999999):
  Replace with old_opts <- options(width = 200, max.print = 999999)
             on.exit(options(old_opts), add = TRUE)

estimateNLLStable.R — options(width = 500, max.print = 50000):
  This may already be fixed in Plan 10 (the sink() in this file was removed, and the
  options() was set only for sink output). If the options() call was also removed in
  Plan 10, skip this instance. Otherwise apply the standard fix.

After fixes:
  grep -rn "^[[:space:]]*options(" R/ | grep -v "old_opts\|on\.exit\|getOption\|#"
  Expected: 0 matches (all options() modifications are paired with on.exit)
</description>
<files_modified>
  EDIT: R/correlationMatrix.R
  EDIT: R/predictScenariosPrep.R
  EDIT: R/controlFileTasksModel.R
  EDIT: R/estimateNLLStable.R (if not already fixed in Plan 10)
</files_modified>
<success_criteria>
  - Every options() modification in R/ stores the old values and restores via on.exit()
  - GH #17 closed
</success_criteria>
</task>

<task id="11-3" status="pending">
<subject>Fix assign(parent.frame()) in applyUserModify.R — GH #18</subject>
<description>
applyUserModify.R uses assign(envir=parent.frame()) three times (lines ~40, 43, 45) to inject
user-modification results back into the calling environment. This was deferred from Plan 10
because it requires an architectural decision.

Current behavior:
  applyUserModify() evaluates user-supplied modification code and assigns the results
  to named variables in the parent environment. The caller uses those variables directly.

Refactoring approach:
  1. Change applyUserModify() to return a named list of the modified values
  2. The caller unpacks the list: list2env(result, envir=environment()) or explicit assignment
     (this keeps assign() inside the function that explicitly requests it, not parent.frame)
  3. Alternatively: return a named list and have the caller use result$varname everywhere

The key constraint: applyUserModify.R is on the boundary between user-supplied code and
internal code. The user's modification script may set arbitrary variable names. Returning a
list is the cleanest approach:

  # BEFORE (inside applyUserModify.R):
  assign("foo", new_foo, envir = parent.frame())
  assign("bar", new_bar, envir = parent.frame())

  # AFTER:
  return(list(foo = new_foo, bar = new_bar))

  # In caller:
  mods <- applyUserModify(...)
  foo <- mods$foo
  bar <- mods$bar

Read applyUserModify.R in full to understand what it modifies before implementing.
The caller(s) of applyUserModify.R must be updated accordingly.

After fix:
  grep -rn "assign.*parent\.frame\|assign.*envir.*parent" R/
  Expected: 0 matches
</description>
<files_modified>
  EDIT: R/applyUserModify.R
  EDIT: caller file(s) of applyUserModify.R (identify via grep before editing)
</files_modified>
<success_criteria>
  - 0 assign(parent.frame()) in R/
  - applyUserModify.R returns a named list
  - Callers unpack the list without parent.frame injection
  - GH #18 fully closed (all 7 assign(parent.frame()) instances resolved across Plans 10+11)
</success_criteria>
</task>

<task id="11-4" status="pending">
<subject>Replace cat() with message() for user-facing output — GH #19</subject>
<description>
Replace all 53 cat() calls used for informational output with message(). cat() is only
appropriate in print/summary S3 methods for structured output that forms part of the
function's contract.

Files requiring cat() → message() conversion (verify scope after Plans 08/09 may have
archived some of these files):

  startModelRun.R         — 7 cat() calls  (data-loading progress messages)
  createInitialParameterControls.R — 16 cat() calls (parameter setup messages)
  readData.R              — 5 cat() calls  (data read progress)
  estimateOptimize.R      — 3 cat() calls  (optimization progress)
  checkClassificationVars.R — 2 cat() calls
  read_dataDictionary.R   — 2 cat() calls
  applyUserModify.R       — 2 cat() calls
  setNLLSWeights.R        — 1 cat() call
  checkAnyMissingSubdataVars.R — verify (was linked to archived files)
  checkMissingSubdataVars.R — verify (may have been archived or simplified)

Files that are now in inst/archived/ after Plans 08/09 — skip them:
  (verify which of the GH #19 files were archived)

Files where cat() MUST be preserved:
  R/print.rsparrow.R — cat() is correct for S3 print output
  R/summary.rsparrow.R — cat() is correct for S3 summary output

Conversion rules:
  cat("Message text\n") → message("Message text")
  cat("Message:", value, "\n") → message("Message: ", value)
  cat(paste0("...", var, "...\n")) → message("...", var, "...")
  # Note: message() adds a trailing newline automatically; do not add \n in the string

For multi-line cat() blocks with paste():
  cat(paste0("line1\n", "line2\n")) → message("line1\nline2")
  # Or split into two message() calls for clarity

After conversion:
  grep -rn "^\s*cat(" R/ | grep -v "print\.rsparrow\|summary\.rsparrow"
  Expected: 0 matches outside S3 print/summary methods

Also verify that message() output is suppressible:
  suppressMessages(startModelRun(...))  # should produce no console output
</description>
<files_modified>
  EDIT: R/startModelRun.R
  EDIT: R/createInitialParameterControls.R
  EDIT: R/readData.R
  EDIT: R/estimateOptimize.R
  EDIT: R/checkClassificationVars.R
  EDIT: R/read_dataDictionary.R
  EDIT: R/applyUserModify.R
  EDIT: R/setNLLSWeights.R
  EDIT: (any other active R/ files with cat() — verify list after Plans 08/09)
</files_modified>
<success_criteria>
  - 0 cat() calls in R/ outside print.rsparrow.R and summary.rsparrow.R
  - suppressMessages() suppresses all informational output
  - GH #19 closed
</success_criteria>
</task>

<task id="11-5" status="pending">
<subject>Fix Rd codoc mismatches — GH #5</subject>
<description>
Three exported functions have Rd documentation that does not match their actual R signatures,
causing R CMD check WARNING: "Codoc mismatches from documentation object ...".

Identify the specific mismatches:
  R CMD check rsparrow_2.1.0.tar.gz 2>&1 | grep -A5 "Codoc mismatch"

Typical causes:
  - Argument added/removed from the function but not from @param documentation
  - Argument renamed in the function but old name still in @param
  - Default value changed in the function but not in @usage in the Rd

Affected functions:
  rsparrow_model() — if model_type was removed in Plan 08, the @param model_type must
                      be removed from man/rsparrow_model.Rd
  rsparrow_scenario() — verify which argument is mismatched
  rsparrow_validate() — verify which argument is mismatched

Fix approach:
  1. Read the current function signature from R/rsparrow_*.R
  2. Read the current @param list in man/rsparrow_*.Rd
  3. Reconcile: add missing @param entries, remove @param for removed arguments,
     update @param names that were renamed
  4. Rebuild documentation: R_LIBS=/home/kp/R/libs Rscript -e "roxygen2::roxygenise('.')"
     OR edit man/*.Rd directly if roxygen2 is unavailable

After fixes:
  R CMD check rsparrow_2.1.0.tar.gz 2>&1 | grep "Codoc"
  Expected: 0 codoc mismatch WARNINGs
</description>
<files_modified>
  EDIT: man/rsparrow_model.Rd (if model_type removed in Plan 08)
  EDIT: man/rsparrow_scenario.Rd
  EDIT: man/rsparrow_validate.Rd
  EDIT: R/rsparrow_model.R, R/rsparrow_scenario.R, R/rsparrow_validate.R (roxygen tags)
</files_modified>
<success_criteria>
  - 0 codoc mismatch WARNINGs in R CMD check
  - GH #5 closed
</success_criteria>
</task>

<task id="11-6" status="pending">
<subject>Fix undeclared stringi/xfun imports — GH #6</subject>
<description>
R CMD check WARNING: "Namespace in Imports field not imported from: 'stringi' 'xfun'"
(or similar: functions from stringi/xfun are used but not declared in NAMESPACE).

Identify the source:
  grep -rn "stringi::\|xfun::\|requireNamespace.*stringi\|requireNamespace.*xfun" R/

These are likely in legacy encoding-related files. After Plans 08 and 09 archived many files,
verify whether the stringi/xfun references are in active R/ files or in now-archived files.

If the references are in archived files (inst/archived/):
  - Remove stringi and xfun from DESCRIPTION Imports (if listed)
  - Remove any importFrom(stringi, ...) or importFrom(xfun, ...) from NAMESPACE

If the references are in active R/ files:
  - Either add proper importFrom() declarations to NAMESPACE and DESCRIPTION
  - Or replace with base R equivalents (stringi::stri_enc_detect → iconv-based approach)

After fix:
  R CMD check rsparrow_2.1.0.tar.gz 2>&1 | grep "stringi\|xfun"
  Expected: 0 WARNINGs related to these packages
</description>
<files_modified>
  EDIT: DESCRIPTION (remove or add stringi/xfun from Imports)
  EDIT: NAMESPACE (remove or add importFrom declarations)
  EDIT: Affected R/ files (if replacing with base R equivalents)
</files_modified>
<success_criteria>
  - 0 stringi/xfun WARNINGs in R CMD check
  - GH #6 closed
</success_criteria>
</task>

<task id="11-7" status="pending">
<subject>Fix layout() shape-argument and predictSensitivity unused-argument WARNINGs — GH #7</subject>
<description>
R CMD check produces WARNINGs for:

1. layout() shape-argument: layout() is called with the shapes= argument deprecated
   or with incorrect dimensions. Find and fix the call:
     grep -rn "layout(" R/
   Fix: update the layout() call to use the correct argument format for the R version
   in use (R >= 4.4.0). Consult ?graphics::layout for the correct signature.

2. predictSensitivity unused argument: a function is called with an argument it does
   not accept (the argument was removed from the function signature but the call site
   still passes it):
     grep -rn "predictSensitivity\|\.rsparrow_plot_sensitivity" R/
   Fix: remove the unused argument from the call site. If the argument should exist,
   add it back to the function signature with a deprecation notice.

After fixes:
  R CMD check rsparrow_2.1.0.tar.gz 2>&1 | grep "layout\|predictSensitivity\|unused"
  Expected: 0 WARNINGs for these issues
</description>
<files_modified>
  EDIT: R/ file containing the layout() call
  EDIT: R/ file calling predictSensitivity with the unused argument
</files_modified>
<success_criteria>
  - 0 layout() shape-argument WARNINGs
  - 0 predictSensitivity unused-argument WARNINGs
  - GH #7 closed
</success_criteria>
</task>

<task id="11-8" status="pending">
<subject>Run R CMD check --as-cran and close all resolved issues</subject>
<description>
After completing Tasks 11-1 through 11-7, run the full CRAN-simulation check:

  source scripts/renv.sh
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --as-cran rsparrow_2.1.0.tar.gz

Target:
  - 0 ERRORs
  - 0 WARNINGs
  - ≤ 2 NOTEs (acceptable: "New submission" NOTE on first CRAN submission, possibly
    a NOTE about package size if inst/archived/ is large)

Run the test suite:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"
  Expected: all tests pass

If any WARNING or ERROR remains, address it before closing issues.

Close GH issues: #5, #6, #7, #16, #17, #18, #19 (all fully resolved).

Also update the CRAN checklist in CRAN_ROADMAP.md to reflect the new passing state of all
items that were previously marked fail.
</description>
<files_modified>
  EDIT: docs/plans/CRAN_ROADMAP.md (update checklist status fields)
</files_modified>
<success_criteria>
  - R CMD check --as-cran: 0 ERRORs, 0 WARNINGs
  - All tests pass
  - GH #5, #6, #7, #16, #17, #18, #19 closed
  - CRAN_ROADMAP.md checklist updated
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>Every sink()/pdf() in R/ has on.exit() protection (GH #16 closed)</criterion>
<criterion>Every options() modification stores old values and restores via on.exit() (GH #17 closed)</criterion>
<criterion>0 assign(parent.frame()) in R/ — all 7 instances resolved across Plans 10+11 (GH #18 closed)</criterion>
<criterion>0 cat() calls in R/ outside S3 print/summary methods (GH #19 closed)</criterion>
<criterion>0 Rd codoc mismatch WARNINGs (GH #5 closed)</criterion>
<criterion>0 undeclared import WARNINGs for stringi/xfun (GH #6 closed)</criterion>
<criterion>0 layout()/predictSensitivity WARNINGs (GH #7 closed)</criterion>
<criterion>R CMD check --as-cran: 0 ERRORs, 0 WARNINGs</criterion>
<criterion>All tests pass</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any R CMD check WARNING remains after all tasks complete</criterion>
<criterion>suppressMessages() does not suppress informational output from rsparrow functions</criterion>
<criterion>applyUserModify.R still uses assign(parent.frame())</criterion>
<criterion>Test regression from cat() → message() conversion</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  applyUserModify.R's assign(parent.frame()) implements a user-code evaluation pattern.
  The refactor in Task 11-3 changes the calling convention. Read applyUserModify.R
  carefully and test the full estimation flow after refactoring.
</risk>
<risk level="low">
  Some cat() calls may include conditional logic or formatting that does not translate
  directly to message(). message() always adds a newline; calls that use cat() without
  \n (for in-line output) need special handling:
    cat("Processing... ")  →  message("Processing...")
  The slight behavioral difference (message goes to stderr; is on a new line) is acceptable
  for CRAN compliance.
</risk>
<risk level="low">
  GH #6 (stringi/xfun) may be automatically resolved after Plans 08/09 archived the files
  containing those calls. Verify before spending time on it — it may already be fixed.
</risk>
</risks>

<notes>
- This plan is explicitly sequenced after Plans 07–10. Some items (GH #5, #7) could
  technically be fixed earlier, but batching all compliance fixes here minimizes
  context-switching and ensures the final check is comprehensive.
- After this plan, the only open GH issues should be #8 (vignette) and #9 (example dataset),
  both addressed in Plan 12. Issues #1–4 (bugs in archived code, DESCRIPTION metadata,
  setNLLSWeights) should be re-evaluated: #1 and #2 are in archived files (note in issue);
  #3 (Author/Maintainer) and #4 (setNLLSWeights ddply) need explicit resolution here or in Plan 12.
- GH #3 (DESCRIPTION missing Author/Maintainer) and GH #4 (setNLLSWeights Suggests-only
  package usage) are not explicitly assigned to a plan. Add them to this plan if they are
  confirmed still open after Plan 07 restructuring.
</notes>

</plan>
