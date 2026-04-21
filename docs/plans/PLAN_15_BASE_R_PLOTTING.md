<plan id="15" label="Base R Plotting — Eliminate plotly Dependency" status="pending" blocked_by="14">

<objective>
Rewrite all four diagnostic plot files using base R graphics (no plotly, ggplot2, gridExtra,
or gplots). plot.rsparrow() will work with zero Suggests packages installed (except spdep
for spatial autocorrelation). plotlyLayout.R is deleted. plotly, ggplot2, gridExtra, and
gplots are removed from Suggests in DESCRIPTION.
</objective>

<context>
All four diagnostic plot files (diagnosticPlots_4panel_A.R, diagnosticPlots_4panel_B.R,
diagnosticPlotsNLLS.R, diagnosticSpatialAutoCorr.R) use plotly exclusively. A user without
plotly installed gets an immediate error when calling plot(model). This is unacceptable for
a CRAN package that lists plotly as Suggests (not Imports).

Base R graphics (graphics package) covers all required plot types:
  - Scatter plots: plot(), points(), lines()
  - Reference lines: abline(), segments()
  - Boxplots: boxplot()
  - Normal Q-Q plots: qqnorm(), qqline()
  - Dot charts: dotchart()
  - Bar plots: barplot()
  - Panel layouts: par(mfrow = ...) or layout()

The Moran's I correlogram (spatial autocorrelation) requires spdep for the computation
but not for the plotting — the plot is a simple scatter + abline in base R.

Interactive hover text (the main advantage of plotly over base R) is a convenience, not
a scientific requirement. Users who want interactive exploration can use plotly themselves
after calling predict(model) to get the underlying data.

plotlyLayout.R is a 100-line helper that builds plotly layout lists — it has no value
after the plotly references are removed.
</context>

<gh_issues>New issue to open: "Plan 15: replace plotly with base R graphics"</gh_issues>

<reference_documents>
  R/diagnosticPlots_4panel_A.R — panel A: 4-panel obs/pred scatter + resid plots
  R/diagnosticPlots_4panel_B.R — panel B: boxplot, Q-Q, resid² diagnostics
  R/diagnosticPlotsNLLS.R — orchestrator: calls 4panel_A, 4panel_B; class-stratified loop
  R/diagnosticSpatialAutoCorr.R — Moran's I correlogram; uses plotly + spdep
  R/diagnosticPlotsValidate.R — thin wrapper (~57 lines); no plotly calls
  R/plotlyLayout.R — plotly layout helper; to be deleted
  R/plot.rsparrow.R — dispatch: type="residuals"/"sensitivity"/"spatial"
  docs/reference/FUNCTION_INVENTORY.md — update plotly-tagged entries
</reference_documents>

<plot_inventory>

<plot type="residuals" panels="A+B" function="diagnosticPlotsNLLS.R → 4panel_A + 4panel_B">

Panel A (2×2 layout):
  Top-left:    Observed load vs predicted load (scatter, log scale)
               x-axis: log10(predicted load), y-axis: log10(observed load)
               Reference line: y = x (abline(0, 1))
  Top-right:   Observed yield vs predicted yield (same pattern)
  Bottom-left: Residuals vs predicted load
               x-axis: log10(predicted), y-axis: (observed - predicted)
               Reference line: y = 0 (abline(h = 0))
  Bottom-right: Residuals vs predicted yield

Panel B (2×2 layout):
  Top-left:    Boxplot of log-residuals by class variable (or single box if no classvar)
  Top-right:   Boxplot of obs/pred ratio by class variable
  Bottom-left: Normal Q-Q plot of residuals (qqnorm + qqline)
  Bottom-right: Squared residuals vs predicted (scatter)

Base R implementation:
  par(mfrow = c(2, 2), mar = c(4, 4, 2, 1))
  # Panel A-1: obs vs pred
  plot(log10(pred_load), log10(obs_load), xlab="log10(Predicted Load)",
       ylab="log10(Observed Load)", main="Observed vs Predicted Load", pch=19, cex=0.7)
  abline(0, 1, col="red", lwd=1.5)
  # ... (repeat for yield, residuals)
  par(mfrow = c(1, 1))  # restore
</plot>

