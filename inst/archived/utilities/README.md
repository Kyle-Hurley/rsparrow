# Archived: Deferred Utility Functions

These utility functions were either orphaned when their call sites were removed
(unPackList, naOmitFuncStr, copyStructure) or were never integrated into the active
package (test_addPlotlyvars, syncVarNames). estimateWeightedErrors was a diagnostic
utility for weight function visualization with a known pdf() resource leak (GH #16).

## Files

- **unPackList.R** — global state injector removed in Plans 04A/04B; last remaining callers
  (mapLoopStr.R) are themselves archived. Closes the final action item from Plan 04C.
- **naOmitFuncStr.R** — NA-omit string utility; no active callers
- **test_addPlotlyvars.R** — standalone plotly variable utility; never integrated into test suite
- **syncVarNames.R** — variable name synchronization; no active callers
- **estimateWeightedErrors.R** — computes observation weights via power-function NLS regression;
  only referenced in comments in active code. Known pdf() resource leak (GH #16) implicitly
  resolved by archival.
- **copyStructure.R** — recursive list structure copier; no active callers
