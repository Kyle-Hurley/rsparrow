#' @title diagnosticPlots_4panel_A
#' @description Generates 4 panel diagnostic plots including "Observed vs.
#'             Predicted Load","Observed vs Predicted Yield","Residuals
#'             vs Predicted Load","Residuals vs Predicted Yield" \cr \cr
#' Executed By: create_diagnosticPlotList.R \cr
#' Executes Routines: \itemize{\item addMarkerText.R
#'                             \item hline.R
#'             \item plotlyLayout.R } \cr
#' @param plotpredict numeric vector of load prediction values
#' @param plotObs numeric vector of load observation values
#' @param plotyldpredict numeric vector of yield prediction values
#' @param plotyldobs numeric vector of yield observation values
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0
#'                & subdata$calsites==1), ]`. The object contains the dataDictionary
#'                'sparrowNames' variables, with records sorted in hydrological
#'                (upstream to downstream) order (see the documentation Chapter
#'                sub-section 5.1.2 for details)
#' @param plotResids numeric vector of residuals
#' @param plotclass character string indicating which class (selection of classvar
#'                 or class_landuse) to filter according to `filterClass`
#' @param plotTitles character vector of plot titles for 4-panel (plain strings or
#'                  single-quoted strings; surrounding quotes are stripped automatically)
#' @param loadUnits character string RSPARROW user setting defining units for load
#' @param yieldUnits character string RSPARROW user setting defining units for yield
#' @param showPlotGrid yes/no setting controlling whether gridlines are displayed
#' @param markerList list defining plotly marker specification (symbol, size, color, etc.)
#' @param add_plotlyVars character vector indicating user selected variables to add to plot hover
#'                      text
#' @param pnch numeric vector of pnch point styles
#' @param markerCols vector of hexodecimal color values
#' @param hline function to create horizontal red line
#' @param filterClass numeric vector of classvar variable being plotted
#' @return 4 panel diagnostic plot of "Observed vs Predicted Load","Observed
#' vs Predicted Yield","Residuals vs Predicted Load","Residuals vs Predicted Yield"
#' @keywords internal
#' @noRd


