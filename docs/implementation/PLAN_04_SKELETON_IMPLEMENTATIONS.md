<skeleton_implementations>
<used_by>Plan 04-D (PLAN_04D_API_IMPLEMENTATION.md) — tasks 8-13</used_by>
<overview>
Pseudocode and implementation guidance for the 12 exported function stubs created in Plan 03.
All currently contain stop("Not yet implemented - see Plan 04: State Elimination").
rsparrow_hydseq() was already implemented in Plan 03 and requires no changes.
</overview>

<rsparrow_object_structure>
<description>
The rsparrow S3 object is the central data structure for the package. All exported functions
either create it (rsparrow_model) or accept and return it (predict, bootstrap, scenario, validate).
The structure maps to the output of the legacy estimate.list and predict.list objects.
</description>
<fields>
  $call           — matched call from match.call() in rsparrow_model()
  $coefficients   — named numeric vector; names from estimate.list$JacobResults$Parmnames,
                    values from estimate.list$JacobResults$oEstimate
  $std_errors     — named numeric; from estimate.list$JacobResults$oSEj  [VERIFIED 04D-3]
  $vcov           — numeric matrix; from estimate.list$HesResults$cov2   [VERIFIED 04D-3]
  $residuals      — numeric vector; from estimate.list$Mdiagnostics.list$Resids [VERIFIED]
  $fitted_values  — numeric vector; from estimate.list$Mdiagnostics.list$predict [VERIFIED]
  $fit_stats      — named list:
      $R2          from estimate.list$ANOVA.list$RSQ    [VERIFIED 04D-3; NOT JacobResults$R2]
      $RMSE        from estimate.list$ANOVA.list$RMSE   [VERIFIED 04D-3]
      $npar        length(coefficients)
      $nobs        nrow(sitedata)
      $convergence logical; !is.null(estimate.list$sparrowEsts)
  $data           — named list (all inputs needed for predict/bootstrap/scenario):
      $subdata            filtered reach data.frame (all reaches)
      $sitedata           calibration site subset of subdata
      $vsitedata          validation site subset (NULL if if_validate=FALSE)
      $DataMatrix.list    numeric matrices for optimization
      $SelParmValues      parameter config from parameters.csv
      $dlvdsgn            design matrix from design_matrix.csv
      $Csites.weights.list NLLS weights [CRITICAL — required by bootstrap/validate; from sparrow_state]
      $estimate.input.list settings: ifHess, s_offset, NLLS_weights, if_auto_scaling
      $scenario.input.list settings for scenario analysis
      $file.output.list   paths for output files
  $predictions    — NULL initially; populated by predict.rsparrow()
                    list with $load, $yield, $load_share, $scenarios (from predictScenarios),
                    $bootstrap (from predictBootstraps if run)
  $bootstrap      — NULL initially; populated by rsparrow_bootstrap()
                    list with bootstrap coefficient samples and uncertainty estimates
  $validation     — NULL initially; populated by rsparrow_validate()
  $metadata       — named list:
      $version     utils::packageVersion("rsparrow")
      $timestamp   Sys.time() at model run
      $run_id      character, from rsparrow_model() argument
      $model_type  "static" or "dynamic"
      $path_main   character, from rsparrow_model() argument
</fields>
<verify_field_names status="VERIFIED in Plan 04D-3">
All field names confirmed from live source code. Key corrections vs. original pseudocode:
  estimate.list is a named list with: sparrowEsts, JacobResults, HesResults, ANOVA.list,
  Mdiagnostics.list (and optionally ANOVAdynamic.list for dynamic models).
  Coefficients/SE are in JacobResults, not at top level of estimate.list.
  Covariance is in HesResults$cov2 (Hessian), not JacobResults$covar.
  R² and RMSE are in ANOVA.list$RSQ / ANOVA.list$RMSE, not JacobResults.
  Residuals are in Mdiagnostics.list$Resids; fitted values in Mdiagnostics.list$predict.

Architecture discovery: startModelRun() already calls controlFileTasksModel() internally.
rsparrow_model() calls only startModelRun(). estimate.list is exposed via one-line addition
to startModelRun.R (line 484): sparrow_state$estimate.list &lt;- estimate.list
</verify_field_names>
</rsparrow_object_structure>

