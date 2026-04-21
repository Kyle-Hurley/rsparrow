#' Extract SPARROW Model Residuals
#'
#' Extracts residuals at monitoring sites from a fitted SPARROW model.
#'
#' @param object An object of class "rsparrow".
#' @param type Character. Type of residuals. Currently only "response" is
#'   supported (default). Reserved for future extensions (e.g., "pearson").
#' @param ... Additional arguments (currently unused).
#'
#' @return A numeric vector of residuals at monitoring sites.
#'
#' @export
#' @method residuals rsparrow
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{summary.rsparrow}}
#'
#' @examples
#' \donttest{
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix,
#'   sparrow_example$data_dictionary
#' )
#' residuals(model)
#' }
residuals.rsparrow <- function(object, type = "response", ...) object$residuals
