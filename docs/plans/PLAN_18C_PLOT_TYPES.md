# Plan 18C: Enhance plot.rsparrow with Diagnostic Plot Types

<plan_metadata>
  <id>18C</id>
  <title>Enhance plot.rsparrow with Diagnostic Plot Types</title>
  <parent>Plan 18: Strip Side Effects and Dead Code from Core Workflow</parent>
  <depends_on>Plan 18B (diagnosticPlotsNLLS archived, estimate.R cleaned)</depends_on>
  <blocked_by>18B</blocked_by>
  <blocks>18D</blocks>
</plan_metadata>

## Objective

<objective>
Surface the most useful diagnostic plots from the archived diagnosticPlotsNLLS as new
on-demand `type=` options in plot.rsparrow(). Add bootstrap and validation plot support.
After this plan, plot.rsparrow() supports 8 types (up from 3): residuals, sensitivity,
spatial, simulation, class, ratio, validation, bootstrap.
</objective>

---

## Context

<context>
After Plan 18B:
- diagnosticPlotsNLLS.R is archived — its plots are no longer produced during estimation
- plot.rsparrow() currently supports 3 types: "residuals", "sensitivity", "spatial"
- The diagnostic data needed for all plots is stored in the model object:
  - model$data$estimate.list$Mdiagnostics.list (estimation diagnostics)
  - model$data$estimate.list$vMdiagnostics.list (validation diagnostics, if available)
  - model$data$estimate.list$Mdiagnostics.list$ppredict, pResids, pratio.obs.pred (simulation)
  - model$data$sitedata, model$data$classvar (classification data)
  - model$bootstrap (bootstrap results, if available)
  - model$validation (validation results, if available)

Existing internal helpers available for reuse:
- diagnosticPlots_4panel_A(predict, Obs, yldpredict, yldobs, Resids, plotclass, plotTitles,
    loadUnits, yieldUnits, filterClass)
- diagnosticPlots_4panel_B(Resids, ratio.obs.pred, standardResids, predict, plotTitles, loadUnits)
</context>

---

## Task 1: Add type="simulation" Plot

<task id="18C-1">
  <title>Add simulation performance panels to plot.rsparrow()</title>
  <description>
  Simulation (unconditioned) performance shows model predictions WITHOUT monitoring-load
  adjustment. This is essential for understanding predictive skill at unmonitored reaches.
  Produces 4-panel A (obs vs pred load/yield, residuals) + 4-panel B (boxplots, Q-Q).
  </description>

  <implementation>
    <file>R/plot.rsparrow.R</file>
    <helper_name>.rsparrow_plot_simulation</helper_name>
    <data_source>
    Uses Mdiagnostics.list$ppredict, $pyldpredict, $pyldobs, $pResids, $pratio.obs.pred, $Obs
    (same fields used by archived diagnosticPlotsNLLS.R lines 232–254)
    </data_source>
    <code_template>
    ```r
    .rsparrow_plot_simulation <- function(x, panel = c("A", "B", "both"), ...) {
      panel <- match.arg(panel)
      d  <- x$data
      Md <- d$estimate.list$Mdiagnostics.list
      mp <- d$mapping.input.list

      if (panel %in% c("A", "both")) {
        diagnosticPlots_4panel_A(
          Md$ppredict, Md$Obs, Md$pyldpredict, Md$pyldobs, Md$pResids,
          plotclass = NA,
          plotTitles = c(
            "MODEL SIMULATION PERFORMANCE\nObserved vs Predicted Load",
            "MODEL SIMULATION PERFORMANCE\nObserved vs Predicted Yield",
            "Residuals vs Predicted Load",
            "Residuals vs Predicted Yield"
          ),
          loadUnits = mp$loadUnits, yieldUnits = mp$yieldUnits, filterClass = NA
        )
      }
      if (panel %in% c("B", "both")) {
        diagnosticPlots_4panel_B(
          Md$pResids, Md$pratio.obs.pred, NA, Md$ppredict,
          plotTitles = c(
            "MODEL SIMULATION PERFORMANCE\nResiduals",
            "MODEL SIMULATION PERFORMANCE\nObserved / Predicted Ratio",
            "Normal Q-Q Plot",
            "Squared Residuals vs Predicted Load"
          ),
          loadUnits = mp$loadUnits
        )
      }
      invisible(NULL)
    }
    ```
    </code_template>
  </implementation>
</task>

---

## Task 2: Add type="class" Plot

