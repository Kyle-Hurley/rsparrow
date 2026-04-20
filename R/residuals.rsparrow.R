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
#' residuals(model)
#' }
residuals.rsparrow <- function(object, type = "response", ...) object$residuals
