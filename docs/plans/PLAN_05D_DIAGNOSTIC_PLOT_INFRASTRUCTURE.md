<plan id="05D">
<title>Plan 05D: Diagnostic Plot Infrastructure and plot.rsparrow() Implementation</title>
<status>COMPLETE</status>
<predecessor>Plan 05C (eval/parse cleanup complete)</predecessor>
<successor>Plan 06 (test suite)</successor>

<goal>
Remove the 2132-line create_diagnosticPlotList.R and the 18-file make_*/makeReport_* HTML
report infrastructure. Replace with a clean, direct implementation of plot.rsparrow() using
ggplot2 that exposes SPARROW diagnostics through the public API. After this plan, no
REMOVE-list files remain in R/.
</goal>

<context>
The diagnostic infrastructure consists of three tightly coupled layers:
  Layer 1 — create_diagnosticPlotList.R (2132 lines, REMOVE): defines a large named list
    of plot specifications (p1–p20+) with plotParams expression strings (the source of
    eval(parse()) calls), plot type flags (sPlot, sacPlot, vPlot), and metadata.
  Layer 2 — make_*.R (10 files, REMOVE): generate individual ggplot2/plotly plot objects
    using parameters from Layer 1. Called by Layer 3 and by REFACTOR diagnostic files.
  Layer 3 — makeReport_*.R (8 files, REMOVE): assemble Rmd content and render HTML reports
    via rmarkdown::render(). Called by diagnosticPlotsNLLS.R (REFACTOR).

The REFACTOR diagnostic files (diagnosticPlotsNLLS.R, diagnosticPlotsNLLS_dyn.R,
diagnosticPlotsNLLS_timeSeries.R, diagnosticPlotsValidate.R, diagnosticPlots_4panel_A.R,
diagnosticPlots_4panel_B.R, diagnosticSensitivity.R, diagnosticSpatialAutoCorr.R) currently
depend on Layers 1–3. This plan refactors those REFACTOR files to eliminate the layer
dependencies, then deletes Layers 1–3.

After Plan 05C, diagnosticPlots_4panel_A/B.R and diagnosticSensitivity.R are already
decoupled from create_diagnosticPlotList.R. diagnosticSpatialAutoCorr.R eliminated its
eval(parse()) calls but still calls create_diagnosticPlotList()$p19-22$plotFunc directly
(no eval; just the function calls) — this remaining dependency is handled in Step 2 below.
This plan also handles the remaining coupling in diagnosticPlotsNLLS.R and diagnosticPlotsNLLS_dyn.R.
</context>

<reference_documents>
  <doc>RSPARROW_master/R/create_diagnosticPlotList.R — 2132 lines, REMOVE</doc>
  <doc>RSPARROW_master/R/diagnosticPlotsNLLS.R — 543 lines, REFACTOR; calls make_* and makeReport_*</doc>
  <doc>RSPARROW_master/R/diagnosticPlotsNLLS_dyn.R — 401 lines, REFACTOR; calls make_dyn* and makeReport_header</doc>
  <doc>RSPARROW_master/R/diagnosticPlotsNLLS_timeSeries.R — 75 lines, REFACTOR; calls make_diagnosticPlotsNLLS_timeSeries</doc>
  <doc>RSPARROW_master/R/diagnosticPlotsValidate.R — 76 lines, thin wrapper</doc>
  <doc>RSPARROW_master/R/diagnosticPlots_4panel_A.R — post-05C: no create_diagnosticPlotList dep</doc>
  <doc>RSPARROW_master/R/diagnosticPlots_4panel_B.R — post-05C: no create_diagnosticPlotList dep</doc>
  <doc>RSPARROW_master/R/diagnosticSensitivity.R — post-05C: no create_diagnosticPlotList dep</doc>
  <doc>RSPARROW_master/R/diagnosticSpatialAutoCorr.R — post-05C: 0 eval/parse; still calls create_diagnosticPlotList()$pNN$plotFunc for p19-22 (no eval; decouple in Step 2)</doc>
  <doc>RSPARROW_master/R/plot.rsparrow.R — current stub with informative stop()</doc>
  <doc>RSPARROW_master/man/plot.rsparrow.Rd — existing man page to update</doc>
</reference_documents>

