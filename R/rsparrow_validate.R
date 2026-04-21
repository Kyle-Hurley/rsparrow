#' Cross-Validation Diagnostics for SPARROW Models
#'
#' Computes validation metrics using held-out monitoring sites that were
#' separated from the calibration set when the model was estimated with
#' \code{if_validate = "yes"}. Reports performance statistics at the
#' validation sites.
#'
#' @param object An object of class "rsparrow" (output from
#'   \code{\link{rsparrow_model}} called with \code{if_validate = "yes"}).
#' @param ... Additional arguments (currently unused).
#'
#' @return The input rsparrow object with validation results added to the
#'   \code{validation} component, a named list including:
#'   \describe{
#'     \item{vANOVA.list}{ANOVA statistics for validation sites}
#'     \item{vMdiagnostics.list}{Diagnostic metrics at validation sites}
#'   }
#'
#' @details
#' Validation data must have been prepared when the model was originally
#' estimated. If the model was estimated without \code{if_validate = "yes"},
#' this function will stop with an informative error.
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{summary.rsparrow}}
#'
#' @examples
#' \donttest{
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix,
#'   sparrow_example$data_dictionary,
#'   if_validate = TRUE
#' )
#' model <- rsparrow_validate(model)
#' }
rsparrow_validate <- function(object, ...) {
  if (!inherits(object, "rsparrow"))
    stop("object must be of class 'rsparrow'")

  if (is.null(object$data$Vsites.list) || is.null(object$data$vsitedata))
    stop(paste0(
      "Validation data not available. ",
      "Re-run rsparrow_model() with if_validate = 'yes'."
    ))

  # classvar is always "sitedata.demtarea.class" at minimum when sites exist;
  # fall back to that name if it was somehow not stored.
  classvar <- object$data$classvar
  if (is.null(classvar) || all(is.na(classvar)))
    classvar <- "sitedata.demtarea.class"

  val_results <- validateMetrics(
    classvar      = classvar,
    estimate.list = object_to_estimate_list(object),
    dlvdsgn       = object$data$dlvdsgn,
    Vsites.list   = object$data$Vsites.list,
    yieldFactor   = object$data$estimate.input.list$yieldFactor,
    SelParmValues = object$data$SelParmValues,
    subdata       = object$data$subdata,
    vsitedata     = object$data$vsitedata,
    DataMatrix.list = object$data$DataMatrix.list
  )

  object$validation <- val_results
  object
}
