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
#' coef(model)
#' }
coef.rsparrow <- function(object, ...) object$coefficients