<infrastructure_analysis>
  <file name="create_diagnosticPlotList.R" lines="2132">
    Returns a named list (p1–p20+) of plot specs. After Plan 05C, only diagnosticPlotsNLLS_dyn.R
    still calls this file. The plot spec structure contains:
      $pNN$plotParams — expression string (source of eval/parse, fixed in 05C for 4panel/sensitivity/spatial)
      $pNN$sPlot, $pNN$sacPlot, $pNN$vPlot — Boolean flags for plot type filtering
      $pNN$plotTitle, $pNN$xlab, $pNN$ylab — plot metadata
    Goal: inline the relevant plot parameters directly into diagnosticPlotsNLLS_dyn.R and
    diagnosticPlotsNLLS.R (or the make_* functions they call), making create_diagnosticPlotList.R
    unreferenced and deletable.
  </file>

  <file name="diagnosticPlotsNLLS.R" lines="543">
    Calls: make_siteAttrMaps(), make_modelEstPerfPlots(), make_modelSimPerfPlots(),
    make_residMaps(), makeReport_diagnosticPlotsNLLS().
    The makeReport_* call renders an HTML report via rmarkdown. The make_* calls generate
    ggplot2 objects that are then passed to makeReport_*.
    Strategy: decouple plot generation from HTML rendering. Keep the ggplot2 generation;
    remove the Rmd/HTML rendering path. Return list of plot objects instead.
  </file>

  <file name="diagnosticPlotsNLLS_dyn.R" lines="401">
    Calls: create_diagnosticPlotList() (filtered), make_dyndiagnosticPlotsNLLS(),
    make_dyndiagnosticPlotsNLLS_sensPlots(), make_dyndiagnosticPlotsNLLS_corrPlots(),
    makeReport_header(), unPackList() (line 67 — must be fixed before unPackList.R deletion).
    The unPackList() call in line 67 is a pre-existing issue not caught in Plan 04C.
    This must be fixed in Plan 05D (direct $ extraction).
  </file>
</infrastructure_analysis>

