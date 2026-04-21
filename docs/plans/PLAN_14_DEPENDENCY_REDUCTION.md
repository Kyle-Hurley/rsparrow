<plan id="14" label="Dependency Reduction — Remove plyr, dplyr, data.table" status="pending" blocked_by="13">

<objective>
Remove plyr, dplyr, and data.table from DESCRIPTION entirely. All six plyr::ddply calls
and three dplyr::sample_n calls are replaced with base R. All data.table::fwrite calls in
output functions are replaced with utils::write.csv. After this plan DESCRIPTION Imports
contains only nlmrt and numDeriv (2 packages); Suggests contains no plyr, dplyr, or
data.table.
</objective>

<context>
Three dependency categories need attention:

1. plyr and dplyr (currently in Suggests): Used in three core computation files without
   requireNamespace() guards. This causes runtime errors when those packages are absent
   (common on headless CRAN check machines and in fresh R installs). All six plyr::ddply
   calls and three dplyr::sample_n calls are trivially replaceable with base R.

2. data.table (currently in Imports): Used exclusively for CSV I/O via fread (in the CSV
   readers archived in Plan 13) and fwrite (in five output functions). With the CSV readers
   gone, fread usage is zero. The remaining fwrite calls in output functions are replaced
   with utils::write.csv.

Plan 13 archives readData.R/readParameters.R/readDesignMatrix.R/read_dataDictionary.R
(the fread users), so Plan 14 only needs to handle the remaining fwrite calls.

The NAMESPACE currently has importFrom(data.table, fwrite) and possibly
importFrom(plyr, ...) / importFrom(dplyr, ...) — all of these are removed.
</context>

<gh_issues>New issue to open: "Plan 14: remove plyr/dplyr/data.table dependencies"</gh_issues>

<reference_documents>
  R/sumIncremAttributes.R — 2 plyr::ddply calls
  R/selectCalibrationSites.R — 2 plyr::ddply calls
  R/setNLLSWeights.R — 2 plyr::ddply calls
  R/correlationMatrix.R — 3 dplyr::sample_n calls + requireNamespace("dplyr") guard
  R/predictOutCSV.R — data.table::fwrite
  R/predictBootsOutCSV.R — data.table::fwrite
  R/predictSummaryOutCSV.R — data.table::fwrite
  R/predictScenariosOutCSV.R — data.table::fwrite
  R/createMasterDataDictionary.R — data.table::fwrite (if still present post-Plan 13)
  DESCRIPTION — Imports: data.table; Suggests: plyr, dplyr (to remove)
  NAMESPACE — importFrom lines to remove
  tests/testthat/test-setNLLSWeights.R — may have explicit library(plyr) workaround
</reference_documents>

<replacement_patterns>

<pattern id="plyr-ddply-length">
Before (sumIncremAttributes.R, selectCalibrationSites.R, setNLLSWeights.R):
  plyr::ddply(xx, plyr::.(groupvar), dplyr::summarize, nirchs = length(groupvar))

After (base R):
  tmp <- aggregate(list(nirchs = xx$groupvar), list(groupvar = xx$groupvar), FUN = length)
  # merge back as needed
</pattern>

<pattern id="plyr-ddply-sum">
Before (sumIncremAttributes.R):
  plyr::ddply(xx, plyr::.(groupvar), dplyr::summarize, tiarea = sum(attrib))

After (base R):
  tmp <- aggregate(list(tiarea = xx$attrib), list(groupvar = xx$groupvar), FUN = sum)
</pattern>

<pattern id="dplyr-sample_n">
Before (correlationMatrix.R, line ~55):
  sdf <- dplyr::sample_n(df, nsamples)

After (base R):
  sdf <- df[sample(nrow(df), min(nsamples, nrow(df))), , drop = FALSE]

Note: the min() guard ensures no error when nrow(df) < nsamples (dplyr::sample_n errors
in this case too unless replace = TRUE; base R sample() with replace = FALSE also errors —
add the min() guard for robustness).
</pattern>

