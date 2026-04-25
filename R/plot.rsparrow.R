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
#'     \item \code{"results"} — Model output visualizations (predicted loads,
#'       yields, source attribution). Use the \code{subtype} argument to select
#'       which panel: \code{"profile"} (default), \code{"network"},
#'       \code{"map"}, \code{"sources"}, or \code{"obs_pred"}.
#'   }
#' @param ... Additional arguments passed to the subtype dispatcher.
#'   For \code{type = "residuals"}, \code{"simulation"}, or
#'   \code{"validation"}, the \code{panel} argument selects which 4-panel
#'   group: \code{"A"} (observed vs. predicted and residuals), \code{"B"}
#'   (boxplots and Q-Q), or \code{"both"}.
#'   For \code{type = "results"}, the \code{subtype} argument selects the
#'   panel (\code{"profile"}, \code{"network"}, \code{"map"},
#'   \code{"sources"}, \code{"obs_pred"}); \code{"map"} also accepts a
#'   \code{variable} argument (\code{"load"}, \code{"yield"}, or
#'   \code{"concentration"}).
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
                                       "validation", "bootstrap", "results"), ...) {
  type <- match.arg(type)
  switch(type,
    residuals   = .rsparrow_plot_residuals(x, ...),
    sensitivity = .rsparrow_plot_sensitivity(x, ...),
    spatial     = .rsparrow_plot_spatial(x, ...),
    simulation  = .rsparrow_plot_simulation(x, ...),
    class       = .rsparrow_plot_class(x, ...),
    ratio       = .rsparrow_plot_ratio(x, ...),
    validation  = .rsparrow_plot_validation(x, ...),
    bootstrap   = .rsparrow_plot_bootstrap(x, ...),
    results     = .rsparrow_plot_results(x, ...)
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


# Internal: results dispatcher ---------------------------------------------------

.rsparrow_plot_results <- function(x,
                                   subtype = c("profile", "network", "map",
                                               "sources", "obs_pred"), ...) {
  subtype <- match.arg(subtype)
  if (subtype != "obs_pred" && is.null(x$predictions))
    stop("Predictions not available. Call predict(model) or use if_predict=TRUE.",
         call. = FALSE)
  switch(subtype,
    profile  = .rsparrow_plot_results_profile(x, ...),
    network  = .rsparrow_plot_results_network(x, ...),
    map      = .rsparrow_plot_results_map(x, ...),
    sources  = .rsparrow_plot_results_sources(x, ...),
    obs_pred = .rsparrow_plot_results_obs_pred(x, ...)
  )
}


# Internal: results — D (hydseq profile) ----------------------------------------

.rsparrow_plot_results_profile <- function(x, ...) {
  pred <- x$predictions
  mp   <- x$data$mapping.input.list

  pm <- as.data.frame(pred$predmatrix)
  names(pm) <- pred$oparmlist
  ym <- as.data.frame(pred$yldmatrix)
  names(ym) <- pred$oyieldlist

  sd <- x$data$subdata[, c("waterid", "demtarea", "hydseq"), drop = FALSE]

  df <- merge(pm[, c("waterid", "pload_total"), drop = FALSE],
              ym[, c("waterid", "yield_total"), drop = FALSE], by = "waterid")
  df <- merge(df, sd, by = "waterid")
  df <- df[order(df$hydseq), ]
  df$reach_idx <- seq_len(nrow(df))

  cex_pt <- 0.4 + 0.8 * sqrt(pmax(df$demtarea, 0)) /
    max(sqrt(pmax(df$demtarea, 0)), na.rm = TRUE)

  op <- par(mfrow = c(2, 1), mar = c(4, 5, 3, 1))
  on.exit(par(op))

  plot(df$reach_idx, df$pload_total, type = "l", lwd = 0.8,
       xlab = "Reach Index (sorted by hydrological sequence)",
       ylab = paste0("Total Load (", mp$loadUnits, ")"),
       main = "Predicted Total Load by Hydrological Sequence")
  points(df$reach_idx, df$pload_total, pch = 20, cex = cex_pt, col = "steelblue")

  plot(df$reach_idx, df$yield_total, type = "l", lwd = 0.8,
       xlab = "Reach Index (sorted by hydrological sequence)",
       ylab = paste0("Total Yield (", mp$yieldUnits, ")"),
       main = "Predicted Total Yield by Hydrological Sequence")
  points(df$reach_idx, df$yield_total, pch = 20, cex = cex_pt, col = "darkorange")

  invisible(NULL)
}


# Internal: results — A (load vs drainage area network scatter) ------------------

.rsparrow_plot_results_network <- function(x, ...) {
  pred <- x$predictions
  mp   <- x$data$mapping.input.list
  Md   <- x$data$estimate.list$Mdiagnostics.list

  pm <- as.data.frame(pred$predmatrix)
  names(pm) <- pred$oparmlist
  ym <- as.data.frame(pred$yldmatrix)
  names(ym) <- pred$oyieldlist

  sd <- x$data$subdata[, c("waterid", "demtarea"), drop = FALSE]

  df <- merge(pm[, c("waterid", "pload_total"), drop = FALSE],
              ym[, c("waterid", "yield_total"), drop = FALSE], by = "waterid")
  df <- merge(df, sd, by = "waterid")

  log_da  <- log(pmax(df$demtarea, 1e-6))
  brks    <- seq(min(log_da), max(log_da) + 1e-10, length.out = 101)
  col_idx <- cut(log_da, breaks = brks, include.lowest = TRUE, labels = FALSE)
  col_idx[is.na(col_idx)] <- 1L
  pal <- heat.colors(100)

  op <- par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))
  on.exit(par(op))

  log_load <- log(pmax(df$pload_total, 1e-10))
  plot(log_da, log_load,
       pch = 20, cex = 0.7, col = pal[col_idx],
       xlab = "log(Drainage Area) (km\u00B2)",
       ylab = paste0("log(Total Load) (", mp$loadUnits, ")"),
       main = "Load vs Drainage Area")
  if (!is.null(Md$tarea) && !is.null(Md$Obs))
    points(log(pmax(Md$tarea, 1e-6)), log(pmax(Md$Obs, 1e-10)),
           pch = 1, cex = 1.4, col = "black")

  log_yld <- log(pmax(df$yield_total, 1e-10))
  plot(log_da, log_yld,
       pch = 20, cex = 0.7, col = pal[col_idx],
       xlab = "log(Drainage Area) (km\u00B2)",
       ylab = paste0("log(Total Yield) (", mp$yieldUnits, ")"),
       main = "Yield vs Drainage Area")
  if (!is.null(Md$tarea) && !is.null(Md$yldobs))
    points(log(pmax(Md$tarea, 1e-6)), log(pmax(Md$yldobs, 1e-10)),
           pch = 1, cex = 1.4, col = "black")

  invisible(NULL)
}


