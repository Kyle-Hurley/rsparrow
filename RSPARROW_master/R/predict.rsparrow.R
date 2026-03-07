#' Predict Method for SPARROW Models
#'
#' Computes reach-level predictions of contaminant loads, yields, and delivery
#' fractions from an estimated SPARROW model. Predictions use the estimated
#' coefficients and can be generated for the original network or new data.
#'
#' @param object An object of class "rsparrow" (output from \code{\link{rsparrow_model}}).
#' @param newdata Optional data.frame with new reach network data. Must have the same
#'   structure as the original estimation data. If NULL (default), predictions are
#'   made for the original network.
#' @param type Character. Type of prediction to compute:
#'   \describe{
#'     \item{"all"}{All prediction types (default)}
#'     \item{"loads"}{Total contaminant loads by reach}
#'     \item{"yields"}{Loads per unit drainage area}
#'     \item{"delivery"}{Delivery fractions from each reach to outlet}
#'   }
#' @param ... Additional arguments (currently unused).
#'
#' @return The input rsparrow object with the \code{predictions} list component populated.
#'   \code{predictions} contains data.frames with one row per reach:
#'   \describe{
#'     \item{loads}{Total predicted loads}
#'     \item{yields}{Predicted yields (load / drainage area)}
#'     \item{delivery_fractions}{Fraction of load delivered to outlet}
#'     \item{incremental_loads}{Load generated within each reach}
#'   }
#'
#' @export
#' @method predict rsparrow
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{rsparrow_scenario}}
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' model_pred <- predict(model, type = "all")
#' head(model_pred$predictions$loads)
#' }
predict.rsparrow <- function(object, newdata = NULL,
                             type = c("all", "loads", "yields", "delivery"), ...) {
  if (!inherits(object, "rsparrow"))
    stop("object must be of class 'rsparrow'")
  type <- match.arg(type)

  # Boot correction factor: use the model-level mean_exp_weighted_error when
  # available; if bootstrap has also been run, the model factor already reflects
  # the fitted residuals and is the appropriate scalar for standard predictions.
  estimate_list <- object_to_estimate_list(object)
  bootcorrection <- if (!is.null(estimate_list$JacobResults$mean_exp_weighted_error))
    estimate_list$JacobResults$mean_exp_weighted_error
  else
    1.0

  predict_list <- predict_sparrow(
    estimate.list       = estimate_list,
    estimate.input.list = object$data$estimate.input.list,
    bootcorrection      = bootcorrection,
    DataMatrix.list     = object$data$DataMatrix.list,
    SelParmValues       = object$data$SelParmValues,
    subdata             = object$data$subdata,
    dlvdsgn             = object$data$dlvdsgn
  )

  object$predictions <- predict_list
  object
}

# Internal helper: return the estimate.list stored in the rsparrow S3 object.
# This is used by predict.rsparrow(), rsparrow_bootstrap(), rsparrow_validate(),
# and rsparrow_scenario() to pass a complete estimate.list to the internal
# functions that expect it.
object_to_estimate_list <- function(object) {
  el <- object$data$estimate.list
  if (is.null(el))
    stop("estimate.list not found in model$data. Re-run rsparrow_model().")
  el
}
