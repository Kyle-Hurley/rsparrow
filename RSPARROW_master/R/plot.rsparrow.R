#' Diagnostic Plots for SPARROW Models
#'
#' Produces diagnostic plots for a fitted SPARROW model. Three plot types are
#' available: residual panels (estimation performance), parameter sensitivity,
#' and spatial autocorrelation of residuals.
#'
#' @param x An object of class \code{"rsparrow"}.
#' @param type Character. One of \code{"residuals"}, \code{"sensitivity"}, or
#'   \code{"spatial"}. Selects the diagnostic plot type.
#' @param ... Additional arguments passed to the internal dispatch function.
#'   For \code{type = "residuals"}, the \code{panel} argument selects which
#'   4-panel group to display: \code{"A"} (observed vs. predicted and residuals),
#'   \code{"B"} (boxplots and Q-Q), or \code{"both"}.
#'
#' @return A named list of plotly plot objects, returned invisibly. For
#'   \code{type = "residuals"}, elements \code{panelA} and/or \code{panelB}. For
#'   \code{type = "sensitivity"} and \code{"spatial"}, whatever the underlying
#'   diagnostic function returns.
#'
#' @export
#' @method plot rsparrow
#'
#' @seealso \code{\link{summary.rsparrow}}, \code{\link{residuals.rsparrow}}
#'
#' @examples
#' \dontrun{
#' model <- rsparrow_model("~/my_model/")
#' plot(model, type = "residuals")
#' plot(model, type = "residuals", panel = "B")
#' plot(model, type = "sensitivity")
#' plot(model, type = "spatial")
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
  d   <- x$data
  Md  <- d$estimate.list$Mdiagnostics.list
  mp  <- d$mapping.input.list

  pnch <- as.character(mp$pchPlotlyCross[mp$pchPlotlyCross$pch == mp$diagnosticPlotPointStyle, ]$plotly)
  markerSize <- mp$diagnosticPlotPointSize * 10
  markerCols <- colorNumeric(c("black", "white"), 1:2)
  test <- regexpr("open", pnch) > 0
  if (test) {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1))
  } else {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1),
                       line = list(color = markerCols(1), width = 0.8))
  }

  out <- list()
  if (panel %in% c("A", "both")) {
    out[["panelA"]] <- diagnosticPlots_4panel_A(
      Md$predict, Md$Obs, Md$yldpredict, Md$yldobs, d$sitedata, Md$Resids,
      plotclass = NA,
      plotTitles = c(
        "'MODEL ESTIMATION PERFORMANCE \n(Monitoring-Adjusted Predictions) \nObserved vs    Predicted Load'",
        "'MODEL ESTIMATION PERFORMANCE \nObserved vs Predicted Yield'",
        "'Residuals vs Predicted \nLoad'",
        "'Residuals vs Predicted \nYield'"
      ),
      mp$loadUnits, mp$yieldUnits, mp$showPlotGrid, markerList, mp$add_plotlyVars,
      pnch, markerCols, hline, filterClass = NA
    )
  }
  if (panel %in% c("B", "both")) {
    out[["panelB"]] <- diagnosticPlots_4panel_B(
      d$sitedata, Md$Resids, Md$ratio.obs.pred, Md$standardResids, Md$predict,
      plotTitles = c(
        "'MODEL ESTIMATION PERFORMANCE \nResiduals'",
        "'MODEL ESTIMATION PERFORMANCE \nObserved / Predicted Ratio'",
        "'Normal Q-Q Plot'",
        "'Squared Residuals vs Predicted Load'"
      ),
      mp$loadUnits, mp$yieldUnits, mp$showPlotGrid, markerList, mp$add_plotlyVars,
      pnch, markerCols, hline
    )
  }
  invisible(out)
}


# Internal: sensitivity plots ----------------------------------------------------

.rsparrow_plot_sensitivity <- function(x, ...) {
  d <- x$data
  classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar
  class.input.list <- list(classvar = classvar, class_landuse = NA)
  # Use raw demtarea as proxy for quantile-classified sitedata.demtarea.class
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
