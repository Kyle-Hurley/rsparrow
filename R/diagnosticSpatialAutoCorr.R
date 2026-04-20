#' @title diagnosticSpatialAutoCorr
#'
#' @description
#' Generates diagnostics for spatial dependence (autocorrelation) in the
#' model residuals. SiteIDs are determined from hydseq sorted file to ensure consistency in hydrologic
#' distance and other ID ordering across programs. Outputs Morans I stats to
#' ~/estimate/summaryCSV/(run_id)_EuclideanMoransI.csv. Returns a named list of plotly plot
#' objects (p19-p22). (Plan 05D: HTML rendering removed; p19-p22 plotFuncs inlined.)
#'
#' Executed By: controlFileTasksModel.R
#'
#'
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by `generateInputList.R`
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 &
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter
#' sub-section 5.1.2 for details)
#' @param estimate.list list output from `estimate.R`
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#' NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo,
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list,
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param subdata data.frame input data (subdata)
#' @param min.sites.list named list of control settings `minimum_headwater_site_area`,
#' `minimum_reaches_separating_sites`, `minimum_site_incremental_area`
#' @param class.input.list list of control settings related to classification variables
#' @keywords internal
#' @noRd



diagnosticSpatialAutoCorr <- function(file.output.list, sitedata, estimate.list,
                                      estimate.input.list, mapping.input.list, subdata, min.sites.list,
                                      class.input.list, DataMatrix.list = NULL) {

  Mdiagnostics.list    <- estimate.list$Mdiagnostics.list
  path_results         <- file.output.list$path_results
  run_id               <- file.output.list$run_id
  path_master          <- file.output.list$path_master
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator  <- file.output.list$csv_columnSeparator
  classvar             <- class.input.list$classvar
  diagnosticPlotPointStyle <- mapping.input.list$diagnosticPlotPointStyle
  diagnosticPlotPointSize  <- mapping.input.list$diagnosticPlotPointSize
  MoranDistanceWeightFunc  <- mapping.input.list$MoranDistanceWeightFunc
  pchPlotlyCross           <- mapping.input.list$pchPlotlyCross
  showPlotGrid             <- mapping.input.list$showPlotGrid

  data.index.list <- DataMatrix.list$data.index.list
  jdepvar <- data.index.list$jdepvar
  jtnode  <- data.index.list$jtnode
  jfnode  <- data.index.list$jfnode

  Resids  <- Mdiagnostics.list$Resids
  Obs     <- Mdiagnostics.list$Obs
  predict <- Mdiagnostics.list$predict
  yldobs  <- Mdiagnostics.list$yldobs

  pnch <- as.character(pchPlotlyCross[pchPlotlyCross$pch == diagnosticPlotPointStyle, ]$plotly)
  markerSize <- diagnosticPlotPointSize * 10
  if (requireNamespace("leaflet", quietly = TRUE)) {
    markerCols <- leaflet::colorNumeric(c("black", "white"), 1:2)
  } else {
    markerCols <- function(x) c("black", "white")[x]
  }
  test <- regexpr('open', pnch) > 0
  if (test) {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1))
  } else {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1),
                       line = list(color = markerCols(1), width = 0.8))
  }

  data <- DataMatrix.list$data

  # contiguous class variables by sites
  class <- as.array(
    sapply(classvar, function(var) as.numeric(sitedata[[var]]))
  )

  set.ZeroPolicyOption(TRUE) # setting required for hydrological distance tests

  numsites      <- length(sitedata$waterid)
  path_masterFormat <- path_master
  dynamic       <- FALSE

  ###############################################################################
  # Shared hydrological network traversal (used by p19, p21, p22)

  nreach <- length(data[, 1])
  nstas  <- sum(ifelse(data[, jdepvar] > 0, 1, 0))
  nnode  <- max(data[, jtnode], data[, jfnode])

  updata1 <- subdata
  updata  <- updata1[with(updata1, order(-updata1$hydseq)), ]

  snode      <- array(0, dim = nnode)
  stnode     <- array(0, dim = nnode)
  dnode      <- array(0, dim = nnode)
  anode      <- array(0, dim = nnode)
  tanode     <- array(0, dim = nnode)
  dnsite     <- numeric(nstas)
  upsite     <- numeric(nstas)
  siteid     <- numeric(nstas)
  dist       <- numeric(nstas)
  area       <- numeric(nstas)
  totarea    <- numeric(nstas)
  shydseq    <- numeric(nstas)
  site_tarea <- array(0, dim = nstas)
  is <- 0

  for (k in 1:nreach) {
    tnode     <- updata$tnode[k]
    fnode     <- updata$fnode[k]
    sitereach <- updata$staidseq[k]

    if (updata$staid[k] > 0) {
      is <- is + 1
      dnsite[is]  <- snode[tnode]
      siteid[is]  <- stnode[tnode]
      upsite[is]  <- sitereach
      dist[is]    <- dnode[tnode]
      area[is]    <- anode[tnode]
      shydseq[is] <- updata$hydseq[k]
      totarea[is] <- tanode[tnode]
      site_tarea[sitereach] <- updata$demtarea[k]

      iarea     <- updata$demiarea[k]
      tarea2    <- updata$demtarea[k]
      idist     <- updata$length[k]
      sitereach <- updata$staidseq[k]
      siteid2   <- updata$staid[k]
    } else {
      iarea     <- updata$demiarea[k] + anode[tnode]
      tarea2    <- tanode[tnode]
      idist     <- (updata$length[k] + dnode[tnode]) * updata$frac[k]
      sitereach <- snode[tnode]
      siteid2   <- stnode[tnode]
    }

    anode[fnode]  <- iarea
    tanode[fnode] <- tarea2
    dnode[fnode]  <- idist
    snode[fnode]  <- sitereach
    stnode[fnode] <- siteid2
  }

  sdata <- data.frame(siteid, dnsite, upsite, dist, area, totarea, shydseq)
  sdata <- sdata[with(sdata, order(sdata$shydseq)), ]

  sdistance <- matrix(0, nrow = nstas, ncol = nstas)
  for (i in 1:nstas) {
    if (sdata$dnsite[i] > 0) {
      dns <- sdata$dnsite[i]
      dnd <- dist[i]
      sdistance[sdata$upsite[i], dns] <- dnd
      if (i < nstas) {
        for (j in (i + 1):nstas) {
          if (dns == sdata$upsite[j]) {
            dns <- sdata$dnsite[j]
            dnd <- dnd + sdata$dist[j]
            sdistance[sdata$upsite[i], dns] <- dnd
          }
        }
      }
    }
  }

  scount <- numeric(nstas)
  for (i in 1:nstas) {
    for (j in 1:nstas) {
      if (sdistance[j, i] > 0) {
        scount[i] <- scount[i] + 1
      }
    }
  }

  ###############################################################################
  # Station header and Euclidean distances (shared by p20, p21, p22)

  staname <- character(nstas)
  ttarea  <- numeric(nstas)
  stano   <- numeric(nstas)
  shydseq <- numeric(nstas)
  ssta    <- numeric(nstas)
  xlon    <- numeric(nstas)
  xlat    <- numeric(nstas)

  is <- 0
  for (i in 1:nreach) {
    if (updata1$staid[i] > 0) {
      is <- is + 1
      staname[is] <- updata1$station_name[i]
      ttarea[is]  <- updata1$demtarea[i]
      stano[is]   <- updata1$staid[i]
      shydseq[is] <- updata1$hydseq[i]
      xlon[is]    <- updata1$lon[i]
      xlat[is]    <- updata1$lat[i]
    }
  }
  index      <- rep(1:nstas)
  siteheader <- data.frame(index, ssta, shydseq, stano, staname, ttarea, xlon, xlat)

  dname <- "  Inverse distance weight function: "
  dd    <- data.frame(dname, MoranDistanceWeightFunc)
  colnames(dd)  <- c(" ", " ")
  row.names(dd) <- c(" ")

  xx <- data.frame(sitedata$station_name, sitedata$station_id, sitedata$staid, scount)
  xx <- xx[with(xx, order(xx$scount, xx$sitedata.staid)), ]
  x1 <- xx[(xx$scount >= 1), ]
  nest_sites <- length(x1$scount) / length(xx$scount)

  Lat <- siteheader$xlat
  Lon <- siteheader$xlon
  Lat <- fixDupLatLons(Lat)
  Lon <- fixDupLatLons(Lon)

  edistance <- matrix(0, nrow = nstas, ncol = nstas)
  for (i in 1:(nstas - 1)) {
    for (j in (i + 1):nstas) {
      lat1 <- Lat[i] * pi / 180
      lat2 <- Lat[j] * pi / 180
      lon1 <- Lon[i] * pi / 180
      lon2 <- Lon[j] * pi / 180
      R <- 6371
      x <- (lon2 - lon1) * cos(0.5 * (lat2 + lat1))
      y <- lat2 - lat1
      edistance[i, j] <- R * sqrt(x * x + y * y)
    }
  }

  ###############################################################################
  # Residuals into matrix (shared by p21, p22)

  mres  <- numeric(nstas)
  mbias <- numeric(nstas)
  mobsd <- numeric(nstas)
  myld  <- numeric(nstas)
  for (k in 1:nstas) {
    mres[k]  <- Resids[k]
    mbias[k] <- Obs[k] / predict[k]
    mobsd[k] <- Obs[k]
    myld[k]  <- yldobs[k]
  }

  ###############################################################################
  # p19: CDF of Station Hydrological Distances

  sdist <- numeric(sum(scount))
  is <- 0
  for (i in 1:nstas) {
    for (j in 1:nstas) {
      if (sdistance[j, i] > 0) {
        is <- is + 1
        sdist[is] <- sdistance[j, i]
      }
    }
  }

  Fn <- ecdf(sdist)
  y  <- Fn(sdist)
  plotData <- data.frame(sdist = sdist, y = y)
  plotData  <- plotData[order(plotData$sdist), ]
  p <- plotlyLayout(plotData$sdist, plotData$y,
    log = "", nTicks = 7, digits = 0,
    xTitle = "Distance Between Sites", xZeroLine = FALSE, xminTick = 0,
    yTitle = "Fn(x)", yZeroLine = FALSE, ymax = 1, ymin = 0, ymaxTick = 1,
    plotTitle = "Station Hydrologic Distances",
    legend = FALSE, showPlotGrid = showPlotGrid
  ) %>%
    add_trace(
      x = plotData$sdist, y = plotData$y, type = "scatter", mode = "lines", color = I("black"),
      line = list(color = I("black"))
    ) %>%
    plotly::layout(shapes = list(
      hline(spatialAutoCorr = TRUE, 1, color = "black", dash = "dash"),
      hline(spatialAutoCorr = TRUE, 0, color = "black", dash = "dash")
    ))

  p.list <- list()
  p.list[["p19"]] <- p

  ###############################################################################
  # p20: CDF of Station Euclidean Distances

  edist <- numeric((nstas * nstas - 1) / 2)
  is <- 0
  for (i in 1:nstas) {
    for (j in 1:nstas) {
      if (edistance[j, i] > 0) {
        is <- is + 1
        edist[is] <- edistance[j, i]
      }
    }
  }
  Fn <- ecdf(edist)
  y  <- Fn(edist)
  plotData <- data.frame(edist = edist, y = y)
  plotData  <- plotData[order(plotData$edist), ]
  p <- plotlyLayout(plotData$edist, plotData$y,
    log = "", nTicks = 7, digits = 0,
    xTitle = "Distance Between Sites", xZeroLine = FALSE, xminTick = 0,
    yTitle = "Fn(x)", yZeroLine = FALSE, ymax = 1, ymin = 0, ymaxTick = 1,
    plotTitle = "Station Euclidean Distances (kilometers)",
    legend = FALSE, showPlotGrid = showPlotGrid
  ) %>%
    add_trace(
      x = plotData$edist, y = plotData$y, type = "scatter", mode = "lines", color = I("black"),
      line = list(color = I("black"))
    ) %>%
    plotly::layout(shapes = list(
      hline(spatialAutoCorr = TRUE, 1, color = "black", dash = "dash"),
      hline(spatialAutoCorr = TRUE, 0, color = "black", dash = "dash")
    ))

  p.list[["p20"]] <- p

  ###############################################################################
  # p21: Moran's I by River Basin

  checkdist  <- ifelse(sdistance > 0, 1, 0)
  checkcount <- scount
  for (j in nstas:1) {
    if (scount[j] > 4 & sum(checkdist[, j]) == scount[j]) {
      checkcount[j] <- scount[j]
      for (i in 1:nstas) {
        if (checkdist[i, j] > 0) {
          checkdist[i, ] <- 0
        }
      }
    } else {
      checkcount[j] <- 0
    }
  }
  xx <- checkcount[checkcount > 0]

  pmoran      <- numeric(length(xx))
  pmoran_dev  <- numeric(length(xx))
  bpmoran     <- numeric(length(xx))
  bpmoran_dev <- numeric(length(xx))
  cind        <- character(length(pmoran))
  dsiteid     <- numeric(length(xx))

  ibasin <- 0
  for (j in 1:nstas) {
    if (checkcount[j] > 0) {
      ibasin <- ibasin + 1
      dsiteid[ibasin] <- j
      is <- 0
      xresids   <- numeric(checkcount[j] + 1)
      xLat      <- numeric(checkcount[j] + 1)
      xLon      <- numeric(checkcount[j] + 1)
      ires      <- numeric(checkcount[j] + 1)
      bdistance <- matrix(0, nrow = checkcount[j] + 1, ncol = checkcount[j] + 1)
      bres      <- numeric(checkcount[j] + 1)
      bsites    <- numeric(checkcount[j] + 1)

      is <- is + 1
      ires[is]    <- is
      xresids[is] <- mres[j]
      xLat[is]    <- Lat[j]
      xLon[is]    <- Lon[j]
      bres[is]    <- mres[j]
      bsites[is]  <- j

      for (i in 1:nstas) {
        if (sdistance[i, j] > 0) {
          is <- is + 1
          ires[is]    <- is
          xresids[is] <- mres[i]
          xLat[is]    <- Lat[i]
          xLon[is]    <- Lon[i]
          bres[is]    <- mres[i]
          bsites[is]  <- i
        }
      }

      xmoran       <- data.frame(ires, xresids, xLat, xLon)
      xmoran.dists <- as.matrix(dist(cbind(xmoran$xLon, xmoran$xLat)), method = "euclidean")
      distance     <- xmoran.dists
      xmoran.dists.inv <- eval(parse(text = MoranDistanceWeightFunc)) # user distance weight expression
      diag(xmoran.dists.inv) <- 0
      cind[ibasin] <- as.character(j)

      lw  <- mat2listw(xmoran.dists.inv)
      lwW <- nb2listw(lw$neighbours, glist = lw$weights, style = "W")
      morantest.obj      <- moran.test(xmoran$xresids, lwW, alternative = "two.sided")
      pmoran[ibasin]     <- morantest.obj$p.value
      pmoran_dev[ibasin] <- morantest.obj$statistic

      bdistance[1:is, 1:is] <- sdistance[bsites, bsites]
      for (i in 1:is) {
        for (k in 1:is) {
          if (bdistance[i, k] == 0) bdistance[i, k] <- bdistance[k, i]
        }
      }

      distance <- bdistance
      xmoran.dists.inv <- ifelse(!distance == 0, eval(parse(text = MoranDistanceWeightFunc)), 0) # user weight
      diag(xmoran.dists.inv) <- 0

      lw  <- mat2listw(xmoran.dists.inv)
      lwW <- nb2listw(lw$neighbours, glist = lw$weights, style = "W", zero.policy = TRUE)
      morantest.obj       <- moran.test(bres, lwW, alternative = "two.sided", adjust.n = TRUE,
                                        na.action = na.exclude, zero.policy = TRUE)
      bpmoran[ibasin]     <- morantest.obj$p.value
      bpmoran_dev[ibasin] <- morantest.obj$statistic
    }
  }

  pmoran  <- ifelse(pmoran == 0.0, min(pmoran[pmoran > 0]), pmoran)
  bpmoran <- ifelse(bpmoran == 0.0, min(bpmoran[bpmoran > 0]), bpmoran)

  if (length(pmoran) == 0) cind <- character(0)
  p <- plotlyLayout(NA, pmoran,
    log = "", nTicks = 7, digits = 1,
    xTitle = "River Basin ID Index", ymin = 0, ymax = 1,
    xZeroLine = FALSE, xLabs = sort(as.numeric(unique(cind))),
    yTitle = "P Value (Euclidean distance weighting within basin)", yZeroLine = FALSE,
    plotTitle = "Moran's I P Value by River Basin",
    legend = FALSE, showPlotGrid = showPlotGrid
  )
  p <- p %>% add_trace(
    y = pmoran, x = as.numeric(cind), type = "scatter", color = I("black"),
    mode = "markers", marker = list(symbol = "line-ew-open", size = 15,
                                    line = list(color = "black", width = 3))
  )
  p_21a <- p %>% plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 0.1)))

  if (length(pmoran_dev) == 0) cind <- character(0)
  p <- plotlyLayout(NA, pmoran_dev,
    log = "", nTicks = 7, digits = 1,
    xTitle = "River Basin ID Index", ymin = 0, ymax = 1,
    xZeroLine = FALSE, xLabs = sort(as.numeric(unique(cind))),
    yTitle = "Standard Deviate (Euclidean distance weighting\n within basin)", yZeroLine = FALSE,
    plotTitle = "Moran's I Standard Deviate by River Basin",
    legend = FALSE, showPlotGrid = showPlotGrid
  )
  p <- p %>% add_trace(
    y = pmoran_dev, x = as.numeric(cind), type = "scatter", color = I("black"),
    mode = "markers", marker = list(symbol = "line-ew-open", size = 15,
                                    line = list(color = "black", width = 3))
  )
  p_21b <- p %>% plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 0.1)))

  if (length(bpmoran) == 0) cind <- character(0)
  p <- plotlyLayout(NA, bpmoran,
    log = "", nTicks = 7, digits = 1,
    xTitle = "River Basin ID Index", ymin = 0, ymax = 1,
    xZeroLine = FALSE, xLabs = sort(as.numeric(unique(cind))),
    yTitle = "P Value (Hydrologic distance weighting)", yZeroLine = FALSE,
    plotTitle = "Moran's I P Value by River Basin",
    legend = FALSE, showPlotGrid = showPlotGrid
  )
  p <- p %>% add_trace(
    y = bpmoran, x = as.numeric(cind), type = "scatter", color = I("black"),
    mode = "markers", marker = list(symbol = "line-ew-open", size = 15,
                                    line = list(color = "black", width = 3))
  )
  p_21c <- p %>% plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 0.1)))

  if (length(bpmoran_dev) == 0) cind <- character(0)
  p <- plotlyLayout(NA, bpmoran_dev,
    log = "", nTicks = 7, digits = 1,
    xTitle = "River Basin ID Index", ymin = 0, ymax = 1,
    xZeroLine = FALSE, xLabs = sort(as.numeric(unique(cind))),
    yTitle = "Standard Deviate (Hydrologic distance weighting)", yZeroLine = FALSE,
    plotTitle = "Moran's I Standard Deviate by River Basin",
    legend = FALSE, showPlotGrid = showPlotGrid
  )
  p <- p %>% add_trace(
    y = bpmoran_dev, x = as.numeric(cind), type = "scatter", color = I("black"),
    mode = "markers", marker = list(symbol = "line-ew-open", size = 15,
                                    line = list(color = "black", width = 3))
  )
  p_21d <- p %>% plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 0.1)))

  p.list[["p21"]] <- subplot(p_21a, p_21b, p_21c, p_21d,
    nrows = 2, widths = c(0.5, 0.5),
    titleX = TRUE, titleY = TRUE, margin = 0.08
  )

  ###############################################################################
  # Between p21 and p22: river basin results and full-domain hydrological Moran's I

  # Build sites_sigmoran from basin loop results (pmoran/bpmoran already min-replaced above)
  x1 <- data.frame(sitedata$station_name, sitedata$station_id, sitedata$staid, scount)
  x2 <- x1[(x1$scount > 0), ]
  xx <- data.frame(dsiteid, pmoran, pmoran_dev, bpmoran, bpmoran_dev)
  x2$dsiteid <- x2$sitedata.staid
  sites_sigmoran <- merge(x2, xx, by = "dsiteid", all.y = TRUE, all.x = TRUE)
  sites_sigmoran <- sites_sigmoran[(!is.na(sites_sigmoran$pmoran)), ]
  sites_sigmoran <- sites_sigmoran[, -1]
  colnames(sites_sigmoran) <- c("Site Name", " Site ID", " Downstrm Site ID", " Upstrm Site Count",
                                " P-Value(E)", " Standard Deviate(E)", " P-Value(H)", " Standard Deviate(H)")

  # Full Domain hydrological channel distance weighting for Moran's I
  for (i in 1:nstas) {
    for (k in 1:nstas) {
      if (sdistance[i, k] == 0) sdistance[i, k] <- sdistance[k, i]
    }
  }
  distance <- sdistance
  xmoran.dists.inv <- ifelse(!distance == 0, eval(parse(text = MoranDistanceWeightFunc)), 0) # user weight
  diag(xmoran.dists.inv) <- 0
  lw  <- mat2listw(xmoran.dists.inv)
  lwW <- nb2listw(lw$neighbours, glist = lw$weights, style = "W", zero.policy = TRUE)
  morantest.obj   <- moran.test(mres, lwW, alternative = "two.sided", adjust.n = TRUE,
                                na.action = na.exclude, zero.policy = TRUE)
  pmoran_hyd_full     <- morantest.obj$p.value
  pmoran_dev_hyd_full <- morantest.obj$statistic
  moranOut <- data.frame(pmoran_hyd_full, pmoran_dev_hyd_full)
  rownames(moranOut) <- c(" ")
  colnames(moranOut) <- c(" Moran's P-Value", " Moran's Standard Deviate")
  xtext <- paste0("  Fraction of sites that are nested:  ", round(nest_sites, digits = 3))

  ###############################################################################
  # p22: Moran's I by Class Variable and Full Spatial Domain (Euclidean)

  ibasin <- 0

  if (!is.na(classvar[1]) & (classvar[1] != "sitedata.demtarea.class")) {
    mrbgrp <- table(class[, 1])
    xx     <- as.data.frame(mrbgrp)
    mrbgrp <- as.numeric(xx$Freq)
    xclass <- as.numeric(xx$Var1)
    xclass <- as.numeric(levels(xx$Var1)[xx$Var1])

    pmoran     <- numeric(length(xclass) + 1)
    pmoran_dev <- numeric(length(xclass) + 1)
    cind       <- character(length(pmoran))
    cindLabel  <- classvar[1]

    for (j in seq_along(xclass)) {
      ibasin <- ibasin + 1
      is <- 0
      xresids <- numeric(mrbgrp[j])
      xLat    <- numeric(mrbgrp[j])
      xLon    <- numeric(mrbgrp[j])
      ires    <- numeric(mrbgrp[j])

      for (i in 1:numsites) {
        if (class[i] == xclass[j]) {
          is <- is + 1
          ires[is]    <- is
          xresids[is] <- mres[i]
          xLat[is]    <- Lat[i]
          xLon[is]    <- Lon[i]
        }
      }

      if (is >= 4) {
        xmoran       <- data.frame(ires, xresids, xLat, xLon)
        xmoran.dists <- as.matrix(dist(cbind(xmoran$xLon, xmoran$xLat)), method = "euclidean")
        distance     <- xmoran.dists
        xmoran.dists.inv <- eval(parse(text = MoranDistanceWeightFunc)) # user weight
        diag(xmoran.dists.inv) <- 0
        cind[ibasin] <- as.character(xclass[j])
        lw  <- mat2listw(xmoran.dists.inv)
        lwW <- nb2listw(lw$neighbours, glist = lw$weights, style = "W")
        morantest.obj      <- moran.test(xmoran$xresids, lwW, alternative = "two.sided")
        pmoran[ibasin]     <- morantest.obj$p.value
        pmoran_dev[ibasin] <- morantest.obj$statistic
      }
    }
  } else {
    pmoran     <- numeric(1)
    pmoran_dev <- numeric(1)
    cind       <- character(1)
    cindLabel  <- "Total Area"
  }

  # Full spatial domain (Euclidean)
  ibasin <- ibasin + 1
  is <- 0
  xresids <- numeric(numsites)
  xLat    <- numeric(numsites)
  xLon    <- numeric(numsites)
  ires    <- numeric(numsites)

  for (i in 1:numsites) {
    is <- is + 1
    ires[is]    <- is
    xresids[is] <- mres[i]
    xLat[is]    <- Lat[i]
    xLon[is]    <- Lon[i]
  }

  xmoran       <- data.frame(ires, xresids, xLat, xLon)
  xmoran.dists <- as.matrix(dist(cbind(xmoran$xLon, xmoran$xLat)), method = "euclidean")
  distance     <- xmoran.dists
  xmoran.dists.inv <- eval(parse(text = MoranDistanceWeightFunc)) # user weight
  diag(xmoran.dists.inv) <- 0
  cind[ibasin] <- "Total Area"
  lw  <- mat2listw(xmoran.dists.inv)
  lwW <- nb2listw(lw$neighbours, glist = lw$weights, style = "W")
  morantest.obj      <- moran.test(xmoran$xresids, lwW, alternative = "two.sided")
  pmoran[ibasin]     <- morantest.obj$p.value
  pmoran_dev[ibasin] <- morantest.obj$statistic

  pmoran <- ifelse(pmoran == 0.0, min(pmoran[pmoran > 0]), pmoran)

  p <- plotlyLayout(NA, pmoran,
    log = "", nTicks = 7, digits = 1,
    xTitle = cindLabel, ymin = 0, ymax = 1,
    xZeroLine = FALSE, xLabs = sort(as.numeric(unique(cind))),
    yTitle = "Moran's P Value (Euclidean distance weighting)", yZeroLine = FALSE,
    plotTitle = "Moran's I P Value by CLASS Variable",
    legend = FALSE, showPlotGrid = showPlotGrid
  )
  p <- p %>% add_trace(
    y = pmoran, x = as.numeric(cind), type = "scatter", color = I("black"),
    mode = "markers", marker = list(symbol = "line-ew-open", size = 15,
                                    line = list(color = "black", width = 3))
  )
  p_22a <- p %>% plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 0.1)))

  p <- plotlyLayout(NA, pmoran_dev,
    log = "", nTicks = 7, digits = 1,
    xTitle = cindLabel, ymin = 0, ymax = 1,
    xZeroLine = FALSE, xLabs = sort(as.numeric(unique(cind))),
    yTitle = "Moran's Standard Deviate\n (Euclidean distance weighting)", yZeroLine = FALSE,
    plotTitle = "Moran's I Standard Deviate by CLASS Variable",
    legend = FALSE, showPlotGrid = showPlotGrid
  )
  p <- p %>% add_trace(
    y = pmoran_dev, x = as.numeric(cind), type = "scatter", color = I("black"),
    mode = "markers", marker = list(symbol = "line-ew-open", size = 15,
                                    line = list(color = "black", width = 3))
  )
  p_22b <- p %>% plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 0.1)))

  h <- if (!dynamic) c(1) else c(0.5)
  p.list[["p22"]] <- subplot(p_22a, p_22b,
    nrows = 1, widths = c(0.5, 0.5), heights = h,
    titleX = TRUE, titleY = TRUE, margin = 0.08
  )

  # Output Moran's I p values to CSV
  if (!dynamic) {
    if (!is.na(classvar[1]) & (classvar[1] != "sitedata.demtarea.class")) {
      nmrbout <- numeric(length(xclass) + 1)
      nmrbout[1:length(mrbgrp)]    <- mrbgrp[1:length(mrbgrp)]
      nmrbout[length(mrbgrp) + 1]  <- sum(mrbgrp)
    } else {
      nmrbout    <- numeric(1)
      nmrbout[1] <- numsites
    }

    class_sigmoran <- data.frame(cind, nmrbout, pmoran, pmoran_dev)
    colnames(class_sigmoran) <- c(cindLabel, " Number Stations", " Moran's P-Value", " Moran's Standard Deviate")

    saveList <- named.list(dd, sites_sigmoran, moranOut, xtext, class_sigmoran)
  } else {
    saveList <- NULL
  }

  invisible(list(plots = p.list, saveList = saveList))

} # end function
