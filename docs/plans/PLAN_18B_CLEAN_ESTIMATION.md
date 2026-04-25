# Plan 18B: Clean the Estimation Pipeline

<plan_metadata>
  <id>18B</id>
  <title>Clean the Estimation Pipeline</title>
  <parent>Plan 18: Strip Side Effects and Dead Code from Core Workflow</parent>
  <depends_on>Plan 18A (dead code archived, stubs in place)</depends_on>
  <blocked_by>18A</blocked_by>
  <blocks>18C, 18D</blocks>
</plan_metadata>

## Objective

<objective>
Strip ALL side effects from estimate.R so it does ONLY computation (~150 lines remaining).
Archive diagnosticPlotsNLLS.R (inline estimation plots). Remove the diagnosticSpatialAutoCorr
call from controlFileTasksModel.R (now on-demand via plot.rsparrow). Move estimateNLLStable()
to write_rsparrow_results(). Remove sf from Suggests. Slim function signatures throughout
the estimate → controlFileTasksModel → startModelRun call chain.

After this plan, estimation produces zero plots and zero files as side effects.
All diagnostic output is available on-demand through plot(model) and write_rsparrow_results(model).
</objective>

---

## Context

<context>
After Plan 18A:
- Cor.ExplanVars.list is permanently NA (correlationMatrix archived)
- sitedata.landuse / vsitedata.landuse are permanently NA (calcIncremLandUse archived)
- Active R/ files: 69
- Suggests: 6 (car, knitr, rmarkdown, sf, spdep, testthat)

estimate.R is currently ~698 lines. Its structure:
- Lines 77–87: Function signature (26 parameters — many only feed diagnostic/shapefile calls)
- Lines 100–115: Setup + estimateOptimize()
- Lines 116–162: estimateNLLSmetrics() + estimateNLLStable() + validateMetrics()
- Lines 164–410: Diagnostic plots (diagnosticPlotsNLLS × 2) + ESRI shapefiles (sf::st_write × 3)
                  + diagnosticSensitivity() + validation plots and shapefiles
- Lines 412–667: Legacy load-from-file branch + simulation mode (mirrors estimation but with
                  starting values: metrics, NLLStable, diagnosticPlotsNLLS, shapefiles, sensitivity)
- Lines 669–697: predict_sparrow() call (duplicates the call in controlFileTasksModel)

controlFileTasksModel.R is currently 375 lines. Structure:
- Lines 85–116: Function signature (28 parameters)
- Lines 153–165: estimate() call
- Lines 172–203: Section B — diagnosticSpatialAutoCorr (side-effect plots)
- Lines 206–334: Bootstrap estimation + predictions
- Lines 340–365: Scenario predictions
- Lines 369–375: Return value with run times
</context>

---

## Task 1: Archive diagnosticPlotsNLLS.R

<task id="18B-1">
  <title>Move diagnosticPlotsNLLS.R to inst/archived/diagnostics/</title>
  <description>
  This function is called during estimation as a side effect to produce 15+ plots inline.
  The core plots (4panel A/B for estimation performance) are already available through
  plot.rsparrow(type="residuals"). Additional plots (simulation, class groups, ratio
  diagnostics) will be surfaced through new plot.rsparrow() types in Plan 18C.
  </description>

  <subtasks>
    <subtask id="18B-1a">
      Use `git mv R/diagnosticPlotsNLLS.R inst/archived/diagnostics/diagnosticPlotsNLLS.R`
    </subtask>
    <subtask id="18B-1b">
      Verify no remaining callers in R/ after estimate.R is cleaned (Task 2).
    </subtask>
  </subtasks>
</task>

---

## Task 2: Strip estimate.R to Pure Computation

