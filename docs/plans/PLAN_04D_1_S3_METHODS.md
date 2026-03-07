<plan id="04-D-1">
<name>S3 Methods</name>
<part_of>Plan 04-D sub-session 1 of 4 — implements Task 8 from PLAN_04D_API_IMPLEMENTATION.md</part_of>
<previous_plans>04-A (tasks 1-3), 04-B (tasks 4-5), 04-C (tasks 6-7)</previous_plans>

<context>
Plans 04-A through 04-C complete:
  - 0 assign(.GlobalEnv) anywhere in RSPARROW_master/R/
  - 0 shell.exec / batch_mode references
  - Specification-string eval(parse()) eliminated from all 7 core math files
  - unPackList() removed from all non-REMOVE files
  - startModelRun() returns sparrow_state (named list)
  - controlFileTasksModel() returns list(runTimes, results)

This sub-session implements the 6 S3 method bodies.
These are independent of all internal SPARROW functions — only access object$field.
No real data files are required; a mock rsparrow object is sufficient for verification.

Note: %||% is NOT defined as a custom operator. DESCRIPTION requires R (>= 4.4.0), which
ships %||% in base R. Any package code can use it directly without definition or import.
</context>

<prerequisites>
- Plans 04-A, 04-B, 04-C all complete and verified
- R CMD check baseline: 0 errors before starting
- Confirm stubs exist:
    grep -r "Not yet implemented" RSPARROW_master/R/ | grep -E "print|summary|coef|residuals|vcov|plot"
</prerequisites>

<reference_documents>
Read before starting:
  docs/implementation/PLAN_04_SKELETON_IMPLEMENTATIONS.md  — implementation name="S3_methods"
  docs/plans/PLAN_04D_API_IMPLEMENTATION.md               — rsparrow_object_structure section
</reference_documents>

<scope>
<in_scope>
- Task 8: Implement 6 S3 method bodies in their respective files:
    print.rsparrow.R, summary.rsparrow.R, coef.rsparrow.R,
    residuals.rsparrow.R, vcov.rsparrow.R, plot.rsparrow.R
- Implement print.summary.rsparrow (in summary.rsparrow.R)
</in_scope>
<out_of_scope>
- rsparrow_model(), read_sparrow_data() — those are sub-sessions 04D-2 and 04D-3
- predict.rsparrow(), rsparrow_bootstrap/scenario/validate — sub-session 04D-4
- Diagnostic plot implementation in plot.rsparrow() — deferred to Plan 05
- Real data loading or CSV file I/O
</out_of_scope>
</scope>

<rsparrow_object_structure label="Fields accessed by S3 methods">
  $call           — match.call() from rsparrow_model()
  $coefficients   — named numeric vector (e.g., c(beta_N_atm=0.42, ...))
  $std_errors     — named numeric vector (same names as $coefficients)
  $vcov           — numeric matrix (npar x npar)
  $residuals      — numeric vector (weighted log residuals at calibration sites)
  $fitted_values  — numeric vector (predicted loads at calibration sites)
  $fit_stats      — list: R2, RMSE, npar, nobs, convergence (logical)
  $data           — list with $sitedata (data.frame) and other fields
  $predictions    — NULL initially
  $bootstrap      — NULL initially
  $validation     — NULL initially
  $metadata       — list: version, timestamp, run_id, model_type, path_main
</rsparrow_object_structure>

<tasks>

<task id="8a" priority="skipped">
<name>Add %||% to rsparrow-package.R — SKIPPED</name>
<reason>
DESCRIPTION requires R (>= 4.4.0). Base R 4.4.0 ships %||% natively, so no custom
definition is needed. Using the base R operator directly is preferable to shadowing it
with a package-local copy. Sub-sessions 04D-4 and later can use %||% without any change
to rsparrow-package.R.
</reason>
</task>

<task id="8b" priority="high">
<name>Implement print.rsparrow</name>
<file>RSPARROW_master/R/print.rsparrow.R</file>
<description>
Replace stop("Not yet implemented") with the implementation below.
Accesses: x$metadata, x$coefficients, x$fit_stats, x$data$sitedata.

