#' Diagnostic Plots for SPARROW Models
#'
#' Produces diagnostic plots for a fitted SPARROW model using base R graphics.
#' Three plot types are available: residual panels (estimation performance),
#' parameter sensitivity, and spatial autocorrelation of residuals.
#'
#' @param x An object of class \code{"rsparrow"}.
#' @param type Character. One of \code{"residuals"}, \code{"sensitivity"}, or
#'   \code{"spatial"}. Selects the diagnostic plot type.
#' @param ... Additional arguments. For \code{type = "residuals"}, the
#'   \code{panel} argument selects which 4-panel group to display: \code{"A"}
#'   (observed vs. predicted and residuals), \code{"B"} (boxplots and Q-Q),
#'   or \code{"both"}.
#'
#' @return Called for its side effects (plots drawn to the current graphics
#'   device). Returns \code{NULL} invisibly.
#'
#' @export
#' @method plot rsparrow
#'
#' @seealso \code{\link{summary.rsparrow}}, \code{\link{residuals.rsparrow}}
#'
#' @examples
#' \donttest{
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix,
#'   sparrow_example$data_dictionary
#' )
#' plot(model, type = "residuals")
#' plot(model, type = "residuals", panel = "B")
#' }
plot.rsparrow <- function(x, type = c("residuals", "sensitivity", "spatial"), ...) {
  type <- match.arg(type)
  switch(type,
    residuals   = .rsparrow_plot_residuals(x, ...),
    sensitivity = .rsparrow_plot_sensitivity(x, ...),
    spatial     = .rsparrow_plot_spatial(x, ...)
  )
}


# Internal: residual plots -------------------------------------------------------

.rsparrow_plot_residuals <- function(x, panel = c("A", "B", "both"), ...) {
  panel <- match.arg(panel)
  d  <- x$data
  Md <- d$estimate.list$Mdiagnostics.list
  mp <- d$mapping.input.list

  if (panel %in% c("A", "both")) {
    diagnosticPlots_4panel_A(
      Md$predict, Md$Obs, Md$yldpredict, Md$yldobs, Md$Resids,
      plotclass = NA,
      plotTitles = c(
        "MODEL ESTIMATION PERFORMANCE\n(Monitoring-Adjusted Predictions)\nObserved vs Predicted Load",
        "MODEL ESTIMATION PERFORMANCE\nObserved vs Predicted Yield",
        "Residuals vs Predicted Load",
        "Residuals vs Predicted Yield"
      ),
      loadUnits  = mp$loadUnits,
      yieldUnits = mp$yieldUnits,
      filterClass = NA
    )
  }
  if (panel %in% c("B", "both")) {
    diagnosticPlots_4panel_B(
      Md$Resids, Md$ratio.obs.pred, Md$standardResids, Md$predict,
      plotTitles = c(
        "MODEL ESTIMATION PERFORMANCE\nResiduals",
        "MODEL ESTIMATION PERFORMANCE\nObserved / Predicted Ratio",
        "Normal Q-Q Plot",
        "Squared Residuals vs Predicted Load"
      ),
      loadUnits = mp$loadUnits
    )
  }
  invisible(NULL)
}


# Internal: sensitivity plots ----------------------------------------------------

.rsparrow_plot_sensitivity <- function(x, ...) {
  d <- x$data
  classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar
  class.input.list <- list(classvar = classvar, class_landuse = NA)
  sitedata.demtarea.class <- d$sitedata$demtarea
  invisible(diagnosticSensitivity(
    file.output.list        = d$file.output.list,
    class.input.list        = class.input.list,
    estimate.input.list     = d$estimate.input.list,
    estimate.list           = d$estimate.list,
    DataMatrix.list         = d$DataMatrix.list,
    SelParmValues           = d$SelParmValues,
    subdata                 = d$subdata,
    sitedata.demtarea.class = sitedata.demtarea.class,
    mapping.input.list      = d$mapping.input.list,
    dlvdsgn                 = d$dlvdsgn
  ))
}


# Internal: spatial autocorrelation plots ----------------------------------------

.rsparrow_plot_spatial <- function(x, ...) {
  d <- x$data
  classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar
  class.input.list <- list(classvar = classvar, class_landuse = NA)
  min.sites.list <- list(
    minimum_headwater_site_area      = 0,
    minimum_reaches_separating_sites = 0,
    minimum_site_incremental_area    = 0
  )
  invisible(diagnosticSpatialAutoCorr(
    file.output.list    = d$file.output.list,
    sitedata            = d$sitedata,
    estimate.list       = d$estimate.list,
    estimate.input.list = d$estimate.input.list,
    mapping.input.list  = d$mapping.input.list,
    subdata             = d$subdata,
    min.sites.list      = min.sites.list,
    class.input.list    = class.input.list,
    DataMatrix.list     = d$DataMatrix.list
  ))
}
