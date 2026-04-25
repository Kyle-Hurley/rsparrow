# Plan 18D: Final Cleanup and Documentation

<plan_metadata>
  <id>18D</id>
  <title>Final Cleanup and Documentation</title>
  <parent>Plan 18: Strip Side Effects and Dead Code from Core Workflow</parent>
  <depends_on>Plans 18A, 18B, 18C</depends_on>
  <blocked_by>18A, 18B, 18C</blocked_by>
  <blocks>none</blocks>
</plan_metadata>

## Objective

<objective>
Remove Shiny code paths from scenario files (predictScenarios.R, predictScenariosPrep.R,
predictScenariosOutCSV.R), eliminating 3 eval/parse calls and the Rshiny/input parameters.
Update documentation files to reflect the new state. Close resolved GitHub issues.
Update MEMORY.md.
</objective>

---

## Context

<context>
After Plans 18A–18C:
- Active R/ files: ~68 (down from 78)
- Suggests: 5 (down from 8)
- estimate.R: ~150 lines (down from ~698)
- plot.rsparrow() supports 8 types
- No side-effect plotting or file I/O during estimation

Remaining work:
- 3 scenario files still have Rshiny/input$ coupling with eval/parse calls
- Documentation files need updating to reflect archived files and new capabilities
- GitHub issues #6 and #22 are resolved by these changes
</context>

---

## Task 1: Clean predictScenarios.R

<task id="18D-1">
  <title>Remove Rshiny/input parameters from predictScenarios.R</title>
  <description>
  Remove the `input`, `allMetrics`, `output_map_type`, and `Rshiny` parameters from
  the function signature. Remove all `if (Rshiny)` branches. The function should only
  support batch/API mode.
  </description>

  <changes>
    <change id="18D-1a">
      <title>Remove Rshiny params from signature</title>
      <location>R/predictScenarios.R, lines 58–73</location>
      <description>
      CURRENT signature:
      ```r
      predictScenarios <- function(
          # Rshiny
          input, allMetrics, output_map_type, Rshiny,
          # regular
          estimate.input.list, estimate.list,
          predict.list, scenario.input.list,
          data_names, JacobResults, if_predict,
          DataMatrix.list, SelParmValues, subdata,
          file.output.list,
          add_vars,
          mapping.input.list,
          dlvdsgn,
          RSPARROW_errorOption)
      ```

      NEW signature:
      ```r
      predictScenarios <- function(
          estimate.input.list, estimate.list,
          predict.list, scenario.input.list,
          data_names, JacobResults, if_predict,
          DataMatrix.list, SelParmValues, subdata,
          file.output.list,
          add_vars,
          mapping.input.list,
          dlvdsgn,
          RSPARROW_errorOption)
      ```

      REMOVED: input, allMetrics, output_map_type, Rshiny (4 params)
      </description>
    </change>

    <change id="18D-1b">
      <title>Remove Rshiny branches in function body</title>
      <description>
      Remove all `if (Rshiny)` conditional blocks. Key locations:

      1. Lines 107–110: Remove Rshiny scenario_name/forecast_filename override:
         ```r
         if (Rshiny) {
           scenario_name     <- as.character(input$scenarioName)
           forecast_filename <- as.character(input$forecast_filename)
         }
         ```

      2. Lines 121–125: Simplify the guard condition:
         CURRENT: `if (((select_scenarioReachAreas != "none" | !is.na(forecast_filename)) & !Rshiny) | Rshiny)`
         NEW: `if (select_scenarioReachAreas != "none" | !is.na(forecast_filename))`

         Also remove `if (Rshiny) { scenario_sources <- as.character(input$scenario_sources) }` at line 123–125.

      3. Lines 140–141: Remove `if (!Rshiny) { input$forecast_filename <- "" }`
         (input no longer exists)

      4. Lines 161–162: Update predictScenariosPrep() call to remove Rshiny params:
         CURRENT: `predictScenariosPrep(input, allMetrics, output_map_type, Rshiny, ...)`
         NEW: `predictScenariosPrep(scenario.input.list, data_names, if_predict, ...)`

      5. Lines 461–462: Remove `if (Rshiny) { scenario_name <- as.character(input$scenarioName) }`

      6. Lines 479–480: Update predictScenariosOutCSV() call to remove Rshiny params:
         CURRENT: `predictScenariosOutCSV(input, Rshiny, ...)`
         NEW: `predictScenariosOutCSV(file.output.list, estimate.list, ...)`
      </description>
    </change>

    <change id="18D-1c">
      <title>Remove TODO comment</title>
      <location>R/predictScenarios.R, line 1</location>
      <description>
      Remove: `# TODO Plan 05 — Shiny/input$ coupling deferred to Plan 05C.`
      </description>
    </change>
  </changes>