<implementation name="read_sparrow_data" file="R/read_sparrow_data.R" task="10">
```r
read_sparrow_data <- function(path_main, run_id = "run1") {
  # Input validation
  if (!dir.exists(path_main))
    stop("path_main does not exist: ", path_main)
  required_files <- c("parameters.csv", "design_matrix.csv", "dataDictionary.csv")
  missing_files <- required_files[
    !file.exists(file.path(path_main, required_files))
  ]
  if (length(missing_files) > 0)
    stop("Missing required control files: ", paste(missing_files, collapse = ", "),
         "\n  Expected in: ", path_main)

  # Construct file.output.list (replaces legacy generateInputLists.R)
  path_results <- file.path(path_main, "results", run_id)
  dir.create(path_results, recursive = TRUE, showWarnings = FALSE)
  file.output.list <- list(
    path_main     = path_main,
    run_id        = run_id,
    path_results  = path_results,
    # Paths to control files
    parameters_file     = file.path(path_main, "parameters.csv"),
    design_matrix_file  = file.path(path_main, "design_matrix.csv"),
    data_dictionary_file = file.path(path_main, "dataDictionary.csv")
    # Additional paths will be added as needed during Task 2 (startModelRun refactoring)
  )

  # Read control files using internal functions
  data_names <- read_dataDictionary(file.output.list)
  data1      <- readData(file.output.list, data_names)

  list(
    file.output.list = file.output.list,
    data1            = data1,
    data_names       = data_names
  )
}
```
<note>
betavalues and dmatrixin are NOT read here — they depend on if_estimate and other settings
that belong to startModelRun(). read_sparrow_data() reads only the data files.
The file.output.list structure will grow during Task 2 as startModelRun() is refactored.
</note>
</implementation>

<implementation name="rsparrow_model" file="R/rsparrow_model.R" task="9">
```r
rsparrow_model <- function(path_main, run_id = "run1", model_type = "static", ...) {
  # Input validation
  stopifnot(is.character(path_main), length(path_main) == 1)
  if (!dir.exists(path_main)) stop("path_main does not exist: ", path_main)
  model_type <- match.arg(model_type, c("static", "dynamic"))

  # Step 1: Read data files
  sparrow_data <- read_sparrow_data(path_main, run_id = run_id)

  # Step 2: Data preparation, calibration setup, estimation, prediction
  # startModelRun() returns sparrow_state (after Task 2 refactoring)
  sparrow_state <- startModelRun(
    file.output.list      = sparrow_data$file.output.list,
    if_estimate           = TRUE,
    if_estimate_simulation = FALSE,
    if_boot_estimate      = FALSE,
    if_boot_predict       = FALSE,
    data1                 = sparrow_data$data1,
    data_names            = sparrow_data$data_names,
    if_userModifyData     = FALSE,
    if_predict            = TRUE,
    if_validate           = FALSE,
    ...
    # Remaining arguments are extracted from file.output.list or use defaults
  )

  # Step 3: Run estimation and prediction
  # controlFileTasksModel() returns list(runTimes, results) (after Task 3 refactoring)
  run_output <- controlFileTasksModel(
    sparrow_state         = sparrow_state,
    if_estimate           = TRUE,
    if_predict            = TRUE,
    if_validate           = FALSE,
    ...
  )

  # Step 4: Extract estimate.list from results
  estimate_list <- run_output$results$estimate_list

  # Step 5: Construct and return rsparrow S3 object
  structure(
    list(
      call          = match.call(),
      coefficients  = stats::setNames(estimate_list$oEstimate, estimate_list$Parmnames),
      std_errors    = estimate_list$JacobResults$Jacobse,
      vcov          = estimate_list$JacobResults$covar,
      residuals     = estimate_list$Residuals,
      fitted_values = estimate_list$Pload_meas,
      fit_stats = list(
        R2          = estimate_list$JacobResults$R2,
        RMSE        = estimate_list$JacobResults$RMSE,
        npar        = length(estimate_list$oEstimate),
        nobs        = nrow(sparrow_state$sitedata),
        convergence = isTRUE(estimate_list$convergence)
      ),
      data = list(
        subdata             = sparrow_state$subdata,
        sitedata            = sparrow_state$sitedata,
        vsitedata           = sparrow_state$vsitedata,
        DataMatrix.list     = sparrow_state$DataMatrix.list,
        SelParmValues       = sparrow_state$SelParmValues,
        dlvdsgn             = sparrow_state$dlvdsgn,
        estimate.input.list = sparrow_state$estimate.input.list,
        scenario.input.list = sparrow_state$scenario.input.list,
        file.output.list    = sparrow_state$file.output.list
      ),
      predictions = run_output$results$predict_list,
      bootstrap   = NULL,
      validation  = NULL,
      metadata = list(
        version    = utils::packageVersion("rsparrow"),
        timestamp  = Sys.time(),
        run_id     = run_id,
        model_type = model_type,
        path_main  = path_main
      )
    ),
    class = "rsparrow"
  )
}
```
<note>
Argument defaults for the many startModelRun() parameters should come from a settings
defaults list. After Task 2, startModelRun() will have a simpler signature — adjust calls
as needed. Keep \dontrun{} in @examples since real CSV files are required.
</note>
</implementation>

