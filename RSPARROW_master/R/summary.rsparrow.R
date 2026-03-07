#' Summarize SPARROW Model Results
#'
#' Produces a summary of SPARROW model estimation including a coefficient table
#' with standard errors, z-values, p-values, and model fit statistics.
#'
#' @param object An object of class "rsparrow".
#' @param ... Additional arguments (currently unused).
#'
#' @return An object of class "summary.rsparrow" (a list) containing:
#'   \describe{
#'     \item{call}{The original model call}
#'     \item{coefficients}{Matrix with estimates, std errors, z-values, p-values}
#'     \item{fit_stats}{Model fit statistics (AIC, BIC, R-squared, RMSE, log-likelihood)}
#'     \item{n_obs}{Number of monitoring sites used in estimation}
#'     \item{n_reach}{Number of reaches in network}
#'   }
#'
#' @export
#' @method summary rsparrow
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{coef.rsparrow}}
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' summary(model)
#' }
summary.rsparrow <- function(object, ...) {
  t_vals <- object$coefficients / object$std_errors
  p_vals <- 2 * stats::pt(-abs(t_vals),
              df = object$fit_stats$nobs - object$fit_stats$npar)
  coef_table <- data.frame(
    Estimate  = object$coefficients,
    Std.Error = object$std_errors,
    t.value   = t_vals,
    p.value   = p_vals,
    row.names = names(object$coefficients)
  )
  structure(
    list(
      call       = object$call,
      coef_table = coef_table,
      fit_stats  = object$fit_stats,
      metadata   = object$metadata
    ),
    class = "summary.rsparrow"
  )
}

#' @method print summary.rsparrow
#' @export
print.summary.rsparrow <- function(x, digits = 4, ...) {
  cat("SPARROW Model Summary\n")
  cat("Run:", x$metadata$run_id, "  Type:", x$metadata$model_type, "\n\n")
  cat("Coefficients:\n")
  print(round(x$coef_table, digits))
  cat("\nFit Statistics:\n")
  cat("  R-squared:", round(x$fit_stats$R2, digits), "\n")
  cat("  RMSE:     ", round(x$fit_stats$RMSE, digits), "\n")
  cat("  N obs:    ", x$fit_stats$nobs, "\n")
  cat("  N par:    ", x$fit_stats$npar, "\n")
  invisible(x)
}