Implementation:
  print.rsparrow <- function(x, digits = 4, ...) {
    cat("SPARROW Model (rsparrow ", as.character(x$metadata$version), ")\n", sep = "")
    cat("Run ID     :", x$metadata$run_id, "\n")
    cat("Model type :", x$metadata$model_type, "\n")
    cat("Parameters :", length(x$coefficients), "\n")
    cat("Cal. sites :", nrow(x$data$sitedata), "\n")
    cat("R-squared  :", round(x$fit_stats$R2, digits), "\n")
    cat("RMSE       :", round(x$fit_stats$RMSE, digits), "\n\n")
    cat("Coefficients:\n")
    print(round(x$coefficients, digits))
    invisible(x)
  }
</description>
<success>No stop("Not yet implemented") in file; print(mock_rsparrow) produces formatted output.</success>
</task>

<task id="8c" priority="high">
<name>Implement summary.rsparrow + print.summary.rsparrow</name>
<file>RSPARROW_master/R/summary.rsparrow.R</file>
<description>
Replace stop("Not yet implemented") with both functions below.
summary.rsparrow computes t-values and p-values from $coefficients / $std_errors.
print.summary.rsparrow formats a concise coefficient + fit-stats table.

Implementation:
  summary.rsparrow <- function(object, ...) {
    t_vals <- object$coefficients / object$std_errors
    p_vals <- 2 * stats::pt(-abs(t_vals),
                df = object$fit_stats$nobs - object$fit_stats$npar)
    coef_table <- data.frame(
      Estimate  = object$coefficients,
      Std.Error = object$std_errors,
      t.value   = t_vals,
      p.value   = p_vals,
      row.names = names(object$coefficients)
    )
    structure(
      list(
        call       = object$call,
        coef_table = coef_table,
        fit_stats  = object$fit_stats,
        metadata   = object$metadata
      ),
      class = "summary.rsparrow"
    )
  }

  print.summary.rsparrow <- function(x, digits = 4, ...) {
    cat("SPARROW Model Summary\n")
    cat("Run:", x$metadata$run_id, "  Type:", x$metadata$model_type, "\n\n")
    cat("Coefficients:\n")
    print(round(x$coef_table, digits))
    cat("\nFit Statistics:\n")
    cat("  R-squared:", round(x$fit_stats$R2, digits), "\n")
    cat("  RMSE:     ", round(x$fit_stats$RMSE, digits), "\n")
    cat("  N obs:    ", x$fit_stats$nobs, "\n")
    cat("  N par:    ", x$fit_stats$npar, "\n")
    invisible(x)
  }

Note: print.summary.rsparrow must also be registered as an S3 method. Add to NAMESPACE:
  S3method(print, summary.rsparrow)
Also add to man page (or use @export for print.summary.rsparrow).
</description>
<success>No stop("Not yet implemented") in file; summary(mock_rsparrow) returns summary.rsparrow object
that prints correctly.</success>
</task>

<task id="8d" priority="high">
<name>Implement coef.rsparrow, residuals.rsparrow, vcov.rsparrow</name>
<files>
  RSPARROW_master/R/coef.rsparrow.R
  RSPARROW_master/R/residuals.rsparrow.R
  RSPARROW_master/R/vcov.rsparrow.R
</files>
<description>
These are one-liners. Replace stop("Not yet implemented") in each:

  # coef.rsparrow.R
  coef.rsparrow <- function(object, ...) object$coefficients

  # residuals.rsparrow.R
  residuals.rsparrow <- function(object, ...) object$residuals

  # vcov.rsparrow.R
  vcov.rsparrow <- function(object, ...) object$vcov
</description>
<success>No stop("Not yet implemented") in any of the three files.</success>
</task>

<task id="8e" priority="medium">
<name>Implement plot.rsparrow (stub with informative message)</name>
<file>RSPARROW_master/R/plot.rsparrow.R</file>
<description>
Diagnostic plot infrastructure is deferred to Plan 05 (function consolidation).
Replace stop("Not yet implemented") with an informative stop message:

  plot.rsparrow <- function(x, type = "diagnostics", ...) {
    stop(
      "Diagnostic plots require Plan 05 (function consolidation). ",
      "Use summary(model) for fit statistics."
    )
  }

