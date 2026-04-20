#' Write rsparrow model results to disk
#'
#' Writes model results (estimates, predictions, diagnostics) to a directory.
#' This is the single opt-in file-output function for the rsparrow package;
#' computation functions do not write files as side effects.
#'
#' @param model An \code{rsparrow} object returned by \code{\link{rsparrow_model}}.
#' @param path Character. Directory to write results into. Created recursively if
#'   it does not exist.
#' @param what Character vector of result types to write. Options:
#'   \code{"estimates"}, \code{"predictions"}, \code{"diagnostics"}, \code{"all"}.
#'   Default: \code{"all"}.
#' @return Invisibly returns a character vector of paths of the files written.
#' @export
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
#' write_rsparrow_results(model, path = tempdir(), what = "estimates")
#' }
write_rsparrow_results <- function(model, path, what = "all") {
  stopifnot(inherits(model, "rsparrow"))
  stopifnot(is.character(path), length(path) == 1L)
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)

  all_what <- c("estimates", "predictions", "diagnostics")
  if (identical(what, "all")) what <- all_what
  what <- match.arg(what, all_what, several.ok = TRUE)

  written <- character(0)

  if ("estimates" %in% what) {
    # TODO: write estimate tables from model$data$estimate.list via data.table::fwrite()
    message("write_rsparrow_results: 'estimates' output not yet implemented.")
  }
  if ("predictions" %in% what) {
    # TODO: write prediction tables from model$predictions
    message("write_rsparrow_results: 'predictions' output not yet implemented.")
  }
  if ("diagnostics" %in% what) {
    # TODO: write correlation matrix, ANOVA tables, spatial autocorrelation summary
    message("write_rsparrow_results: 'diagnostics' output not yet implemented.")
  }

  invisible(written)
}
