<s3_class_design>

<overview>
The rsparrow S3 class provides a standard container for SPARROW model objects returned by
estimation. It enables method dispatch for predict(), summary(), print(), coef(), residuals(),
plot() following standard R conventions (like lm, glm).
</overview>

<canonical_structure>
<example>
```r
rsparrow_object <- list(
  # Model specification
  call = matched.call(),              # Original function call
  formula = NULL,                     # Future: formula interface
  model_type = "static",              # or "dynamic"

  # Input data
  data = list(
    subdata = subdata,                # Reach network data.frame
    sitedata = sitedata,              # Calibration sites subset
    SelParmValues = SelParmValues,    # Parameter specifications (CSV)
    DataMatrix.list = DataMatrix.list # Numeric matrices for optimization
  ),

  # Estimation results
  coefficients = beta_vector,         # Named vector of estimated parameters
  std_errors = se_vector,             # Standard errors
  vcov = vcov_matrix,                 # Variance-covariance matrix
  residuals = residuals_vector,       # Residuals at monitoring sites
  fitted_values = fitted_vector,      # Fitted loads at monitoring sites

  # Model fit statistics
  fit_stats = list(
    log_likelihood = LL,
    aic = AIC,
    bic = BIC,
    r_squared = R2,
    rmse = RMSE,
    convergence = convergence_code
  ),

  # Predictions (populated by predict.rsparrow)
  predictions = list(
    loads = NULL,                     # Predicted loads by reach
    yields = NULL,                    # Predicted yields by reach
    delivery_fractions = NULL,        # Delivery fractions
    incremental_loads = NULL          # Incremental loads
  ),

  # Diagnostics
  diagnostics = list(
    leverage = NULL,
    cooks_distance = NULL,
    validation_metrics = NULL
  ),

  # Metadata
  metadata = list(
    package_version = packageVersion("rsparrow"),
    estimation_date = Sys.time(),
    convergence_info = convergence_details,
    fortran_info = list(
      tnoder_calls = n_calls,
      max_iterations = max_iter
    )
  )
)

class(rsparrow_object) <- c("rsparrow", "list")
```
</example>
</canonical_structure>

<field_specifications>

<mandatory_fields>
<description>These fields MUST be populated by rsparrow_model()</description>

<field name="call">The matched function call (via match.call())</field>
<field name="model_type">Either "static" or "dynamic"</field>
<field name="data">List containing all input data (subdata, sitedata, SelParmValues, DataMatrix.list)</field>
<field name="coefficients">Named numeric vector of estimated parameters</field>
<field name="std_errors">Standard errors matching coefficients</field>
<field name="vcov">Variance-covariance matrix</field>
<field name="residuals">Residuals at monitoring sites</field>
<field name="fitted_values">Fitted loads at monitoring sites</field>
<field name="fit_stats">Model fit metrics (at minimum: AIC, log_likelihood, convergence)</field>
</mandatory_fields>

<optional_fields>
<description>These fields are NULL initially and populated by other functions</description>

<field name="formula">Reserved for future formula interface</field>
<field name="predictions">Populated by predict.rsparrow()</field>
<field name="diagnostics">Populated by rsparrow_validate() or diagnostic methods</field>
</optional_fields>

<metadata_fields>
<description>Always populated with package version, timestamp, convergence details</description>

<field name="metadata$package_version">Version of rsparrow package used</field>
<field name="metadata$estimation_date">Timestamp of estimation</field>
<field name="metadata$convergence_info">Details from optimizer</field>
<field name="metadata$fortran_info">Fortran call statistics</field>
</metadata_fields>

</field_specifications>

<mapping_from_current_code>

<from_estimate_r>
<description>Current code stores results in .GlobalEnv and returns estimate.list. Map as follows:</description>

<mapping>
<current>estimate.list$estimate.input.list</current>
<new>data$DataMatrix.list</new>
</mapping>

<mapping>
<current>estimate.list$betavalues</current>
<new>coefficients</new>
</mapping>

<mapping>
<current>estimate.list$sparrowEsts</current>
<new>std_errors</new>
</mapping>

<mapping>
<current>estimate.list$VarCov</current>
<new>vcov</new>
</mapping>

<mapping>
<current>estimate.list$residuals</current>
<new>residuals</new>
</mapping>

<mapping>
<current>estimate.list$fit.metrics</current>
<new>fit_stats</new>
</mapping>
</from_estimate_r>

<from_predict_r>
<description>Current code stores results in .GlobalEnv and returns predict.list. Map as follows:</description>

<mapping>
<current>predict.list$JacobResults</current>
<new>predictions$loads</new>
</mapping>

<mapping>
<current>predict.list$yields</current>
<new>predictions$yields</new>
</mapping>

<mapping>
<current>predict.list$deliv_frac</current>
<new>predictions$delivery_fractions</new>
</mapping>
</from_predict_r>

</mapping_from_current_code>

<s3_method_patterns>

