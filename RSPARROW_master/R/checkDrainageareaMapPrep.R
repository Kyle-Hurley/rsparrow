#' @title checkDrainageareaMapPrep
#' 
#' @description 
#' Compiles and prepares necessary map data and parameters for 
#' checkDrainageErrors maps
#' 
#' Executed By: make_drainageAreaErrorsMaps.R
#' 
#' Executes Routines: \itemize{
#'              \item checkDynamic.R,
#'              \item named.list.R,
#'              \item set_unique_breaks.R,
#'              \item setupDynamicMaps.R}
#' 
#' @param file.output.list list of control settings and relative paths used for input and 
#' output of external files.  Created by `generateInputList.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit, 
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo, 
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list, 
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param break1 list of all legend breaks for prediction maps
#' @param DAreaFailCheckObj data.frame of all rows of subdata in which the user's original 
#' data for Total Drainage Area vs. Total Drainage Area calculated by RSPARROW differ
#' @param data1 input data (data1)
#' @param existGeoLines TRUE/FALSE indicating whether the Geolines shape file is present
#' @param commonvar string indicating the column to join the map data and the shapefile
#' @param map.vars.list character vector indicating which checkDrainageErrors maps to generate
#' @param k numeric index for current map
#' 
#' @return `prepReturns.list` a named list containing
#' \tabular{ll}{
#' `dmap` \tab data.frame to be used for mapping \cr
#' `break1` \tab vector of legend breaks created using `set_unique_breaks()`  \cr
#' `nlty` \tab numeric vector indicating line types with `length(nlty)==length(break1)` \cr
#' `nlwd` \tab numeric vector indicating line widths with `length(nlwd)==length(break1)` \cr
#' `Mcol` \tab character vector of unique map colors with `length(Mcol)==length(break1)` \cr
#' }
#' @keywords internal
#' @noRd

