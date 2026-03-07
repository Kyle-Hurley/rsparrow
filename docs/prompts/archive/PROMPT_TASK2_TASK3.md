<prompt>
<instruction>
Execute Tasks 2 and 3 from Plan 04A. Read @PLAN_04A_WINDOWS_GLOBALENV_CORE.md for full context.
Task 1 (Windows/batch_mode removal) is already complete. Do NOT re-do Task 1.
Execute tasks in order: Task 2 first, then Task 3. Read each file fully before editing.
</instruction>

<status>
  <task id="1" status="DONE">Remove Windows-only code (shell.exec, batch_mode)</task>
  <task id="2" status="DONE">Eliminate assign(.GlobalEnv) from startModelRun.R</task>
  <task id="3" status="DONE">Refactor controlFileTasksModel.R</task>
</status>

<references>
  <file role="plan">PLAN_04A_WINDOWS_GLOBALENV_CORE.md</file>
  <file role="target" task="2">RSPARROW_master/R/startModelRun.R</file>
  <file role="target" task="3">RSPARROW_master/R/controlFileTasksModel.R</file>
  <file role="context">docs/PLAN_04_SUBSTITUTION_PATTERNS.md</file>
  <file role="context">docs/PLAN_04_FILE_INVENTORY.md</file>
</references>

<!-- ============================================================ -->
<!--  TASK 2                                                       -->
<!-- ============================================================ -->

