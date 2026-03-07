<api_reference>

<overview>
This reference provides roxygen2 patterns, templates, and best practices for documenting the
rsparrow package API. All exported functions must have complete documentation following these
standards.
</overview>

<roxygen2_requirements>

<exported_functions>
<description>Every exported function must have:</description>

<requirement>@title - One-line description (sentence case, no period)</requirement>
<requirement>@description - 1-3 paragraphs explaining what the function does</requirement>
<requirement>@param - One line per parameter with type and description</requirement>
<requirement>@return - Description of return object structure</requirement>
<requirement>@export - Makes function available to users</requirement>
<requirement>@examples - Runnable code demonstrating usage</requirement>
<requirement>@seealso - Optional links to related functions</requirement>
</exported_functions>

<internal_functions>
<description>Internal helper functions should have:</description>

<requirement>@keywords internal - Marks function as internal</requirement>
<requirement>@noRd - Optional; suppresses .Rd file generation</requirement>
<requirement>Brief description of what the function does</requirement>
<requirement>No @export tag</requirement>
</internal_functions>

<s3_methods>
<description>S3 methods require special syntax:</description>

<requirement>@method generic class - NOT @export function.class</requirement>
<requirement>@export - Still needed to export the method</requirement>
<requirement>Example: @method predict rsparrow (generates S3method(predict, rsparrow))</requirement>
</s3_methods>

</roxygen2_requirements>

<documentation_templates>

<template type="main_function">
<name>rsparrow_model pattern</name>
<example>
```r
#' Estimate a SPARROW Water Quality Model
#'
#' Estimates a SPARROW (SPAtially Referenced Regressions On Watershed attributes)
#' model using nonlinear least squares. Reads input data from CSV control files,
#' validates the reach network, computes hydrological sequencing, and optimizes
#' model parameters using the nlmrt package.
#'
#' The function orchestrates the full SPARROW estimation workflow:
#' \enumerate{
#'   \item Reads and validates control files (parameters.csv, design_matrix.csv)
#'   \item Loads reach network and monitoring site data
#'   \item Computes hydrological sequencing via rsparrow_hydseq()
#'   \item Prepares data matrices for optimization
#'   \item Calls nonlinear least squares optimizer
#'   \item Computes fit statistics and diagnostics
#' }
#'
#' @param path_main Character. Path to the main directory containing control files
#'   and data. Must contain parameters.csv, design_matrix.csv, dataDictionary.csv.
#' @param run_id Character. Name of the model run (default: "run1"). Used to match
#'   parameter specifications in the control files.
#' @param model_type Character. Either "static" for long-term mean annual models
#'   or "dynamic" for seasonal/annual time-varying models. Default: "static".
#' @param ... Additional arguments passed to the internal estimation routine.
#'
#' @return An S3 object of class "rsparrow" containing:
#'   \describe{
#'     \item{call}{The matched function call}
#'     \item{coefficients}{Named numeric vector of estimated parameters}
#'     \item{std_errors}{Standard errors of coefficients}
#'     \item{vcov}{Variance-covariance matrix}
#'     \item{residuals}{Residuals at monitoring sites}
#'     \item{fitted_values}{Fitted loads at monitoring sites}
#'     \item{fit_stats}{List with AIC, BIC, R², RMSE, log-likelihood, convergence}
#'     \item{data}{Input data (reach network, sites, design matrices)}
#'     \item{predictions}{List (initially NULL) for predict() results}
#'     \item{metadata}{Package version, timestamp, Fortran call info}
#'   }
#'
#' @export
#'
#' @seealso \code{\link{predict.rsparrow}}, \code{\link{summary.rsparrow}},
#'   \code{\link{read_sparrow_data}}
#'
#' @examples
#' \dontrun{
#' # Estimate a static SPARROW model
#' model <- rsparrow_model(
#'   path_main = "~/sparrow_projects/my_watershed/",
#'   run_id = "baseline_2020",
#'   model_type = "static"
#' )
#'
#' # View estimation results
#' print(model)
#' summary(model)
#'
#' # Extract coefficients
#' coef(model)
#'
#' # Generate predictions
#' model <- predict(model, type = "all")
#' }
rsparrow_model <- function(path_main, run_id = "run1", model_type = "static", ...) {
  stop("Not yet implemented - see Plan 04: State Elimination")
}
```
</example>
</template>