<task id="18C-2">
  <title>Add by-class diagnostic panels to plot.rsparrow()</title>
  <description>
  4-panel A faceted by each classvar group level. Shows obs vs pred within classification
  groups (typically drainage-area deciles). Helps identify whether the model fits well
  across all watershed types.
  </description>

  <implementation>
    <file>R/plot.rsparrow.R</file>
    <helper_name>.rsparrow_plot_class</helper_name>
    <data_source>
    Uses Mdiagnostics.list$predict, $Obs, $yldpredict, $yldobs, $Resids
    Uses sitedata[[classvar]] for classification groups
    (same logic as archived diagnosticPlotsNLLS.R lines 209–223)
    </data_source>
    <code_template>
    ```r
    .rsparrow_plot_class <- function(x, ...) {
      d  <- x$data
      Md <- d$estimate.list$Mdiagnostics.list
      mp <- d$mapping.input.list
      classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar

      # Build class matrix from sitedata
      sitedata <- d$sitedata
      class_vals <- as.numeric(sitedata[[classvar[1]]])
      grp <- sort(unique(class_vals[!is.na(class_vals)]))

      for (i in seq_along(grp)) {
        nsites_i <- sum(!is.na(class_vals) & class_vals == grp[i])
        diagnosticPlots_4panel_A(
          Md$predict, Md$Obs, Md$yldpredict, Md$yldobs, Md$Resids,
          plotclass = class_vals,
          plotTitles = c(
            paste0("Observed vs Predicted Load\nClass = ", grp[i], " (n=", nsites_i, ")"),
            "Observed vs Predicted Yield",
            "Residuals vs Predicted Load",
            "Residuals vs Predicted Yield"
          ),
          loadUnits = mp$loadUnits, yieldUnits = mp$yieldUnits,
          filterClass = as.double(grp[i])
        )
      }
      invisible(NULL)
    }
    ```
    </code_template>
  </implementation>
</task>

---

## Task 3: Add type="ratio" Plot

<task id="18C-3">
  <title>Add obs/pred ratio diagnostics to plot.rsparrow()</title>
  <description>
  Boxplots of observed/predicted ratio by drainage area deciles and by classvar.
  Quick visual check for systematic bias across watershed size or type.
  </description>

  <implementation>
    <file>R/plot.rsparrow.R</file>
    <helper_name>.rsparrow_plot_ratio</helper_name>
    <data_source>
    Uses Mdiagnostics.list$ratio.obs.pred, sitedata.demtarea.class, sitedata[[classvar]]
    (same logic as archived diagnosticPlotsNLLS.R lines 162–177)
    </data_source>
    <code_template>
    ```r
    .rsparrow_plot_ratio <- function(x, ...) {
      d  <- x$data
      Md <- d$estimate.list$Mdiagnostics.list
      classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar
      sitedata <- d$sitedata

      # Drainage area deciles
      sitedata.demtarea.class <- sitedata$demtarea  # or use calcDemtareaClass if available
      # Use calcDemtareaClass to get proper decile classes
      demtarea.class <- calcDemtareaClass(sitedata$demtarea)
      boxplot(Md$ratio.obs.pred ~ demtarea.class,
              xlab = "Upper Bound for Total Drainage Area Deciles (km\u00B2)",
              ylab = "Observed to Predicted Ratio",
              main = "Ratio Obs/Pred by Drainage Area Deciles",
              las = 2, cex.axis = 0.7, col = "white", border = "black", log = "y")
      abline(h = 1, col = "red", lty = 2, lwd = 1.5)

      # By classvar (if different from demtarea)
      if (!identical(classvar[1], "sitedata.demtarea.class")) {
        for (k in seq_along(classvar)) {
          vvar <- as.numeric(sitedata[[classvar[k]]])
          boxplot(Md$ratio.obs.pred ~ vvar,
                  xlab = classvar[k],
                  ylab = "Observed to Predicted Ratio",
                  main = "Ratio Observed to Predicted",
                  las = 2, cex.axis = 0.7, col = "white", border = "black", log = "y")
          abline(h = 1, col = "red", lty = 2, lwd = 1.5)
        }
      }
      invisible(NULL)
    }
    ```
    </code_template>
  </implementation>
</task>

---

## Task 4: Add type="validation" Plot