<pattern id="fwrite">
Before (all output CSV functions):
  data.table::fwrite(df, file = path, ...)

After (base R):
  utils::write.csv(df, file = path, row.names = FALSE, ...)

Note: fwrite is faster than write.csv for large files, but output CSV files in rsparrow
are diagnostic outputs (not in the hot path). write.csv is entirely adequate.
fwrite uses sep = "," by default matching write.csv; verify quote behavior per file.
</pattern>

</replacement_patterns>

<tasks>

<task id="14-1" status="pending">
<subject>Replace plyr::ddply in sumIncremAttributes.R</subject>
<description>
Read sumIncremAttributes.R. Locate the two plyr::ddply calls. Replace each with base R
aggregate() following the patterns above.

Specific calls (verify line numbers against actual file):
  1. Count call: groups reaches by some ID variable; counts members per group (nirchs).
  2. Sum call: groups by same ID; sums an area/attribute column (tiarea).

After replacement, confirm the output columns and column names match what downstream code
expects. sumIncremAttributes() is called from startModelRun.R — check that the returned
data frame has the same structure.

Run:
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_file('tests/testthat/test-sumIncremAttributes.R')"
(if the test file exists; otherwise verify manually with sparrow_example).
</description>
<files_modified>
  EDIT: R/sumIncremAttributes.R
</files_modified>
<success_criteria>
  - No plyr:: or dplyr:: references in sumIncremAttributes.R
  - Function output is identical to previous plyr-based output on sparrow_example
  - R CMD check shows no new WARNING
</success_criteria>
</task>

<task id="14-2" status="pending">
<subject>Replace plyr::ddply in selectCalibrationSites.R</subject>
<description>
Read selectCalibrationSites.R. Locate the plyr::ddply calls. Replace with base R
aggregate(). The grouping variable is likely staidseq (station ID); the summarised
variable is demiarea (drainage area).

Verify that the returned data frame column names and types are identical to the
plyr output. selectCalibrationSites() is called from startModelRun.R.

Check if there is a test file: tests/testthat/test-selectCalibrationSites.R.
If not, add a minimal test using sparrow_example after the replacement.
</description>
<files_modified>
  EDIT: R/selectCalibrationSites.R
</files_modified>
<success_criteria>
  - No plyr:: or dplyr:: references in selectCalibrationSites.R
  - Function output matches previous behavior on sparrow_example
</success_criteria>
</task>

<task id="14-3" status="pending">
<subject>Replace plyr::ddply in setNLLSWeights.R</subject>
<description>
Read setNLLSWeights.R. This function is covered by tests/testthat/test-setNLLSWeights.R
(per MEMORY.md: "remove explicit library(plyr) workarounds"). Locate the plyr::ddply calls
and replace with base R aggregate().

After replacement, run the existing test:
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_file('tests/testthat/test-setNLLSWeights.R')"

If the test file has explicit library(plyr) or library(dplyr) calls, remove them.
The test must pass without plyr installed.

setNLLSWeights() signature (from MEMORY.md):
  setNLLSWeights(NLLS_weights, run_id, subdata, sitedata, data_names,
    minimum_reaches_separating_sites)
  Returns: list(NLLS_weights, tiarea, count, weight)

Verify the returned list elements are unchanged.
</description>
<files_modified>
  EDIT: R/setNLLSWeights.R
  EDIT: tests/testthat/test-setNLLSWeights.R (remove library(plyr) calls)
</files_modified>
<success_criteria>
  - No plyr:: or dplyr:: references in setNLLSWeights.R
  - test-setNLLSWeights.R passes without plyr installed
  - Return value structure unchanged
</success_criteria>
</task>

<task id="14-4" status="pending">
<subject>Replace dplyr::sample_n in correlationMatrix.R</subject>
<description>
Read correlationMatrix.R. Locate the three dplyr::sample_n calls and the
requireNamespace("dplyr") guard around them (line ~55 per MEMORY.md).