diagnosticPlots_4panel_A <- function(plotpredict, plotObs, plotyldpredict, plotyldobs, sitedata, plotResids, plotclass,
                                     plotTitles, loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
                                     pnch, markerCols, hline, filterClass) {
  markerText <- "~paste('</br> Observed Load: ',plotObs,
                   '</br> Predicted Load: ',plotpredict"
  #  observed vs. predicted mass
  df <- data.frame(plotpredict, plotObs)

  markerText <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$markerText
  df <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$mapData

  if (!all(is.na(filterClass))) {
    df <- subset(df, plotclass == filterClass)
    df <- df[!is.na(df$waterid_for_RSPARROW_mapping), ]
  }

  nsites <- as.numeric(length(df$plotpredict))

  p1 <- plotlyLayout(df$plotpredict, df$plotObs,
    log = "xy", nTicks = 5, digits = 0,
    xTitle = paste0("PREDICTED LOAD (", loadUnits, ")"), xZeroLine = TRUE,
    yTitle = paste0("OBSERVED LOAD (", loadUnits, ")"), yZeroLine = TRUE,
    plotTitle = gsub("^'|'$", "", plotTitles[1]),
    legend = FALSE, showPlotGrid = showPlotGrid
  )


  p1 <- p1 %>% add_trace(
    data = df, x = ~plotpredict, y = ~plotObs,
    type = "scatter",
    mode = "markers",
    marker = markerList,
    hoverinfo = "text",
    text = as.formula(markerText)
  )
  p1 <- p1 %>% add_trace(
    data = df, x = ~plotObs, y = ~plotObs,
    type = "scatter",
    mode = "lines",
    color = I("red"),
    hoverinfo = "text",
    text = "Observed Load vs. Observed Load"
  )

  # observed vs. predicted yield
  markerText <- "~paste('</br> Observed Yield: ',plotyldobs,
                   '</br> Predicted Yield: ',plotyldpredict"

  df <- data.frame(plotyldpredict, plotyldobs)

  markerText <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$markerText
  df <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$mapData

  if (!all(is.na(filterClass))) {
    df <- subset(df, plotclass == filterClass)
    df <- df[!is.na(df$waterid_for_RSPARROW_mapping), ]
  }

  p2 <- plotlyLayout(df$plotyldpredict, df$plotyldobs,
    log = "xy", nTicks = 5, digits = 0,
    xTitle = paste0("PREDICTED YIELD (", yieldUnits, ")"), xZeroLine = TRUE,
    yTitle = paste0("OBSERVED YIELD (", yieldUnits, ")"), yZeroLine = TRUE,
    plotTitle = gsub("^'|'$", "", plotTitles[2]),
    # plotTitle = "Observed vs Predicted \nYield",
    legend = FALSE, showPlotGrid = showPlotGrid
  )


  p2 <- p2 %>% add_trace(
    data = df, x = ~plotyldpredict, y = ~plotyldobs,
    type = "scatter",
    mode = "markers",
    marker = markerList,
    hoverinfo = "text",
    text = as.formula(markerText)
  )
  p2 <- p2 %>% add_trace(
    data = df, x = ~plotyldobs, y = ~plotyldobs,
    type = "scatter",
    mode = "lines",
    color = I("red"),
    hoverinfo = "text",
    text = "Observed Yield vs. Observed Yield"
  )


  # mass residual plot
  markerText <- "~paste('</br> Log Residual: ',plotResids,
                   '</br> Predicted Load: ',plotpredict"
  df <- data.frame(plotpredict, plotResids)

  markerText <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$markerText
  df <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$mapData

  if (!all(is.na(filterClass))) {
    df <- subset(df, plotclass == filterClass)
    df <- df[!is.na(df$waterid_for_RSPARROW_mapping), ]
  }

  p3 <- plotlyLayout(df$plotpredict, df$plotResids,
    log = "x", nTicks = 5, digits = 0,
    xTitle = paste0("PREDICTED LOAD (", loadUnits, ")"), xZeroLine = TRUE,
    yTitle = "LOG RESIDUAL", yZeroLine = TRUE,
    plotTitle = gsub("^'|'$", "", plotTitles[3]),
    # plotTitle = "Residuals vs Predicted \nLoad",
    legend = FALSE, showPlotGrid = showPlotGrid
  )


  p3 <- p3 %>% add_trace(
    data = df, x = ~plotpredict, y = ~plotResids,
    type = "scatter",
    mode = "markers",
    marker = markerList,
    hoverinfo = "text",
    text = as.formula(markerText)
  )
  p3 <- p3 %>% layout(shapes = list(hline(spatialAutoCorr=FALSE, 0)))


  # yield residual plot
  markerText <- "~paste('</br> Log Residual: ',plotResids,
                   '</br> Predicted Yield: ',plotyldpredict"
  df <- data.frame(plotyldpredict, plotResids)

  markerText <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$markerText
  df <- addMarkerText(markerText, add_plotlyVars, df, sitedata)$mapData

  if (!all(is.na(filterClass))) {
    df <- subset(df, plotclass == filterClass)
    df <- df[!is.na(df$waterid_for_RSPARROW_mapping), ]
  }

  p4 <- plotlyLayout(df$plotyldpredict, df$plotResids,
    log = "x", nTicks = 5, digits = 0,
    xTitle = paste0("PREDICTED YIELD (", yieldUnits, ")"), xZeroLine = TRUE,
    yTitle = "LOG RESIDUAL", yZeroLine = TRUE,
    plotTitle = gsub("^'|'$", "", plotTitles[4]),
    # plotTitle = "Residuals vs Predicted \nYield",
    legend = FALSE, showPlotGrid = showPlotGrid
  )


  p4 <- p4 %>% add_trace(
    data = df, x = ~plotyldpredict, y = ~plotResids,
    type = "scatter",
    mode = "markers",
    marker = markerList,
    hoverinfo = "text",
    text = as.formula(markerText)
  )
  p4 <- p4 %>% layout(shapes = list(hline(spatialAutoCorr=FALSE, 0)))

  p <- subplot(p1, p2, p3, p4,
    nrows = 2, widths = c(0.5, 0.5), heights = c(0.5, 0.5),
    titleX = TRUE, titleY = TRUE, margin = 0.08
  )
  return(p)
}
