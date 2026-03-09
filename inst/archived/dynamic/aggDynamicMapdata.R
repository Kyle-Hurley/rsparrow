#' @title aggDynamicMapdata
#' @description Aggregate data for dynamic mapping by year, season, or year
#'             and season based on the user selected `map_years` and `map_seasons`
#'             settings.  Available aggregation functions include mean, median,
#'             min, and max. \cr \cr
#' 
#' Executed By: \itemize{
#'              \item goShinyPlot.R, 
#'              \item make_residMaps.R, 
#'              \item make_siteAttrMaps.R, 
#'              \item predictMaps.R}
#' 
#' Executes Routines: \itemize{
#'              \item named.list.R, 
#'              \item naOmitFuncStr.R, 
#'              \item test_addPlotlyvars.R}
#' 
#' @param map_years RSPARROW dynamic user setting indicating how dynamic mapping
#'                 should proceed with regards to the year timestep.  A numeric
#'                 vector of years indicates mapping of each year in the vector.
#'                 A character string equal to "all" indicates that all years
#'                 present in the data1 file should be mapped. A character string
#'                 from the following list of approved aggregation functions
#'                 c("mean","median","min","max") indicates that the selected
#'                 aggregation function should be applied to the "year" attribute
#'                 to obtain a seasonal mean, median, min or max.  NA indicates that
#'                 the year timestep is not present in data1
#' @param map_seasons RSPARROW dynamic user setting indicating how dynamic mapping
#'                 should proceed with regards to the season timestep.  A character
#'                 vector of seasons indicates mapping of each season in the vector.
#'                 Seasons must be from the following list c("winter","spring","summer"
#'                 "fall").A character string equal to "all" indicates that all seasons
#'                 present in the data1 file should be mapped. A character string
#'                 from the following list of approved aggregation functions
#'                 c("mean","median","min","max") indicates that the selected
#'                 aggregation function should be applied to the "season" attribute
#'                 to obtain an annual mean, median, min or max.  NA indicates that
#'                 the season timestep is not present in data1
#' @param enable_plotlyMaps yes/no indicating whether to enable plotly interactive
#'                         displays for maps
#' @param add_plotlyVars character vector indicating user selected variables to add to plot hover
#'                      text
#' @param aggFuncs character vector of possible aggregate functions. For RSPARROW 2.0,
#'                c("mean","median","min","max")
#' @param vvar mapping variable as vector
#' @param MAPID vector of waterid_for_RSPARROW_mapping
#' @param commonvar string indicating the column to join the map data and the shapefile
#' @param subdata data.frame input data (subdata)
#' @return `map_agg.list` named list including \cr \cr
#' \tabular{ll}{
#' `uniqueSubdata` \tab `subdata` columns specified by `add_plotlyVars` aggregated according
#' to `map_years` and `map_seasons` \cr
#' `mapdata` `subdata` columns specified by `vvar` and `commonvar` aggregated according
#' to `map_years` and `map_seasons`  \cr
#' `dmapfinal` final completed data.frame including mapping data specifed by `vvar` and
#' columns specifed by `add_plotlyVars` aggregated according to `map_years` and `map_seasons` \cr
#' `add_plotlyVars` \tab character vector indicating user selected variables to add to plot
#' hover text \cr
#' `MAPID` \tab vector of waterid_for_RSPARROW_mapping \cr
#' `vvar` \tab mapping variable as vector aggregated according to `map_years` and `map_seasons` \cr
#' }
#' @keywords internal
#' @noRd