# Internal: results — B (spatial dot map) ----------------------------------------

.rsparrow_plot_results_map <- function(x,
                                       variable = c("load", "yield", "concentration"),
                                       ...) {
  variable <- match.arg(variable)
  pred <- x$predictions
  mp   <- x$data$mapping.input.list
  Md   <- x$data$estimate.list$Mdiagnostics.list

  sd <- x$data$subdata
  if (!all(c("lat", "lon") %in% names(sd)))
    stop("subdata does not contain 'lat' and 'lon' columns required for map plot.",
         call. = FALSE)
  sd <- sd[, c("waterid", "lat", "lon"), drop = FALSE]

  pm <- as.data.frame(pred$predmatrix)
  names(pm) <- pred$oparmlist
  ym <- as.data.frame(pred$yldmatrix)
  names(ym) <- pred$oyieldlist

  df <- merge(pm[, c("waterid", "pload_total"), drop = FALSE],
              ym[, c("waterid", "yield_total", "concentration"), drop = FALSE],
              by = "waterid")
  df <- merge(df, sd, by = "waterid")

  z_col <- switch(variable,
    load          = "pload_total",
    yield         = "yield_total",
    concentration = "concentration"
  )
  z_units <- switch(variable,
    load          = mp$loadUnits,
    yield         = mp$yieldUnits,
    concentration = {
      u <- x$data$estimate.input.list$ConcUnits
      if (is.null(u)) "" else u
    }
  )
  z_label <- paste0(
    toupper(substr(variable, 1, 1)), substr(variable, 2, nchar(variable))
  )

  z     <- df[[z_col]]
  log_z <- log(pmax(z, 1e-10))
  pal   <- colorRampPalette(c("green", "purple"))(100)
  brks  <- seq(min(log_z, na.rm = TRUE), max(log_z, na.rm = TRUE) + 1e-10,
               length.out = 101)
  col_idx <- cut(log_z, breaks = brks, include.lowest = TRUE, labels = FALSE)
  col_idx[is.na(col_idx)] <- 1L

  plot(df$lon, df$lat, pch = 20, cex = 0.6, col = pal[col_idx], asp = 1,
       xlab = "Longitude", ylab = "Latitude",
       main = paste0("Predicted ", z_label, " (", z_units, ")"))

  if (!is.null(Md$xlon) && !is.null(Md$xlat))
    points(Md$xlon, Md$xlat, pch = 1, cex = 1.1, col = "black")

  q_probs <- quantile(log_z, probs = c(0, 0.25, 0.5, 0.75, 1.0), na.rm = TRUE)
  leg_cols <- pal[round(seq(1, 100, length.out = 5))]
  legend("bottomright",
         legend = formatC(exp(q_probs), format = "g", digits = 3),
         fill = leg_cols, title = z_units, cex = 0.65, bg = "white")

  invisible(NULL)
}