<implementation name="predict.rsparrow" file="R/predict.rsparrow.R" task="12">
```r
predict.rsparrow <- function(object, type = c("all", "load", "yield"),
                              newdata = NULL, ...) {
  if (!inherits(object, "rsparrow"))
    stop("object must be of class 'rsparrow'")
  type <- match.arg(type)

  # Boot correction factor: use if bootstrap has been run
  bootcorrection <- if (!is.null(object$bootstrap))
    object$bootstrap$mean_exp_weighted_error
  else
    NULL

  # Call internal prediction function (renamed from predict() in Plan 03)
  predict_list <- predict_sparrow(
    estimate.list       = object_to_estimate_list(object),
    estimate.input.list = object$data$estimate.input.list,
    bootcorrection      = bootcorrection,
    DataMatrix.list     = object$data$DataMatrix.list,
    SelParmValues       = object$data$SelParmValues,
    subdata             = object$data$subdata
  )

  object$predictions <- predict_list
  object
}

# Internal helper: reconstruct estimate.list from rsparrow object
# (needed because rsparrow_model() stores only the essential fields)
object_to_estimate_list <- function(object) {
  list(
    oEstimate    = object$coefficients,
    Parmnames    = names(object$coefficients),
    JacobResults = list(
      Jacobse = object$std_errors,
      covar   = object$vcov,
      R2      = object$fit_stats$R2,
      RMSE    = object$fit_stats$RMSE
    ),
    Residuals    = object$residuals,
    Pload_meas   = object$fitted_values
  )
}
```
</implementation>

<implementation name="S3_methods" task="8" status="COMPLETE">
<print>
```r
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
```
</print>
<summary>
```r
summary.rsparrow <- function(object, ...) {
  t_vals <- object$coefficients / object$std_errors
  p_vals <- 2 * stats::pt(-abs(t_vals), df = object$fit_stats$nobs - object$fit_stats$npar)
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
```
</summary>
<simple_methods>
```r
# coef.rsparrow
coef.rsparrow <- function(object, ...) object$coefficients

# residuals.rsparrow
residuals.rsparrow <- function(object, ...) object$residuals

# vcov.rsparrow
vcov.rsparrow <- function(object, ...) object$vcov

# plot.rsparrow — diagnostic plots deferred to Plan 05 (function consolidation)
plot.rsparrow <- function(x, type = "diagnostics", ...) {
  stop("Diagnostic plots require Plan 05 (function consolidation). ",
       "Use summary(model) for fit statistics.")
}
```
</simple_methods>
<test_scaffold>
```r
# Use this scaffold to verify all S3 methods without real data:
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
print(mock_rsparrow)
summary(mock_rsparrow)
coef(mock_rsparrow)
residuals(mock_rsparrow)
vcov(mock_rsparrow)
```
</test_scaffold>
</implementation>