<task id="18B-2">
  <title>Remove all side effects from estimate.R</title>
  <description>
  Rewrite estimate.R to contain ONLY computation: setup → estimateOptimize →
  estimateNLLSmetrics → (optional validateMetrics) → return estimate.list.
  Remove all plotting, shapefile writing, file loading, and the duplicate predict call.
  Target: ~150 lines.
  </description>

  <changes>
    <change id="18B-2a">
      <title>Slim the function signature</title>
      <description>
      Remove parameters that only fed diagnostic/shapefile calls.

      CURRENT signature (lines 77–87):
      ```r
      estimate <- function(if_estimate, if_predict, file.output.list,
                           class.input.list, dlvdsgn,
                           estimate.input.list,
                           minimum_reaches_separating_sites,
                           DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list, sitedata, numsites,
                           if_validate, Vsites.list, vsitedata, subdata, min.sites.list,
                           Cor.ExplanVars.list,
                           sitedata.landuse, vsitedata.landuse, sitedata.demtarea.class, vsitedata.demtarea.class,
                           mapping.input.list, betavalues,
                           if_estimate_simulation,
                           add_vars, data_names)
      ```

      NEW signature:
      ```r
      estimate <- function(if_estimate, if_estimate_simulation, file.output.list,
                           dlvdsgn, estimate.input.list,
                           DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list,
                           sitedata, numsites,
                           if_validate, Vsites.list, vsitedata, subdata,
                           classvar, betavalues)
      ```

      REMOVED parameters (14 total):
      - if_predict (predict_sparrow call removed — done in controlFileTasksModel)
      - class.input.list (only fed diagnosticPlotsNLLS/diagnosticSensitivity; extract classvar directly)
      - minimum_reaches_separating_sites (unused after calcIncremLandUse removed)
      - min.sites.list (only fed diagnosticSpatialAutoCorr)
      - Cor.ExplanVars.list (permanently NA after correlationMatrix archived)
      - sitedata.landuse (permanently NA after calcIncremLandUse archived)
      - vsitedata.landuse (permanently NA)
      - sitedata.demtarea.class (only fed diagnosticPlotsNLLS)
      - vsitedata.demtarea.class (only fed diagnosticPlotsNLLS)
      - mapping.input.list (only fed diagnostic/shapefile calls)
      - add_vars (only fed shapefile/diagnostic calls)
      - data_names (only fed diagnosticPlotsNLLS)

      ADDED parameter:
      - classvar (extracted from class.input.list$classvar upstream; needed by estimateNLLSmetrics)
      </description>
    </change>

    <change id="18B-2b">
      <title>Remove setup lines that extract diagnostic/shapefile variables</title>
      <description>
      DELETE lines 103–110 (variable extractions for diagnostics):
      ```r
      path_results <- file.output.list$path_results
      run_id <- file.output.list$run_id
      csv_decimalSeparator <- file.output.list$csv_decimalSeparator
      csv_columnSeparator <- file.output.list$csv_columnSeparator
      outputESRImaps <- file.output.list$outputESRImaps
      add_vars <- file.output.list$add_vars
      CRStext <- file.output.list$CRStext
      map_siteAttributes.list <- file.output.list$map_siteAttributes.list
      ```
      Also DELETE line 112: `classvar <- class.input.list$classvar` (classvar now a parameter).
      </description>
    </change>

    <change id="18B-2c">
      <title>Remove estimateNLLStable() calls</title>
      <description>
      DELETE the estimateNLLStable() call at lines 156–162 (estimation mode).
      DELETE the estimateNLLStable() call at lines 490–496 (simulation mode).
      These are moved to write_rsparrow_results() in Task 5.
      </description>
    </change>

    <change id="18B-2d">
      <title>Remove all diagnosticPlotsNLLS() calls</title>
      <description>
      DELETE the diagnosticPlotsNLLS() call block at lines 171–183 (estimation diagnostics).
      DELETE the diagnosticPlotsNLLS() call block at lines 333–345 (validation diagnostics).
      DELETE the diagnosticPlotsNLLS() call block at lines 500–512 (simulation diagnostics).
      </description>
    </change>

    <change id="18B-2e">
      <title>Remove all sf::st_write ESRI shapefile blocks</title>
      <description>
      DELETE these 5 blocks:
      1. Lines 186–235: siteAttributes shapefile (estimation, outputESRImaps[4])
      2. Lines 238–308: residuals shapefile (estimation, outputESRImaps[3])
      3. Lines 348–408: validation residuals shapefile
      4. Lines 514–564: siteAttributes shapefile (simulation mode)
      5. Lines 567–637: residuals shapefile (simulation mode)
      </description>
    </change>

    <change id="18B-2f">
      <title>Remove all diagnosticSensitivity() calls</title>
      <description>
      DELETE the diagnosticSensitivity() call at lines 315–325 (estimation).
      DELETE the diagnosticSensitivity() call at lines 641–651 (simulation).
      These remain available on-demand via plot(model, type="sensitivity").
      </description>
    </change>

    <change id="18B-2g">
      <title>Remove legacy load-from-file branch</title>
      <description>
      DELETE lines 412–443 (the `else` branch that loads sparrowEsts/JacobResults/HesResults
      from .rda files). This file-based continuation is not part of the in-memory API.

      The structure after removal should be:
      ```r
      if (if_estimate == "yes" & if_estimate_simulation == "no") {
        # ... estimation path (kept) ...
      } else if (if_estimate_simulation == "yes") {
        # ... simulation path (kept, but without diagnostic calls) ...
      }
      ```
      </description>
    </change>

    <change id="18B-2h">
      <title>Remove dead predict_sparrow() call at end</title>
      <description>
      DELETE lines 669–697. This predict_sparrow() call at the end of estimate() is
      redundant — the live prediction call is in controlFileTasksModel.R lines 298–301.
      The result of this call is never returned (estimate.R returns estimate.list, not
      predict.list).

      NOTE: The `if (if_predict == "yes" & if_estimate == "yes")` block is the one to
      remove. Verify that the function simply returns estimate.list after the estimation
      and simulation branches.
      </description>
    </change>

    <change id="18B-2i">
      <title>Remove MONOLITH NOTE comment block</title>
      <description>
      DELETE the seam comments at lines 88–98. After this cleanup, estimate.R will be
      ~150 lines and no longer a monolith.
      </description>
    </change>
  </changes>

  <expected_result>
  estimate.R should be approximately 150 lines with this structure:
  ```r
  estimate <- function(if_estimate, if_estimate_simulation, file.output.list,
                       dlvdsgn, estimate.input.list,
                       DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list,
                       sitedata, numsites,
                       if_validate, Vsites.list, vsitedata, subdata,
                       classvar, betavalues) {
    ifHess <- estimate.input.list$ifHess
    yieldFactor <- estimate.input.list$yieldFactor
    estimate.list <- NULL

    if (if_estimate == "yes" & if_estimate_simulation == "no") {
      # 1. Optimize
      sparrowEsts <- estimateOptimize(...)
      # 2. Compute metrics
      estimate.metrics.list <- estimateNLLSmetrics(...)
      # 3. Unpack
      JacobResults <- ...
      estimate.list <- named.list(sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list)
      # 4. Optional validation
      if (if_validate == "yes") {
        validate.metrics.list <- validateMetrics(...)
        estimate.list <- named.list(..., vANOVA.list, vMdiagnostics.list)
      }
    } else if (if_estimate_simulation == "yes") {
      # Simulation mode with starting values
      sparrowEsts <- ...
      if (sum(nn) > 0) {
        sparrowEsts$resid <- estimateFevalNoadj(...)
        estimate.metrics.list <- estimateNLLSmetrics(...)
        estimate.list <- named.list(...)
      } else {
        # No monitoring loads — store starting values only
        JacobResults <- ...
        estimate.list <- named.list(sparrowEsts, JacobResults)
      }
    }

    return(estimate.list)
  }
  ```
  </expected_result>
