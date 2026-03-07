<exports_specification>

<overview>
This document specifies the 13 functions that form the user-facing API for the rsparrow package.
These functions will be exported via @export roxygen2 tags and documented with complete
@param, @return, and @examples sections.
</overview>

<primary_interface>
<description>Main entry points for SPARROW modeling</description>

<function name="rsparrow_model">
<purpose>Main entry point for SPARROW model estimation</purpose>
<current_equivalent>startModelRun() + controlFileTasksModel() + estimate()</current_equivalent>
<signature>rsparrow_model(path_main, run_id = "run1", model_type = "static", ...)</signature>
<parameters>
<param name="path_main">Character. Path to main directory containing control files</param>
<param name="run_id">Character. Name of model run (default: "run1")</param>
<param name="model_type">Character. Either "static" or "dynamic" (default: "static")</param>
<param name="...">Additional arguments passed to estimation routine</param>
</parameters>
<returns>S3 object of class "rsparrow"</returns>
<notes>Wrapper that orchestrates data loading, validation, estimation. Does NOT mutate .GlobalEnv.</notes>
</function>

<function name="predict.rsparrow">
<purpose>S3 predict method for rsparrow objects</purpose>
<current_equivalent>predict.R</current_equivalent>
<signature>predict(object, newdata = NULL, type = c("loads", "yields", "delivery"), ...)</signature>
<parameters>
<param name="object">An object of class "rsparrow"</param>
<param name="newdata">Optional data.frame with new reach network data. If NULL, uses original data.</param>
<param name="type">Character. Type of prediction: "loads", "yields", "delivery", or "all"</param>
<param name="...">Additional arguments</param>
</parameters>
<returns>Modified rsparrow object with predictions populated</returns>
<notes>Standard S3 method; users call predict(model)</notes>
</function>

<function name="read_sparrow_data">
<purpose>Read and validate SPARROW input data from CSV control files</purpose>
<current_equivalent>startModelRun.R (data loading portion)</current_equivalent>
<signature>read_sparrow_data(path_main, run_id = "run1")</signature>
<parameters>
<param name="path_main">Character. Path to main directory</param>
<param name="run_id">Character. Name of model run</param>
</parameters>
<returns>List with subdata, SelParmValues, design matrices</returns>
<notes>Separates I/O from computation; enables programmatic data construction</notes>
</function>

</primary_interface>

<s3_methods>
<description>Standard S3 generic methods for rsparrow class</description>

<method name="summary.rsparrow">
<purpose>Summarize SPARROW model estimation results</purpose>
<current_equivalent>Parts of estimateNLLSmetrics.R</current_equivalent>
<signature>summary(object, ...)</signature>
<returns>Summary object (class "summary.rsparrow") with coefficient table, fit statistics</returns>
<standard_s3>Yes</standard_s3>
</method>

<method name="print.rsparrow">
<purpose>Print SPARROW model object</purpose>
<signature>print(x, ...)</signature>
<returns>Invisible(x); prints model summary to console</returns>
<standard_s3>Yes</standard_s3>
</method>

<method name="coef.rsparrow">
<purpose>Extract model coefficients</purpose>
<signature>coef(object, ...)</signature>
<returns>Named vector of coefficients</returns>
<standard_s3>Yes</standard_s3>
</method>

<method name="residuals.rsparrow">
<purpose>Extract model residuals</purpose>
<signature>residuals(object, type = "response", ...)</signature>
<returns>Vector of residuals at monitoring sites</returns>
<standard_s3>Yes</standard_s3>
</method>

<method name="vcov.rsparrow">
<purpose>Extract variance-covariance matrix</purpose>
<signature>vcov(object, ...)</signature>
<returns>Variance-covariance matrix</returns>
<standard_s3>Yes</standard_s3>
</method>

<method name="plot.rsparrow">
<purpose>Diagnostic plots for SPARROW models</purpose>
<current_equivalent>Selected diagnostic plots (not interactive maps)</current_equivalent>
<signature>plot(x, type = c("residuals", "qq", "leverage"), ...)</signature>
<returns>ggplot2 or base graphics plots</returns>
<standard_s3>Yes</standard_s3>
</method>

</s3_methods>

<advanced_functions>
<description>Specialized modeling and diagnostic functions</description>

<function name="rsparrow_bootstrap">
<purpose>Bootstrap uncertainty estimation</purpose>
<current_equivalent>predictBoot.R</current_equivalent>
<signature>rsparrow_bootstrap(object, n_boot = 100, seed = NULL, ...)</signature>
<parameters>
<param name="object">An rsparrow model object</param>
<param name="n_boot">Integer. Number of bootstrap iterations</param>
<param name="seed">Integer. Random seed for reproducibility</param>
<param name="...">Additional arguments</param>
</parameters>
<returns>rsparrow object with bootstrap results in metadata</returns>
</function>

<function name="rsparrow_scenario">
<purpose>Run scenario predictions with modified sources</purpose>
<current_equivalent>predictScenarios.R</current_equivalent>
<signature>rsparrow_scenario(object, scenario_name, source_modifications, ...)</signature>
<parameters>
<param name="object">An rsparrow model object</param>
<param name="scenario_name">Character. Name for this scenario</param>
<param name="source_modifications">List specifying source changes</param>
<param name="...">Additional arguments</param>
</parameters>
<returns>rsparrow object with scenario predictions</returns>
</function>