This is intentionally a stop() — plot.rsparrow is exported but not yet functional.
The stop message must be different from "Not yet implemented" so it passes grep checks.
</description>
<success>No "Not yet implemented" text in file; plot(mock_rsparrow) throws the informative message.</success>
</task>

</tasks>

<verification label="Run all checks after completing all tasks above">
<mock_scaffold>
Use this scaffold in an R session (no real data needed):

  library(rsparrow)
  mock_rsparrow <- structure(
    list(
      call         = quote(rsparrow_model("path")),
      coefficients = c(beta_N_atm = 0.42, beta_N_fert = 0.18, k_reach = 0.003),
      std_errors   = c(beta_N_atm = 0.05, beta_N_fert = 0.02, k_reach = 0.0005),
      vcov         = diag(c(0.0025, 0.0004, 0.00000025)),
      residuals    = rnorm(150, 0, 0.3),
      fitted_values = exp(rnorm(150, 3, 1)),
      fit_stats    = list(R2 = 0.87, RMSE = 0.31, npar = 3, nobs = 150,
                          convergence = TRUE),
      data         = list(sitedata = data.frame(waterid = 1:150)),
      predictions  = NULL, bootstrap = NULL, validation = NULL,
      metadata     = list(version = "2.1.0", run_id = "test_model",
                          model_type = "static", path_main = "/tmp",
                          timestamp = Sys.time())
    ),
    class = "rsparrow"
  )
  print(mock_rsparrow)           # should print formatted summary
  s <- summary(mock_rsparrow)    # should return summary.rsparrow object
  print(s)                       # should print coef table + fit stats
  coef(mock_rsparrow)            # should return named numeric vector (length 3)
  residuals(mock_rsparrow)       # should return numeric vector (length 150)
  vcov(mock_rsparrow)            # should return 3x3 diagonal matrix
</mock_scaffold>
<grep_checks label="All must return 0 results">
  grep -r "Not yet implemented" RSPARROW_master/R/print.rsparrow.R
  grep -r "Not yet implemented" RSPARROW_master/R/summary.rsparrow.R
  grep -r "Not yet implemented" RSPARROW_master/R/coef.rsparrow.R
  grep -r "Not yet implemented" RSPARROW_master/R/residuals.rsparrow.R
  grep -r "Not yet implemented" RSPARROW_master/R/vcov.rsparrow.R
  grep -r "Not yet implemented" RSPARROW_master/R/plot.rsparrow.R
</grep_checks>
<build_check>
  R CMD build --no-build-vignettes RSPARROW_master/
  R CMD check rsparrow_2.1.0.tar.gz
  # Must produce 0 new errors vs Plan 04-C baseline
</build_check>
</verification>

<risks>
<risk name="print.summary.rsparrow_not_registered">
  print.summary.rsparrow must be added to NAMESPACE as S3method(print, summary.rsparrow),
  otherwise print(summary(model)) dispatches to print.default and the custom formatting
  is never used. Check that the Rd file for summary.rsparrow lists @method print summary.rsparrow.
</risk>
<risk name="stats_pt_missing_import">
  summary.rsparrow() calls stats::pt(). stats is in base R and available without import,
  but use stats::pt() explicitly (not just pt()) to avoid CRAN NOTE about missing import.
</risk>
</risks>

<success_criteria>
- grep -r "Not yet implemented" RSPARROW_master/R/ | grep -E "print|summary|coef|residuals|vcov|plot" → 0 results
- All 5 S3 methods (print, summary, coef, residuals, vcov) dispatch correctly on mock object
- R CMD check introduces no new errors vs Plan 04-C baseline
</success_criteria>

<failure_criteria>
- Any of the 6 files still contains "Not yet implemented" → sub-session incomplete
- print(summary(mock)) dispatches to print.default → S3method(print, summary.rsparrow) missing from NAMESPACE
- R CMD check introduces new errors → fix before proceeding to 04D-2
</failure_criteria>

<next_session>04D-2: read_sparrow_data() implementation (LOW-MEDIUM complexity; independent of 04D-1)</next_session>

</plan>