<plot type="sensitivity" function="diagnosticSensitivity.R → plot.rsparrow() dispatch">
Sensitivity: one value per parameter showing sensitivity metric.
Base R: dotchart() with parameter names on y-axis and sensitivity on x-axis.
abline(v = 0) reference line.
The actual sensitivity computation in diagnosticSensitivity.R is unchanged; only the
plotting code needs to switch from plotly to base R.
</plot>

<plot type="spatial" function="diagnosticSpatialAutoCorr.R">
Moran's I correlogram: lag distance on x-axis, Moran's I statistic on y-axis.
Points: observed Moran's I at each lag.
Lines: confidence envelope (upper/lower bounds).
Reference line: y = 0 (abline(h = 0)).
Requires spdep for Moran's I computation. The plot itself is straightforward base R.

Current plotly usage: plotly::layout(shapes = list(hline(...))) for the zero reference.
After: abline(h = 0, col = "gray", lty = 2)
</plot>

</plot_inventory>

<tasks>

<task id="15-1" status="pending">
<subject>Rewrite diagnosticPlots_4panel_A.R with base R graphics</subject>
<description>
Read the current diagnosticPlots_4panel_A.R. Map each plotly trace to its base R
equivalent. The function signature (arguments) must not change — only the internal
plotting code changes.

Implementation outline:
  1. Open a new plot region with par(mfrow = c(2, 2)).
  2. Panel 1 (obs vs pred load):
     plot(x = log10(pred_load), y = log10(obs_load),
          xlab = "log10 Predicted Load", ylab = "log10 Observed Load",
          main = "Observed vs. Predicted Load", pch = 19, cex = 0.6, col = "steelblue")
     abline(0, 1, col = "red", lwd = 1.5)
  3. Panel 2 (obs vs pred yield): same pattern with yield variables.
  4. Panel 3 (resid vs pred load):
     plot(x = log10(pred_load), y = resid_load,
          xlab = "log10 Predicted Load", ylab = "Residual",
          main = "Residuals vs. Predicted Load", pch = 19, cex = 0.6, col = "steelblue")
     abline(h = 0, col = "red", lwd = 1.5)
  5. Panel 4 (resid vs pred yield): same pattern.
  6. par(mfrow = c(1, 1)) to restore.

Remove all: plotly::plot_ly(), plotly::add_trace(), plotly::layout(),
  plotlyLayout(), subplot(), htmlwidgets::saveWidget(), etc.

The function should no longer return a plotly object — it returns NULL invisibly (or the
par() settings, for compatibility). The calling code in diagnosticPlotsNLLS.R should
not try to capture or print the return value as a plotly object.

If the function previously saved the plot to a file, replace plotly's htmlwidgets::saveWidget
with pdf()/png() + dev.off() guarded by output_dir != NULL.
</description>
<files_modified>
  EDIT: R/diagnosticPlots_4panel_A.R
</files_modified>
<success_criteria>
  - No plotly:: references in diagnosticPlots_4panel_A.R
  - Function runs without error on sparrow_example data
  - 2×2 panel plot appears with correct axes and reference lines
  - Function returns NULL invisibly (no plotly object)
</success_criteria>
</task>

<task id="15-2" status="pending">
<subject>Rewrite diagnosticPlots_4panel_B.R with base R graphics</subject>
<description>
Read diagnosticPlots_4panel_B.R. The assign to parent.frame() that was eliminated in
Plan 10 (line 134 per CRAN_ROADMAP.md) is already gone. Map remaining plotly calls.

Implementation outline:
  par(mfrow = c(2, 2))
  1. Panel 1 (log-resid boxplot by classvar):
     if (no classvar) boxplot(resids, ylab = "Log Residual", main = "Residuals")
     else             boxplot(resids ~ classvar_vals, ylab = "Log Residual",
                              xlab = classvar_name, main = "Residuals by Class",
                              las = 2, cex.axis = 0.7)
     abline(h = 0, col = "red", lty = 2)
  2. Panel 2 (obs/pred ratio boxplot):
     same pattern with obs_pred_ratio variable
  3. Panel 3 (Q-Q plot):
     qqnorm(resids, main = "Normal Q-Q Plot", pch = 19, cex = 0.6, col = "steelblue")
     qqline(resids, col = "red", lwd = 1.5)
  4. Panel 4 (resid² vs pred):
     plot(x = log10(pred), y = resids^2, pch = 19, cex = 0.6, col = "steelblue",
          xlab = "log10 Predicted", ylab = "Squared Residual",
          main = "Squared Residuals vs. Predicted")
     abline(h = 0, col = "red", lty = 2)
  par(mfrow = c(1, 1))