<task id="18C-4">
  <title>Add validation performance panels to plot.rsparrow()</title>
  <description>
  Same as simulation panels but using vMdiagnostics.list (validation site data).
  Only available after rsparrow_validate() has been called (model$validation exists).
  Guard with an informative error if validation data is not available.
  </description>

  <implementation>
    <file>R/plot.rsparrow.R</file>
    <helper_name>.rsparrow_plot_validation</helper_name>
    <data_source>
    Uses estimate.list$vMdiagnostics.list$ppredict, $pyldpredict, $pyldobs, $pResids, $pratio.obs.pred, $Obs
    </data_source>
    <code_template>
    ```r
    .rsparrow_plot_validation <- function(x, panel = c("A", "B", "both"), ...) {
      panel <- match.arg(panel)
      d  <- x$data
      vMd <- d$estimate.list$vMdiagnostics.list
      if (is.null(vMd)) {
        stop("Validation diagnostics not available. Run rsparrow_model() with if_validate=TRUE ",
             "or call rsparrow_validate() first.", call. = FALSE)
      }
      mp <- d$mapping.input.list

      if (panel %in% c("A", "both")) {
        diagnosticPlots_4panel_A(
          vMd$ppredict, vMd$Obs, vMd$pyldpredict, vMd$pyldobs, vMd$pResids,
          plotclass = NA,
          plotTitles = c(
            "MODEL VALIDATION PERFORMANCE\nObserved vs Predicted Load",
            "MODEL VALIDATION PERFORMANCE\nObserved vs Predicted Yield",
            "Residuals vs Predicted Load",
            "Residuals vs Predicted Yield"
          ),
          loadUnits = mp$loadUnits, yieldUnits = mp$yieldUnits, filterClass = NA
        )
      }
      if (panel %in% c("B", "both")) {
        diagnosticPlots_4panel_B(
          vMd$pResids, vMd$pratio.obs.pred, NA, vMd$ppredict,
          plotTitles = c(
            "MODEL VALIDATION PERFORMANCE\nResiduals",
            "MODEL VALIDATION PERFORMANCE\nObserved / Predicted Ratio",
            "Normal Q-Q Plot",
            "Squared Residuals vs Predicted Load"
          ),
          loadUnits = mp$loadUnits
        )
      }
      invisible(NULL)
    }
    ```
    </code_template>
  </implementation>
</task>

---

## Task 5: Add type="bootstrap" Plot

<task id="18C-5">
  <title>Add bootstrap coefficient uncertainty plot to plot.rsparrow()</title>
  <description>
  Histogram or density of bootstrap coefficient distributions with confidence intervals.
  Only available after rsparrow_bootstrap() has been called.
  Guard with an informative error if bootstrap data is not available.
  </description>

  <implementation>
    <file>R/plot.rsparrow.R</file>
    <helper_name>.rsparrow_plot_bootstrap</helper_name>
    <data_source>
    Uses model$bootstrap (populated by rsparrow_bootstrap()).
    The bootstrap results contain BootResults with coefficient distributions.
    Check the structure: likely BootResults$bootBetaest (matrix: biters × ncoef).
    </data_source>
    <code_template>
    ```r
    .rsparrow_plot_bootstrap <- function(x, ...) {
      boot <- x$bootstrap
      if (is.null(boot)) {
        stop("Bootstrap results not available. Call rsparrow_bootstrap() first.",
             call. = FALSE)
      }

      # Extract bootstrap coefficient matrix
      # Structure depends on estimateBootstraps.R return value
      # Typically: boot$BootBetaest (matrix: biters × ncoef)
      # and boot$Parmnames for parameter names
      boot_beta <- boot$BootBetaest
      parm_names <- boot$Parmnames
      if (is.null(boot_beta) || is.null(parm_names)) {
        stop("Bootstrap coefficient data not found in expected format.", call. = FALSE)
      }

      ncoef <- ncol(boot_beta)
      # Layout: arrange panels for each coefficient
      nr <- ceiling(sqrt(ncoef))
      nc <- ceiling(ncoef / nr)
      op <- par(mfrow = c(nr, nc), mar = c(4, 4, 3, 1))
      on.exit(par(op))

      for (j in seq_len(ncoef)) {
        vals <- boot_beta[, j]
        vals <- vals[is.finite(vals)]
        if (length(vals) < 2) next
        ci <- quantile(vals, c(0.025, 0.975))
        hist(vals,
             main = parm_names[j],
             xlab = "Coefficient Value",
             col = "lightblue", border = "white",
             breaks = 30)
        abline(v = ci, col = "red", lty = 2, lwd = 1.5)
        abline(v = mean(vals), col = "blue", lwd = 2)
        legend("topright", legend = c("Mean", "95% CI"),
               col = c("blue", "red"), lty = c(1, 2), lwd = c(2, 1.5),
               cex = 0.7, bg = "white")
      }
      invisible(NULL)
    }
    ```
    NOTE: The exact structure of model$bootstrap needs to be verified by reading
    rsparrow_bootstrap.R and estimateBootstraps.R. The template above is approximate.
    Adjust field names (BootBetaest, Parmnames) to match the actual structure.
    </code_template>
  </implementation>