checkDrainageareaMapPrep <- function(file.output.list, mapping.input.list, 
                                     break1 = NULL, 
                                     DAreaFailCheckObj, data1, existGeoLines, 
                                     commonvar, map.vars.list, k) {
  predictionMapColors <- mapping.input.list$predictionMapColors
  mapsPerPage <- mapping.input.list$mapsPerPage
  enable_plotlyMaps <- mapping.input.list$enable_plotlyMaps
  map_years <- mapping.input.list$map_years
  map_seasons <- mapping.input.list$map_seasons
  mapPageGroupBy <- mapping.input.list$mapPageGroupBy

  is_dynamic <- checkDynamic(data1)
  if (!is_dynamic) {
    map_years <- NA
    map_seasons <- NA
    mapPageGroupBy <- NA
  }
  
  if (k %in% c(2, 3)) { # hydseq, breakpoints by plotpage
    plots <- setupDynamicMaps(data1, map_years, map_seasons, mapPageGroupBy, mapsPerPage, Rshiny = FALSE, enable_plotlyMaps)
    if (checkDynamic(data1)) {
      # DAreaFailCheckObj <- merge(DAreaFailCheckObj, data1[c("waterid", "year", "season")], by = "waterid")
      DAreaFailCheckObj <- merge(DAreaFailCheckObj, data1[c("waterid", "year", "season")])
      # Otherwise numeric seasons give subdata1 with 0 rows
      if (any(is.numeric(plots$season))) {
        plots$season <- NA
      }
    } else {
      DAreaFailCheckObj$year <- rep(1, nrow(DAreaFailCheckObj))
      DAreaFailCheckObj$season <- rep(1, nrow(DAreaFailCheckObj))
      data1$year <- rep(1, nrow(data1))
      data1$season <- rep(1, nrow(data1))
    }
    
    break2 <- list()
    Mcol2 <- list()
    for (p in unique(plots$plotKey)) {
      if (!all(is.na(plots[plots$plotKey == p, ]$year)) & !all(is.na(plots[plots$plotKey == p, ]$season))) {
        subdata1 <- data1[data1$year %in% plots[plots$plotKey == p, ]$year &
          data1$season %in% plots[plots$plotKey == p, ]$season, ]
        subDAreaFailCheckObj <- DAreaFailCheckObj[DAreaFailCheckObj$year %in% plots[plots$plotKey == p, ]$year &
          DAreaFailCheckObj$season %in% plots[plots$plotKey == p, ]$season, ]
      } else if (!all(is.na(plots[plots$plotKey == p, ]$year))) {
        subdata1 <- data1[data1$year %in% plots[plots$plotKey == p, ]$year, ]
        subDAreaFailCheckObj <- DAreaFailCheckObj[DAreaFailCheckObj$year, ]
      } else if (!all(is.na(plots[plots$plotKey == p, ]$season))) {
        subdata1 <- data1[data1$season %in% plots[plots$plotKey == p, ]$season, ]
        subDAreaFailCheckObj <- DAreaFailCheckObj[DAreaFailCheckObj$season, ]
      } else {
        subdata1 <- data1
        subDAreaFailCheckObj <- DAreaFailCheckObj
      }

      if (k >= 3) {
        vvar <- subDAreaFailCheckObj[[map.vars.list[k]]]
        waterid <- subDAreaFailCheckObj$waterid
      } else {
        vvar <- subdata1[[map.vars.list[k]]]
        waterid <- subdata1$waterid
      }

      # check for NAs
      vvar <- ifelse(is.na(vvar), 0.0, vvar)

      # link MAPCOLORS for variable to shape object (https://gist.github.com/mbacou/5880859)
      # Color classification of variable
      
      iprob <- 5

      iprob <- set_unique_breaks(vvar, iprob)$ip

      if (iprob >= 2) {
        chk1 <- stats::quantile(vvar, probs = 0:iprob / iprob)
        chk <- unique(stats::quantile(vvar, probs = 0:iprob / iprob)) # define quartiles
        qvars <- as.integer(cut(vvar, stats::quantile(vvar, probs = 0:iprob / iprob), include.lowest = TRUE)) # classify variable
        # Mcolors <- c("blue","dark green","gold","red","dark red")
        Mcolors <- predictionMapColors
        Mcolors <- Mcolors[1:(length(chk1) - 1)]
        # http://research.stowers-institute.org/efg/R/Color/Chart/index.htm
        MAPCOLORS <- as.character(Mcolors[qvars])


        dmap <- data.frame(waterid, MAPCOLORS, vvar)
        colnames(dmap) <- c(commonvar, "MAPCOLORS", "VVAR")
        dmap$MAPCOLORS <- as.character(dmap$MAPCOLORS)



        if (k >= 3) {
          # add background color for matched drainage areas
          fwaterid <- data1$waterid
          fMAPCOLORS <- rep("grey", length(fwaterid))
          fdf <- data.frame(fwaterid, fMAPCOLORS)
          newdf <- merge(dmap, fdf, by.y = "fwaterid", by.x = commonvar, all.x = TRUE, all.y = TRUE)
          newdf$MAPCOLORS <- ifelse(is.na(newdf$MAPCOLORS), "grey", as.character(newdf$MAPCOLORS))
          dmap <- newdf
        }



        if (k >= 3) {
          break1[k][[1]][[p]] <- as.character(chk[1:iprob] + 1)
          for (i in 1:iprob) {
            break1[k][[1]][[p]][i] <- paste0(round(chk[i], digits = 2), " TO ", round(chk[i + 1], digits = 2))
          }
          break1[k][[1]][[p]][iprob + 1] <- "Areas Match"
          nlty <- rep(1, iprob)
          nlwd <- rep(0.8, iprob)
          Mcol <- length(Mcolors) + 1
          Mcol[1:iprob] <- Mcolors[1:iprob]
          Mcol[iprob + 1] <- "grey"
        } else {
          break1[k][[1]][[p]] <- as.character(chk[1:iprob])
          for (i in 1:iprob) {
            break1[k][[1]][[p]][i] <- paste0(round(chk[i], digits = 2), " TO ", round(chk[i + 1], digits = 2))
          }
          nlty <- rep(1, iprob)
          nlwd <- rep(0.8, iprob)
          Mcol <- Mcolors
        }
        if (p == plots$plotKey[1]) {
          dmaptot <- dmap
          # break2[[1]]<-break1
          # break1<-break2
          Mcol2[[p]] <- Mcol
          Mcol <- Mcol2
        } else {
          dmaptot <- rbind(dmaptot, dmap)
          # break2[[which(unique(plots$plotKey)==p)]]<-break1
          # break1<-break2
          Mcol2[[p]] <- Mcol
          Mcol <- Mcol2
        }
      } else {
        # no map
      }
    } # end for p

    if (exists("dmaptot")) {
      dmap <- dmaptot
      prepReturns.list <- named.list(dmap, break1, nlty, nlwd, Mcol)
    } else {
      prepReturns.list <- NA
    }
  } else { # end if hydseq

    if (k >= 3) {
      vvar <- DAreaFailCheckObj[[map.vars.list[k]]]
      waterid <- DAreaFailCheckObj$waterid
    } else {
      vvar <- data1[[map.vars.list[k]]]
      waterid <- data1$waterid
    }

    # check for NAs
    vvar <- ifelse(is.na(vvar), 0.0, vvar)

    # link MAPCOLORS for variable to shape object (https://gist.github.com/mbacou/5880859)
    # Color classification of variable
    iprob <- 5

    iprob <- set_unique_breaks(vvar, iprob)$ip

    if (iprob >= 2) {
      chk1 <- stats::quantile(vvar, probs = 0:iprob / iprob)
      chk <- unique(stats::quantile(vvar, probs = 0:iprob / iprob)) # define quartiles
      qvars <- as.integer(cut(vvar, stats::quantile(vvar, probs = 0:iprob / iprob), include.lowest = TRUE)) # classify variable
      # Mcolors <- c("blue","dark green","gold","red","dark red")
      Mcolors <- predictionMapColors
      Mcolors <- Mcolors[1:(length(chk1) - 1)]
      # http://research.stowers-institute.org/efg/R/Color/Chart/index.htm
      MAPCOLORS <- as.character(Mcolors[qvars])


      dmap <- data.frame(waterid, MAPCOLORS, vvar)
      colnames(dmap) <- c(commonvar, "MAPCOLORS", "VVAR")
      dmap$MAPCOLORS <- as.character(dmap$MAPCOLORS)



      if (k >= 3) {
        # add background color for matched drainage areas
        fwaterid <- data1$waterid
        fMAPCOLORS <- rep("grey", length(fwaterid))
        fdf <- data.frame(fwaterid, fMAPCOLORS)
        newdf <- merge(dmap, fdf, by.y = "fwaterid", by.x = commonvar, all.x = TRUE, all.y = TRUE)
        newdf$MAPCOLORS <- ifelse(is.na(newdf$MAPCOLORS), "grey", as.character(newdf$MAPCOLORS))
        dmap <- newdf
      }



      if (k >= 3) {
        break1 <- as.character(chk[1:iprob] + 1)
        for (i in 1:iprob) {
          break1[i] <- paste0(round(chk[i], digits = 2), " TO ", round(chk[i + 1], digits = 2))
        }
        break1[iprob + 1] <- "Areas Match"
        nlty <- rep(1, iprob)
        nlwd <- rep(0.8, iprob)
        Mcol <- length(Mcolors) + 1
        Mcol[1:iprob] <- Mcolors[1:iprob]
        Mcol[iprob + 1] <- "grey"
      } else {
        break1 <- as.character(chk[1:iprob])
        for (i in 1:iprob) {
          break1[i] <- paste0(round(chk[i], digits = 2), " TO ", round(chk[i + 1], digits = 2))
        }
        nlty <- rep(1, iprob)
        nlwd <- rep(0.8, iprob)
        Mcol <- Mcolors
      }

      prepReturns.list <- named.list(dmap, break1, nlty, nlwd, Mcol)

    } else {
      prepReturns.list <- NA
    }
  } # end hydseq

  return(prepReturns.list)
} # end func