Remove the assign to parent.frame() if it somehow survived Plan 10 (verify with grep).
</description>
<files_modified>
  EDIT: R/diagnosticPlots_4panel_B.R
</files_modified>
<success_criteria>
  - No plotly:: references in diagnosticPlots_4panel_B.R
  - No assign(parent.frame()) in diagnosticPlots_4panel_B.R
  - Function runs on sparrow_example with and without a class variable
  - Q-Q plot, boxplots, and scatter appear correctly
</success_criteria>
</task>

<task id="15-3" status="pending">
<subject>Simplify diagnosticPlotsNLLS.R — remove plotly orchestration</subject>
<description>
Read diagnosticPlotsNLLS.R. This function orchestrates the class-stratified loop over
panels A and B and assembles plotly subplot grids. With base R, the loop simplification is:

Current (pseudocode):
  for each class level:
    pA <- diagnosticPlots_4panel_A(...)  # returns plotly object
    pB <- diagnosticPlots_4panel_B(...)  # returns plotly object
    combined <- plotly::subplot(pA, pB, ...)
    htmlwidgets::saveWidget(combined, file = ...)

After:
  for each class level:
    if (!is.null(output_dir)) {
      png(file.path(output_dir, paste0(run_id, "_panel_A_", level, ".png")),
          width = 900, height = 700)
    }
    diagnosticPlots_4panel_A(...)   # draws to current device
    if (!is.null(output_dir)) dev.off()

    if (!is.null(output_dir)) {
      png(file.path(output_dir, paste0(run_id, "_panel_B_", level, ".png")),
          width = 900, height = 700)
    }
    diagnosticPlots_4panel_B(...)
    if (!is.null(output_dir)) dev.off()

Remove the plotly marker construction block (lines 97–127 per the plan specification):
  - Any code that builds plotly marker lists, trace colors, etc.

Remove plotlyLayout() calls: since plotlyLayout.R is deleted in task 15-6, any calls
to plotlyLayout() must be removed here.

The PPCC test output (Probability Plot Correlation Coefficient) and residual summary
table generation within diagnosticPlotsNLLS.R (if present) are unchanged — these are
text/data outputs, not plotly.

After simplification, diagnosticPlotsNLLS.R should be substantially shorter (estimate
~30–40% reduction in line count).
</description>
<files_modified>
  EDIT: R/diagnosticPlotsNLLS.R
</files_modified>
<success_criteria>
  - No plotly:: references in diagnosticPlotsNLLS.R
  - No plotlyLayout() calls
  - Class-stratified loop still runs for each level
  - PNG output saved when output_dir is non-NULL
  - No error when output_dir is NULL (in-memory mode)
</success_criteria>
</task>

<task id="15-4" status="pending">
<subject>Rewrite diagnosticSpatialAutoCorr.R — replace plotly with base R</subject>
<description>
Read diagnosticSpatialAutoCorr.R. This file has ~5 eval(parse()) calls and plotly layout
shapes for the Moran's I correlogram (per MEMORY.md technical facts).

The Moran's I computation via spdep is unchanged. Only the plotting code changes.

Current plotting (pseudocode):
  p <- plotly::plot_ly(x = lag_dist, y = morans_i, type = "scatter", mode = "markers")
  p <- plotly::layout(p, shapes = list(hline(0)), ...)

After (base R):
  plot(lag_dist, morans_i,
       xlab = "Lag Distance", ylab = "Moran's I",
       main = "Spatial Autocorrelation Correlogram",
       pch = 19, col = "steelblue", cex = 0.7)
  abline(h = 0, col = "gray50", lty = 2)
  # If confidence bounds are available:
  lines(lag_dist, upper_bound, col = "red", lty = 2)
  lines(lag_dist, lower_bound, col = "red", lty = 2)

Remove all plotly::layout(shapes = list(hline(...))) calls — these are the specific
plotly pattern called out in the plan.