<task id="2" name="Eliminate assign(.GlobalEnv) from startModelRun.R">

  <overview>
  Convert all ~27 assign(.GlobalEnv) calls to accumulate into a sparrow_state list.
  Remove the unPackList() call at the function top.
  Remove enable_ShinyApp from the parameter signature (Shiny separated in Plan 02).
  Return sparrow_state at the end of the function.
  </overview>

  <step id="2a" name="Add sparrow_state accumulator">
    After the unPackList(...) block (or its replacement — see step 2c), add:
    ```r
    sparrow_state <- list()
    ```
  </step>

  <step id="2b" name="Replace every assign(.GlobalEnv) with sparrow_state assignment">
    <pattern name="unconditional">
      <!-- BEFORE -->
      assign("betavalues", betavalues, envir = .GlobalEnv)
      <!-- AFTER -->
      sparrow_state$betavalues <- betavalues
    </pattern>

    <pattern name="conditional (preserve the if-block, change only the assign)">
      <!-- BEFORE -->
      if (if_validate == "yes") {
        ...
        assign("Vsites.list", Vsites.list, envir = .GlobalEnv)
      }
      <!-- AFTER -->
      if (if_validate == "yes") {
        ...
        sparrow_state$Vsites.list <- Vsites.list
      }
    </pattern>

    <variables_to_capture note="all become sparrow_state$varname">
      betavalues, SelParmValues, ifHess (conditional on bcols==1),
      dmatrixin, dlvdsgn, subdata (appears multiple times — keep all occurrences),
      add_vars (conditional on dynamic), Vsites.list (conditional on validate),
      DataMatrix.list, sitedata, numsites, sitegeolimits,
      vsitedata (conditional on validate),
      sitedata.landuse, sitedata.demtarea.class,
      vsitedata.landuse, vsitedata.demtarea.class,
      class.input.list, classvar,
      Csites.weights.list, Csites.list, Cor.ExplanVars.list,
      map_uncertainties, BootUncertainties
    </variables_to_capture>

    <known_typo>
      There is one assign with an extra comma:
        assign("Cor.ExplanVars.list", Cor.ExplanVars.list, , envir = .GlobalEnv)
      Fix the double comma when converting to:
        sparrow_state$Cor.ExplanVars.list <- Cor.ExplanVars.list
    </known_typo>
  </step>

  <step id="2c" name="Remove unPackList() call and replace with direct extractions">
    <what_to_delete>
      Delete the unPackList(lists = list(...), parentObj = list(...)) block near lines 112-129.
      It unpacks these 6 lists into bare local names:
        file.output.list, class.input.list, min.sites.list,
        scenario.input.list, estimate.input.list, mapping.input.list
    </what_to_delete>

    <what_to_add>
      Replace with direct `$` extractions for every bare name used downstream.
      IMPORTANT: Before editing, grep the file to find ALL bare variable names that
      originate from these lists. The starter list below may be incomplete.

      ```r
      # Extract frequently used variables from input lists
      path_results <- file.output.list$path_results
      path_master <- file.output.list$path_master
      run_id <- file.output.list$run_id
      classvar <- class.input.list$classvar
      class_landuse <- class.input.list$class_landuse
      minimum_reaches_separating_sites <- min.sites.list$minimum_reaches_separating_sites
      NLLS_weights <- estimate.input.list$NLLS_weights
      if_mean_adjust_delivery_vars <- estimate.input.list$if_mean_adjust_delivery_vars
      if_corrExplanVars <- estimate.input.list$if_corrExplanVars
      if_boot_estimate <- estimate.input.list$if_boot_estimate
      if_boot_predict <- estimate.input.list$if_boot_predict
      master_map_list <- mapping.input.list$master_map_list
      lon_limit <- mapping.input.list$lon_limit
      ```
    </what_to_add>

    <bare_names_to_grep note="check each against the file to confirm usage">
      <list_source name="file.output.list">path_results, path_master, path_main, run_id</list_source>
      <list_source name="class.input.list">classvar, class_landuse</list_source>
      <list_source name="min.sites.list">minimum_reaches_separating_sites (also a function param — check for duplication)</list_source>
      <list_source name="estimate.input.list">NLLS_weights, if_mean_adjust_delivery_vars, ifHess, s_offset, if_auto_scaling, if_corrExplanVars, if_boot_estimate, if_boot_predict</list_source>
      <list_source name="scenario.input.list">any scenario vars used as bare names</list_source>
      <list_source name="mapping.input.list">master_map_list, lon_limit, lat_limit, output_map_type, ConcFactor, reach_decay_specification, reservoir_decay_specification</list_source>
    </bare_names_to_grep>
  </step>

  <step id="2d" name="Add return(sparrow_state) at function end">
    Add `return(sparrow_state)` just before the closing `}` of the function.
  </step>

  <step id="2e" name="Remove enable_ShinyApp from parameter signature">
    Remove `enable_ShinyApp` from both the roxygen @param documentation and the
    function(...) signature. Shiny was separated in Plan 02; this parameter is dead.
  </step>

  <step id="2f" name="Caller update (info only)">
    startModelRun() calls controlFileTasksModel() (not the other way around).
    The real callers of startModelRun() are legacy code (already deleted in Plan 02).
    No caller update is needed for Task 2. Task 3 handles controlFileTasksModel changes.
  </step>

  <success_criteria>
    <check>grep -c "assign.*\.GlobalEnv" RSPARROW_master/R/startModelRun.R  → 0</check>
    <check>grep -c "unPackList" RSPARROW_master/R/startModelRun.R  → 0</check>
    <check>grep -c "enable_ShinyApp" RSPARROW_master/R/startModelRun.R  → 0</check>
  </success_criteria>

  <failure_criteria>
    <check>Any assign(.GlobalEnv) remains → task incomplete</check>
    <check>Any bare name from deleted unPackList is now undefined → runtime error</check>
  </failure_criteria>
</task>

<!-- ============================================================ -->
<!--  TASK 3                                                       -->
<!-- ============================================================ -->