<template type="s3_predict_method">
<name>predict.rsparrow pattern</name>
<example>
```r
#' Predict Method for SPARROW Models
#'
#' Computes reach-level predictions of contaminant loads, yields, and delivery
#' fractions from an estimated SPARROW model. Predictions use the estimated
#' coefficients and can be generated for the original network or new data.
#'
#' @param object An object of class "rsparrow" (output from \code{\link{rsparrow_model}}).
#' @param newdata Optional data.frame with new reach network data. Must have the same
#'   structure as the original estimation data. If NULL (default), predictions are
#'   made for the original network.
#' @param type Character. Type of prediction to compute:
#'   \describe{
#'     \item{"all"}{All prediction types (default)}
#'     \item{"loads"}{Total contaminant loads by reach}
#'     \item{"yields"}{Loads per unit drainage area}
#'     \item{"delivery"}{Delivery fractions from each reach to outlet}
#'   }
#' @param ... Additional arguments (currently unused; reserved for future extensions).
#'
#' @return The input rsparrow object with the \code{predictions} list component populated.
#'   \code{predictions} contains data.frames with one row per reach:
#'   \describe{
#'     \item{loads}{Total predicted loads}
#'     \item{yields}{Predicted yields (load / drainage area)}
#'     \item{delivery_fractions}{Fraction of load delivered to outlet}
#'     \item{incremental_loads}{Load generated within each reach}
#'   }
#'
#' @export
#' @method predict rsparrow
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{rsparrow_scenario}}
#'
#' @examples
#' \dontrun{
#' # Estimate model
#' model <- rsparrow_model("~/my_model/")
#'
#' # Generate all predictions
#' model <- predict(model, type = "all")
#'
#' # Access predictions
#' head(model$predictions$loads)
#' head(model$predictions$yields)
#'
#' # Plot predicted loads
#' plot(model$predictions$loads$total_load)
#' }
predict.rsparrow <- function(object, newdata = NULL,
                             type = c("all", "loads", "yields", "delivery"), ...) {
  stop("Not yet implemented - see Plan 04: State Elimination")
}
```
</example>
</template>