The eval(parse()) calls in this file (~5 per MEMORY.md) are "COMPLEX/deferred" — do NOT
attempt to remove them in this plan. They are documented in MEMORY.md and deferred to Plan 16.
Only remove the plotly calls.

Wrap spdep usage in requireNamespace("spdep", quietly = TRUE) if not already done.
If spdep is absent, emit message("spdep required for spatial autocorrelation plot") and
return NULL invisibly.
</description>
<files_modified>
  EDIT: R/diagnosticSpatialAutoCorr.R
</files_modified>
<success_criteria>
  - No plotly:: references in diagnosticSpatialAutoCorr.R
  - Moran's I correlogram plots correctly with base R on sparrow_example (if spdep installed)
  - Graceful degradation with message() if spdep absent
  - eval(parse()) calls UNCHANGED (deferred to Plan 16)
</success_criteria>
</task>

<task id="15-5" status="pending">
<subject>Verify diagnosticPlotsValidate.R requires no changes</subject>
<description>
Read diagnosticPlotsValidate.R. Per the plan specification it is a thin ~57-line wrapper
with no plotly calls. Verify this with:
  grep -n "plotly" R/diagnosticPlotsValidate.R

If no plotly references: no changes needed. Document this in the plan completion notes.
If plotly references are found: apply the same base R replacement pattern used in tasks
15-1 through 15-4.

Also verify that diagnosticPlotsValidate.R correctly calls the updated (base R)
diagnosticPlotsNLLS.R without any plotly assumptions in its calling code.
</description>
<files_modified>
  EDIT: R/diagnosticPlotsValidate.R (only if plotly references found)
</files_modified>
<success_criteria>
  - diagnosticPlotsValidate.R has 0 plotly:: references
  - Function calls updated diagnosticPlotsNLLS.R without error
</success_criteria>
</task>

<task id="15-6" status="pending">
<subject>Delete plotlyLayout.R</subject>
<description>
plotlyLayout.R is a helper that constructs plotly layout lists. After all plotly references
are removed from the four diagnostic plot files, plotlyLayout.R has no callers.

Verify with:
  grep -rn "plotlyLayout" R/
Expected: 0 results (after tasks 15-1 through 15-3 remove all calls).

Then delete:
  git rm R/plotlyLayout.R
  git rm man/plotlyLayout.Rd  (if it exists — it should not since plotlyLayout is internal)

Verify deletion does not break R CMD build.
</description>
<files_modified>
  DELETE: R/plotlyLayout.R
  DELETE: man/plotlyLayout.Rd (if exists)
</files_modified>
<success_criteria>
  - plotlyLayout.R absent from R/
  - grep -rn "plotlyLayout" R/ returns 0 results
  - R CMD build succeeds after deletion
</success_criteria>
</task>

<task id="15-7" status="pending">
<subject>Remove plotly, ggplot2, gridExtra, gplots from DESCRIPTION Suggests</subject>
<description>
Edit DESCRIPTION: remove from Suggests:
  plotly
  ggplot2
  gridExtra
  gplots

Verify no R/ files still reference these packages:
  grep -rn "plotly::\|ggplot2::\|gridExtra::\|gplots::" R/
  grep -rn "requireNamespace.*plotly\|requireNamespace.*ggplot2\|requireNamespace.*gridExtra\|requireNamespace.*gplots" R/
Expected: 0 results.

NAMESPACE: remove any importFrom(plotly, ...), importFrom(ggplot2, ...) lines.

DESCRIPTION Suggests after Plan 15:
  car, knitr, leaflet, magrittr, mapview, rmarkdown, sf, spdep, testthat

(magrittr, leaflet, mapview, sf remain because inst/shiny_dss/ uses them and they appear
in Suggests; verify each is still referenced before removing.)

Run R CMD check:
  R CMD build --no-build-vignettes .
  R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false \
    R CMD check --no-manual rsparrow_2.1.0.tar.gz
Expected: 0 ERRORs, 0 WARNINGs.
</description>
<files_modified>
  EDIT: DESCRIPTION
  EDIT: NAMESPACE (if plotly/ggplot2 importFrom lines exist)
</files_modified>
<success_criteria>
  - DESCRIPTION Suggests has no plotly, ggplot2, gridExtra, gplots
  - NAMESPACE has no importFrom for these packages
  - R CMD check: 0 ERRORs, 0 WARNINGs
