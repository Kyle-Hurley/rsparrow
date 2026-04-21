#' @title diagnosticPlotsNLLS
#'
#' @description
#' Creates diagnostic plots using base R graphics. Plots are drawn directly to
#' the current graphics device. (Plan 05D: HTML rendering removed; make_modelEstPerfPlots and
#' make_modelSimPerfPlots inlined; unPackList replaced with direct $ extractions;
#' eval/parse+plotFunc replaced with direct function calls. Plan 16: base R plotting
#' replaces plotly throughout.)
#'
#' Executed By: \itemize{
#'              \item estimate.R}
#'
#' Executes Routines: \itemize{
#'              \item diagnosticPlots_4panel_A.R,
#'              \item diagnosticPlots_4panel_B.R}
#'
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by `generateInputList.R`
#' @param class.input.list list of control settings related to classification variables
#' @param sitedata.demtarea.class Total drainage area classification variable for calibration
#' sites.
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 &
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter
#' sub-section 5.1.2 for details)
#' @param sitedata.landuse Land use for incremental basins for diagnostics.
#' @param estimate.list list output from `estimate.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo,
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list,
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R`
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#' prediction, yield, and residuals csv and shape files
#' @param batch_mode yes/no character string indicating whether RSPARROW is being run in batch
#' mode
#' @param validation TRUE/FALSE indicating whether validation or diagnostic plots are to be
#' generated
#' @keywords internal
#' @noRd


diagnosticPlotsNLLS <- function(file.output.list, class.input.list, sitedata.demtarea.class,
                                sitedata, sitedata.landuse, estimate.list, mapping.input.list,
                                Cor.ExplanVars.list, data_names = NA, add_vars = NA, batch_mode = "no",
                                validation = TRUE) {

  # Direct extractions
  loadUnits     <- mapping.input.list$loadUnits
  yieldUnits    <- mapping.input.list$yieldUnits
  classvar      <- class.input.list$classvar
  class_landuse <- class.input.list$class_landuse

  # Extract estimation diagnostics from Mdiagnostics.list
  Mdiag           <- estimate.list$Mdiagnostics.list
  predict         <- Mdiag$predict
  Obs             <- Mdiag$Obs
  yldpredict      <- Mdiag$yldpredict
  yldobs          <- Mdiag$yldobs
  Resids          <- Mdiag$Resids
  ratio.obs.pred  <- Mdiag$ratio.obs.pred
  standardResids  <- Mdiag$standardResids
  ppredict        <- Mdiag$ppredict
  pyldpredict     <- Mdiag$pyldpredict
  pyldobs         <- Mdiag$pyldobs
  pResids         <- Mdiag$pResids
  pratio.obs.pred <- Mdiag$pratio.obs.pred

  # For validation, override sim variables from vMdiagnostics.list
  if (validation) {
    vMdiag          <- estimate.list$vMdiagnostics.list
    ppredict        <- vMdiag$ppredict
    Obs             <- vMdiag$Obs
    pyldpredict     <- vMdiag$pyldpredict
    pyldobs         <- vMdiag$pyldobs
    pResids         <- vMdiag$pResids
    pratio.obs.pred <- vMdiag$pratio.obs.pred
  }

  # class matrix and group levels for grouped plots
  class <- sapply(classvar, function(var_name) as.numeric(sitedata[[var_name]]))
  if (is.null(dim(class))) dim(class) <- c(length(class), 1L)
  colnames(class) <- classvar
  grp <- as.numeric(names(table(class[, 1])))

  if (!is.na(class_landuse[1])) {
    classvar2 <- paste0(class_landuse, "_pct")
  } else {
    classvar2 <- NA
  }

  # Helper: boxplot with h=1 reference for obs/pred ratio plots
  .ratio_boxplot <- function(y, grp_var, xlab, ylab, main) {
    boxplot(y ~ grp_var,
            xlab = xlab, ylab = ylab, main = main,
            las = 2, cex.axis = 0.7, col = "white", border = "black",
            log = "y")
    abline(h = 1, col = "red", lty = 2, lwd = 1.5)
  }

  ###########################################################################
  # ESTIMATION PERFORMANCE PLOTS (only when validation = FALSE)
  ###########################################################################

  if (!validation) {

    # p1: Obs vs Pred (monitoring-adjusted)
    diagnosticPlots_4panel_A(
      predict, Obs, yldpredict, yldobs, Resids,
      plotclass = NA,
      plotTitles = c(
        "MODEL ESTIMATION PERFORMANCE\n(Monitoring-Adjusted Predictions)\nObserved vs Predicted Load",
        "MODEL ESTIMATION PERFORMANCE\nObserved vs Predicted Yield",
        "Residuals vs Predicted Load",
        "Residuals vs Predicted Yield"
      ),
      loadUnits, yieldUnits, filterClass = NA
    )

    # p2: Box/Quantile residuals (estimation)
    diagnosticPlots_4panel_B(
      Resids, ratio.obs.pred, standardResids, predict,
      plotTitles = c(
        "MODEL ESTIMATION PERFORMANCE\nResiduals",
        "MODEL ESTIMATION PERFORMANCE\nObserved / Predicted Ratio",
        "Normal Q-Q Plot",
        "Squared Residuals vs Predicted Load"
      ),
      loadUnits
    )

    # p3: Monitoring-adjusted vs Simulated Loads
    {
      pos <- ppredict > 0 & predict > 0 & is.finite(ppredict) & is.finite(predict)
      lim <- range(c(ppredict[pos], predict[pos]))
      plot(ppredict[pos], predict[pos],
           log  = "xy",
           xlim = lim, ylim = lim,
           xlab = paste0("Simulated Load (", loadUnits, ")"),
           ylab = paste0("Monitoring-Adjusted Load (", loadUnits, ")"),
           main = "Monitoring-Adjusted vs. Simulated Loads",
           pch  = 19, cex = 0.6, col = "steelblue")
      abline(0, 1, col = "red", lwd = 1.5)
    }

    # p4: Obs/Pred ratio vs area-weighted explanatory variables
    if (!identical(Cor.ExplanVars.list, NA)) {
      for (i in seq_along(Cor.ExplanVars.list$names)) {
        xv      <- Cor.ExplanVars.list$cmatrixM_all[, i]
        use_log <- if (min(xv, na.rm = TRUE) > 0) "x" else ""
        plot(xv, ratio.obs.pred,
             log  = use_log,
             xlab = paste0("Area-Weighted Explanatory Variable (", Cor.ExplanVars.list$names[i], ")"),
             ylab = "Ratio Observed to Predicted",
             main = paste0("Obs/Pred Ratio vs ", Cor.ExplanVars.list$names[i]),
             pch  = 19, cex = 0.6, col = "steelblue")
        abline(h = 1, col = "red", lty = 2, lwd = 1.5)
      }
    }

    # p5: Obs/Pred ratio by drainage area deciles
    .ratio_boxplot(ratio.obs.pred, sitedata.demtarea.class,
                   xlab = "Upper Bound for Total Drainage Area Deciles (km\u00B2)",
                   ylab = "Observed to Predicted Ratio",
                   main = "Ratio Obs/Pred by Drainage Area Deciles")

    # p6: Obs/Pred ratio by classvar
    if (!identical(classvar, "sitedata.demtarea.class")) {
      for (k in seq_along(classvar)) {
        vvar <- as.numeric(sitedata[[classvar[k]]])
        .ratio_boxplot(ratio.obs.pred, vvar,
                       xlab = classvar[k],
                       ylab = "Observed to Predicted Ratio",
                       main = "Ratio Observed to Predicted")
      }
    }

    # p7: Obs/Pred ratio by landuse deciles
    if (!is.na(class_landuse[1])) {
      for (k in seq_along(classvar2)) {
        vvar  <- as.numeric(sitedata.landuse[[classvar2[k]]])
        iprob <- 10
        chk   <- unique(quantile(vvar, probs = 0:iprob / iprob))
        chk1  <- 11 - length(chk)
        if (chk1 == 0) {
          qvars  <- as.integer(cut(vvar, quantile(vvar, probs = 0:iprob / iprob),
                                   include.lowest = TRUE))
          avars  <- quantile(vvar, probs = 0:iprob / iprob)
          qvars2 <- numeric(length(qvars))
          for (jj in 1:10) {
            for (ii in seq_along(qvars)) {
              if (qvars[ii] == jj) qvars2[ii] <- round(avars[jj + 1], digits = 0)
            }
          }
          .ratio_boxplot(ratio.obs.pred, qvars2,
                         xlab = paste0("Upper Bound for ", classvar2[k]),
                         ylab = "Observed to Predicted Ratio",
                         main = "Ratio Obs/Pred by Deciles")
        } else {
          .ratio_boxplot(ratio.obs.pred, vvar,
                         xlab = classvar2[k],
                         ylab = "Observed to Predicted Ratio",
                         main = "Ratio Observed to Predicted")
        }
      }
    }

    # p8: 4-panel by classvar group (estimation)
    for (i in seq_along(grp)) {
      nsites_i <- sum(!is.na(class[, 1]) & class[, 1] == grp[i])
      diagnosticPlots_4panel_A(
        predict, Obs, yldpredict, yldobs, Resids,
        plotclass = class[, 1],
        plotTitles = c(
          paste0("Observed vs Predicted Load\nClass = ", grp[i], " (n=", nsites_i, ")"),
          "Observed vs Predicted Yield",
          "Residuals vs Predicted Load",
          "Residuals vs Predicted Yield"
        ),
        loadUnits, yieldUnits, filterClass = as.double(grp[i])
      )
    }

  } # end !validation

  ###########################################################################
  # SIMULATION PERFORMANCE PLOTS
  ###########################################################################

  # p9: Simulation 4-panel obs vs pred
  diagnosticPlots_4panel_A(
    ppredict, Obs, pyldpredict, pyldobs, pResids,
    plotclass = NA,
    plotTitles = c(
      "MODEL SIMULATION PERFORMANCE\nObserved vs Predicted Load",
      "MODEL SIMULATION PERFORMANCE\nObserved vs Predicted Yield",
      "Residuals vs Predicted Load",
      "Residuals vs Predicted Yield"
    ),
    loadUnits, yieldUnits, filterClass = NA
  )

  # p10: Simulation box/quantile residuals
  diagnosticPlots_4panel_B(
    pResids, pratio.obs.pred, NA, ppredict,
    plotTitles = c(
      "MODEL SIMULATION PERFORMANCE\nResiduals",
      "MODEL SIMULATION PERFORMANCE\nObserved / Predicted Ratio",
      "Normal Q-Q Plot",
      "Squared Residuals vs Predicted Load"
    ),
    loadUnits
  )

  # p11: Simulation ratio vs area-weighted explanatory variables (!validation only)
  if (!validation && !identical(Cor.ExplanVars.list, NA)) {
    for (i in seq_along(Cor.ExplanVars.list$names)) {
      xv      <- Cor.ExplanVars.list$cmatrixM_all[, i]
      use_log <- if (min(xv, na.rm = TRUE) > 0) "x" else ""
      plot(xv, pratio.obs.pred,
           log  = use_log,
           xlab = paste0("Area-Weighted Explanatory Variable (", Cor.ExplanVars.list$names[i], ")"),
           ylab = "Ratio Observed to Predicted",
           main = paste0("Sim Obs/Pred Ratio vs ", Cor.ExplanVars.list$names[i]),
           pch  = 19, cex = 0.6, col = "steelblue")
      abline(h = 1, col = "red", lty = 2, lwd = 1.5)
    }
  }

  # p12: Simulation ratio by drainage area deciles
  .ratio_boxplot(pratio.obs.pred, sitedata.demtarea.class,
                 xlab = "Upper Bound for Total Drainage Area Deciles (km\u00B2)",
                 ylab = "Observed to Predicted Ratio",
                 main = "Sim Ratio Obs/Pred by Drainage Area Deciles")

  # p13: Simulation ratio by classvar
  if (!identical(classvar, "sitedata.demtarea.class")) {
    for (k in seq_along(classvar)) {
      vvar <- as.numeric(sitedata[[classvar[k]]])
      .ratio_boxplot(pratio.obs.pred, vvar,
                     xlab = classvar[k],
                     ylab = "Observed to Predicted Ratio",
                     main = "Sim Ratio Observed to Predicted")
    }
  }

  # p14: Simulation ratio by landuse deciles
  if (!is.na(class_landuse[1])) {
    for (l in seq_along(classvar2)) {
      vvar  <- as.numeric(sitedata.landuse[[classvar2[l]]])
      iprob <- 10
      chk   <- unique(quantile(vvar, probs = 0:iprob / iprob))
      chk1  <- 11 - length(chk)
      if (chk1 == 0) {
        qvars  <- as.integer(cut(vvar, quantile(vvar, probs = 0:iprob / iprob),
                                 include.lowest = TRUE))
        avars  <- quantile(vvar, probs = 0:iprob / iprob)
        qvars2 <- numeric(length(qvars))
        for (jj in 1:10) {
          for (ii in seq_along(qvars)) {
            if (qvars[ii] == jj) qvars2[ii] <- round(avars[jj + 1], digits = 0)
          }
        }
        .ratio_boxplot(pratio.obs.pred, qvars2,
                       xlab = paste0("Upper Bound for ", classvar2[l]),
                       ylab = "Observed to Predicted Ratio",
                       main = "Sim Ratio Obs/Pred by Deciles")
      } else {
        .ratio_boxplot(pratio.obs.pred, vvar,
                       xlab = classvar2[l],
                       ylab = "Observed to Predicted Ratio",
                       main = "Sim Ratio Observed to Predicted")
      }
    }
  }

  # p15: 4-panel by classvar group (simulation)
  for (i in seq_along(grp)) {
    nsites_i <- sum(!is.na(class[, 1]) & class[, 1] == grp[i])
    diagnosticPlots_4panel_A(
      ppredict, Obs, pyldpredict, pyldobs, pResids,
      plotclass = class[, 1],
      plotTitles = c(
        paste0("Sim Observed vs Predicted Load\nClass = ", grp[i], " (n=", nsites_i, ")"),
        "Observed vs Predicted Yield",
        "Residuals vs Predicted Load",
        "Residuals vs Predicted Yield"
      ),
      loadUnits, yieldUnits, filterClass = as.double(grp[i])
    )
  }

  invisible(NULL)

} # end function
