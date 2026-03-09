#' @title hline
#' @description Creates list object for horizontal red line on plotly plot  \cr \cr
#' Executed By: \itemize{\item create_diagnosticPlotList.R
#'             \item diagnosticPlots_4panel_A.R
#'             \item diagnosticPlots_4panel_B.R} \cr
#' @param spatialAutoCorr TRUE/FALSE indicating whether plot is a spatial auto correlation plot
#' @param y y axis value to create horizontal line
#' @param color color of horizontal line
#' @param dash character string to apply to dash value in plotly line list
#' @return named.list for plotly horizontal line
#' \tabular{ll}{
#' `type` \tab character string type of plotly object \cr
#' `x0` \tab numeric value of x0 \cr
#' `x1` \tab numeric value of x1 \cr
#' `xref` \tab character string defining plot area of x values \cr
#' `y1` \tab numeric value at which to plot horizontal line \cr
#' `line` \tab list of line attributes for plotly \cr
#' }
#' @keywords internal
#' @noRd


  hline <- function(spatialAutoCorr,y = 0, color = "red",dash) {
    if (!spatialAutoCorr){
    list(
      type = "line", 
      x0 = 0, 
      x1 = 1, 
      xref = "paper",
      y0 = y, 
      y1 = y, 
      line = list(color = color)
    )
  }else{
 list(
      type = "line", 
      x0 = 0, 
      x1 = 1, 
      xref = "paper",
      y0 = y, 
      y1 = y, 
      line = list(color = color, dash = dash)
    )
  }
}