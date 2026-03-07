<plan id="05C">
<title>Plan 05C: Remaining eval(parse()) Elimination</title>
<status>COMPLETE</status>
<predecessor>Plan 05B (predict consolidation complete)</predecessor>
<successor>Plan 05D</successor>

<goal>
Eliminate all remaining eval(parse()) calls in non-REMOVE R files (excluding the
make_*/makeReport_*/create_diagnosticPlotList.R cluster deferred to Plan 05D).
After Plan 05B, approximately 38 eval(parse()) remain across 6 files. This plan reduces
that count to 0 or near-0 in those 6 files.
</goal>

<context>
After Plans 04B, 04C, and 05B, the remaining eval(parse()) clusters fall into distinct
categories requiring different fix strategies. None are mechanically identical — each
requires understanding the data structure and constructing a direct alternative.

Remaining clusters (estimated post-05B):
  - diagnosticPlots_4panel_A.R: ~12 (plotTitles over-quoted strings; markerList, markerText)
  - diagnosticPlots_4panel_B.R: ~6  (same pattern, 2-panel version)
  - predictScenariosPrep.R: ~9 (S_ bare-variable patterns; 2–3 Shiny DSS expression strings)
  - applyUserModify.R: ~5 (dynamic function string construction; 1 unPackList string ref)
  - diagnosticSensitivity.R: ~3 (plotParam dispatch from create_diagnosticPlotList)
  - diagnosticSpatialAutoCorr.R: ~1 (plotParam dispatch from create_diagnosticPlotList)
  - createSubdataSorted.R: ~1 (user-supplied filter condition string)
</context>

<reference_documents>
  <doc>RSPARROW_master/R/diagnosticPlots_4panel_A.R — 200 lines; plotTitles/markerList/markerText patterns</doc>
  <doc>RSPARROW_master/R/diagnosticPlots_4panel_B.R — 178 lines; same patterns</doc>
  <doc>RSPARROW_master/R/predictScenariosPrep.R — 571 lines; S_ variable and expression patterns</doc>
  <doc>RSPARROW_master/R/applyUserModify.R — 121 lines; dynamic modifySubdata function string</doc>
  <doc>RSPARROW_master/R/diagnosticSensitivity.R — 177 lines; plotParam dispatch</doc>
  <doc>RSPARROW_master/R/diagnosticSpatialAutoCorr.R — 166 lines; plotParam dispatch</doc>
  <doc>RSPARROW_master/R/createSubdataSorted.R — caller of user filter condition</doc>
  <doc>docs/reference/TECHNICAL_DEBT.md — eval(parse) section for detailed categorization</doc>
</reference_documents>

