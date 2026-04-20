#' Print SPARROW Model Object
#'
#' Prints a concise summary of a fitted SPARROW model, including model type,
#' the original call, estimated coefficients, and key fit statistics.
#'
#' @param x An object of class "rsparrow".
#' @param digits Number of significant digits to display (default 4).
#' @param ... Additional arguments (currently unused).
#'
#' @return Invisible \code{x}. Called for its side effect of printing to the console.
#'
#' @export
#' @method print rsparrow
#'
#' @seealso \code{\link{summary.rsparrow}}, \code{\link{rsparrow_model}}
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
#' print(model)
#' }
print.rsparrow <- function(x, digits = 4, ...) {
  cat("SPARROW Model (rsparrow ", as.character(x$metadata$version), ")\n", sep = "")
  cat("Run ID     :", x$metadata$run_id, "\n")
  cat("Model type :", x$metadata$model_type, "\n")
  cat("Parameters :", length(x$coefficients), "\n")
  cat("Cal. sites :", nrow(x$data$sitedata), "\n")
  cat("R-squared  :", round(x$fit_stats$R2, digits), "\n")
  cat("RMSE       :", round(x$fit_stats$RMSE, digits), "\n\n")
  cat("Coefficients:\n")
  print(round(x$coefficients, digits))
  invisible(x)
}