<function name="rsparrow_hydseq">
<purpose>Compute hydrological sequencing for reach network</purpose>
<current_equivalent>hydseq.R</current_equivalent>
<signature>rsparrow_hydseq(data, from_col = "fnode", to_col = "tnode")</signature>
<parameters>
<param name="data">data.frame with reach network topology</param>
<param name="from_col">Character. Column name for upstream node</param>
<param name="to_col">Character. Column name for downstream node</param>
</parameters>
<returns>Vector of hydrological sequence IDs</returns>
<notes>Useful standalone utility for network ordering</notes>
</function>

<function name="rsparrow_validate">
<purpose>Cross-validation diagnostics</purpose>
<current_equivalent>Parts of estimate.R (validation routines)</current_equivalent>
<signature>rsparrow_validate(object, method = c("leave-one-out", "k-fold"), k = 10, ...)</signature>
<parameters>
<param name="object">An rsparrow model object</param>
<param name="method">Character. Validation method</param>
<param name="k">Integer. Number of folds for k-fold validation</param>
<param name="...">Additional arguments</param>
</parameters>
<returns>List with validation statistics</returns>
</function>

</advanced_functions>

<roxygen_templates>

<template for="rsparrow_model">
<example>
```r
#' Estimate a SPARROW Water Quality Model
#'
#' Estimates a SPARROW (SPAtially Referenced Regressions On Watershed attributes)
#' model using nonlinear least squares. Reads input data from CSV control files,
#' validates the reach network, computes hydrological sequencing, and optimizes
#' model parameters.
#'
#' @param path_main Character. Path to the main directory containing control files
#'   (parameters.csv, design_matrix.csv, dataDictionary.csv, and data files).
#' @param run_id Character. Name of the model run (default: "run1"). Used for
#'   organizing output and matching parameter specifications.
#' @param model_type Character. Either "static" (long-term mean annual) or "dynamic"
#'   (seasonal/annual time-varying). Default: "static".
#' @param ... Additional arguments passed to estimation routine.
#'
#' @return An S3 object of class "rsparrow" containing:
#'   \describe{
#'     \item{coefficients}{Named vector of estimated model parameters}
#'     \item{std_errors}{Standard errors of coefficients}
#'     \item{residuals}{Residuals at monitoring sites}
#'     \item{fit_stats}{List with AIC, BIC, R², RMSE, log-likelihood}
#'     \item{data}{Input data (reach network, sites, design matrices)}
#'     \item{metadata}{Estimation details and timestamps}
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Estimate a SPARROW model
#' model <- rsparrow_model(
#'   path_main = "~/sparrow_projects/my_model/",
#'   run_id = "baseline",
#'   model_type = "static"
#' )
#'
#' # View summary
#' summary(model)
#'
#' # Extract coefficients
#' coef(model)
#' }
rsparrow_model <- function(path_main, run_id = "run1", model_type = "static", ...) {
  stop("Not yet implemented - see Plan 04: State Elimination")
}
```
</example>
</template>

<template for="predict.rsparrow">
<example>
```r
#' Predict Method for SPARROW Models
#'
#' Computes reach-level predictions of contaminant loads, yields, and delivery
#' fractions from an estimated SPARROW model.
#'
#' @param object An object of class "rsparrow" (output from rsparrow_model).
#' @param newdata Optional. A data.frame with new reach network data. If NULL,
#'   predictions are made for the original estimation network.
#' @param type Character. Type of prediction: "loads" (total loads), "yields"
#'   (loads per unit area), "delivery" (delivery fractions), or "all". Default: "all".
#' @param ... Additional arguments (currently unused).
#'
#' @return A modified rsparrow object with predictions populated in the
#'   \code{predictions} list component. Predictions are data.frames with one row
#'   per reach.
#'
#' @export
#' @method predict rsparrow
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' model_pred <- predict(model, type = "all")
#' head(model_pred$predictions$loads)
#' }
predict.rsparrow <- function(object, newdata = NULL,
                             type = c("all", "loads", "yields", "delivery"), ...) {
  stop("Not yet implemented - see Plan 04: State Elimination")
}
```
</example>
</template>

<template for="summary.rsparrow">
<example>
```r
#' Summarize SPARROW Model Results
#'
#' Produces a summary of SPARROW model estimation including coefficient table
#' with standard errors, z-values, p-values, and model fit statistics.
#'
#' @param object An object of class "rsparrow".
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "summary.rsparrow" containing coefficient table
#'   and fit statistics.
#'
#' @export
#' @method summary rsparrow
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' summary(model)
#' }
summary.rsparrow <- function(object, ...) {
  stop("Not yet implemented - see Plan 04: State Elimination")
}
```
</example>
</template>

</roxygen_templates>

<implementation_notes>

<note>
All skeleton functions created in Plan 03 should contain only:
`stop("Not yet implemented - see Plan 04: State Elimination")`
Actual implementation happens in Plan 04 after global state is eliminated.
</note>

<note>
For S3 methods, use @method tag in roxygen2:
`@method predict rsparrow` (not `@export predict.rsparrow`)
</note>

<note>
All examples should be wrapped in \dontrun{} to prevent execution during R CMD check
until Plan 04 implements the functions.
</note>

<note>
The rsparrow_hydseq() wrapper CAN be fully implemented in Plan 03 since hydseq.R
is a pure function with no global state dependencies.
</note>

</implementation_notes>

</exports_specification>
