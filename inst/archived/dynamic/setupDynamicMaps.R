#' @title setupDynamicMaps
#' @description Create a data.frame of all plots per page according to
#'             RSPARROW user settings map_years, map_seasons,
#'             mapPageGroupBy, and mapsPerPage \cr \cr
#' Executed By: \itemize{\item checkDrainageareaMapPrep.R
#'                      \item make_residMaps.R
#'                      \item make_siteAttrMaps.R
#'                      \item goShinyPlot.R
#'                      \item predictMaps.R} \cr
#' @param dmapfinal data.frame containing variables to map
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
#' @param mapPageGroupBy RSPARROW dynamic user setting indicating grouping variable for
#'                      maps on a page, select "season","year",or NA for no group
#' @param mapsPerPage number between 1 and 4 indicating maps per page
#' @param Rshiny TRUE/FALSE indicating whether routine is being run from the Shiny app
#' @param enable_plotlyMaps yes/no indicating whether to enable plotly interactive
#'                         displays for maps
#' @return data.frame of all pages of plots grouped according to `map_years`, `map_seasons`,
#'             `mapPageGroupBy`, and `mapsPerPage`
#' @keywords internal
#' @noRd


setupDynamicMaps <- function(dmapfinal, map_years, map_seasons, mapPageGroupBy, mapsPerPage,
                             Rshiny, enable_plotlyMaps) {
  aggFuncs <- c("mean", "median", "min", "max")

  # if "all" selected get list
  if (!identical(map_years, NA) & (identical(map_years, "all") | length(map_years[map_years %in% aggFuncs]) != 0)) {
    map_years <- unique(dmapfinal$year)
  }
  if (!identical(map_seasons, NA) & (identical(map_seasons, "all") | length(map_seasons[map_seasons %in% aggFuncs]) != 0)) {
    map_seasons <- unique(dmapfinal$season)
  }

  # subset data by year and season
  if (!is.na(map_years[1]) & !is.na(map_seasons[1]) &
    !length(map_years[map_years %in% aggFuncs]) != 0 & !length(map_seasons[map_seasons %in% aggFuncs]) != 0) { # map specific years or seasons
    dmapfinal <- dmapfinal[dmapfinal$year %in% map_years & dmapfinal$season %in% map_seasons, ]
  } else if (!is.na(map_years[1]) & !length(map_years[map_years %in% aggFuncs]) != 0) { # map specific years
    dmapfinal <- dmapfinal[dmapfinal$year %in% map_years, ]
  } else if (!identical(map_seasons, NA) & !length(map_seasons[map_seasons %in% aggFuncs]) != 0) { # map specific seasons
    dmapfinal <- dmapfinal[dmapfinal$season %in% map_seasons, ]
  } else {
    mapPageGroupBy <- NA # all
  }

  plotData <- as.data.frame(dmapfinal)


  # create plot sequence
  plotSeq <- numeric(0)


  if (mapPageGroupBy %in% c("year", NA) &
    (!identical(map_years, NA) & !length(map_years[map_years %in% aggFuncs]) != 0 & !identical(map_seasons, NA) & !length(map_seasons[map_seasons %in% aggFuncs]) != 0)) {
    plots <- unique(plotData[c("year", "season")])
  } else if (mapPageGroupBy %in% c("year", NA) &
    ((identical(map_seasons, NA) | length(map_seasons[map_seasons %in% aggFuncs]) != 0) & !identical(map_years, NA) & !length(map_years[map_years %in% aggFuncs]) != 0)) {
    plots <- unique(plotData[c("year")])
    plots$season <- rep(1, nrow(plots))
  } else if (mapPageGroupBy %in% c("season", NA) &
    ((identical(map_years, NA) | length(map_years[map_years %in% aggFuncs]) != 0) & !identical(map_seasons, NA) & !length(map_seasons[map_seasons %in% aggFuncs]) != 0)) {
    plots <- unique(plotData[c("season")])
    plots$year <- rep(1, nrow(plots))
  } else if (is.na(mapPageGroupBy) & (((identical(map_years, NA) | length(map_years[map_years %in% aggFuncs]) != 0) & (identical(map_seasons, NA) | length(map_seasons[map_seasons %in% aggFuncs]) != 0)) |
    (identical(map_years, NA) & identical(map_seasons, NA)))) { # all
    plots <- data.frame(year = 1, season = 1, plotKey = 1)
  } else {
    plots <- unique(plotData[c("year", "season")])
  }

  if (is.na(mapPageGroupBy)) {
    plotSeq <- rep(seq(1, nrow(plots), mapsPerPage), each = mapsPerPage)
  }
  if (!is.na(mapPageGroupBy)) {
    if (mapPageGroupBy == "year") {
      group <- map_years
    } else if (mapPageGroupBy == "season") {
      group <- map_seasons
    }
  } else {
    group <- NA
  }

  if (!is.na(mapPageGroupBy)) {
    if (mapPageGroupBy == "year") {
      # plots<-plots[order(plots$year,plots$season),]
      plots <- plots %>%
        arrange(factor(season, levels = c("winter", "spring", "summer", "fall")))
      plots <- plots[order(plots$year), ]
    } else if (mapPageGroupBy == "season") {
      plots <- plots[order(plots$season, plots$year), ]
    }
  } else if (!identical(map_seasons, NA) & (identical(map_years, NA) | length(map_years) == 1)) {
    if (length(map_seasons) > 1) {
      plots <- plots %>%
        arrange(factor(season, levels = c("winter", "spring", "summer", "fall")))
    }
  }


  # fill in blank lines for missing seasons or years
  if (!identical(group, NA)) {
    groupSeq <- numeric(0)
    pItr <- nrow(plots)

    for (y in group) {
      pItr <- pItr + 1
      ydata <- plots
      names(ydata)[names(ydata) == mapPageGroupBy] <- "groupVar"
      uniqueVar <- ifelse(mapPageGroupBy == "year", "season", ifelse(mapPageGroupBy == "season", "year", NA))
      names(ydata)[names(ydata) == uniqueVar] <- "uniqueVar"
      yseq <- rep(y, length(na.omit(unique(ydata[ydata$groupVar == y, ]$uniqueVar))))

      if (length(yseq) < mapsPerPage & !is.na(mapPageGroupBy)) {
        addMissingPlots <- plots[1, ]
        names(addMissingPlots) <- c("groupVar", "uniqueVar")
        addMissingPlots$groupVar <- NA
        addMissingPlots$uniqueVar <- NA


        for (m in 1:(mapsPerPage - (length(yseq)))) {
          ydata2 <- plots

          names(ydata2)[names(ydata2) == mapPageGroupBy] <- "groupVar"
          uniqueVar <- ifelse(mapPageGroupBy == "year", "season", ifelse(mapPageGroupBy == "season", "year", NA))
          names(ydata2)[names(ydata2) == uniqueVar] <- "uniqueVar"


          ydata2 <- rbind(ydata2[ydata2$groupVar == y & !is.na(ydata2$groupVar), ], addMissingPlots, ydata2[ydata2$groupVar != y, ])
          names(ydata2) <- names(plots)

          plots <- ydata2
        }

        yseq <- c(yseq, rep(NA, mapsPerPage - (length(yseq))))
      }
      if (!is.na(mapPageGroupBy)) {
        if (length(yseq) == mapsPerPage) {
          pSeq <- rep(pItr, mapsPerPage)
        } else {
          pSeq <- rep(seq(pItr, length(yseq) + pItr, 1), each = mapsPerPage, length.out = length(yseq))
        }
        plotSeq <- c(plotSeq, pSeq)
      }
      groupSeq <- c(groupSeq, yseq)
      pItr <- max(pSeq)
    }
  }


  # generate plot sequence variable
  if (is.na(mapPageGroupBy) & ((!identical(map_years, NA) & length(map_years[map_years %in% aggFuncs]) != 0 & !identical(map_seasons, NA) & length(map_seasons[map_seasons %in% aggFuncs]) != 0) |
    (identical(map_years, NA) & identical(map_seasons, NA)))) { # all
  } else {
    plotSeq <- plotSeq[1:nrow(plots)]
    plots$plotKey <- plotSeq
  }

  if (Rshiny) {
    plots <- plots[plots$plotKey == 1, ]
  }
  if (enable_plotlyMaps == "leaflet") {
    plots <- plots[1, ]
  }


  return(plots)
}