aggDynamicMapdata <- function(map_years, map_seasons, enable_plotlyMaps, add_plotlyVars,
                              aggFuncs, vvar, MAPID, commonvar, subdata) {
  # is static add year and seasons as add_plotlyVars
  if (enable_plotlyMaps == "no" | enable_plotlyMaps == "static") {
    if (identical(NA, map_years) & identical(NA, map_seasons)) {
      add_plotlyVars <- NA
    } else if (identical(NA, map_years)) {
      add_plotlyVars <- "season"
    } else if (identical(NA, map_seasons)) {
      add_plotlyVars <- "year"
    } else {
      add_plotlyVars <- c("year", "season")
    }
  }


  # aggregate seasons or years if required
  if (!identical(NA, map_years) & length(map_years[map_years %in% aggFuncs]) != 0 & (!length(map_seasons[map_seasons %in% aggFuncs]) != 0 & !identical(NA, map_seasons))) {
    mapdata <- data.frame(subdata[c("mapping_waterid", "season")], vvar)

    if (!identical(map_seasons, "all")) {
      mapdata <- mapdata[mapdata$season %in% map_seasons, ]
    }
    mapdata <- aggregate(mapdata["vvar"],
      by = list(mapping_waterid = mapdata$mapping_waterid, season = mapdata$season),
      FUN = eval(parse(text = naOmitFuncStr(map_years)))
    )

    MAPID <- mapdata$mapping_waterid
    vvar <- mapdata$vvar
    names(mapdata)[1] <- commonvar
    dmapfinal <- data.frame(mapdata[, names(mapdata) != "vvar"]) # added 3-25-2017
    names(dmapfinal)[1] <- c(commonvar)

    if ((enable_plotlyMaps != "no" & enable_plotlyMaps != "static") | !is.na(add_plotlyVars[1])) {
      add_plotlyVars <- test_addPlotlyvars(
        add_plotlyVars = c(add_plotlyVars, "lat", "lon"),
        subdata[subdata$season %in% unique(mapdata$season), ],
        groupVar = c("season", "mapping_waterid"),
        maxUnique = nrow(mapdata)
      )
      uniqueSubdata <- subdata[, names(subdata) %in% c(add_plotlyVars, "season", "mapping_waterid")]
      names(uniqueSubdata)[names(uniqueSubdata) == "mapping_waterid"] <- commonvar
      uniqueSubdata <- as.data.frame(unique(uniqueSubdata))
      if (length(uniqueSubdata) == 1) {
        names(uniqueSubdata) <- commonvar
      }
      uniqueSubdata$year <- rep(1, nrow(uniqueSubdata))
      if (!identical(map_seasons, "all")) {
        uniqueSubdata <- uniqueSubdata[uniqueSubdata$season %in% map_seasons, ]
      }
    }
  } else if (!identical(NA, map_seasons) & length(map_seasons[map_seasons %in% aggFuncs]) != 0 & (!length(map_years[map_years %in% aggFuncs]) != 0 & !identical(NA, map_years))) {
    mapdata <- data.frame(subdata[c("mapping_waterid", "year")], vvar)
    if (!identical(map_years, "all")) {
      mapdata <- mapdata[mapdata$year %in% map_years, ]
    }
    mapdata <- aggregate(mapdata["vvar"],
      by = list(mapping_waterid = mapdata$mapping_waterid, year = mapdata$year),
      FUN = eval(parse(text = naOmitFuncStr(map_seasons)))
    )
    MAPID <- mapdata$mapping_waterid
    names(mapdata)[1] <- commonvar
    vvar <- mapdata$vvar
    dmapfinal <- data.frame(mapdata[, names(mapdata) != "vvar"]) # added 3-25-2017
    names(dmapfinal)[1] <- c(commonvar)

    if ((enable_plotlyMaps != "no" & enable_plotlyMaps != "static") | !is.na(add_plotlyVars[1])) {
      add_plotlyVars <- test_addPlotlyvars(
        add_plotlyVars = c(add_plotlyVars, "lat", "lon"),
        subdata[subdata$year %in% unique(mapdata$year), ],
        groupVar = c("year", "mapping_waterid"),
        maxUnique = nrow(mapdata)
      )
      uniqueSubdata <- subdata[, names(subdata) %in% c(add_plotlyVars, "year", "mapping_waterid")]
      names(uniqueSubdata)[names(uniqueSubdata) == "mapping_waterid"] <- commonvar
      uniqueSubdata <- as.data.frame(unique(uniqueSubdata))
      if (length(uniqueSubdata) == 1) {
        names(uniqueSubdata) <- commonvar
      }
      uniqueSubdata$season <- rep(1, nrow(uniqueSubdata))
      if (!identical(map_years, "all")) {
        uniqueSubdata <- uniqueSubdata[uniqueSubdata$year %in% map_years, ]
      }
    }
  } else if (!identical(NA, map_years) & length(map_years[map_years %in% aggFuncs]) != 0 & !identical(NA, map_seasons) & length(map_seasons[map_seasons %in% aggFuncs]) != 0) {
    mapdata <- data.frame(subdata[c("mapping_waterid", "year")], vvar)
    mapdata <- aggregate(mapdata["vvar"],
      by = list(mapping_waterid = mapdata$mapping_waterid, year = mapdata$year),
      FUN = eval(parse(text = naOmitFuncStr(map_years)))
    )
    mapdata <- aggregate(mapdata["vvar"],
      by = list(mapping_waterid = mapdata$mapping_waterid),
      FUN = eval(parse(text = naOmitFuncStr(map_years)))
    )
    MAPID <- mapdata$mapping_waterid
    names(mapdata)[1] <- commonvar
    vvar <- mapdata$vvar
    dmapfinal <- data.frame(mapdata[, names(mapdata) != "vvar"]) # added 3-25-2017
    names(dmapfinal)[1] <- c(commonvar)

    if ((enable_plotlyMaps != "no" & enable_plotlyMaps != "static") | !is.na(add_plotlyVars[1])) {
      add_plotlyVars <- test_addPlotlyvars(
        add_plotlyVars = c(add_plotlyVars, "lat", "lon"),
        subdata,
        groupVar = c("mapping_waterid"),
        maxUnique = nrow(mapdata)
      )
      uniqueSubdata <- subdata[, names(subdata) %in% c(add_plotlyVars, "mapping_waterid")]
      names(uniqueSubdata)[names(uniqueSubdata) == "mapping_waterid"] <- commonvar
      uniqueSubdata <- as.data.frame(unique(uniqueSubdata))
      if (length(uniqueSubdata) == 1) {
        names(uniqueSubdata) <- commonvar
      }
      uniqueSubdata$season <- rep(1, nrow(uniqueSubdata))
      uniqueSubdata$year <- rep(1, nrow(uniqueSubdata))
    }
  } else if ((!identical(NA, map_years) & length(map_years[map_years %in% aggFuncs]) != 0) | (!identical(NA, map_seasons) & length(map_seasons[map_seasons %in% aggFuncs]) != 0)) {
    mapdata <- data.frame(subdata[c("mapping_waterid")], vvar)
    if (length(map_years[map_years %in% aggFuncs]) != 0) {
      aggFunc <- map_years
    } else {
      aggFunc <- map_seasons
    }
    mapdata <- aggregate(mapdata["vvar"],
      by = list(mapping_waterid = mapdata$mapping_waterid),
      FUN = eval(parse(text = naOmitFuncStr(aggFunc)))
    )
    MAPID <- mapdata$mapping_waterid
    names(mapdata)[1] <- commonvar
    vvar <- mapdata$vvar
    dmapfinal <- data.frame(mapdata[, names(mapdata) != "vvar"]) # added 3-25-2017
    names(dmapfinal)[1] <- c(commonvar)

    if ((enable_plotlyMaps != "no" & enable_plotlyMaps != "static") | !is.na(add_plotlyVars[1])) {
      add_plotlyVars <- test_addPlotlyvars(
        add_plotlyVars = c(add_plotlyVars, "lat", "lon"),
        subdata,
        groupVar = c("mapping_waterid"),
        maxUnique = nrow(mapdata)
      )
      uniqueSubdata <- subdata[, names(subdata) %in% c(add_plotlyVars, "mapping_waterid")]
      names(uniqueSubdata)[names(uniqueSubdata) == "mapping_waterid"] <- commonvar
      uniqueSubdata <- as.data.frame(unique(uniqueSubdata))
      if (length(uniqueSubdata) == 1) {
        names(uniqueSubdata) <- commonvar
      }
      uniqueSubdata$season <- rep(1, nrow(uniqueSubdata))
      uniqueSubdata$year <- rep(1, nrow(uniqueSubdata))
    }
  } else {
    uniqueSubdata <- subdata
    names(uniqueSubdata)[names(uniqueSubdata) == "waterid_for_RSPARROW_mapping"] <- commonvar
    mapdata <- data.frame(MAPID)
    colnames(mapdata) <- commonvar
    dmapfinal <- data.frame(MAPID)
    colnames(dmapfinal) <- c(commonvar)
  }

  map_agg.list <- named.list(uniqueSubdata, mapdata, dmapfinal, add_plotlyVars, MAPID, vvar)
  return(map_agg.list)
}