<implementation_steps>
  <step n="1" label="Audit diagnosticPlotsNLLS_dyn.R unPackList call (pre-condition)">
    Read diagnosticPlotsNLLS_dyn.R line 67 to identify which list is unpacked.
    Replace unPackList(someList) with direct $ extractions, same as Plan 04C pattern.
    This MUST be done before Plan 05A deletes unPackList.R (or as part of Plan 05A
    if discovered during that step — see Plan 05A risk note).
    If Plan 05A already ran without catching this, fix it here before proceeding.
  </step>

  <step n="2" label="Inline create_diagnosticPlotList plot parameters into diagnosticPlotsNLLS_dyn.R">
    diagnosticPlotsNLLS_dyn.R filters create_diagnosticPlotList() output by sPlot/sacPlot/vPlot
    flags to select which plots to generate. Replace:
      plotList &lt;- Filter(function(x) x$sPlot == TRUE, create_diagnosticPlotList())
    with a hardcoded named list of the relevant plot specs (titles, axis labels, etc.) for
    the dynamic model plots. The sPlot/sacPlot/vPlot filtering becomes explicit:
      sens_plots &lt;- list(p_sensA = list(title="...", xlab="...", ylab="..."), ...)
      corr_plots &lt;- list(p_corrA = list(...), ...)
      val_plots  &lt;- list(...)
    Read create_diagnosticPlotList.R to extract the actual p-numbers that sPlot/sacPlot/vPlot
    == TRUE and copy their title/axis/type metadata inline.
    Result: diagnosticPlotsNLLS_dyn.R no longer calls create_diagnosticPlotList().
  </step>

  <step n="3" label="Decouple diagnosticPlotsNLLS.R from makeReport_* and make_*">
    Strategy: Instead of calling make_modelEstPerfPlots() → makeReport_diagnosticPlotsNLLS()
    (which renders to HTML), refactor diagnosticPlotsNLLS.R to:
      a. Call the make_* functions to generate ggplot2/plotly objects.
      b. Return those objects as a named list instead of rendering HTML.
      c. Remove the makeReport_* call entirely.
    The HTML report generation capability is dropped in the CRAN package (it requires rmarkdown
    as a dep; rmarkdown moves to Suggests; HTML output is out-of-scope for CRAN core package).
    This keeps make_modelEstPerfPlots.R, make_modelSimPerfPlots.R, make_residMaps.R,
    make_siteAttrMaps.R temporarily until they can be inlined (Step 6).
  </step>

  <step n="4" label="Remove makeReport_header.R dependency from dyn and other callers">
    makeReport_header() builds an Rmd header string for report rendering.
    After Step 3 removes HTML rendering, makeReport_header() calls become dead code.
    Remove all makeReport_header() calls from:
      diagnosticPlotsNLLS_dyn.R, diagnosticPlotsNLLS_timeSeries.R,
      diagnosticSpatialAutoCorr.R, diagnosticSensitivity.R,
      checkDrainageareaErrors.R (calls make_drainageAreaErrorsMaps + makeReport_outputMaps).
    For checkDrainageareaErrors.R: also remove make_drainageAreaErrorsMaps() and
    makeReport_outputMaps() calls — these generate HTML map reports (non-core, REMOVE).
    Replace with: return the drainage area error data.frame and let the caller decide output format.
  </step>

  <step n="5" label="Delete create_diagnosticPlotList.R and all makeReport_*.R files">
    Pre-condition: grep -r "create_diagnosticPlotList" RSPARROW_master/R/ returns 0 results.
    Pre-condition: grep -r "makeReport_" RSPARROW_master/R/ returns 0 non-makeReport_*.R results.
    Delete: create_diagnosticPlotList.R (2132 lines)
    Delete: makeReport_diagnosticPlotsNLLS.R, makeReport_drainageAreaErrorsPlot.R,
      makeReport_header.R, makeReport_modelEstPerf.R, makeReport_modelSimPerf.R,
      makeReport_outputMaps.R, makeReport_residMaps.R, makeReport_siteAttrMaps.R (8 files)
    Remove from DESCRIPTION Collate: 9 entries.
  </step>

  <step n="6" label="Inline make_*.R content into callers and delete make_*.R files">
    After Step 3 and 4, remaining make_*.R callers:
      make_dyndiagnosticPlotsNLLS → diagnosticPlotsNLLS_dyn.R
      make_dyndiagnosticPlotsNLLS_sensPlots → diagnosticPlotsNLLS_dyn.R
      make_dyndiagnosticPlotsNLLS_corrPlots → diagnosticPlotsNLLS_dyn.R
      make_modelEstPerfPlots → diagnosticPlotsNLLS.R
      make_modelSimPerfPlots → diagnosticPlotsNLLS.R
      make_residMaps → diagnosticPlotsNLLS.R
      make_siteAttrMaps → diagnosticPlotsNLLS.R
      make_drainageAreaErrorsPlot → checkDrainageareaErrors.R
      make_drainageAreaErrorsMaps → checkDrainageareaErrors.R (removed in Step 4)
      make_diagnosticPlotsNLLS_timeSeries → diagnosticPlotsNLLS_timeSeries.R

    For each make_* function: either inline the function body into its single caller, or
    if it is used by multiple callers, keep it as a renamed internal helper.
    After inlining, delete all 10 make_*.R files.
    Remove from DESCRIPTION Collate: 10 entries.
  </step>

  <step n="7" label="Implement plot.rsparrow()">
    Current state: plot.rsparrow.R contains a stub with stop("Not yet implemented").
    Implement with type= parameter dispatching to the refactored diagnostic functions:

    plot.rsparrow &lt;- function(x, type = c("residuals", "sensitivity", "spatial"), ...) {
      type &lt;- match.arg(type)
      switch(type,
        residuals  = .plot_residuals(x, ...),
        sensitivity = .plot_sensitivity(x, ...),
        spatial    = .plot_spatial(x, ...)
      )
    }

    Internal dispatchers (in plot.rsparrow.R or companion file):
      .plot_residuals(object, panel = c("A", "B", "both"), ...):
        calls diagnosticPlots_4panel_A() or _B() with object$data components.
        Returns a list of ggplot2/plotly objects (invisible).
      .plot_sensitivity(object, ...):
        calls diagnosticSensitivity() with object$data components.
        Returns sensitivity plot object (invisible).
      .plot_spatial(object, ...):
        calls diagnosticSpatialAutoCorr() with object$data components.
        Returns Moran's I plot object (invisible).

    Verify that diagnosticPlots_4panel_A/B, diagnosticSensitivity, diagnosticSpatialAutoCorr
    accept the required inputs from object$data (established in Plan 05C cleanup).
  </step>

  <step n="8" label="Update plot.rsparrow Rd man page">
    Update RSPARROW_master/man/plot.rsparrow.Rd to document type= parameter with @param,
    @return, and @examples. Examples should use \dontrun{} wrapping since they require
    a model fit.
  </step>

  <step n="9" label="Update DESCRIPTION Collate">
    Remove all deleted filenames. Verify alphabetical order.
    Net removals: create_diagnosticPlotList.R (1), makeReport_*.R (8), make_*.R (10) = 19 files.
  </step>

  <step n="10" label="Final verification">
    R CMD build --no-build-vignettes RSPARROW_master/ → succeeds.
    grep -rn "create_diagnosticPlotList\|makeReport_\|make_dyn\|make_model\|make_resid\|make_site\|make_drain\|make_diag" \
      RSPARROW_master/R/ → 0 results (no callers remaining).
    grep -rn "eval(parse" RSPARROW_master/R/ → 0–3 results (only hardened user-expression sites).
    R CMD check → same pre-existing warnings, no new errors.
    plot.rsparrow() method dispatches without error (at minimum, run with UserTutorial data
    or verify the dispatch chain doesn't crash on missing inputs).
  </step>
</implementation_steps>

<success_criteria>
  <criterion>create_diagnosticPlotList.R deleted; 0 references remain in R/</criterion>
  <criterion>All 8 makeReport_*.R files deleted; 0 calls remain in R/</criterion>
  <criterion>All 10 make_*.R files deleted (or inlined); 0 external references remain in R/</criterion>
  <criterion>plot.rsparrow() dispatches type= to residuals/sensitivity/spatial</criterion>
  <criterion>plot.rsparrow.Rd updated with @param type, @return, @examples</criterion>
  <criterion>diagnosticPlotsNLLS_dyn.R has 0 unPackList() calls</criterion>
  <criterion>diagnosticPlotsNLLS_dyn.R has 0 create_diagnosticPlotList() calls</criterion>
  <criterion>R CMD build succeeds; 0 new R CMD check errors</criterion>
  <criterion>Total R file count in R/: ~118 (down from 153 at start of Plan 05)</criterion>
  <criterion>eval(parse()) total across R/: &lt;= 3 (only hardened user-expression sites)</criterion>
</success_criteria>

<failure_criteria>
  <criterion>R CMD build fails after deletions — missed reference; grep for deleted function names</criterion>
  <criterion>plot.rsparrow() crashes on valid rsparrow object — signature mismatch with diagnostic functions</criterion>
  <criterion>create_diagnosticPlotList.R still referenced after Step 2 — blocks deletion in Step 5</criterion>
  <criterion>diagnosticPlotsNLLS_dyn.R still calls unPackList() after Step 1 — causes error since unPackList.R deleted in Plan 05A</criterion>
</failure_criteria>

<risks>
  <risk level="high">
    Dependency chain: Steps 1–4 must fully decouple REFACTOR files before Steps 5–6 delete
    the REMOVE files. Any missed reference will cause R CMD build failure. Use grep verification
    after each step before proceeding to deletion.
    Mitigation: delete files one at a time (or in small groups) and rebuild between each.
  </risk>
  <risk level="medium">
    diagnosticPlotsNLLS_dyn.R line 67 unPackList() call: if Plan 05A was executed without
    catching this, unPackList.R is already deleted and this file currently fails to load.
    Step 1 fixes this but it should be the first action.
    Mitigation: Verify R CMD build after Plan 05A before running 05D.
  </risk>
  <risk level="medium">
    create_diagnosticPlotList.R is 2132 lines with complex plot spec structures. Extracting
    and inlining the relevant parameters for diagnosticPlotsNLLS_dyn.R requires careful
    reading to avoid missing metadata (axis limits, color scales, etc.).
    Mitigation: Read the full file; extract only the p-numbers with sPlot/sacPlot/vPlot == TRUE.
  </risk>
  <risk level="low">
    Dropping HTML report generation (makeReport_*.R) removes a feature users relied on in
    legacy workflow. This is intentional for CRAN scope but should be noted in NEWS.md:
    "HTML diagnostic reports removed from core package; use plot() and S3 methods instead."
  </risk>
</risks>

<deferred>
  Further refactoring of diagnosticPlotsNLLS.R, diagnosticPlotsNLLS_dyn.R (currently
  400–543 lines after this plan) is deferred to Plan 06 scope or a future Plan 07.
  The goal here is to remove the REMOVE-list infrastructure, not to fully refactor the
  REFACTOR diagnostic functions.
</deferred>

</plan>
