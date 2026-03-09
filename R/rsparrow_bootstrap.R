#' Bootstrap Uncertainty Estimation for SPARROW Models
#'
#' Performs parametric bootstrap to estimate coefficient uncertainty and
#' prediction intervals for a fitted SPARROW model.
#'
#' @param object An object of class "rsparrow" (output from \code{\link{rsparrow_model}}).
#' @param n_boot Integer. Number of bootstrap iterations (default: 100).
#' @param seed Integer or NULL. Random seed for reproducibility. If NULL
#'   (default), a random seed is generated.
#' @param ... Additional arguments passed to the internal bootstrap routine.
#'
#' @return The input rsparrow object with bootstrap results added to the
#'   \code{bootstrap} component, including:
#'   \describe{
#'     \item{bEstimate}{Matrix of bootstrap coefficient estimates (n_boot x n_params)}
#'     \item{bootmean_exp_weighted_error}{Numeric vector of bootstrap mean exponential
#'       weighted errors, one per iteration}
#'     \item{boot_resids}{Matrix of bootstrap residuals}
#'     \item{boot_lev}{Matrix of bootstrap leverage values}
#'   }
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{predict.rsparrow}}
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' model <- rsparrow_bootstrap(model, n_boot = 200, seed = 42)
#' model$bootstrap$bEstimate
#' }
rsparrow_bootstrap <- function(object, n_boot = 100L, seed = NULL, ...) {
  if (!inherits(object, "rsparrow"))
    stop("object must be of class 'rsparrow'")
  if (!is.numeric(n_boot) || n_boot < 10 || n_boot > 10000)
    stop("n_boot must be a numeric value between 10 and 10000")

  iseed <- seed %||% sample.int(.Machine$integer.max, 1L)
  if (!is.null(seed)) set.seed(seed)

  boot_results <- estimateBootstraps(
    iseed               = iseed,
    biters              = as.integer(n_boot),
    estimate.list       = object_to_estimate_list(object),
    DataMatrix.list     = object$data$DataMatrix.list,
    SelParmValues       = object$data$SelParmValues,
    Csites.weights.list = object$data$Csites.weights.list,
    estimate.input.list = object$data$estimate.input.list,
    dlvdsgn             = object$data$dlvdsgn,
    file.output.list    = object$data$file.output.list
  )

  object$bootstrap <- boot_results
  object
}
