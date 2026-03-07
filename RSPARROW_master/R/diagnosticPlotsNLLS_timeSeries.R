#' @title diagnosticPlotsNLLS_timeSeries
#'
#' @description
#' Creates Observed vs Predicted Load plots for each timestep in dynamic data and returns
#' the plots as a named list. (Plan 05D: HTML rendering removed; make_diagnosticPlotsNLLS_timeSeries
#' inlined.)
#'
#' Executed By: estimate.R
#'
#' Executes Routines: \itemize{
#'              \item addMarkerText.R,
#'              \item checkDynamic.R}
#'
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo,
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list,
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by `generateInputList.R`
#' @param estimate.list list output from `estimate.R`
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 &
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter
#' sub-section 5.1.2 for details)
#' @keywords internal
#' @noRd

diagnosticPlotsNLLS_timeSeries <- function(mapping.input.list, file.output.list, estimate.list,
                                           sitedata) {

  dynamic <- checkDynamic(sitedata)
  if (!dynamic) {
    stop("Object sitedata is not timeseries.")
  }

  # Extract variables from lists (replaces unPackList)
  loadUnits           <- mapping.input.list$loadUnits
  siteAttrClassRounding <- mapping.input.list$siteAttrClassRounding
  add_plotlyVars      <- mapping.input.list$add_plotlyVars
  diagnosticPlotPointStyle <- mapping.input.list$diagnosticPlotPointStyle
  diagnosticPlotPointSize  <- mapping.input.list$diagnosticPlotPointSize
  pchPlotlyCross      <- mapping.input.list$pchPlotlyCross
  showPlotGrid        <- mapping.input.list$showPlotGrid

  pnch <- as.character(pchPlotlyCross[pchPlotlyCross$pch == diagnosticPlotPointStyle, ]$plotly)
  markerSize <- diagnosticPlotPointSize * 10
  markerCols <- colorNumeric(c("black", "white"), 1:2)
  test <- regexpr('open', pnch) > 0
  if (test) {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1))
  } else {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1),
                       line = list(color = markerCols(1), width = 0.8))
  }

  timeSeriesdat <- data.frame(
    "mapping_waterid" = sitedata$mapping_waterid,
    "staid" = sitedata$staid,
    "Obs" = estimate.list$Mdiagnostics.list$Obs,
    "predict" = estimate.list$Mdiagnostics.list$predict
  )

  if ("year" %in% names(sitedata)) {
    if (!any(is.na(sitedata$year))) {
      timeSeriesdat$year <- sitedata$year
    }
  }
  if ("season" %in% names(sitedata)) {
    if (!any(is.na(sitedata$season))) {
      timeSeriesdat$season <- sitedata$season
    }
  }
  if ("year" %in% names(timeSeriesdat) & "season" %in% names(timeSeriesdat)) {
    timeSeriesdat <- timeSeriesdat[
      order(timeSeriesdat$year,
            match(timeSeriesdat$season, c("winter", "spring", "summer", "fall"))), ]
    timeSeriesdat$timeStep <- paste(timeSeriesdat$year, timeSeriesdat$season)
  } else if ("year" %in% names(timeSeriesdat)) {
    timeSeriesdat <- timeSeriesdat[order(timeSeriesdat$year), ]
    timeSeriesdat$timeStep <- timeSeriesdat$year
  } else {
    timeSeriesdat <- timeSeriesdat[
      order(match(timeSeriesdat$season, c("winter", "spring", "summer", "fall"))), ]
    timeSeriesdat$timeStep <- timeSeriesdat$season
  }

  unique_waterid <- unique(timeSeriesdat$mapping_waterid)
  mapList <- list()
  for (i in seq_along(unique_waterid)) {

    df <- timeSeriesdat[timeSeriesdat$mapping_waterid == unique_waterid[i], ]

    markerText <- "~paste('</br> timeStep: ',timeStep,
            '</br> Obs :',round(Obs,siteAttrClassRounding),
      '</br> Predict :',round(predict,siteAttrClassRounding)"

    if ("year" %in% names(df) & "season" %in% names(df)) {
      sitedata2 <- merge(
        sitedata,
        df[c("mapping_waterid", "year", "season")],
        by = c("mapping_waterid", "year", "season")
      )
    } else if ("year" %in% names(df)) {
      sitedata2 <- merge(
        sitedata,
        df[c("mapping_waterid", "year")],
        by = c("mapping_waterid", "year")
      )
    } else {
      sitedata2 <- merge(
        sitedata,
        df[c("mapping_waterid", "season")],
        by = c("mapping_waterid", "season")
      )
    }

    mapInfo <- addMarkerText(markerText, add_plotlyVars, df, sitedata2)

    if ("year" %in% names(mapInfo$mapData) & "season" %in% names(mapInfo$mapData)) {
      mapInfo$mapData$season <- factor(
        mapInfo$mapData$season,
        levels = c("winter", "spring", "summer", "fall")
      )
      mapInfo$mapData <- mapInfo$mapData[order(mapInfo$mapData$year, mapInfo$mapData$season), ]
    } else if ("year" %in% names(mapInfo$mapData)) {
      mapInfo$mapData <- mapInfo$mapData[order(mapInfo$mapData$year), ]
    } else {
      mapInfo$mapData$season <- factor(
        mapInfo$mapData$season,
        levels = c("winter", "spring", "summer", "fall")
      )
      mapInfo$mapData <- mapInfo$mapData[order(mapInfo$mapData$season), ]
    }

    mapInfo$mapData$timeStep <- factor(
      mapInfo$mapData$timeStep,
      levels = unique(mapInfo$mapData$timeStep)
    )

    p1 <- plotly::plot_ly() |>
      plotly::layout(
        xaxis = list(
          dtick = 1,
          showticklabels = TRUE,
          title = "TimeStep"
        ),
        yaxis = list(
          showticklabels = TRUE,
          title = paste0("OBSERVED/PREDICTED LOAD (", loadUnits, ")")
        ),
        title = timeSeriesdat$mapping_waterid[i]
      )

    p1 <- p1 |>
      plotly::add_trace(
        data = mapInfo$mapData, x = ~timeStep, y = ~Obs,
        type = "scatter",
        mode = "markers",
        marker = markerList,
        hoverinfo = "text",
        text = eval(parse(text = mapInfo$markerText)),
        showlegend = FALSE
      )
    p1 <- p1 |>
      plotly::add_lines(
        data = mapInfo$mapData,
        x = ~ timeStep,
        y = ~ Obs,
        showlegend = TRUE,
        name = "Observed"
      )

    p1 <- p1 |>
      plotly::add_trace(
        data = mapInfo$mapData,
        x = ~ timeStep,
        y = ~ predict,
        type = "scatter",
        mode = "markers",
        marker = markerList,
        hoverinfo = "text",
        text = eval(parse(text = mapInfo$markerText)),
        showlegend = FALSE
      )
    p1 <- p1 |>
      plotly::add_lines(
        data = mapInfo$mapData,
        x = ~ timeStep,
        y = ~ predict,
        showlegend = TRUE,
        name = "Predicted"
      )

    mapList[[as.character(unique_waterid[i])]] <- p1

  }

  invisible(mapList)

}