<method name="predict.rsparrow">
<example>
```r
predict.rsparrow <- function(object, newdata = NULL,
                             type = c("all", "loads", "yields", "delivery"), ...) {
  stopifnot(inherits(object, "rsparrow"))
  type <- match.arg(type)

  # Access: object$coefficients, object$data
  # Compute predictions using predict.R logic
  # Populate: object$predictions

  return(object)
}
```
</example>
</method>

<method name="summary.rsparrow">
<example>
```r
summary.rsparrow <- function(object, ...) {
  stopifnot(inherits(object, "rsparrow"))

  # Extract: object$coefficients, object$std_errors, object$fit_stats
  # Build coefficient table with z-values and p-values

  result <- list(
    call = object$call,
    coefficients = coef_table,
    fit_stats = object$fit_stats,
    n_obs = length(object$residuals)
  )
  class(result) <- c("summary.rsparrow", "list")
  return(result)
}
```
</example>
</method>

<method name="coef.rsparrow">
<example>
```r
coef.rsparrow <- function(object, ...) {
  stopifnot(inherits(object, "rsparrow"))
  return(object$coefficients)
}
```
</example>
</method>

<method name="residuals.rsparrow">
<example>
```r
residuals.rsparrow <- function(object, type = "response", ...) {
  stopifnot(inherits(object, "rsparrow"))
  # type argument for future extensions (pearson, deviance, etc.)
  return(object$residuals)
}
```
</example>
</method>

<method name="vcov.rsparrow">
<example>
```r
vcov.rsparrow <- function(object, ...) {
  stopifnot(inherits(object, "rsparrow"))
  return(object$vcov)
}
```
</example>
</method>

<method name="print.rsparrow">
<example>
```r
print.rsparrow <- function(x, ...) {
  cat("SPARROW Model (", x$model_type, ")\n", sep = "")
  cat("\nCall:\n")
  print(x$call)
  cat("\nCoefficients:\n")
  print(round(x$coefficients, 4))
  cat("\nModel fit: AIC =", round(x$fit_stats$aic, 2),
      " R² =", round(x$fit_stats$r_squared, 3), "\n")
  invisible(x)
}
```
</example>
</method>

<method name="plot.rsparrow">
<example>
```r
plot.rsparrow <- function(x, type = c("residuals", "qq", "leverage"), ...) {
  type <- match.arg(type)

  if (type == "residuals") {
    # Residuals vs fitted plot
  } else if (type == "qq") {
    # Q-Q plot for normality
  } else if (type == "leverage") {
    # Leverage vs residuals
  }
}
```
</example>
</method>

</s3_method_patterns>

<constructor_pattern>
<description>The constructor function rsparrow_model() should follow this pattern</description>

<example>
```r
rsparrow_model <- function(path_main, run_id = "run1",
                          model_type = "static", ...) {
  # 1. Validate inputs
  stopifnot(dir.exists(path_main))
  stopifnot(model_type %in% c("static", "dynamic"))

  # 2. Read and validate data
  data_objects <- read_sparrow_data(path_main, run_id)

  # 3. Run estimation (refactored estimate.R)
  est_results <- estimate_internal(data_objects, ...)

  # 4. Build rsparrow object from results
  result <- list(
    call = match.call(),
    formula = NULL,
    model_type = model_type,
    data = data_objects,
    coefficients = est_results$beta,
    std_errors = est_results$se,
    vcov = est_results$vcov,
    residuals = est_results$residuals,
    fitted_values = est_results$fitted,
    fit_stats = est_results$metrics,
    predictions = list(loads = NULL, yields = NULL,
                      delivery_fractions = NULL, incremental_loads = NULL),
    diagnostics = list(leverage = NULL, cooks_distance = NULL,
                      validation_metrics = NULL),
    metadata = list(
      package_version = packageVersion("rsparrow"),
      estimation_date = Sys.time(),
      convergence_info = est_results$convergence,
      fortran_info = est_results$fortran_stats
    )
  )

  class(result) <- c("rsparrow", "list")
  return(result)
}
```
</example>
</constructor_pattern>

<validation>
<description>A validation function should check object integrity</description>

<example>
```r
validate_rsparrow <- function(obj) {
  stopifnot(inherits(obj, "rsparrow"))
  stopifnot(!is.null(obj$call))
  stopifnot(!is.null(obj$coefficients))
  stopifnot(!is.null(obj$data))
  stopifnot(length(obj$coefficients) == length(obj$std_errors))
  stopifnot(nrow(obj$vcov) == length(obj$coefficients))
  stopifnot(obj$model_type %in% c("static", "dynamic"))
  invisible(obj)
}
```
</example>
</validation>

<future_extensions>
<extension>bootstrap_results: List with bootstrap coefficient distributions</extension>
<extension>scenario_results: List with scenario predictions</extension>
<extension>sensitivity: Sensitivity analysis results</extension>
<extension>spatial_autocorr: Moran's I and spatial diagnostics</extension>
</future_extensions>

</s3_class_design>