# Internal: results — C (source attribution stacked bars) ------------------------

.rsparrow_plot_results_sources <- function(x, ...) {
  pred <- x$predictions
  sd   <- x$data$subdata

  pm <- as.data.frame(pred$predmatrix)
  names(pm) <- pred$oparmlist

  share_cols <- grep("^share_total_", pred$oparmlist, value = TRUE)
  if (length(share_cols) == 0)
    stop("No 'share_total_*' columns found in predictions.", call. = FALSE)
  src_names <- sub("^share_total_", "", share_cols)
  nsrc <- length(src_names)

  pm_sub <- merge(pm[, c("waterid", share_cols), drop = FALSE],
                  sd[, c("waterid", "demtarea"), drop = FALSE],
                  by = "waterid")

  dec_class <- calcDemtareaClass(pm_sub$demtarea)
  deciles   <- sort(unique(dec_class))
  ndec      <- length(deciles)

  share_mat <- matrix(0, nrow = nsrc, ncol = ndec,
                      dimnames = list(src_names, as.character(deciles)))
  for (i in seq_len(nsrc)) {
    for (j in seq_len(ndec)) {
      idx <- dec_class == deciles[j]
      share_mat[i, j] <- mean(pm_sub[[share_cols[i]]][idx], na.rm = TRUE)
    }
  }

  # Normalize columns to 100 %
  col_sums <- colSums(share_mat, na.rm = TRUE)
  for (j in seq_len(ndec)) {
    if (!is.na(col_sums[j]) && col_sums[j] > 0)
      share_mat[, j] <- share_mat[, j] / col_sums[j] * 100
  }

  pal <- rainbow(nsrc)
  op  <- par(mar = c(5, 5, 3, 10), xpd = TRUE)
  on.exit(par(op))

  bp <- barplot(share_mat, beside = FALSE, col = pal, border = NA,
                xlab = "Drainage Area Decile Class",
                ylab = "Mean Source Contribution (%)",
                main = "Source Attribution by Drainage Area Decile",
                ylim = c(0, 115),
                names.arg = colnames(share_mat), las = 2, cex.names = 0.7)

  legend(x = max(bp) + 0.5, y = 110, legend = src_names, fill = pal,
         border = NA, cex = 0.7, title = "Source", xpd = TRUE)

  invisible(NULL)
}


# Internal: results — E (obs vs. pred scatter) -----------------------------------

.rsparrow_plot_results_obs_pred <- function(x, ...) {
  d   <- x$data
  Md  <- d$estimate.list$Mdiagnostics.list
  mp  <- d$mapping.input.list
  RSQ <- d$estimate.list$ANOVA.list$RSQ

  n <- length(Md$Obs)
  if (!is.null(Md$classgrp) && length(Md$classgrp) == n && !all(is.na(Md$classgrp))) {
    grp <- as.integer(factor(Md$classgrp))
  } else {
    grp <- rep(1L, n)
  }
  n_grp  <- max(grp, na.rm = TRUE)
  pal    <- rainbow(max(n_grp, 1L))
  pt_col <- pal[grp]

  op <- par(mfrow = c(1, 2), mar = c(5, 5, 3, 1))
  on.exit(par(op))

  log_obs  <- log(pmax(Md$Obs, 1e-10))
  log_pred <- log(pmax(Md$predict, 1e-10))
  lim_load <- range(c(log_obs, log_pred), na.rm = TRUE)
  plot(log_obs, log_pred, pch = 20, cex = 0.9, col = pt_col,
       xlim = lim_load, ylim = lim_load,
       xlab = paste0("log(Observed Load) (", mp$loadUnits, ")"),
       ylab = paste0("log(Predicted Load) (", mp$loadUnits, ")"),
       main = "Observed vs Predicted Load")
  abline(0, 1, col = "gray40", lty = 2, lwd = 1.5)
  if (!is.null(RSQ))
    legend("topleft", legend = paste0("R\u00B2 = ", round(RSQ, 3)),
           bty = "n", cex = 0.9)

  log_yobs  <- log(pmax(Md$yldobs, 1e-10))
  log_ypred <- log(pmax(Md$yldpredict, 1e-10))
  lim_yld   <- range(c(log_yobs, log_ypred), na.rm = TRUE)
  plot(log_yobs, log_ypred, pch = 20, cex = 0.9, col = pt_col,
       xlim = lim_yld, ylim = lim_yld,
       xlab = paste0("log(Observed Yield) (", mp$yieldUnits, ")"),
       ylab = paste0("log(Predicted Yield) (", mp$yieldUnits, ")"),
       main = "Observed vs Predicted Yield")
  abline(0, 1, col = "gray40", lty = 2, lwd = 1.5)

  invisible(NULL)
}