</task>

---

## Task 6: Update plot.rsparrow() Dispatcher

<task id="18C-6">
  <title>Update the main dispatcher to include all 8 types</title>
  <description>
  Update the plot.rsparrow() function to accept and dispatch all 8 types.
  Update the roxygen documentation to describe the new types.
  </description>

  <changes>
    <change id="18C-6a">
      <title>Update dispatcher</title>
      <location>R/plot.rsparrow.R, lines 34–41</location>
      <description>
      Replace the current dispatcher:
      ```r
      plot.rsparrow <- function(x, type = c("residuals", "sensitivity", "spatial"), ...) {
        type <- match.arg(type)
        switch(type,
          residuals   = .rsparrow_plot_residuals(x, ...),
          sensitivity = .rsparrow_plot_sensitivity(x, ...),
          spatial     = .rsparrow_plot_spatial(x, ...)
        )
      }
      ```
      With:
      ```r
      plot.rsparrow <- function(x, type = c("residuals", "sensitivity", "spatial",
                                             "simulation", "class", "ratio",
                                             "validation", "bootstrap"), ...) {
        type <- match.arg(type)
        switch(type,
          residuals   = .rsparrow_plot_residuals(x, ...),
          sensitivity = .rsparrow_plot_sensitivity(x, ...),
          spatial     = .rsparrow_plot_spatial(x, ...),
          simulation  = .rsparrow_plot_simulation(x, ...),
          class       = .rsparrow_plot_class(x, ...),
          ratio       = .rsparrow_plot_ratio(x, ...),
          validation  = .rsparrow_plot_validation(x, ...),
          bootstrap   = .rsparrow_plot_bootstrap(x, ...)
        )
      }
      ```
      </description>
    </change>

    <change id="18C-6b">
      <title>Update roxygen documentation</title>
      <description>
      Update the @param type description to list all 8 types with brief descriptions:
      ```r
      #' @param type Character. One of:
      #'   \itemize{
      #'     \item \code{"residuals"} — Estimation residual panels (4-panel A/B)
      #'     \item \code{"sensitivity"} — Parameter sensitivity analysis
      #'     \item \code{"spatial"} — Spatial autocorrelation of residuals
      #'     \item \code{"simulation"} — Simulation (unconditioned) performance panels
      #'     \item \code{"class"} — By-class (classvar group) diagnostic panels
      #'     \item \code{"ratio"} — Obs/pred ratio by drainage area and classvar
      #'     \item \code{"validation"} — Validation performance panels (requires validation data)
      #'     \item \code{"bootstrap"} — Bootstrap coefficient uncertainty (requires bootstrap data)
      #'   }
      ```
      </description>
    </change>
  </changes>
</task>

---

## Task 7: Add Tests

<task id="18C-7">
  <title>Add tests for new plot types</title>
  <description>
  Add tests in tests/testthat/ for each new plot type. Since plot functions produce
  graphical output, tests should verify they run without error (wrap in pdf()/dev.off()).
  </description>

  <implementation>
    <file>tests/testthat/test-plot-types.R (new file)</file>
    <test_cases>
      <test name="simulation plot produces output">
        Build model, call plot(model, type="simulation") inside pdf()/dev.off(), expect no error.
      </test>
      <test name="simulation plot accepts panel argument">
        Test panel="A", panel="B", panel="both".
      </test>
      <test name="class plot produces output">
        Build model, call plot(model, type="class") inside pdf()/dev.off(), expect no error.
      </test>
      <test name="ratio plot produces output">
        Build model, call plot(model, type="ratio") inside pdf()/dev.off(), expect no error.
      </test>
      <test name="validation plot errors without validation data">
        Build model without validation, expect_error(plot(model, type="validation"),
        "Validation diagnostics not available").
      </test>
      <test name="validation plot works with validation data">
        Build model with if_validate=TRUE, call plot(model, type="validation"), expect no error.
        NOTE: This requires the sparrow_example dataset to have vdepvar column. If not
        available, skip this test.
      </test>
      <test name="bootstrap plot errors without bootstrap data">
        Build model without bootstrap, expect_error(plot(model, type="bootstrap"),
        "Bootstrap results not available").
      </test>
    </test_cases>
  </implementation>