Replace each dplyr::sample_n call:
  sdf <- dplyr::sample_n(df, nsamples)
  →
  sdf <- df[sample(nrow(df), min(nsamples, nrow(df))), , drop = FALSE]

Remove the requireNamespace("dplyr") guard — it is no longer needed.

Also check for any requireNamespace("car") guard in the same file (Plan 03 note:
"Fixed library(car)/library(dplyr) -> requireNamespace() in correlationMatrix.R").
The requireNamespace("car") guard should remain since car is in Suggests.

Verify correlationMatrix.R still returns the same data structure after replacement.
correlationMatrix() is an internal function called from diagnosticSpatialAutoCorr.R.
</description>
<files_modified>
  EDIT: R/correlationMatrix.R
</files_modified>
<success_criteria>
  - No dplyr:: references in correlationMatrix.R
  - requireNamespace("dplyr") guard removed
  - car requireNamespace() guard preserved
  - Function returns same structure
</success_criteria>
</task>

<task id="14-5" status="pending">
<subject>Replace data.table::fwrite with utils::write.csv in output functions</subject>
<description>
Read each of the following files and replace data.table::fwrite calls with utils::write.csv:

  predictOutCSV.R
  predictBootsOutCSV.R
  predictSummaryOutCSV.R
  predictScenariosOutCSV.R
  createMasterDataDictionary.R (check if still in R/; may already use write.csv)

Replacement pattern:
  data.table::fwrite(df, file = path, ...)
  →
  utils::write.csv(df, file = path, row.names = FALSE)

Verify any additional fwrite arguments (e.g., sep, na, quote, col.names) and translate
them to write.csv equivalents. write.csv always uses sep = "," and quote = TRUE by default;
fwrite uses sep = "," and quote = "auto". Check if any output CSVs have special quoting
requirements.