<fix_strategies>

  <strategy id="A" files="diagnosticPlots_4panel_A.R diagnosticPlots_4panel_B.R">
    <problem>
      plotTitles is a character vector of over-quoted strings (e.g. '"Observed vs. Predicted"')
      so eval(parse(text=plotTitles[1])) is needed to strip the extra quotes.
      markerList and markerText are single character strings containing R expressions
      (e.g. "list(color=colors, size=5)") passed from create_diagnosticPlotList.R.
    </problem>
    <fix>
      plotTitles: Replace with a direct character vector of unquoted strings. The over-quoting
      originates in create_diagnosticPlotList.R (REMOVE-list, handled in Plan 05D). For now,
      strip quotes at the call site:
        plot_title &lt;- gsub('^"|"$', '', plotTitles[1])
      Or, since create_diagnosticPlotList.R will be refactored in Plan 05D to return plain
      strings, add a TODO and use the gsub workaround now.

      markerList / markerText: These are plotly marker spec expressions. Replace with direct
      inline plotly marker lists:
        # BEFORE:
        marker = eval(parse(text = markerList))
        # AFTER:
        marker = list(color = colors, size = marker_size, opacity = marker_opacity)
      Extract the actual expression from create_diagnosticPlotList.R to determine the concrete
      values, then hardcode them (or pass them as parameters if they vary per plot).
      This removes the dependency on create_diagnosticPlotList.R for these two files.
    </fix>
    <eval_parse_count before="12 (A) + 6 (B)" after="0 (both files)"/>
  </strategy>

  <strategy id="B" files="predictScenariosPrep.R">
    <problem>
      Two patterns:
      Pattern 1 — S_ bare-variable patterns (9 occurrences):
        eval(parse(text = paste0("S_", scenario_sources[i], "&lt;- rep(", scenario_factors[i], ",nrow(subdata))")))
        eval(parse(text = paste0("S_", scenario_sources[i])))
        eval(parse(text = paste0("S_", scenario_sources[i], "_LC")))
      These create and retrieve per-source scenario scaling variables named S_sourceName.

      Pattern 2 — Shiny DSS expression strings (2–3 occurrences at lines ~204, ~206):
        eval(parse(text = input$selectFuncs[f]))
        eval(parse(text = input$lcFuncs[f]))
      These are Shiny reactive input strings from the DSS UI — not callable in batch mode.
    </problem>
    <fix>
      Pattern 1 (S_ variables): Replace with a named list `scenario_mods`:
        scenario_mods &lt;- vector("list", length(scenario_sources))
        names(scenario_mods) &lt;- scenario_sources
        # BEFORE: eval(parse(text = paste0("S_", scenario_sources[i], "&lt;- rep(...)")))
        # AFTER:  scenario_mods[[scenario_sources[i]]] &lt;- rep(scenario_factors[i], nrow(subdata))
        # BEFORE: temp &lt;- eval(parse(text = paste0("S_", scenario_sources[i])))
        # AFTER:  temp &lt;- scenario_mods[[scenario_sources[i]]]
      Update all downstream references from S_name to scenario_mods[["name"]].
      The _LC (land-use conversion) companion variables get their own list:
        lc_mods &lt;- vector("list", length(scenario_sources)); names(lc_mods) &lt;- scenario_sources

      Pattern 2 (Shiny expression strings lines ~204, ~206):
        These paths are only reached when Rshiny=TRUE. In batch mode (Rshiny=FALSE),
        which is the only mode called from rsparrow_scenario(), this code is unreachable.
        Wrap with: if (isTRUE(Rshiny)) { ... } to document the branch is Shiny-only.
        Add a comment: # Shiny DSS only — not evaluated in batch mode (Rshiny=FALSE).
        Do NOT eval() these strings in batch mode. This is not a code fix but a
        code-clarity fix — the eval() calls stay but are guarded behind Rshiny=TRUE.
        (Full removal deferred to companion rsparrow.dss package work.)
    </fix>
    <eval_parse_count before="~11" after="2 (Shiny-only, guarded by Rshiny=TRUE)"/>
  </strategy>

  <strategy id="C" files="applyUserModify.R">
    <problem>
      applyUserModify.R builds a function string dynamically:
        dname &lt;- paste0('replaceNAs(named.list(', ..., '))')
        eval(parse(text = dname))   # line 81
        eval(parse(text = dname))   # line 91, 98
      and:
        userMod &lt;- paste0("modifySubdata &lt;- function(subdata, ... ) { unPackList(...); ... }")
        eval(parse(text = userMod))  # line 111
      The user supplies an R expression string in the control CSV (sparrow_control.R field
      user_modify_data) for custom data modifications.
    </problem>
    <fix>
      Lines 81, 91, 98 — replaceNAs/named.list pattern:
        These create a replaceNAs call from a list of parameter names. Replace with:
        null_params &lt;- betavalues$sparrowNames[betavalues$parmMax != 0]
        replaceNAs(setNames(vector("list", length(null_params)), null_params))
        (The named.list utility just does setNames(mget(names), names), so skip it entirely.)

      Line 111 — userMod dynamic function string:
        The userMod string contains unPackList() inside it. Since unPackList.R is deleted in
        Plan 05A, this string is broken. Fix:
        Option A (preferred): Change the API contract. Instead of evaluating a user-supplied
        R function string, require users to pass a proper R function to rsparrow_model() via
        a `modify_fn` parameter. applyUserModify() then calls modify_fn(subdata, ...) directly.
        This eliminates all eval() and aligns with R package best practices.
        Option B (fallback): If Option A breaks backward compatibility too severely, keep the
        eval() but remove the unPackList() from the generated string — replace with explicit
        parameter extraction matching Plan 04C pattern.
        Recommend Option A. Document the API change in NEWS.md.
    </fix>
    <eval_parse_count before="~5 real + 2 commented" after="0 (with Option A)"/>
  </strategy>

  <strategy id="D" files="diagnosticSensitivity.R diagnosticSpatialAutoCorr.R">
    <problem>
      Both files call:
        plotParam.list &lt;- eval(parse(text = create_diagnosticPlotList()$p16$plotParams))
      create_diagnosticPlotList() returns a list where each plot entry has a `plotParams`
      field containing an R expression string for plotly parameters. This is a 2132-line
      file on the REMOVE list (Plan 05D).
    </problem>
    <fix>
      For the 3 occurrences in diagnosticSensitivity.R and 1 in diagnosticSpatialAutoCorr.R:
      Extract the actual plotParams expression strings from create_diagnosticPlotList.R for
      plots p16, p17, p18, and the spatial autocorrelation plot. Inline them as direct list()
      calls rather than evaluated strings:
        # BEFORE:
        plotParam.list &lt;- eval(parse(text = create_diagnosticPlotList()$p16$plotParams))
        # AFTER (inline the actual params from the REMOVE file):
        plotParam.list &lt;- list(xlab = "Estimated Parameter Value",
                               ylab = "Sensitivity (%)",
                               main = "Parameter Sensitivity",
                               ...)
      This makes diagnosticSensitivity.R and diagnosticSpatialAutoCorr.R independent of
      create_diagnosticPlotList.R before Plan 05D deletes it.
      Check what the actual plotParams strings contain by reading:
        grep -A5 '"p16"' RSPARROW_master/R/create_diagnosticPlotList.R
    </fix>
    <eval_parse_count before="4 (3 in sensitivity + 1 in spatialAutoCorr)" after="0"/>
  </strategy>

  <strategy id="E" files="createSubdataSorted.R">
    <problem>
      1 eval(parse()) for user-supplied filter_data1_conditions string:
        subdata &lt;- subdata[eval(parse(text = filter_data1_conditions)), ]
      This is a user-controlled expression (from sparrow_control) applied as a row filter.
    </problem>
    <fix>
      This eval() is inherently necessary for user-supplied expressions — it cannot be
      eliminated without changing the control file API. Harden instead:
        tryCatch(
          subdata &lt;- subdata[eval(parse(text = filter_data1_conditions), envir = as.environment(subdata)), ],
          error = function(e) stop(paste0("Invalid filter_data1_conditions: '",
            filter_data1_conditions, "'. Error: ", conditionMessage(e)))
        )
      Using envir = as.environment(subdata) restricts evaluation to subdata columns only
      (security improvement; prevents access to .GlobalEnv variables).
      This remains a single flagged eval() but is now hardened.
    </fix>
    <eval_parse_count before="1" after="1 (hardened, inevitable for user expressions)"/>
  </strategy>

