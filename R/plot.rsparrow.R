#' Diagnostic Plots for SPARROW Models
#'
#' Produces diagnostic plots for a fitted SPARROW model using base R graphics.
#' Three plot types are available: residual panels (estimation performance),
#' parameter sensitivity, and spatial autocorrelation of residuals.
#'
#' @param x An object of class \code{"rsparrow"}.
#' @param type Character. One of:
#'   \itemize{
#'     \item \code{"residuals"} — Estimation residual panels (4-panel A/B)
#'     \item \code{"sensitivity"} — Parameter sensitivity analysis
#'     \item \code{"spatial"} — Spatial autocorrelation of residuals
#'     \item \code{"simulation"} — Simulation (unconditioned) performance panels
#'     \item \code{"class"} — By-class (classvar group) diagnostic panels
#'     \item \code{"ratio"} — Obs/pred ratio by drainage area and classvar
#'     \item \code{"validation"} — Validation performance panels (requires
#'       validation data in \code{estimate.list$vMdiagnostics.list})
#'     \item \code{"bootstrap"} — Bootstrap coefficient uncertainty
#'       (requires prior call to \code{\link{rsparrow_bootstrap}})
#'   }
#' @param ... Additional arguments. For \code{type = "residuals"},
#'   \code{"simulation"}, or \code{"validation"}, the \code{panel} argument
#'   selects which 4-panel group: \code{"A"} (observed vs. predicted and
#'   residuals), \code{"B"} (boxplots and Q-Q), or \code{"both"}.
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
plot.rsparrow <- function(x, type = c("residuals", "sensitivity", "spatial",
                                       "simulation", "class", "ratio",
                                       "validation", "bootstrap"), ...) {
  type <- match.arg(type)
  switch(type,
    residuals   = .rsparrow_plot_residuals(x, ...),
    sensitivity = .rsparrow_plot_sensitivity(x, ...),
    spatial     = .rsparrow_plot_spatial(x, ...),
    simulation  = .rsparrow_plot_simulation(x, ...),
    class       = .rsparrow_plot_class(x, ...),
    ratio       = .rsparrow_plot_ratio(x, ...),
    validation  = .rsparrow_plot_validation(x, ...),
    bootstrap   = .rsparrow_plot_bootstrap(x, ...)
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


# Internal: simulation performance plots -----------------------------------------

.rsparrow_plot_simulation <- function(x, panel = c("A", "B", "both"), ...) {
  panel <- match.arg(panel)
  d  <- x$data
  Md <- d$estimate.list$Mdiagnostics.list
  mp <- d$mapping.input.list

  if (panel %in% c("A", "both")) {
    diagnosticPlots_4panel_A(
      Md$ppredict, Md$Obs, Md$pyldpredict, Md$pyldobs, Md$pResids,
      plotclass = NA,
      plotTitles = c(
        "MODEL SIMULATION PERFORMANCE\nObserved vs Predicted Load",
        "MODEL SIMULATION PERFORMANCE\nObserved vs Predicted Yield",
        "Residuals vs Predicted Load",
        "Residuals vs Predicted Yield"
      ),
      loadUnits = mp$loadUnits, yieldUnits = mp$yieldUnits, filterClass = NA
    )
  }
  if (panel %in% c("B", "both")) {
    diagnosticPlots_4panel_B(
      Md$pResids, Md$pratio.obs.pred, NA, Md$ppredict,
      plotTitles = c(
        "MODEL SIMULATION PERFORMANCE\nResiduals",
        "MODEL SIMULATION PERFORMANCE\nObserved / Predicted Ratio",
        "Normal Q-Q Plot",
        "Squared Residuals vs Predicted Load"
      ),
      loadUnits = mp$loadUnits
    )
  }
  invisible(NULL)
}


# Internal: by-class diagnostic plots --------------------------------------------

.rsparrow_plot_class <- function(x, ...) {
  d  <- x$data
  Md <- d$estimate.list$Mdiagnostics.list
  mp <- d$mapping.input.list
  classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar

  sitedata <- d$sitedata
  class_vals <- as.numeric(sitedata[[classvar[1]]])
  grp <- sort(unique(class_vals[!is.na(class_vals)]))

  for (i in seq_along(grp)) {
    nsites_i <- sum(!is.na(class_vals) & class_vals == grp[i])
    diagnosticPlots_4panel_A(
      Md$predict, Md$Obs, Md$yldpredict, Md$yldobs, Md$Resids,
      plotclass = class_vals,
      plotTitles = c(
        paste0("Observed vs Predicted Load\nClass = ", grp[i], " (n=", nsites_i, ")"),
        "Observed vs Predicted Yield",
        "Residuals vs Predicted Load",
        "Residuals vs Predicted Yield"
      ),
      loadUnits = mp$loadUnits, yieldUnits = mp$yieldUnits,
      filterClass = as.double(grp[i])
    )
  }
  invisible(NULL)
}


# Internal: obs/pred ratio plots -------------------------------------------------

.rsparrow_plot_ratio <- function(x, ...) {
  d  <- x$data
  Md <- d$estimate.list$Mdiagnostics.list
  classvar <- if (identical(d$classvar, NA_character_)) "sitedata.demtarea.class" else d$classvar
  sitedata <- d$sitedata

  demtarea.class <- calcDemtareaClass(sitedata$demtarea)
  boxplot(Md$ratio.obs.pred ~ demtarea.class,
          xlab = "Upper Bound for Total Drainage Area Deciles (km\u00B2)",
          ylab = "Observed to Predicted Ratio",
          main = "Ratio Obs/Pred by Drainage Area Deciles",
          las = 2, cex.axis = 0.7, col = "white", border = "black", log = "y")
  abline(h = 1, col = "red", lty = 2, lwd = 1.5)

  if (!identical(classvar[1], "sitedata.demtarea.class")) {
    for (k in seq_along(classvar)) {
      vvar <- as.numeric(sitedata[[classvar[k]]])
      boxplot(Md$ratio.obs.pred ~ vvar,
              xlab = classvar[k],
              ylab = "Observed to Predicted Ratio",
              main = "Ratio Observed to Predicted",
              las = 2, cex.axis = 0.7, col = "white", border = "black", log = "y")
      abline(h = 1, col = "red", lty = 2, lwd = 1.5)
    }
  }
  invisible(NULL)
}


# Internal: validation performance plots -----------------------------------------

.rsparrow_plot_validation <- function(x, panel = c("A", "B", "both"), ...) {
  panel <- match.arg(panel)
  d  <- x$data
  vMd <- d$estimate.list$vMdiagnostics.list
  if (is.null(vMd)) {
    stop("Validation diagnostics not available. Run rsparrow_model() with if_validate=TRUE ",
         "or call rsparrow_validate() first.", call. = FALSE)
  }
  mp <- d$mapping.input.list

  if (panel %in% c("A", "both")) {
    diagnosticPlots_4panel_A(
      vMd$ppredict, vMd$Obs, vMd$pyldpredict, vMd$pyldobs, vMd$pResids,
      plotclass = NA,
      plotTitles = c(
        "MODEL VALIDATION PERFORMANCE\nObserved vs Predicted Load",
        "MODEL VALIDATION PERFORMANCE\nObserved vs Predicted Yield",
        "Residuals vs Predicted Load",
        "Residuals vs Predicted Yield"
      ),
      loadUnits = mp$loadUnits, yieldUnits = mp$yieldUnits, filterClass = NA
    )
  }
  if (panel %in% c("B", "both")) {
    diagnosticPlots_4panel_B(
      vMd$pResids, vMd$pratio.obs.pred, NA, vMd$ppredict,
      plotTitles = c(
        "MODEL VALIDATION PERFORMANCE\nResiduals",
        "MODEL VALIDATION PERFORMANCE\nObserved / Predicted Ratio",
        "Normal Q-Q Plot",
        "Squared Residuals vs Predicted Load"
      ),
      loadUnits = mp$loadUnits
    )
  }
  invisible(NULL)
}


# Internal: bootstrap coefficient uncertainty plots ------------------------------

.rsparrow_plot_bootstrap <- function(x, ...) {
  boot <- x$bootstrap
  if (is.null(boot)) {
    stop("Bootstrap results not available. Call rsparrow_bootstrap() first.",
         call. = FALSE)
  }

  boot_beta  <- boot$bEstimate
  parm_names <- x$data$estimate.list$JacobResults$Parmnames
  if (is.null(boot_beta) || is.null(parm_names)) {
    stop("Bootstrap coefficient data not found in expected format.", call. = FALSE)
  }

  ncoef <- ncol(boot_beta)
  nr <- ceiling(sqrt(ncoef))
  nc <- ceiling(ncoef / nr)
  op <- par(mfrow = c(nr, nc), mar = c(4, 4, 3, 1))
  on.exit(par(op))

  for (j in seq_len(ncoef)) {
    vals <- boot_beta[, j]
    vals <- vals[is.finite(vals)]
    if (length(vals) < 2) next
    ci <- quantile(vals, c(0.025, 0.975))
    hist(vals,
         main   = parm_names[j],
         xlab   = "Coefficient Value",
         col    = "lightblue", border = "white",
         breaks = 30)
    abline(v = ci, col = "red", lty = 2, lwd = 1.5)
    abline(v = mean(vals), col = "blue", lwd = 2)
    legend("topright", legend = c("Mean", "95% CI"),
           col = c("blue", "red"), lty = c(1, 2), lwd = c(2, 1.5),
           cex = 0.7, bg = "white")
  }
  invisible(NULL)
}