<implementation name="rsparrow_bootstrap" file="R/rsparrow_bootstrap.R" task="11">
```r
rsparrow_bootstrap <- function(model, n_iter = 200, seed = NULL) {
  if (!inherits(model, "rsparrow"))
    stop("model must be of class 'rsparrow'")
  stopifnot(is.numeric(n_iter), n_iter >= 10, n_iter <= 10000)
  if (!is.null(seed)) set.seed(seed)

  boot_results <- estimateBootstraps(
    iseed           = seed %||% sample.int(.Machine$integer.max, 1),
    biters          = as.integer(n_iter),
    estimate.list   = object_to_estimate_list(model),
    DataMatrix.list = model$data$DataMatrix.list,
    SelParmValues   = model$data$SelParmValues,
    Csites.weights.list = model$data$Csites.weights.list,
    estimate.input.list = model$data$estimate.input.list,
    dlvdsgn         = model$data$dlvdsgn,
    file.output.list = model$data$file.output.list
  )

  model$bootstrap <- boot_results
  model
}
# Use `%||%` <- function(a, b) if (!is.null(a)) a else b in rsparrow-package.R
```
</implementation>

<implementation name="rsparrow_scenario" file="R/rsparrow_scenario.R" task="11">
```r
rsparrow_scenario <- function(model, source_changes) {
  if (!inherits(model, "rsparrow"))
    stop("model must be of class 'rsparrow'")
  if (is.null(model$predictions))
    stop("Run predict(model) before rsparrow_scenario()")
  if (!is.data.frame(source_changes) && !is.list(source_changes))
    stop("source_changes must be a data.frame or named list of source multipliers")

  scenario_results <- predictScenarios(
    predict.list    = model$predictions,
    subdata         = model$data$subdata,
    DataMatrix.list = model$data$DataMatrix.list,
    SelParmValues   = model$data$SelParmValues,
    estimate.input.list = model$data$estimate.input.list,
    dlvdsgn         = model$data$dlvdsgn,
    scenario.input.list = model$data$scenario.input.list,
    file.output.list    = model$data$file.output.list
  )

  model$predictions$scenarios <- scenario_results
  model
}
```
</implementation>

<implementation name="rsparrow_validate" file="R/rsparrow_validate.R" task="11">
```r
rsparrow_validate <- function(model, fraction = 0.2, seed = NULL) {
  if (!inherits(model, "rsparrow"))
    stop("model must be of class 'rsparrow'")
  stopifnot(is.numeric(fraction), fraction > 0, fraction < 1)

  val_results <- validateMetrics(
    iseed       = seed %||% sample.int(.Machine$integer.max, 1),
    pvalidate   = fraction,
    subdata     = model$data$subdata,
    DataMatrix.list = model$data$DataMatrix.list,
    SelParmValues   = model$data$SelParmValues,
    estimate.input.list = model$data$estimate.input.list,
    dlvdsgn     = model$data$dlvdsgn,
    Csites.weights.list = model$data$Csites.weights.list
  )

  model$validation <- val_results
  model
}
```
</implementation>

<gotchas>
<gotcha name="estimate.list fields must be verified">
The field names used in object_to_estimate_list() (oEstimate, JacobResults, Residuals,
Pload_meas, Parmnames) are inferred from grep searches on estimate.R. Verify actual names
before implementing: grep -n "estimate\.list\[" RSPARROW_master/R/estimate.R
</gotcha>
<gotcha name="Csites.weights.list location">
After Task 2, Csites.weights.list is in sparrow_state. Store it in rsparrow$data$Csites.weights.list
so rsparrow_bootstrap() and rsparrow_validate() can access it.
</gotcha>
<gotcha name="yes_no_strings">
Internal functions (estimateBootstraps, predictScenarios, etc.) still use if_x=="yes"
style. When calling them from skeleton functions, pass "yes"/"no" strings for now.
Full logical conversion is Plan 05 scope.
</gotcha>
<gotcha name="null_coalescing">
Define `%||%` in rsparrow-package.R or a small utils.R file:
  `%||%` <- function(a, b) if (!is.null(a)) a else b
This is used in bootstrap and validate wrappers.
</gotcha>
</gotchas>

</skeleton_implementations>