</task>

---

## Task 3: Update controlFileTasksModel.R

<task id="18B-3">
  <title>Slim controlFileTasksModel.R signature and remove diagnostic dispatch</title>
  <description>
  Remove the diagnosticSpatialAutoCorr call (Section B), slim the function signature
  to match what's actually used, update the estimate() call to match its new signature,
  and remove run time tracking from the return value.
  </description>

  <changes>
    <change id="18B-3a">
      <title>Slim function signature</title>
      <description>
      Remove parameters that only fed estimate()'s diagnostic calls or
      diagnosticSpatialAutoCorr:

      REMOVE from signature:
      - Cor.ExplanVars.list (permanently NA)
      - min.sites.list (only fed diagnosticSpatialAutoCorr)
      - sitedata.landuse (permanently NA)
      - vsitedata.landuse (permanently NA)
      - sitedata.demtarea.class (only fed estimate's diagnostic calls)
      - vsitedata.demtarea.class (only fed estimate's diagnostic calls)
      - data_names (only fed estimate's diagnostic calls)
      - add_vars (only fed estimate's diagnostic calls)
      - mapping.input.list (only fed diagnostic calls; scenario code builds its own)

      WAIT — check if mapping.input.list is used elsewhere in controlFileTasksModel.R:
      - Line 149: `master_map_list <- mapping.input.list$master_map_list` — feeds scenario check
      - Line 150: `output_map_type <- mapping.input.list$output_map_type` — feeds predictScenarios
      - Lines 349–362: passed to predictScenarios()

      KEEP mapping.input.list in the signature. It IS used by scenarios.

      Also check add_vars: line 360 passes it to predictScenarios(). KEEP add_vars.
      Also check data_names: line 354 passes it to predictScenarios(). KEEP data_names.

      FINAL parameters to REMOVE from signature (7):
      - Cor.ExplanVars.list
      - min.sites.list
      - sitedata.landuse
      - vsitedata.landuse
      - sitedata.demtarea.class
      - vsitedata.demtarea.class
      - minimum_reaches_separating_sites (not used in controlFileTasksModel itself)

      WAIT — check minimum_reaches_separating_sites: it's not directly used in
      controlFileTasksModel.R, only passed through to estimate(). Since estimate() no
      longer needs it, remove it.
      </description>
    </change>

    <change id="18B-3b">
      <title>Remove Section B: diagnosticSpatialAutoCorr</title>
      <description>
      DELETE lines 168–203 (the entire Section B block):
      ```r
      ######################
      ### B. DIAGNOSTICS ###
      ######################

      if (if_spatialAutoCorr == "yes") {
        ...
        diagnosticSpatialAutoCorr(...)
        ...
      }
      ```
      This diagnostic is now available on-demand via plot(model, type="spatial").
      Also DELETE line 144: `if_spatialAutoCorr <- estimate.input.list$if_spatialAutoCorr`
      (no longer needed).
      </description>
    </change>

    <change id="18B-3c">
      <title>Update estimate() call</title>
      <description>
      Update the estimate() call at lines 153–165 to match the new slimmed signature:

      NEW call:
      ```r
      estimate.list <- estimate(
        if_estimate, if_estimate_simulation, file.output.list,
        dlvdsgn, estimate.input.list,
        DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list,
        sitedata, numsites,
        if_validate, Vsites.list, vsitedata, subdata,
        classvar = class.input.list$classvar, betavalues
      )
      ```
      </description>
    </change>

    <change id="18B-3d">
      <title>Update return value</title>
      <description>
      Remove boot/map run times from return value. Change:
      ```r
      runTimes <- named.list(BootEstRunTime, BootPredictRunTime, MapPredictRunTime,
                             estimate.list, predict.list, predictBoots.list)
      ```
      To:
      ```r
      runTimes <- named.list(estimate.list, predict.list, predictBoots.list)
      ```
      Also DELETE the BootEstRunTime/BootPredictRunTime/MapPredictRunTime timing
      variables and proc.time() calls throughout the function (lines 212–213, 240,
      281, 311, 334, 337).
      </description>
    </change>

    <change id="18B-3e">
      <title>Remove unused variable extractions</title>
      <description>
      DELETE lines that extract variables no longer used:
      - Line 138: `path_master <- file.output.list$path_master`
      - Line 139: `path_main <- file.output.list$path_main`
      - Line 141: `runScript <- file.output.list$runScript`
      - Line 142: `run2 <- file.output.list$run2`
      - Line 145: `diagnosticPlots_timestep <- estimate.input.list$diagnosticPlots_timestep`

      Verify each is not used elsewhere in the function before removing.
      </description>
    </change>
  </changes>
</task>

---

## Task 4: Update startModelRun.R

<task id="18B-4">
  <title>Update controlFileTasksModel() call in startModelRun.R</title>
  <description>
  Update the controlFileTasksModel() call (lines 348–380) to match its slimmed signature.
  Remove parameters that were removed from the signature in Task 3.
  </description>

  <changes>
    <change id="18B-4a">
      <title>Update controlFileTasksModel() call</title>
      <description>
      Remove from the call site at lines 348–380:
      - `Cor.ExplanVars.list,` (line 361)
      - `min.sites.list,` (line 363; also note: min.sites.list was never defined in
        startModelRun.R — check if it exists. If not, the code may error before this
        fix; this removal prevents that.)
      - `sitedata.landuse, vsitedata.landuse, sitedata.demtarea.class,` (line 370)
      - `vsitedata.demtarea.class,` (line 371)
      - `minimum_reaches_separating_sites,` (line 364)

      Also remove corresponding stubs from 18A if they're no longer passed downstream:
      - `Cor.ExplanVars.list <- NA` can remain (harmless local variable)
      - `sitedata.landuse <- NA` and `vsitedata.landuse <- NA` stubs can be removed since
        they're no longer passed to controlFileTasksModel
      </description>
    </change>

    <change id="18B-4b">
      <title>Update return value handling</title>
      <description>
      If the return value from controlFileTasksModel changed (no more run times),
      update the code that accesses runTimes (lines 386–399 were already deleted in 18A).
      Verify lines 414–416 still work:
      ```r
      estimate.list <- runTimes$estimate.list
      sparrow_state$estimate.list <- estimate.list
      sparrow_state$predict.list  <- runTimes$predict.list
      ```
      These should still work since named.list preserves the names.
      </description>
    </change>
  </changes>
</task>

---

## Task 5: Add estimateNLLStable to write_rsparrow_results

<task id="18B-5">
  <title>Add estimateNLLStable() call to write_rsparrow_results()</title>
  <description>
  The estimateNLLStable() function produces summary text/CSV output of estimation results.
  It was removed from estimate.R (Task 2c) but should still be available when the user
  explicitly requests file output via write_rsparrow_results(model, path, what="estimates").
  </description>

  <changes>
    <change id="18B-5a">
      <title>Add estimateNLLStable call in the "estimates" section</title>
      <description>
      In write_rsparrow_results.R, inside the `if ("estimates" %in% what)` block
      (currently lines 56–75), add a call to estimateNLLStable() BEFORE the existing
      predictSummaryOutCSV() call.

      Add approximately:
      ```r
      # Write NLLS summary table
      if (!is.null(estimate.list$ANOVA.list)) {
        classvar_val <- model$data$classvar
        if (identical(classvar_val, NA_character_)) classvar_val <- "sitedata.demtarea.class"
        sitedata <- model$data$sitedata
        numsites <- if (!is.null(sitedata)) nrow(sitedata) else 0L
        betavalues <- model$data$estimate.list$sparrowEsts$coefficients
        # Build minimal betavalues if needed
        if (is.null(betavalues)) betavalues <- model$coefficients

        estimateNLLStable(
          fol, if_estimate = "yes", if_estimate_simulation = "no",
          ifHess = if (!is.null(estimate.list$HesResults)) "yes" else "no",
          if_sparrowEsts = 1L,
          classvar = classvar_val, sitedata = sitedata, numsites = numsites,
          estimate.list = estimate.list,
          Cor.ExplanVars.list = NA,
          if_validate = if (!is.null(estimate.list$vANOVA.list)) "yes" else "no",
          vANOVA.list = estimate.list$vANOVA.list,
          vMdiagnostics.list = estimate.list$vMdiagnostics.list,
          betavalues = betavalues,
          Csites.weights.list = model$data$Csites.weights.list
        )
        written <- c(written,
          file.path(path, "estimate", paste0(run_id, "_summary.txt")))
      }
      ```

      NOTE: Review estimateNLLStable() to understand what file.output.list fields it
      needs (path_results, run_id at minimum). The `fol` variable built at line 40 should
      have these.
      </description>
    </change>
  </changes>
</task>

---

## Task 6: Remove sf from DESCRIPTION Suggests

<task id="18B-6">
  <title>Remove sf from Suggests</title>
  <description>
  All sf::st_write blocks in estimate.R are now removed. If sf is not used anywhere
  else in R/, remove it from Suggests.
  </description>

  <subtasks>
    <subtask id="18B-6a">
      Verify: `grep -rn "sf::" R/*.R` — should return zero hits after estimate.R cleanup.
      If there are other uses (e.g., in predictScenarios), keep sf.
    </subtask>
    <subtask id="18B-6b">
      If zero remaining sf:: references in R/, remove from DESCRIPTION:
      ```
      sf (>= 0.9-6),
      ```
      After removal, Suggests should be (5 packages):
      ```
      Suggests:
          car (>= 3.0-10),
          knitr (>= 1.30),
          rmarkdown (>= 2.5),
          spdep (>= 1.1-5),
          testthat (>= 3.0.0)
      ```
    </subtask>
  </subtasks>
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
    <expected>All tests pass (FAIL 0)</expected>
  </step>
  <step id="v4">
    <title>Verify plot.rsparrow still works</title>
    <command>
    R_LIBS=/home/kp/R/libs Rscript -e "
      library(rsparrow)
      model <- rsparrow_model(sparrow_example\$reaches, sparrow_example\$parameters,
                               sparrow_example\$design_matrix, sparrow_example\$data_dictionary)
      pdf('/dev/null')
      plot(model, type='residuals')
      plot(model, type='sensitivity')
      dev.off()
      cat('plot.rsparrow works\n')
    "
    </command>
    <expected>No errors; "plot.rsparrow works" printed</expected>
  </step>
  <step id="v5">
    <title>Verify write_rsparrow_results still works</title>
    <command>
    R_LIBS=/home/kp/R/libs Rscript -e "
      library(rsparrow)
      model <- rsparrow_model(sparrow_example\$reaches, sparrow_example\$parameters,
                               sparrow_example\$design_matrix, sparrow_example\$data_dictionary)
      files <- write_rsparrow_results(model, tempdir(), what='estimates')
      cat('Written:', files, sep='\n')
    "
    </command>
    <expected>Files written including summary output from estimateNLLStable</expected>
  </step>
  <step id="v6">
    <title>Verify estimate.R line count</title>
    <command>wc -l R/estimate.R</command>
    <expected>~150 lines (down from ~698)</expected>
  </step>
  <step id="v7">
    <title>Verify no sf references remain</title>
    <command>grep -rn "sf::" R/*.R</command>
    <expected>Zero hits (if sf was fully removed)</expected>
  </step>
</verification>

---

## Success Criteria

<success_criteria>
  <criterion>estimate.R is ~150 lines of pure computation (no plotting, no file I/O)</criterion>
  <criterion>diagnosticPlotsNLLS.R archived to inst/archived/diagnostics/</criterion>
  <criterion>controlFileTasksModel.R Section B (diagnosticSpatialAutoCorr) removed</criterion>
  <criterion>estimate() signature reduced from 26 to ~17 parameters</criterion>
  <criterion>controlFileTasksModel() signature reduced by 7 parameters</criterion>
  <criterion>estimateNLLStable() available through write_rsparrow_results()</criterion>
  <criterion>sf removed from Suggests (if no other R/ usage)</criterion>
  <criterion>plot(model, type="residuals") still works (calls 4panel A/B directly)</criterion>
  <criterion>plot(model, type="sensitivity") still works</criterion>
  <criterion>plot(model, type="spatial") still works</criterion>
  <criterion>R CMD check: 0 errors, 0 warnings</criterion>
  <criterion>All tests pass</criterion>
</success_criteria>

---

## Important Notes for Implementation

<implementation_notes>
  <note>
  The predict_sparrow() call at the end of estimate.R (lines 673–693) is a DUPLICATE
  of the call in controlFileTasksModel.R lines 298–301. The one in controlFileTasksModel
  is the live call that actually returns predict.list. The one in estimate.R assigns to a
  local predict.list that is never returned (estimate.R returns estimate.list). Safe to remove.
  </note>
  <note>
  When removing the legacy load-from-file branch (lines 412–443), be careful about the
  `else` structure. The current structure is:
  ```
  if (if_estimate == "yes" & if_estimate_simulation == "no") { ... }
  else { ... legacy load + simulation mode ... }
  ```
  The simulation mode (if_estimate_simulation == "yes") is INSIDE the else branch.
  After removing the legacy load-from-file code, restructure as:
  ```
  if (if_estimate == "yes" & if_estimate_simulation == "no") { ... }
  else if (if_estimate_simulation == "yes") { ... }
  ```
  </note>
  <note>
  The simulation mode path (starting at line 449) needs to keep the estimateFevalNoadj()
  and estimateNLLSmetrics() calls — these are computation. Only remove the diagnostic
  plotting and shapefile writing from the simulation path.
  </note>
  <note>
  estimateNLLStable() uses sink() to capture output. It writes to files using the
  path_results from file.output.list. Make sure the fol (file.output.list) passed in
  write_rsparrow_results() has the correct path_results set to the user's output path.
  Review estimateNLLStable.R to confirm what fields it reads from file.output.list.
  </note>
  <note>
  After removing the diagnostic calls from estimate.R, the variables Obs, predict,
  xlat, xlon, standardResids, ratio.obs.pred, etc. that were extracted from
  Mdiagnostics.list for use in shapefile/plot construction are no longer needed.
  They may be defined inside estimateNLLSmetrics() and returned in Mdiagnostics.list,
  which is fine — they stay in the return value for plot.rsparrow() to use.
  </note>
  <note>
  Commit message convention: `Co-Authored-By: Claude` (no email, no angle brackets).
  </note>
</implementation_notes>
