#' Extract SPARROW Model Coefficients
#'
#' Extracts the estimated coefficients (parameter values) from a fitted
#' SPARROW model.
#'
#' @param object An object of class "rsparrow".
#' @param ... Additional arguments (currently unused).
#'
#' @return A named numeric vector of estimated model coefficients.
#'
#' @export
#' @method coef rsparrow
#'
#' @seealso \code{\link{vcov.rsparrow}}, \code{\link{rsparrow_model}}
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' coef(model)
#' }
coef.rsparrow <- function(object, ...) object$coefficients
