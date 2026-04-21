#' @title diagnosticPlots_4panel_A
#' @description Generates 4 panel diagnostic plots: Observed vs Predicted Load,
#'             Observed vs Predicted Yield, Residuals vs Predicted Load,
#'             Residuals vs Predicted Yield. Uses base R graphics. \cr \cr
#' Executed By: diagnosticPlotsNLLS.R, plot.rsparrow.R \cr
#' @param plotpredict numeric vector of load prediction values
#' @param plotObs numeric vector of load observation values
#' @param plotyldpredict numeric vector of yield prediction values
#' @param plotyldobs numeric vector of yield observation values
#' @param plotResids numeric vector of log residuals
#' @param plotclass numeric vector of class variable values (NA if no filtering)
#' @param plotTitles character vector of 4 plot titles
#' @param loadUnits character string for load units
#' @param yieldUnits character string for yield units
#' @param filterClass numeric scalar: class level to display, or NA for all data
#' @return NULL invisibly (plots drawn to the current graphics device)
#' @keywords internal
#' @noRd


diagnosticPlots_4panel_A <- function(plotpredict, plotObs, plotyldpredict, plotyldobs,
                                     plotResids, plotclass, plotTitles,
                                     loadUnits, yieldUnits, filterClass) {

  # Apply class filter if requested
  if (!all(is.na(filterClass))) {
    mask <- !is.na(plotclass) & plotclass == filterClass
    plotpredict    <- plotpredict[mask]
    plotObs        <- plotObs[mask]
    plotyldpredict <- plotyldpredict[mask]
    plotyldobs     <- plotyldobs[mask]
    plotResids     <- plotResids[mask]
  }

  op <- par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1))
  on.exit(par(op), add = TRUE)

  # --- Panel 1: Observed vs Predicted Load (log-log) ---
  pos1 <- plotpredict > 0 & plotObs > 0 & is.finite(plotpredict) & is.finite(plotObs)
  plot(plotpredict[pos1], plotObs[pos1],
       log  = "xy",
       xlab = paste0("Predicted Load (", loadUnits, ")"),
       ylab = paste0("Observed Load (", loadUnits, ")"),
       main = plotTitles[1],
       pch  = 19, cex = 0.6, col = "steelblue")
  abline(0, 1, col = "red", lwd = 1.5)

  # --- Panel 2: Observed vs Predicted Yield (log-log) ---
  pos2 <- plotyldpredict > 0 & plotyldobs > 0 &
          is.finite(plotyldpredict) & is.finite(plotyldobs)
  plot(plotyldpredict[pos2], plotyldobs[pos2],
       log  = "xy",
       xlab = paste0("Predicted Yield (", yieldUnits, ")"),
       ylab = paste0("Observed Yield (", yieldUnits, ")"),
       main = plotTitles[2],
       pch  = 19, cex = 0.6, col = "steelblue")
  abline(0, 1, col = "red", lwd = 1.5)

  # --- Panel 3: Residuals vs Predicted Load (log x-axis) ---
  pos3 <- plotpredict > 0 & is.finite(plotpredict) & is.finite(plotResids)
  plot(plotpredict[pos3], plotResids[pos3],
       log  = "x",
       xlab = paste0("Predicted Load (", loadUnits, ")"),
       ylab = "Log Residual",
       main = plotTitles[3],
       pch  = 19, cex = 0.6, col = "steelblue")
  abline(h = 0, col = "red", lwd = 1.5)

  # --- Panel 4: Residuals vs Predicted Yield (log x-axis) ---
  pos4 <- plotyldpredict > 0 & is.finite(plotyldpredict) & is.finite(plotResids)
  plot(plotyldpredict[pos4], plotResids[pos4],
       log  = "x",
       xlab = paste0("Predicted Yield (", yieldUnits, ")"),
       ylab = "Log Residual",
       main = plotTitles[4],
       pch  = 19, cex = 0.6, col = "steelblue")
  abline(h = 0, col = "red", lwd = 1.5)

  invisible(NULL)
}