</success_criteria>
</task>

<task id="15-8" status="pending">
<subject>Update FUNCTION_INVENTORY.md and run final verification</subject>
<description>
Update docs/reference/FUNCTION_INVENTORY.md:
  - Update any entries tagged "plotly" to "base R graphics"
  - Remove plotlyLayout entry (deleted function)
  - Verify the inventory reflects current R/ file count

Run the full verification:
  R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch .
  R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"

Smoke test plot.rsparrow() with sparrow_example (requires actually fitting the model):
  library(rsparrow)
  model <- rsparrow_model(
    sparrow_example$reaches, sparrow_example$parameters,
    sparrow_example$design_matrix, sparrow_example$data_dictionary
  )
  plot(model, type = "residuals")   # must work with zero Suggests installed
  plot(model, type = "sensitivity")

Update MEMORY.md:
  - Note that plotly, ggplot2, gridExtra, gplots removed from Suggests
  - Note Plan 15 complete
  - Update eval(parse()) counts if any were incidentally removed
</description>
<files_modified>
  EDIT: docs/reference/FUNCTION_INVENTORY.md
  EDIT: memory/MEMORY.md
</files_modified>
<success_criteria>
  - plot(model, type="residuals") works with no Suggests installed
  - plot(model, type="sensitivity") works with no Suggests installed
  - FUNCTION_INVENTORY.md has no plotly references
  - All tests pass
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>grep -rn "plotly::" R/ returns 0 results</criterion>
<criterion>grep -rn "ggplot2::" R/ returns 0 results</criterion>
<criterion>plotlyLayout.R deleted</criterion>
<criterion>DESCRIPTION Suggests: no plotly, ggplot2, gridExtra, gplots</criterion>
<criterion>plot(model, type="residuals") and type="sensitivity" work with zero Suggests</criterion>
<criterion>plot(model, type="spatial") works when spdep is installed; graceful message when absent</criterion>
<criterion>R CMD check: 0 ERRORs, 0 WARNINGs, ≤ 2 NOTEs</criterion>
<criterion>All tests pass</criterion>
</success_criteria>

<failure_criteria>
<criterion>Any plotly:: reference survives in R/ after task 15-6</criterion>
<criterion>plot(model) errors with "there is no package called 'plotly'" on a clean R install</criterion>
<criterion>Base R plots are missing axis labels or reference lines that make them scientifically uninterpretable</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  The class-stratified loop in diagnosticPlotsNLLS.R currently generates a plotly subplot
  grid with all class levels in one HTML widget. Base R will produce separate PNG files
  (or separate calls to the graphics device). This changes the user experience from a
  single interactive HTML to multiple static images. This is an acceptable trade-off
  (interactive plotting is the user's responsibility) but should be documented in the
  vignette or NEWS.
</risk>
<risk level="medium">
  diagnosticSpatialAutoCorr.R has ~5 eval(parse()) calls deferred to Plan 16. Ensure the
  base R plotting changes do not interact with the eval(parse()) logic. Read the file
  carefully before editing.
</risk>
<risk level="low">
  If diagnosticPlotsNLLS.R currently saves plotly output to inst/doc/figures/ (referenced
  in .Rinstignore from Plan 12), the removal of plotly output may leave stale figure files.
  Check whether any figures are committed to inst/doc/ and remove them if so.
</risk>
</risks>

<notes>
- This plan rewrites all plotting to base R. The scientific content (axes, reference lines,
  Q-Q, Moran's I correlogram) is preserved exactly; only the rendering engine changes.
- Interactive hover text is deliberately removed. Users who want interactivity can pipe
  model results into plotly themselves.
- The graphics package is in base R (always available) — no new Imports or Suggests needed
  for any of the base R plot functions.
- After Plans 13, 14, and 15, DESCRIPTION has:
    Imports: nlmrt, numDeriv
    Suggests: car, knitr, leaflet, magrittr, mapview, rmarkdown, sf, spdep, testthat
  This is a clean, minimal dependency footprint.
- Plan 16 (Function Audit) will handle the remaining eval(parse()) calls in
  diagnosticSpatialAutoCorr.R and other files. Do not attempt to remove them here.
</notes>

</plan>
