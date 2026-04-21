#' @title diagnosticSensitivity
#'
#' @description
#' Calculates the parameter sensitivities (change in load predictions for a 1% unit change in
#' the explanatory variables) and produces diagnostic plots using base R graphics.
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
#' NLLS_weights, if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param estimate.list list output from `estimate.R`
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list' for
#' optimization
#' @param SelParmValues selected parameters from parameters.csv
#' @param subdata data.frame input data (subdata)
#' @param sitedata.demtarea.class Total drainage area classification variable for calibration
#' sites.
#' @param mapping.input.list Named list of sparrow_control settings for mapping
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @keywords internal
#' @noRd



diagnosticSensitivity <- function(file.output.list, class.input.list, estimate.input.list, estimate.list,
                                  DataMatrix.list, SelParmValues, subdata, sitedata.demtarea.class,
                                  mapping.input.list, dlvdsgn) {

  # Direct extractions
  oEstimate  <- estimate.list$JacobResults$oEstimate
  Parmnames  <- estimate.list$JacobResults$Parmnames
  betaconstant <- SelParmValues$betaconstant
  classvar   <- class.input.list$classvar
  depvar     <- subdata$depvar
  xclass     <- subdata[[classvar[1]]]

  Estimate <- oEstimate  # baseline estimates

  # Baseline predictions
  predict <- predictSensitivity(
    AEstimate     = Estimate,
    estimate.list = estimate.list,
    DataMatrix.list = DataMatrix.list,
    SelParmValues = SelParmValues,
    subdata       = subdata,
    dlvdsgn       = dlvdsgn
  )

  apredict_sum <- matrix(1, nrow = length(depvar), ncol = length(Estimate))

  for (i in seq_along(Estimate)) {
    if (betaconstant[i] == 0) {
      AEstimate    <- Estimate
      AEstimate[i] <- Estimate[i] * 0.99
      apredict <- predictSensitivity(
        AEstimate     = AEstimate,
        estimate.list = estimate.list,
        DataMatrix.list = DataMatrix.list,
        SelParmValues = SelParmValues,
        subdata       = subdata,
        dlvdsgn       = dlvdsgn
      )
      apredict_sum[, i] <- abs((apredict - predict) / predict * 100) / 1.0
    }
  }

  # --- Per-parameter boxplots ---
  for (i in seq_along(Estimate)) {
    x1 <- apredict_sum[, i]
    xx <- data.frame(x1 = x1, depvar = depvar, xclass = xclass)
    parmsens <- xx[xx$depvar > 0, ]
    boxplot(parmsens$x1 ~ parmsens$xclass,
            xlab = classvar[1],
            ylab = "Prediction Change (%) Relative to 1% Change",
            main = paste0("Parameter Sensitivity:  ", Parmnames[i]),
            las = 2, cex.axis = 0.7,
            col = "white", border = "black")
  }

  # Compute quantile summaries
  ct     <- length(Estimate)
  xiqr   <- matrix(0, nrow = 4, ncol = ct)
  xmed   <- numeric(ct)
  xparm  <- character(ct)
  xvalue2 <- numeric(ct)
  xsens  <- matrix(0, nrow = sum(depvar > 0), ncol = ct)

  for (i in seq_along(Estimate)) {
    x1 <- apredict_sum[, i]
    xx <- data.frame(x1 = x1, depvar = depvar, xclass = xclass)
    parmsens <- xx[xx$depvar > 0, ]
    xvalue2[i] <- i
    xiqr[, i]  <- quantile(parmsens$x1, c(0.05, 0.25, 0.75, 0.95))
    xmed[i]    <- median(parmsens$x1)
    xparm[i]   <- Parmnames[i]
    xsens[, i] <- parmsens$x1
  }

  # Floor zeros to avoid log(0)
  xx_p <- data.frame(xmed = xmed, xiqr = t(xiqr), xparm = xparm, stringsAsFactors = FALSE)
  xx_p <- xx_p[order(xx_p$xmed), ]

  xminimum <- min(xiqr[1, xiqr[1, ] > 0], na.rm = TRUE)
  xminimum <- if (is.infinite(xminimum)) 0 else xminimum

  xmed_p <- ifelse(xmed == 0, xminimum, xmed)
  xiqr_p <- ifelse(xiqr == 0, xminimum, xiqr)

  # Sort by median
  ord <- order(xmed_p)
  xmed_sorted  <- xmed_p[ord]
  xparm_sorted <- xparm[ord]
  xupper <- (xiqr_p[3, ] - xmed_p)[ord]
  xlower <- (xmed_p - xiqr_p[2, ])[ord]
  supper <- (xiqr_p[4, ] - xmed_p)[ord]
  slower <- (xmed_p - xiqr_p[1, ])[ord]
  xupper <- ifelse(xupper == 0, xminimum, xupper)
  supper <- ifelse(supper == 0, xminimum, supper)
  xlower <- ifelse(xlower == 0, xminimum, xlower)
  slower <- ifelse(slower == 0, xminimum, slower)

  n <- length(xmed_sorted)

  # --- p17: Sensitivity summary, arithmetic scale ---
  .plot_sens_errbar <- function(log_scale) {
    ylo <- xmed_sorted - slower
    yhi <- xmed_sorted + supper
    if (log_scale) {
      ylo <- pmax(ylo, xminimum)
      yhi <- pmax(yhi, xminimum)
    }
    op <- par(mar = c(7, 4.5, 3, 1))
    on.exit(par(op), add = TRUE)
    plot(seq_len(n), xmed_sorted,
         pch  = 19, col = "black", cex = 0.9,
         xaxt = "n",
         ylim = range(c(ylo, yhi), na.rm = TRUE),
         log  = if (log_scale) "y" else "",
         xlab = "",
         ylab = "Change in Predicted Values (%)",
         main = "Parameter Sensitivity to 1% Change")
    axis(1, at = seq_len(n), labels = xparm_sorted, las = 2, cex.axis = 0.7)
    # 90% interval — blue
    suppressWarnings(arrows(seq_len(n), pmax(xmed_sorted - slower, if (log_scale) xminimum else -Inf),
                            seq_len(n), xmed_sorted + supper,
                            angle = 90, code = 3, length = 0.05, col = "blue"))
    # 50% interval — red
    suppressWarnings(arrows(seq_len(n), pmax(xmed_sorted - xlower, if (log_scale) xminimum else -Inf),
                            seq_len(n), xmed_sorted + xupper,
                            angle = 90, code = 3, length = 0.05, col = "red", lwd = 2))
    legend("topleft",
           legend = c("90% interval", "50% interval", "median"),
           col = c("blue", "red", "black"),
           lty = c(1, 1, NA), pch = c(NA, NA, 19),
           cex = 0.8, bty = "n")
  }

  .plot_sens_errbar(log_scale = FALSE)  # p17: arithmetic
  .plot_sens_errbar(log_scale = TRUE)   # p18: log scale

  # Preserve data for callers
  sensitivities.list <- named.list(xparm, xmed, xiqr, xsens)

  invisible(NULL)
}