<template type="s3_summary_method">
<name>summary.rsparrow pattern</name>
<example>
```r
#' Summarize SPARROW Model Results
#'
#' Produces a summary of SPARROW model estimation including a coefficient table
#' with standard errors, z-values, p-values, and model fit statistics.
#'
#' @param object An object of class "rsparrow".
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "summary.rsparrow" (a list) containing:
#'   \describe{
#'     \item{call}{The original model call}
#'     \item{coefficients}{Matrix with estimates, std errors, z-values, p-values}
#'     \item{fit_stats}{Model fit statistics (AIC, BIC, R², RMSE, log-likelihood)}
#'     \item{n_obs}{Number of monitoring sites used in estimation}
#'     \item{n_reach}{Number of reaches in network}
#'   }
#'
#' @export
#' @method summary rsparrow
#'
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

<template type="s3_coef_method">
<name>coef.rsparrow pattern</name>
<example>
```r
#' Extract SPARROW Model Coefficients
#'
#' Extracts the estimated coefficients (parameter values) from a fitted SPARROW model.
#'
#' @param object An object of class "rsparrow".
#' @param ... Additional arguments (currently unused).
#'
#' @return A named numeric vector of estimated model coefficients.
#'
#' @export
#' @method coef rsparrow
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' coef(model)
#' }
coef.rsparrow <- function(object, ...) {
  stop("Not yet implemented - see Plan 04: State Elimination")
}
```
</example>
</template>

<template type="utility_function">
<name>rsparrow_hydseq pattern (standalone utility)</name>
<example>
```r
#' Compute Hydrological Sequence for Stream Network
#'
#' Orders stream reaches from upstream to downstream based on network topology.
#' This is a key preprocessing step for SPARROW models, ensuring that load
#' accumulation occurs in the correct hydrological order.
#'
#' The algorithm uses depth-first search on the directed graph defined by the
#' from-node and to-node columns. Headwater reaches (no upstream connections)
#' are assigned sequence 1, and sequence numbers increase moving downstream.
#'
#' @param data A data.frame containing reach network topology.
#' @param from_col Character. Name of column containing upstream node IDs
#'   (default: "fnode").
#' @param to_col Character. Name of column containing downstream node IDs
#'   (default: "tnode").
#'
#' @return An integer vector of hydrological sequence IDs, with length equal to
#'   nrow(data). Sequence starts at 1 for headwater reaches.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' # Create simple network
#' network <- data.frame(
#'   reach_id = 1:5,
#'   fnode = c(1, 2, 3, 4, 5),
#'   tnode = c(3, 3, 5, 5, 6)
#' )
#'
#' # Compute sequence
#' network$hydseq <- rsparrow_hydseq(network, from_col = "fnode", to_col = "tnode")
#' network[order(network$hydseq), ]
#' }
#'
#' @details
#' This function is a wrapper around the internal hydseq() function. It can be
#' used independently of SPARROW model estimation for reach network preprocessing.
rsparrow_hydseq <- function(data, from_col = "fnode", to_col = "tnode") {
  # This function CAN be fully implemented in Plan 03 since hydseq.R is pure
  hydseq(data, from_col, to_col)
}
```
</example>
</template>

<template type="internal_function">
<name>Internal helper function pattern</name>
<example>
```r
#' Compute NLLS Objective Function Value (Internal)
#'
#' This is an internal function called by estimateOptimize during nonlinear least
#' squares optimization. Users should not call this directly. It computes the
#' negative log-likelihood for the SPARROW model given a parameter vector.
#'
#' @keywords internal
#' @noRd
estimateFeval <- function(beta, DataMatrix.list, Csites.weights.list, ...) {
  # existing implementation
  # ...
}
```
</example>

<note>
Internal functions use @keywords internal and optionally @noRd to suppress .Rd generation.
They do NOT have @export tags. Minimal documentation is sufficient since they're not user-facing.
</note>
</template>

</documentation_templates>

<parameter_documentation_patterns>

<pattern type="path_parameter">
<example>
```r
#' @param path_main Character. Path to the main directory containing control files
#'   (parameters.csv, design_matrix.csv, dataDictionary.csv, and data files).
```
</example>
</pattern>

<pattern type="logical_parameter">
<example>
```r
#' @param validate Logical. If TRUE (default), performs input validation checks
#'   on the reach network and monitoring site data.
```
</example>
</pattern>

<pattern type="choice_parameter">
<example>
```r
#' @param type Character. Type of prediction: "loads" (total loads), "yields"
#'   (loads per unit area), "delivery" (delivery fractions), or "all". Default: "all".
```
</example>
</pattern>

<pattern type="dataframe_parameter">
<example>
```r
#' @param data A data.frame containing reach network data with columns for node IDs,
#'   drainage areas, and watershed attributes. See \code{\link{read_sparrow_data}}
#'   for required structure.
```
</example>
</pattern>

<pattern type="dots_parameter">
<example>
```r
#' @param ... Additional arguments passed to the internal estimation routine. See
#'   Details for available options.
```
</example>
</pattern>

</parameter_documentation_patterns>

<return_documentation_patterns>

<pattern type="s3_object_return">
<example>
```r
#' @return An S3 object of class "rsparrow" containing:
#'   \describe{
#'     \item{coefficients}{Named vector of estimated parameters}
#'     \item{std_errors}{Standard errors of coefficients}
#'     \item{fit_stats}{List with AIC, BIC, R², RMSE}
#'   }
```
</example>
</pattern>

<pattern type="modified_object_return">
<example>
```r
#' @return The input rsparrow object with the \code{predictions} component populated.
```
</example>
</pattern>

<pattern type="vector_return">
<example>
```r
#' @return A named numeric vector of estimated model coefficients.
```
</example>
</pattern>

<pattern type="list_return">
<example>
```r
#' @return A list with components:
#'   \describe{
#'     \item{validation_rmse}{Root mean squared error from validation}
#'     \item{validation_r2}{R-squared from validation}
#'     \item{site_predictions}{Data.frame of predictions at held-out sites}
#'   }
```
</example>
</pattern>

</return_documentation_patterns>

<examples_guidelines>

<guideline>
<rule>All examples for skeleton functions must be wrapped in \dontrun{}</rule>
<reason>Functions are not yet implemented in Plan 03; unwrapped examples would fail R CMD check</reason>
<example>
```r
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' summary(model)
#' }
```
</example>
</guideline>

<guideline>
<rule>Examples should demonstrate realistic usage with clear variable names</rule>
<example>
```r
#' @examples
#' \dontrun{
#' # Estimate baseline model
#' baseline <- rsparrow_model(
#'   path_main = "~/projects/watershed_study/",
#'   run_id = "baseline_2020"
#' )
#'
#' # Generate predictions
#' baseline <- predict(baseline, type = "all")
#'
#' # Compare with scenario
#' reduced_sources <- rsparrow_scenario(
#'   baseline,
#'   scenario_name = "reduce_fertilizer",
#'   source_modifications = list(fertilizer = 0.5)
#' )
#' }
```
</example>
</guideline>

<guideline>
<rule>Use \donttest{} for slow examples that should run but take >5 seconds</rule>
<note>
After Plan 04 implementation, change \dontrun{} to \donttest{} for examples that work
but are slow (bootstrap, large datasets). Keep \dontrun{} for examples requiring
external data not included in package.
</note>
</guideline>

</examples_guidelines>

<seealso_patterns>

<pattern>
```r
#' @seealso \code{\link{rsparrow_model}}, \code{\link{predict.rsparrow}},
#'   \code{\link{summary.rsparrow}}
```
</pattern>

<pattern>
```r
#' @seealso \code{\link{read_sparrow_data}} for data loading,
#'   \code{\link{rsparrow_hydseq}} for network ordering
```
</pattern>

</seealso_patterns>

<namespace_generation>

<description>
After adding roxygen2 tags to all functions, regenerate NAMESPACE using roxygen2.
This replaces hand-edited NAMESPACE with auto-generated version.
</description>

<steps>
<step n="1">
<command>roxygen2::roxygenize("RSPARROW_master")</command>
<description>Generates NAMESPACE and .Rd files from roxygen2 tags</description>
</step>

<step n="2">
<verification>Check that NAMESPACE contains "# Generated by roxygen2: do not edit by hand"</verification>
</step>

<step n="3">
<verification>Verify export() lines for all 13 exported functions</verification>
</step>

<step n="4">
<verification>Verify S3method() registrations for 7 S3 methods</verification>
</step>

<step n="5">
<verification>Verify importFrom() lines (no blanket import() lines)</verification>
</step>

<step n="6">
<verification>Run R CMD build and R CMD check to test documentation</verification>
</step>
</steps>

<common_warnings>
<warning>
<message>function 'X' not found in package 'Y'</message>
<solution>Add function X to @importFrom Y in rsparrow-package.R</solution>
</warning>

<warning>
<message>undocumented arguments in documentation object</message>
<solution>Add missing @param tags for all function arguments</solution>
</warning>

<warning>
<message>@examples with \dontrun{} only</message>
<solution>Acceptable for Plan 03; functions not yet implemented</solution>
</warning>
</common_warnings>

</namespace_generation>

</api_reference>