</task>

---

## Task 8: Rebuild Roxygen Documentation

<task id="18C-8">
  <title>Rebuild roxygen docs to update man/plot.rsparrow.Rd</title>
  <description>
  Run roxygen2::roxygenise() to regenerate the man page for plot.rsparrow with
  the updated type parameter documentation.
  </description>

  <subtasks>
    <subtask id="18C-8a">
      Run: R_LIBS=/home/kp/R/libs Rscript -e "roxygen2::roxygenise('.')"
    </subtask>
    <subtask id="18C-8b">
      Verify man/plot.rsparrow.Rd was updated with new type descriptions.
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
    <expected>All tests pass including new plot type tests</expected>
  </step>
  <step id="v4">
    <title>Verify all new plot types work</title>
    <command>
    R_LIBS=/home/kp/R/libs Rscript -e "
      library(rsparrow)
      model <- rsparrow_model(sparrow_example\$reaches, sparrow_example\$parameters,
                               sparrow_example\$design_matrix, sparrow_example\$data_dictionary)
      pdf('/tmp/rsparrow_plots_18C.pdf')
      plot(model, type='residuals')
      plot(model, type='sensitivity')
      plot(model, type='simulation')
      plot(model, type='class')
      plot(model, type='ratio')
      dev.off()
      cat('All plot types work\n')
    "
    </command>
    <expected>PDF created with all plot types; no errors</expected>
  </step>
  <step id="v5">
    <title>Verify error messages for missing data</title>
    <command>
    R_LIBS=/home/kp/R/libs Rscript -e "
      library(rsparrow)
      model <- rsparrow_model(sparrow_example\$reaches, sparrow_example\$parameters,
                               sparrow_example\$design_matrix, sparrow_example\$data_dictionary)
      tryCatch(plot(model, type='validation'), error = function(e) cat('validation error OK:', e\$message, '\n'))
      tryCatch(plot(model, type='bootstrap'), error = function(e) cat('bootstrap error OK:', e\$message, '\n'))
    "
    </command>
    <expected>Both produce informative error messages</expected>
  </step>
</verification>

---

## Success Criteria

<success_criteria>
  <criterion>plot.rsparrow() supports 8 types: residuals, sensitivity, spatial, simulation, class, ratio, validation, bootstrap</criterion>
  <criterion>Existing types (residuals, sensitivity, spatial) are unchanged</criterion>
  <criterion>New types produce clean base R graphics</criterion>
  <criterion>validation and bootstrap types guard with informative errors when data is missing</criterion>
  <criterion>Tests exist for each new type</criterion>
  <criterion>Roxygen man page updated</criterion>
  <criterion>R CMD check: 0 errors, 0 warnings</criterion>
  <criterion>All tests pass</criterion>
</success_criteria>

---

## Important Notes for Implementation

<implementation_notes>
  <note>
  Before implementing the bootstrap plot (Task 5), read rsparrow_bootstrap.R and
  estimateBootstraps.R to understand the exact structure of model$bootstrap. The field
  names (BootBetaest, Parmnames) in the template are approximate and need verification.
  </note>
  <note>
  The calcDemtareaClass() function (used in the ratio plot) should still be available
  in R/ after Plans 18A/18B — it was NOT archived. Verify it exists before using it.
  </note>
  <note>
  For the class plot, use sitedata from model$data$sitedata. The classvar defaults to
  "sitedata.demtarea.class" when model$data$classvar is NA_character_.
  </note>
  <note>
  All new helpers should follow the naming convention: .rsparrow_plot_* (dot-prefix
  for internal functions, consistent with existing helpers).
  </note>
  <note>
  The validation plot checks model$data$estimate.list$vMdiagnostics.list, NOT
  model$validation. The validation metrics are stored in estimate.list when
  if_validate="yes" is passed to rsparrow_model() or rsparrow_estimate().
  model$validation is populated by rsparrow_validate() which is a separate pathway.
  Check which one is appropriate or support both.
  </note>
  <note>
  Commit message convention: `Co-Authored-By: Claude` (no email, no angle brackets).
  </note>
</implementation_notes>