<task id="3" name="Refactor controlFileTasksModel.R">

  <overview>
  Remove unPackList() calls and the single assign(.GlobalEnv).
  Replace bare-name access with direct $-extraction from input lists.
  Return a structured list at the end.
  </overview>

  <step id="3a" name="Remove the primary unPackList() call">
    <what_to_delete>
      The unPackList call near line 142 that unpacks:
        file.output.list, estimate.input.list, class.input.list, scenario.input.list
    </what_to_delete>

    <what_to_add>
      Replace with direct `$` extractions. Grep the file to find ALL bare names from these lists.
    </what_to_add>

    <bare_names_to_grep>
      <list_source name="file.output.list">path_results, path_master, path_main, run_id, runScript, run2</list_source>
      <list_source name="estimate.input.list">ifHess, s_offset, NLLS_weights, if_auto_scaling, if_mean_adjust_delivery_vars, if_boot_estimate, if_boot_predict, if_spatialAutoCorr, diagnosticPlots_timestep</list_source>
      <list_source name="class.input.list">classvar, class_landuse</list_source>
      <list_source name="scenario.input.list">scenario-related bare names (grep to find)</list_source>
    </bare_names_to_grep>
  </step>

  <step id="3b" name="Evaluate the second unPackList() call">
    There is a second unPackList around line 260 that unpacks `saveList` (loaded from
    an .RData file for spatial autocorrelation diagnostics). This is NOT unpacking
    function arguments into GlobalEnv — it's unpacking saved diagnostic results.
    This one is acceptable to keep. If you choose to remove it, replace with direct
    list element access.
  </step>

  <step id="3c" name="Remove the assign(.GlobalEnv)">
    There is 1 assign(.GlobalEnv): `assign("BootResults", BootResults, envir = .GlobalEnv)`
    around line 422. Remove it entirely — BootResults is only used locally after being
    loaded from file.
  </step>

  <step id="3d" name="Verify return structure">
    The function currently returns via:
      runTimes <- named.list(BootEstRunTime, BootPredictRunTime, MapPredictRunTime, estimate.list)
      return(runTimes)

    This already includes estimate.list. Verify this is sufficient. If the caller in
    startModelRun.R accesses runTimes$estimate.list, the current structure works.
    If not, adjust to a clearer structure.
  </step>

  <step id="3e" name="Update caller in startModelRun.R">
    startModelRun.R calls controlFileTasksModel() and captures the return as `runTimes`:
      runTimes <- controlFileTasksModel(...)
    Then accesses: runTimes$BootEstRunTime, runTimes$BootPredictRunTime,
    runTimes$MapPredictRunTime.

    If you change the return structure in step 3d, update these access patterns
    in startModelRun.R accordingly.
  </step>

  <success_criteria>
    <check>grep "assign.*\.GlobalEnv" RSPARROW_master/R/controlFileTasksModel.R  → 0 results</check>
    <check>The primary unPackList (function-argument unpacking) is removed</check>
    <note>The saveList unPackList (diagnostic data loading) is acceptable to keep</note>
  </success_criteria>

  <failure_criteria>
    <check>Any assign(.GlobalEnv) remains → task incomplete</check>
    <check>Any bare name from deleted unPackList is now undefined → runtime error</check>
  </failure_criteria>
</task>

<!-- ============================================================ -->
<!--  FINAL VERIFICATION                                           -->
<!-- ============================================================ -->

<verification>
  <build_command>R CMD build --no-build-vignettes RSPARROW_master/</build_command>
  <check_command>R CMD check --no-examples --no-tests --no-vignettes rsparrow_2.1.0.tar.gz</check_command>

  <expected_results>
    <result>Build must succeed: rsparrow_2.1.0.tar.gz produced</result>
    <result>Check: 0 errors (warnings/notes from Plan 03 baseline are acceptable)</result>
    <result>Plan 03 baseline: 0 errors, 4 warnings, 1 note</result>
  </expected_results>

  <grep_checks>
    <check>grep -c "assign.*\.GlobalEnv" RSPARROW_master/R/startModelRun.R  → 0</check>
    <check>grep -c "unPackList" RSPARROW_master/R/startModelRun.R  → 0</check>
    <check>grep "assign.*\.GlobalEnv" RSPARROW_master/R/controlFileTasksModel.R  → 0 results</check>
    <check>grep -c "enable_ShinyApp" RSPARROW_master/R/startModelRun.R  → 0</check>
  </grep_checks>
</verification>

</prompt>
