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
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' residuals(model)
#' }
residuals.rsparrow <- function(object, type = "response", ...) object$residuals
