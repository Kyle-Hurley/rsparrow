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
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix,
#'   sparrow_example$data_dictionary
#' )
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