</fix_strategies>

<completion_summary date="2026-02-22">
  All 7 target files met their success criteria. R CMD build succeeds. Total eval(parse())
  across non-REMOVE R files reduced from ~47 to ~27 (all remaining are COMPLEX/deferred).

  Strategy A — diagnosticPlots_4panel_A.R + _B.R: COMPLETE (0 eval/parse each).
    markerList replaced with direct R list construction; plotTitles gsub-stripped;
    markerText as.formula() used for plotly formula strings.
    All make_*.R callers updated to pass markerList as an R list, not paste0 string.

  Strategy B — predictScenariosPrep.R: COMPLETE (3 Shiny-only remain, guarded by Rshiny=TRUE).
    9 S_ bare-variable eval(parse()) replaced with scenario_mods / lc_mods named lists.
    Bridge added after selectFuncs loop to copy Shiny-created S_ vars into named lists.
    3 Shiny DSS eval() calls (selectFuncs, lcFuncs expressions) left guarded: if(Rshiny).
    cfFuncs guarded: if(Rshiny &amp;&amp; length(names(input)...)); S__CF access via get().
    Cleanup block updated to also nil out scenario_mods / lc_mods entries.

  Strategy C — applyUserModify.R: COMPLETE, Option B chosen (1 unavoidable outer eval remains).
    Outer eval(parse(text=userMod)) kept — cannot eliminate without API redesign.
    unPackList() removed from generated `top` string; replaced with three assign() loops
    (one for data_names$sparrowNames, one for betavalues$sparrowNames, one for file.output.list).
    3 inner eval/parse in `bottom` string replaced: mget(null_params) for replaceNAs,
    get(datalstreq[i]) + [[]] for subdata column reassignment loops.

  Strategy D — diagnosticSensitivity.R: COMPLETE (0 eval/parse; independent of create_diagnosticPlotList.R).
    p16 plotFunc inlined as direct plotly loop (box plots per parameter).
    Computation loop (xiqr, xmed, xparm, xsens) moved before p17/p18 plots.
    p17 (arithmetic scale) and p18 (log scale) plotFuncs inlined using renamed vars
    (xmed_p, xiqr_p, data_p, ymin_p, ymax_p) to avoid clobbering originals for sensitivities.list.
    showPlotGrid extracted from mapping.input.list.
    Roxygen Executes Routines updated to remove create_diagnosticPlotList.R.

  Strategy D — diagnosticSpatialAutoCorr.R: PARTIAL — 0 eval/parse, but still calls
    create_diagnosticPlotList()$pNN$plotFunc for p19–p22 (deferred to Plan 05D).
    Map()+eval/parse replaced with explicit p.list[[...]] = create_diagnosticPlotList()$pNN$plotFunc(list(...)).
    showPlotGrid added; parameter lists constructed directly without expression strings.

  Strategy E — createSubdataSorted.R: COMPLETE (1 hardened eval remains — intentional).
    tryCatch added with informative error message quoting the failing condition.
    Note: envir restriction was NOT applied (base_mask + filter_expr need current environment).
</completion_summary>

