#' @title diagnosticPlots_4panel_B
#' @description Generates 4 panel diagnostic plots: Residuals (boxplot),
#'              Observed/Predicted Ratio (boxplot), Normal Q-Q Plot,
#'              Squared Residuals vs Predicted Load. Uses base R graphics. \cr \cr
#' Executed By: diagnosticPlotsNLLS.R, plot.rsparrow.R \cr
#' @param plotResids numeric vector of log residuals
#' @param plot.ratio.obs.pred numeric vector of obs/pred ratios
#' @param plot.standardResids numeric vector of standardized residuals (or NA)
#' @param plotpredict numeric vector of load prediction values
#' @param plotTitles character vector of 4 plot titles
#' @param loadUnits character string for load units
#' @return NULL invisibly (plots drawn to the current graphics device)
#' @keywords internal
#' @noRd


diagnosticPlots_4panel_B <- function(plotResids, plot.ratio.obs.pred, plot.standardResids,
                                     plotpredict, plotTitles, loadUnits) {

  op <- par(mfrow = c(2, 2), mar = c(4.5, 4.5, 3, 1))
  on.exit(par(op), add = TRUE)

  # --- Panel 1: Boxplot of log residuals ---
  boxplot(plotResids,
          ylab = "Log Residual",
          main = plotTitles[1],
          col  = "white", border = "black")
  abline(h = 0, col = "red", lty = 2, lwd = 1.5)

  # --- Panel 2: Boxplot of obs/pred ratio ---
  boxplot(plot.ratio.obs.pred,
          ylab = "Ratio Observed to Predicted",
          main = plotTitles[2],
          col  = "white", border = "black")
  abline(h = 1, col = "red", lty = 2, lwd = 1.5)

  # --- Panel 3: Normal Q-Q plot ---
  resids_qq <- if (!all(is.na(plot.standardResids))) plot.standardResids else plotResids
  ylab_qq   <- if (!all(is.na(plot.standardResids))) "Standardized Residuals" else "Log Residuals"
  qqnorm(resids_qq,
         main = plotTitles[3],
         ylab = ylab_qq,
         pch  = 19, cex = 0.6, col = "steelblue")
  qqline(resids_qq, col = "red", lwd = 1.5)

  # --- Panel 4: Squared residuals vs predicted load (log x-axis) ---
  Resids2   <- plotResids^2
  lwresids  <- lowess(plotpredict, Resids2, f = 0.5, iter = 3)
  lwy <- lwresids$y[seq_len(length(lwresids$y) - 1)]
  lwx <- lwresids$x[seq_len(length(lwresids$x) - 1)]

  pos <- plotpredict > 0 & is.finite(plotpredict) & is.finite(Resids2)
  plot(plotpredict[pos], Resids2[pos],
       log  = "x",
       xlab = paste0("Predicted Load (", loadUnits, ")"),
       ylab = "Squared Log Residuals",
       main = plotTitles[4],
       pch  = 19, cex = 0.6, col = "steelblue")
  lines(lwx[lwx > 0], lwy[lwx > 0], col = "red", lwd = 1.5)

  invisible(NULL)
}
