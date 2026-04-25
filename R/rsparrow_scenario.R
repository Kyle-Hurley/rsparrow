#' Run Scenario Predictions with Modified Sources
#'
#' Generates predictions under hypothetical scenarios where contaminant
#' sources are modified (e.g., reduced fertilizer application). Uses the
#' estimated model coefficients with altered source multipliers.
#'
#' @param object An object of class "rsparrow" (output from \code{\link{rsparrow_model}}).
#' @param source_changes A named numeric vector or named list specifying source
#'   multipliers. Names correspond to source variable names in the model;
#'   values are multiplicative factors (e.g.,
#'   \code{list(fertilizer = 0.5)} reduces fertilizer inputs by 50 percent.
#' @param scenario_name Character. Name for this scenario (used in output file
#'   labeling). Default: \code{"scenario1"}.
#' @param ... Additional arguments (currently unused).
#'
#' @return The input rsparrow object with scenario predictions added to
#'   \code{predictions$scenarios}.
#'
#' @details
#' Predictions must already be populated (i.e., \code{\link{predict.rsparrow}}
#' or \code{rsparrow_model(if_predict = "yes")} must have been run first).
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{predict.rsparrow}}
#'
#' @examples
#' \donttest{
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix,
#'   sparrow_example$data_dictionary
#' )
#' # Reduce the agricultural N source by 50%
#' model <- rsparrow_scenario(model, source_changes = list(agN = 0.5))
#' }
rsparrow_scenario <- function(object, source_changes,
                              scenario_name = "scenario1", ...) {
  if (!inherits(object, "rsparrow"))
    stop("object must be of class 'rsparrow'")
  if (is.null(object$predictions))
    stop("Run predict(model) before rsparrow_scenario()")
  if (!is.data.frame(source_changes) && !is.list(source_changes) &&
      !is.numeric(source_changes))
    stop("source_changes must be a named numeric vector or named list of source multipliers")
  if (is.null(names(source_changes)) || any(names(source_changes) == ""))
    stop("source_changes must have names corresponding to source variable names")

  # Build scenario.input.list from model defaults, overriding scenario sources
  sc <- object$data$scenario.input.list
  sc$scenario_name    <- scenario_name
  sc$scenario_sources <- names(source_changes)
  sc$scenario_factors <- unlist(unname(source_changes), use.names = FALSE)

  estimate_list <- object_to_estimate_list(object)

  scenario_results <- predictScenarios(
    estimate.input.list = object$data$estimate.input.list,
    estimate.list       = estimate_list,
    predict.list        = object$predictions,
    scenario.input.list = sc,
    data_names          = object$data$data_names,
    JacobResults        = estimate_list$JacobResults,
    if_predict          = object$data$file.output.list$if_predict,
    DataMatrix.list     = object$data$DataMatrix.list,
    SelParmValues       = object$data$SelParmValues,
    subdata             = object$data$subdata,
    file.output.list    = object$data$file.output.list,
    add_vars            = object$data$file.output.list$add_vars,
    mapping.input.list  = object$data$mapping.input.list,
    dlvdsgn             = object$data$dlvdsgn,
    RSPARROW_errorOption = "no"
  )

  object$predictions$scenarios <- scenario_results
  object
}