<implementation_steps>
  <step n="1" label="Fix diagnosticPlots_4panel_A.R and _B.R (Strategy A)">
    Read create_diagnosticPlotList.R to extract the actual markerList and markerText
    expression strings used for the 4-panel plots. Inline them as direct list() calls.
    Apply gsub quote-stripping to plotTitles[1..4].
    Verify plots render (manual inspection or snapshot test).
  </step>

  <step n="2" label="Fix predictScenariosPrep.R (Strategy B)">
    Replace the 9 S_ eval(parse()) occurrences with named list access (scenario_mods, lc_mods).
    Update all downstream references within predictScenariosPrep.R.
    Guard the 2–3 Shiny DSS eval() calls with if (isTRUE(Rshiny)) { }.
    Run rsparrow_scenario() test case (from UserTutorial if available) to verify.
  </step>

  <step n="3" label="Fix applyUserModify.R (Strategy C)">
    Replace lines 81, 91, 98 with direct replaceNAs(setNames(...)) call.
    For line 111 (userMod function string):
      - If Option A: add modify_fn parameter to rsparrow_model(); update applyUserModify()
        to call modify_fn(subdata, ...) instead of building a string. Update rsparrow_model.R
        to accept and pass through modify_fn (default NULL = no modification).
      - If Option B: remove unPackList() from generated string; replace with explicit extractions.
    Document the API change if Option A.
  </step>

  <step n="4" label="Fix diagnosticSensitivity.R and diagnosticSpatialAutoCorr.R (Strategy D)">
    Read create_diagnosticPlotList.R lines for p16, p17, p18 plotParams.
    Extract and inline the parameter lists. Remove create_diagnosticPlotList() calls from
    both files (important: this makes them independent before Plan 05D deletes it).
  </step>

  <step n="5" label="Harden createSubdataSorted.R (Strategy E)">
    Apply the tryCatch + envir = as.environment(subdata) hardening.
    Keep the TODO comment noting this eval() is intentional.
  </step>

  <step n="6" label="Verify eval(parse) count">
    grep -rn "eval(parse" RSPARROW_master/R/ | \
      grep -v "make_\|makeReport_\|create_diagnostic\|\.Rmd\|# " | \
      grep -v "Shiny-only"
    Expected remaining: 1 (createSubdataSorted.R, hardened) + 2 (predictScenariosPrep.R,
    Shiny-only guarded) = 3 or fewer.
  </step>

  <step n="7" label="Build and check">
    R CMD build --no-build-vignettes RSPARROW_master/
    Confirm no new errors. Run existing testthat tests.
  </step>
</implementation_steps>

<success_criteria>
  <criterion>eval(parse()) in diagnosticPlots_4panel_A.R = 0</criterion>
  <criterion>eval(parse()) in diagnosticPlots_4panel_B.R = 0</criterion>
  <criterion>eval(parse()) in predictScenariosPrep.R &lt;= 2 (Shiny-only, guarded)</criterion>
  <criterion>eval(parse()) in applyUserModify.R = 0 (Option A) or 1 (Option B, no unPackList ref)</criterion>
  <criterion>eval(parse()) in diagnosticSensitivity.R = 0</criterion>
  <criterion>eval(parse()) in diagnosticSpatialAutoCorr.R = 0</criterion>
  <criterion>createSubdataSorted.R eval() is hardened with tryCatch + envir restriction</criterion>
  <criterion>R CMD build succeeds</criterion>
  <criterion>Total eval(parse()) across all non-REMOVE, non-make_*, non-makeReport_* R files &lt;= 3</criterion>
</success_criteria>

<failure_criteria>
  <criterion>New errors in R CMD check related to modified files</criterion>
  <criterion>rsparrow_scenario() fails — indicates S_ named list replacement broke scenario prep</criterion>
  <criterion>diagnosticSensitivity.R references create_diagnosticPlotList() after this plan — blocks Plan 05D</criterion>
  <criterion>applyUserModify.R still contains unPackList() string reference after Plan 05A deleted unPackList.R</criterion>
</failure_criteria>

<risks>
  <risk level="medium">
    create_diagnosticPlotList.R is 2132 lines and generates complex plotly parameter specs.
    Extracting the right plotParams strings for p16/p17/p18 requires careful reading.
    Mistake could break diagnostic sensitivity plots. Low impact (internal plots) but should
    be validated visually.
  </risk>
  <risk level="medium">
    applyUserModify.R Option A (modify_fn parameter) is a breaking API change for users who
    used sparrow_control.R with user_modify_data expressions. Document the migration path:
    "Wrap your expression in a function: modify_fn = function(subdata) subdata[condition, ]"
  </risk>
  <risk level="low">
    predictScenariosPrep.R scenario_mods named list must propagate to all downstream code
    that previously read S_sourceName variables from the local environment. Any missed
    reference will be a silent NA (R will not error on missing list elements by default).
    Use [[ ]] access (stops on missing) rather than $ (returns NULL silently).
  </risk>
</risks>

</plan>