</task>

---

## Task 2: Clean predictScenariosPrep.R

<task id="18D-2">
  <title>Remove Rshiny/input parameters from predictScenariosPrep.R</title>
  <description>
  Remove the `input`, `allMetrics`, `output_map_type`, and `Rshiny` parameters.
  Remove all `if (Rshiny)` branches. This eliminates 3 eval/parse() calls
  (GH #22), which were all guarded by Rshiny=TRUE.
  </description>

  <changes>
    <change id="18D-2a">
      <title>Remove Rshiny params from signature</title>
      <location>R/predictScenariosPrep.R, lines 64–76</location>
      <description>
      CURRENT signature:
      ```r
      predictScenariosPrep <- function(
          ## Rshiny
          input, allMetrics, output_map_type, Rshiny,
          ## regular
          scenario.input.list,
          data_names, if_predict,
          data, srcvar, jsrcvar, dataNames, JacobResults,
          subdata, SelParmValues,
          file.output.list)
      ```

      NEW signature:
      ```r
      predictScenariosPrep <- function(
          scenario.input.list,
          data_names, if_predict,
          data, srcvar, jsrcvar, dataNames, JacobResults,
          subdata, SelParmValues,
          file.output.list)
      ```

      REMOVED: input, allMetrics, output_map_type, Rshiny (4 params)
      </description>
    </change>

    <change id="18D-2b">
      <title>Remove Rshiny branches and eval/parse calls</title>
      <description>
      Remove ALL `if (Rshiny)` blocks. Key locations and the eval/parse calls they contain:

      1. Lines 112–138: The main Rshiny block that extracts from input$:
         ```r
         if (Rshiny) {
           map_years <- as.character(input$yearSelect)
           ...
           map_seasons <- as.character(input$seasonSelect)
           ...
         }
         ```
         DELETE this entire block. The non-Rshiny path already extracts these from
         file.output.list (lines 84–87).

      2. Lines 144–152: The dir.create block with Rshiny branch:
         ```r
         if (!Rshiny) {
           dir.create(...)
         } else {
           if (!dir.exists(...input$scenarioName...)) {
             dir.create(...)
           }
         }
         ```
         KEEP only the non-Rshiny path (the `if (!Rshiny)` block contents, without the condition).

      3. Lines 166–201: The main Rshiny scenario parameter extraction + eval/parse:
         ```r
         if (Rshiny) {
           scenario_name <- as.character(input$scenarioName)
           ...
           for (f in 1:length(input$selectFuncs)) {
             eval(parse(text = input$selectFuncs[f]))     # <-- eval/parse #1
             if (input$allSrc == "no") {
               eval(parse(text = input$lcFuncs[f]))       # <-- eval/parse #2
             }
           }
           ...
         }
         ```
         DELETE this entire block. The non-Rshiny path at lines 253+ extracts from
         scenario.input.list directly.

      4. Lines 287–291: Conditional Rshiny check:
         ```r
         if (Rshiny) { ... } else if (!Rshiny & ...) { ... }
         ```
         Simplify to just the non-Rshiny branch.

      5. Lines 393–396: The cfFuncs eval/parse block:
         ```r
         if (Rshiny && length(names(input)[which(names(input) == "cfFuncs")]) != 0) {
           for (f in input$cfFuncs) {
             eval(parse(text = f))                        # <-- eval/parse #3
           }
         }
         ```
         DELETE this entire block.

      RESULT: 3 eval/parse() calls eliminated (GH #22 resolved).
      </description>
    </change>

    <change id="18D-2c">
      <title>Remove Rshiny roxygen param</title>
      <description>
      Remove the `@param Rshiny` line from the roxygen block (line 15).
      Also remove `@param input`, `@param allMetrics`, `@param output_map_type` if present.
      </description>
    </change>
  </changes>
</task>

---

## Task 3: Clean predictScenariosOutCSV.R

<task id="18D-3">
  <title>Remove Rshiny/input parameters from predictScenariosOutCSV.R</title>
  <description>
  Remove the `input` and `Rshiny` parameters from the function signature.
  Remove the `if (Rshiny)` branch.
  </description>

  <changes>
    <change id="18D-3a">
      <title>Remove Rshiny params from signature</title>
      <location>R/predictScenariosOutCSV.R, lines 30–35</location>
      <description>
      CURRENT:
      ```r
      predictScenariosOutCSV <- function(
          # Rshiny
          input, Rshiny,
          # regular
          file.output.list, estimate.list, predictScenarios.list, subdata, add_vars,
          scenario_name, scenarioFlag, data_names, scenarioCoefficients)
      ```

      NEW:
      ```r
      predictScenariosOutCSV <- function(
          file.output.list, estimate.list, predictScenarios.list, subdata, add_vars,
          scenario_name, scenarioFlag, data_names, scenarioCoefficients)
      ```

      REMOVED: input, Rshiny (2 params)
      </description>
    </change>

    <change id="18D-3b">
      <title>Remove Rshiny branch</title>
      <location>R/predictScenariosOutCSV.R, lines 39–41</location>
      <description>
      DELETE:
      ```r
      if (Rshiny) {
        scenario_name <- input$scenarioName
      }
      ```
      The scenario_name is already passed as a parameter.
      </description>
    </change>
  </changes>
</task>

---

## Task 4: Update controlFileTasksModel.R Scenario Call

<task id="18D-4">
  <title>Update predictScenarios() call in controlFileTasksModel.R</title>
  <description>
  After removing Rshiny params from predictScenarios(), update the call site in
  controlFileTasksModel.R to match the new signature.
  </description>

  <changes>
    <change id="18D-4a">
      <location>R/controlFileTasksModel.R, lines 347–365</location>
      <description>
      CURRENT call:
      ```r
      input <- list(variable = "", scLoadCheck = "", batch = "", scYieldCheck = "",
                    domain = "", selectReaches = "", sourcesCheck = "", factors = "")
      if (exists("estimate.list") & !is.null(estimate.list)) {
        predictScenarios(
          input, NA, output_map_type, FALSE,
          estimate.input.list, estimate.list,
          ...
        )
      }
      ```

      NEW call:
      ```r
      if (!is.null(estimate.list)) {
        predictScenarios(
          estimate.input.list, estimate.list,
          predict.list, scenario.input.list,
          data_names, estimate.list$JacobResults, if_predict,
          DataMatrix.list, SelParmValues, subdata,
          file.output.list,
          add_vars,
          mapping.input.list,
          dlvdsgn,
          RSPARROW_errorOption
        )
      }
      ```

      Changes:
      1. Remove `input <- list(...)` stub (line 347)
      2. Remove `input, NA, output_map_type, FALSE,` from call args
      3. Simplify guard: `exists("estimate.list") &` is unnecessary since estimate.list
         is always defined in this function scope
      </description>
    </change>
  </changes>
</task>

---

## Task 5: Update Documentation Files

<task id="18D-5">
  <title>Update reference documentation</title>
  <description>
  Update the docs/reference/ files to reflect all changes from Plans 18A–18D.
  </description>

  <changes>
    <change id="18D-5a">
      <title>Update FUNCTION_INVENTORY.md</title>
      <location>docs/reference/FUNCTION_INVENTORY.md</location>
      <description>
      Move archived functions to the "Archived" section:
      - createInitialParameterControls (utilities)
      - mod_read_utf8 (utilities)
      - checkFileEncoding (utilities)
      - createMasterDataDictionary (utilities)
      - findMinMaxLatLon (utilities)
      - correlationMatrix (diagnostics)
      - calcIncremLandUse (diagnostics)
      - sumIncremAttributes (diagnostics)
      - setNAdf (diagnostics)
      - diagnosticPlotsNLLS (diagnostics)

      Update active function signatures for:
      - estimate() — new slimmed signature
      - controlFileTasksModel() — new slimmed signature
      - predictScenarios() — Rshiny params removed
      - predictScenariosPrep() — Rshiny params removed
      - predictScenariosOutCSV() — Rshiny params removed
      - plot.rsparrow() — 8 types now

      Update the Shiny DSS section to note it's archived.
      </description>
    </change>

    <change id="18D-5b">
      <title>Update ARCHITECTURE.md</title>
      <location>docs/reference/ARCHITECTURE.md</location>
      <description>
      - Update module list to reflect archived files
      - Update the estimation pipeline description to note it's pure computation
      - Update plot.rsparrow section to list all 8 types
      - Note that Shiny DSS is archived
      - Update file counts
      </description>
    </change>

    <change id="18D-5c">
      <title>Update TECHNICAL_DEBT.md</title>
      <location>docs/reference/TECHNICAL_DEBT.md</location>
      <description>
      Update issue counts:
      - eval/parse: 6 remaining (down from 9; 3 removed from predictScenariosPrep)
      - sf::st_write: 0 remaining (down from 5)
      - Suggests: 5 (down from 8)
      - Active R/ files: ~68 (down from 78)
      - estimate.R: ~150 lines (down from ~698)
      - Mark GH #6, #22 as resolved
      </description>
    </change>
  </changes>
</task>

---

## Task 6: Update Vignette (if needed)

<task id="18D-6">
  <title>Update vignette if any exported API changed</title>
  <description>
  Review the vignette to ensure no references to removed features (e.g., Shiny DSS,
  correlationMatrix, etc.). The exported API (rsparrow_model, plot.rsparrow, etc.)
  should be unchanged, so vignette changes should be minimal — mainly adding
  documentation for the 5 new plot types.
  </description>

  <subtasks>
    <subtask id="18D-6a">
      Check vignettes/RSPARROW_vignette.Rmd for references to archived functions.
    </subtask>
    <subtask id="18D-6b">
      Add examples for new plot types (simulation, class, ratio, validation, bootstrap)
      if the vignette has a plotting section.
    </subtask>
  </subtasks>
</task>

---

## Task 7: Close GitHub Issues

<task id="18D-7">
  <title>Close resolved GitHub issues</title>
  <description>
  Close issues that are resolved by Plans 18A–18D.
  </description>

  <subtasks>
    <subtask id="18D-7a">
      <title>Close GH #6 (stringi/xfun undeclared)</title>
      <description>
      Fixed by archiving checkFileEncoding.R and mod_read_utf8.R in Plan 18A.
      stringi removed from Suggests.
      Command: `gh issue close 6 --comment "Resolved in Plan 18A: checkFileEncoding.R and mod_read_utf8.R archived; stringi removed from Suggests."`
      </description>
    </subtask>
    <subtask id="18D-7b">
      <title>Close GH #22 (eval/parse in predictScenariosPrep)</title>
      <description>
      Fixed by removing all Rshiny branches from predictScenariosPrep.R in Plan 18D.
      3 eval/parse calls eliminated.
      Command: `gh issue close 22 --comment "Resolved in Plan 18D: All Rshiny branches removed from predictScenariosPrep.R; 3 eval/parse calls eliminated."`
      </description>
    </subtask>
  </subtasks>
</task>

---

## Task 8: Update MEMORY.md

<task id="18D-8">
  <title>Update auto-memory with Plan 18 results</title>
  <description>
  Update /home/kp/.claude/projects/-home-kp-Documents-projects-rsparrow-master/memory/MEMORY.md
  with the final state after Plans 18A–18D.
  </description>

  <updates>
    <update>Active R/ files: ~68 (down from 78)</update>
    <update>Suggests: 5 (car, knitr, rmarkdown, spdep, testthat)</update>
    <update>eval/parse remaining: 6 (down from 9)</update>
    <update>estimate.R: ~150 lines (down from ~698)</update>
    <update>plot.rsparrow types: 8 (residuals, sensitivity, spatial, simulation, class, ratio, validation, bootstrap)</update>
    <update>Shiny DSS archived to inst/archived/shiny_dss/</update>
    <update>diagnosticPlotsNLLS archived; estimation produces zero side effects</update>
    <update>Scenario files cleaned of all Rshiny coupling</update>
    <update>GH #6, #22 closed</update>
    <update>Plan 18 status: COMPLETE</update>
  </updates>
</task>

---

## Verification

<verification>
  <step id="v1">
    <command>R CMD build --no-build-vignettes .</command>
    <expected>Package builds successfully</expected>
  </step>
  <step id="v2">
    <command>R_LIBS=/home/kp/R/libs _R_CHECK_FORCE_SUGGESTS_=false R CMD check --no-build-vignettes --no-manual rsparrow_2.1.0.tar.gz</command>
    <expected>0 errors, 0 warnings</expected>
  </step>
  <step id="v3">
    <command>R_LIBS=/home/kp/R/libs R CMD INSTALL --no-multiarch . && R_LIBS=/home/kp/R/libs Rscript -e "testthat::test_package('rsparrow')"</command>
    <expected>All tests pass</expected>
  </step>
  <step id="v4">
    <title>Verify eval/parse count</title>
    <command>grep -rn "eval(parse" R/*.R | wc -l</command>
    <expected>6 (down from 9)</expected>
  </step>
  <step id="v5">
    <title>Verify Rshiny references removed from scenario files</title>
    <command>grep -rn "Rshiny\|input\$" R/predictScenarios.R R/predictScenariosPrep.R R/predictScenariosOutCSV.R</command>
    <expected>Zero hits</expected>
  </step>
  <step id="v6">
    <title>Full API workflow test</title>
    <command>
    R_LIBS=/home/kp/R/libs Rscript -e "
      library(rsparrow)
      # prepare -> estimate
      data <- rsparrow_prepare(sparrow_example\$reaches, sparrow_example\$parameters,
                                sparrow_example\$design_matrix, sparrow_example\$data_dictionary)
      model <- rsparrow_estimate(data)
      # predict
      preds <- predict(model)
      # write results
      files <- write_rsparrow_results(model, tempdir())
      # plot (all non-conditional types)
      pdf('/dev/null')
      plot(model, type='residuals')
      plot(model, type='sensitivity')
      plot(model, type='simulation')
      plot(model, type='class')
      plot(model, type='ratio')
      dev.off()
      cat('Full API workflow OK\n')
    "
    </command>
    <expected>"Full API workflow OK" printed with no errors</expected>
  </step>
</verification>

---

## Success Criteria

<success_criteria>
  <criterion>predictScenarios.R, predictScenariosPrep.R, predictScenariosOutCSV.R have zero Rshiny/input$ references</criterion>
  <criterion>3 eval/parse calls eliminated from predictScenariosPrep.R (total: 6 remaining)</criterion>
  <criterion>Documentation files updated (FUNCTION_INVENTORY, ARCHITECTURE, TECHNICAL_DEBT)</criterion>
  <criterion>GH #6 and #22 closed</criterion>
  <criterion>MEMORY.md updated with Plan 18 results</criterion>
  <criterion>Full API workflow works end-to-end</criterion>
  <criterion>R CMD check: 0 errors, 0 warnings</criterion>
  <criterion>All tests pass</criterion>
</success_criteria>

---

## Important Notes for Implementation

<implementation_notes>
  <note>
  When removing Rshiny branches from predictScenariosPrep.R, be very careful about
  the control flow. The Rshiny blocks are interleaved with non-Rshiny code. The safest
  approach is: for each `if (Rshiny) { ... } else { ... }` block, keep only the else
  content (removing the if/else wrapper). For standalone `if (Rshiny) { ... }` blocks,
  delete them entirely.
  </note>
  <note>
  After removing Rshiny params, update ALL call sites. The call chain is:
  controlFileTasksModel.R → predictScenarios() → predictScenariosPrep()
  controlFileTasksModel.R → predictScenarios() → predictScenariosOutCSV()
  </note>
  <note>
  The rsparrow_scenario() exported function also calls predictScenarios(). Check
  R/rsparrow_scenario.R to ensure its call is updated to match the new signature.
  </note>
  <note>
  Verify that the `output_map_type` variable removed from predictScenarios() signature
  is not used in the non-Rshiny code path. If it is, extract it from
  mapping.input.list$output_map_type inside the function body instead.
  </note>
  <note>
  Commit message convention: `Co-Authored-By: Claude` (no email, no angle brackets).
  </note>
</implementation_notes>
