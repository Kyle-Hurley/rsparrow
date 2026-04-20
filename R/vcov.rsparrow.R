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
#' \donttest{
#' td <- tempdir()
#' write.csv(sparrow_example$data_dictionary,
#'           file.path(td, "dataDictionary.csv"), row.names = FALSE)
#' write.csv(sparrow_example$parameters,
#'           file.path(td, "parameters.csv"), row.names = FALSE)
#' write.csv(sparrow_example$design_matrix,
#'           file.path(td, "design_matrix.csv"), row.names = FALSE)
#' reaches <- rsparrow_hydseq(sparrow_example$reaches)
#' write.csv(reaches, file.path(td, "data1.csv"), row.names = FALSE)
#' model <- rsparrow_model(td, run_id = "ex")
#' vcov(model)
#' }
vcov.rsparrow <- function(object, ...) object$vcov