These functions are called only when output_dir is non-NULL (per Plan 10's NULL guard),
so this change does not affect in-memory usage.

After replacement, check for any remaining data.table:: references in R/:
  grep -r "data.table::" R/
Expected: 0 results.
</description>
<files_modified>
  EDIT: R/predictOutCSV.R
  EDIT: R/predictBootsOutCSV.R
  EDIT: R/predictSummaryOutCSV.R
  EDIT: R/predictScenariosOutCSV.R
  EDIT: R/createMasterDataDictionary.R (if applicable)
</files_modified>
<success_criteria>
  - grep -r "data.table::" R/ returns 0 results
  - Output CSV files have identical content to fwrite output (verify with small test)
  - R CMD check: 0 new WARNINGs
</success_criteria>
</task>

<task id="14-6" status="pending">
<subject>Update DESCRIPTION and NAMESPACE to remove all three packages</subject>
<description>
DESCRIPTION changes:
  - Remove data.table from Imports
  - Remove plyr from Suggests
  - Remove dplyr from Suggests

DESCRIPTION Imports after this plan: nlmrt, numDeriv (2 packages)
DESCRIPTION Suggests after this plan: car, gridExtra, ggplot2, gplots, knitr, leaflet,
  magrittr, mapview, plotly, rmarkdown, sf, spdep, testthat (remove plyr, dplyr, data.table)

Note: plotly, ggplot2, gridExtra, gplots are still in Suggests here but will be removed
in Plan 15 (base R plotting). Do not remove them yet.

NAMESPACE changes (edit NAMESPACE directly, or update rsparrow-package.R @importFrom tags
and re-run roxygen2):
  - Remove: importFrom(data.table, fwrite)
  - Remove: any importFrom(plyr, ...) lines
  - Remove: any importFrom(dplyr, ...) lines

After updating DESCRIPTION and NAMESPACE:
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-manual rsparrow_2.1.0.tar.gz

Expected: 0 ERRORs, 0 WARNINGs. The NOTE about unavailable Suggests packages may shrink
(plyr, dplyr no longer listed).
</description>
<files_modified>
  EDIT: DESCRIPTION
  EDIT: NAMESPACE (or R/rsparrow-package.R and re-run roxygen2)
</files_modified>
<success_criteria>
  - DESCRIPTION has no mention of data.table, plyr, or dplyr
  - NAMESPACE has no importFrom(data.table, ...), importFrom(plyr, ...), importFrom(dplyr, ...)
  - R CMD check: 0 ERRORs, 0 WARNINGs
</success_criteria>
</task>

<task id="14-7" status="pending">
<subject>Update IMPORTS_GUIDE.md, run final check, update MEMORY.md</subject>
<description>
Update docs/api/IMPORTS_GUIDE.md:
  - Remove data.table, plyr, dplyr entries
  - Note that utils::write.csv replaces fwrite
  - Note that base R aggregate() replaces plyr::ddply
  - Note that base R sample() replaces dplyr::sample_n
  - Update the Imports count: 3 → 2 (nlmrt, numDeriv)

Run the full test suite:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"
Expected: all tests pass.

Update MEMORY.md:
  - Change "3 Imports (data.table, nlmrt, numDeriv)" to "2 Imports (nlmrt, numDeriv)"
  - Remove plyr, dplyr from Suggests list
  - Note Plan 14 complete
</description>
<files_modified>
  EDIT: docs/api/IMPORTS_GUIDE.md
  EDIT: memory/MEMORY.md
</files_modified>
<success_criteria>
  - IMPORTS_GUIDE.md accurately reflects 2 Imports and no plyr/dplyr/data.table
  - All tests pass
  - MEMORY.md updated
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>grep -r "plyr::" R/ returns 0 results</criterion>
<criterion>grep -r "dplyr::" R/ returns 0 results</criterion>
<criterion>grep -r "data.table::" R/ returns 0 results</criterion>
<criterion>DESCRIPTION Imports: nlmrt, numDeriv only</criterion>
<criterion>DESCRIPTION Suggests: no plyr, no dplyr, no data.table</criterion>
<criterion>R CMD check: 0 ERRORs, 0 WARNINGs</criterion>
<criterion>All tests pass without plyr, dplyr, or data.table installed</criterion>
</success_criteria>

<failure_criteria>
<criterion>aggregate() output column names differ from ddply output, causing downstream breakage</criterion>
<criterion>write.csv produces different quoting causing downstream CSV parsers to fail</criterion>
<criterion>R CMD check introduces any new WARNING after DESCRIPTION changes</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  plyr::ddply automatically handles edge cases (empty groups, NA groups) differently from
  aggregate(). Verify that no reach network in tests produces empty groups before finalising
  the replacement. The sparrow_example and mini_network fixtures cover this.
</risk>
<risk level="low">
  utils::write.csv writes a header row and uses row.names = FALSE by default when specified.
  Some downstream consumers of the output CSVs may rely on exact whitespace or quoting.
  Post-replacement, visually inspect one output CSV using output_dir to confirm format.
</risk>
<risk level="low">
  The test-setNLLSWeights.R "explicit library(plyr) workarounds" (per MEMORY.md) may mask
  the original bug that necessitated plyr. Ensure the base R replacement produces identical
  numerical output on the test fixture.
</risk>
</risks>

<notes>
- Execution order: 14-1 through 14-4 (base R replacements) can be done in any order.
  14-5 (fwrite) is independent. 14-6 (DESCRIPTION/NAMESPACE) must come after all
  replacements are done. 14-7 (docs + check) is last.
- Plan 15 will remove plotly, ggplot2, gridExtra, gplots from Suggests. Do not remove them
  in this plan — they are still referenced in existing diagnostic plot files until Plan 15
  rewrites those files.
- After Plan 14, the package has 2 Imports: nlmrt (NLLS optimizer) and numDeriv
  (Jacobian/Hessian). This is extremely lean and well below the CRAN expectation
  for a computation package.
- The MEMORY.md "Internal Function Signatures" note for setNLLSWeights mentions "Uses
  plyr::ddply (bug: unqualified)" — that bug is resolved by this plan.
</notes>

</plan>
