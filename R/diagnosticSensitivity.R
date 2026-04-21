#' @title diagnosticSensitivity
#' 
#' @description 
#' Calculates the parameter sensitivities (change in load predictions for a a 1% unit change in the 
#' explanatory variables) Outputs `sensitivities.list` as binary file to 
#' ~/estimate/(run_id)_sensitivities.list and a report to 
#' "~/estimate/(run_id)_diagnostic_sensitivity.html".
#' 
#' Executed By: estimate.R
#' 
#' Executes Routines: \itemize{
#'              \item named.list.R,
#'              \item predictSensitivity.R}
#' 
#' @param file.output.list list of control settings and relative paths used for input and 
#' output of external files.  Created by `generateInputList.R`
#' @param class.input.list list of control settings related to classification variables
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset, 
#' NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param estimate.list list output from `estimate.R`
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list' for 
#' optimization
#' @param SelParmValues selected parameters from parameters.csv using condition 
#' `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" & 
#' parmMin>=0) | parmType!="SOURCE")`
#' @param subdata data.frame input data (subdata)
#' @param sitedata.demtarea.class Total drainage area classification variable for calibration 
#' sites.
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit, 
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo, 
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list, 
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @keywords internal
#' @noRd



diagnosticSensitivity <- function(file.output.list, class.input.list, estimate.input.list, estimate.list, 
                                  DataMatrix.list, SelParmValues, subdata, sitedata.demtarea.class, 
                                  mapping.input.list,dlvdsgn) {
  
  # Direct extractions (replacing unPackList)
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id
  oEstimate <- estimate.list$JacobResults$oEstimate
  Parmnames <- estimate.list$JacobResults$Parmnames
  betaconstant <- SelParmValues$betaconstant
  classvar <- class.input.list$classvar
  showPlotGrid <- mapping.input.list$showPlotGrid
  depvar <- subdata$depvar
  xclass <- subdata[[classvar[1]]]
  
  # required SPARROW estimated coefficients (oEstimate, Parmnames)
  Estimate <- oEstimate # initial baseline estimates
  
  # obtain baseline predictions all reaches
  predict <- predictSensitivity(
    AEstimate = Estimate,
    estimate.list = estimate.list,
    DataMatrix.list = DataMatrix.list,
    SelParmValues = SelParmValues,
    subdata = subdata, dlvdsgn = dlvdsgn
  )
  
  apredict <- predict
  apredict_sum <- matrix(1, nrow = length(depvar), ncol = length(Estimate))
  
  for (i in 1:length(Estimate)) {
    if (betaconstant[i] == 0) { # an estimated parameter
      #  adjust parameter by 1%
      AEstimate <- Estimate
      AEstimate[i] <- Estimate[i] * 0.99
      apredict <- predictSensitivity(
        AEstimate = AEstimate,
        estimate.list = estimate.list,
        DataMatrix.list = DataMatrix.list,
        SelParmValues = SelParmValues,
        subdata = subdata, dlvdsgn = dlvdsgn
      )
      apredict_sum[, i] <- abs((apredict - predict) / predict * 100) / 1.0 # change relative to 1% change
    }
  }
  
  p.list <- list()
  for (i in seq_along(Estimate)) {
    # Inlined from create_diagnosticPlotList.R p16$plotFunc (Plan 05C)
    x1 <- apredict_sum[, i]
    xx <- data.frame(x1, depvar, xclass)
    parmsens <- xx[(xx$depvar > 0), ]
    p <- plotlyLayout(NA, parmsens$x1,
      log = "", nTicks = 5, digits = 0,
      xTitle = "", xZeroLine = FALSE, xLabs = parmsens$xclass,
      yTitle = "Prediction Change (%) Relative to 1% Change", yZeroLine = FALSE,
      plotTitle = paste0("Parameter Sensitivity:  ", Parmnames[i]),
      legend = FALSE, showPlotGrid = showPlotGrid
    ) |>
      add_trace(
        y = parmsens$x1, x = parmsens$xclass, type = "box", name = Parmnames[i],
        color = I("black"), fillcolor = "white"
      )
    p.list[[as.character(Parmnames[i])]] <- p
  }
  
  # Compute quantile summaries for all parameters (used by p17/p18 plots and sensitivities.list)
  ct <- length(Estimate)
  xiqr <- matrix(0, nrow = 4, ncol = sum(ct))
  xmed <- numeric(sum(ct))
  xparm <- character(sum(ct))
  xvalue2 <- numeric(sum(ct))
  xsens <- matrix(0, nrow = sum(depvar > 0), ncol = length(Estimate))

  for (i in seq_along(Estimate)) {
    x1 <- apredict_sum[, i]
    xx <- data.frame(x1, depvar, xclass)
    parmsens <- xx[(xx$depvar > 0), ]
    xvalue2[i] <- i
    xiqr[, i] <- quantile(parmsens$x1, c(0.05, 0.25, 0.75, 0.95))
    xmed[i] <- median(parmsens$x1)
    xparm[i] <- Parmnames[i]
    xsens[, i] <- parmsens$x1 # sensitivities for all calibration sites
  }

  # p17: sensitivity summary, arithmetic scale — inlined from create_diagnosticPlotList.R (Plan 05C)
  {
    xx_p <- xiqr[1, (xiqr[1, ] > 0)]
    xminimum <- min(xx_p)
    xminimum <- ifelse(is.infinite(xminimum), 0, xminimum)
    xmed_p <- ifelse(xmed == 0, xminimum, xmed)
    xiqr_p <- ifelse(xiqr == 0, xminimum, xiqr)

    xupper <- xiqr_p[3, ] - xmed_p
    xlower <- xmed_p - xiqr_p[2, ]
    supper <- xiqr_p[4, ] - xmed_p
    slower <- xmed_p - xiqr_p[1, ]

    xupper <- ifelse(xupper == 0, xminimum, xupper)
    supper <- ifelse(supper == 0, xminimum, supper)
    xlower <- ifelse(xlower == 0, xminimum, xlower)
    slower <- ifelse(slower == 0, xminimum, slower)

    xx_p <- data.frame(xmed = xmed_p, xlower, xupper, supper, slower, xparm)
    xx_p <- xx_p[with(xx_p, order(xx_p$xmed)), ]

    ymin_p <- min(xiqr_p)
    ymax_p <- max(xiqr_p)
    data_p <- data.frame(x = xvalue2)
    data_p <- cbind(data_p, xx_p)

    p <- plotlyLayout(NA, data_p$xmed,
      log = "", nTicks = 5, digits = 0,
      xTitle = "", xZeroLine = FALSE, xLabs = as.character(data_p$xparm),
      yTitle = "CHANGE IN PREDICTED VALUES (%)", yZeroLine = FALSE, ymin = ymin_p, ymax = ymax_p,
      plotTitle = "PARAMETER SENSITIVITY TO 1% CHANGE",
      legend = TRUE, showPlotGrid = showPlotGrid
    ) |>
      add_trace(
        data = data_p, x = ~xparm, y = ~xmed, type = "scatter", mode = "markers",
        color = I("#0000FF"), name = "90% Interval",
        error_y = ~ list(symetric = FALSE, array = supper, arrayminus = slower, color = "#0000FF")
      ) |>
      add_trace(
        data = data_p, x = ~xparm, y = ~xmed, type = "scatter", mode = "markers",
        color = I("#FF0000"), name = "50% Interval",
        error_y = ~ list(symetric = FALSE, array = xupper, arrayminus = xlower, color = "#FF0000")
      ) |>
      add_trace(
        data = data_p, x = ~xparm, y = ~xmed, type = "scatter", mode = "markers",
        color = I("black"), name = "median"
      )
    p.list[["By_Param"]] <- p
  }

  # p18: sensitivity summary, log scale — inlined from create_diagnosticPlotList.R (Plan 05C)
  {
    p <- plotlyLayout(NA, data_p$xmed,
      log = "y", nTicks = 5, digits = 0,
      xTitle = "", xZeroLine = FALSE, xLabs = as.character(data_p$xparm),
      yTitle = "CHANGE IN PREDICTED VALUES (%)", yZeroLine = FALSE, ymin = ymin_p, ymax = ymax_p,
      plotTitle = "PARAMETER SENSITIVITY TO 1% CHANGE",
      legend = TRUE, showPlotGrid = showPlotGrid
    ) |>
      add_trace(
        data = data_p, x = ~xparm, y = ~xmed, type = "scatter", mode = "markers",
        color = I("#0000FF"), name = "90% Interval",
        error_y = ~ list(symetric = FALSE, array = supper, arrayminus = slower, color = "#0000FF")
      ) |>
      add_trace(
        data = data_p, x = ~xparm, y = ~xmed, type = "scatter", mode = "markers",
        color = I("#FF0000"), name = "50% Interval",
        error_y = ~ list(symetric = FALSE, array = xupper, arrayminus = xlower, color = "#FF0000")
      ) |>
      add_trace(
        data = data_p, x = ~xparm, y = ~xmed, type = "scatter", mode = "markers",
        color = I("black"), name = "median"
      )
    p.list[["By_Param_Log"]] <- p
  }
  # save results to directory and global environment
  sensitivities.list <- named.list(xparm, xmed, xiqr, xsens)
  invisible(p.list)

}
