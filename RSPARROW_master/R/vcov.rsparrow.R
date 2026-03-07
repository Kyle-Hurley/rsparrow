#' Extract SPARROW Model Variance-Covariance Matrix
#'
#' Extracts the variance-covariance matrix of the estimated coefficients
#' from a fitted SPARROW model.
#'
#' @param object An object of class "rsparrow".
#' @param ... Additional arguments (currently unused).
#'
#' @return A square numeric matrix with dimensions equal to the number of
#'   estimated coefficients. Row and column names match coefficient names.
#'
#' @export
#' @method vcov rsparrow
#'
#' @seealso \code{\link{coef.rsparrow}}, \code{\link{rsparrow_model}}
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' vcov(model)
#' }
vcov.rsparrow <- function(object, ...) object$vcov
