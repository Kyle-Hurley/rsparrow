#' @title diagnosticPlotsNLLS
#'
#' @description
#' Creates diagnostic plots and maps. Returns a named list of plot objects. (Plan 05D:
#' HTML rendering removed; make_modelEstPerfPlots and make_modelSimPerfPlots inlined;
#' unPackList replaced with direct $ extractions; eval/parse+plotFunc replaced with
#' direct function calls.)
#'
#' Executed By: \itemize{
#'              \item diagnosticPlotsNLLS_dyn.R,
#'              \item diagnosticPlotsValidate.R,
#'              \item estimate.R}
#'
#' Executes Routines: \itemize{
#'              \item addMarkerText.R,
#'              \item checkBinaryMaps.R,
#'              \item checkDynamic.R,
#'              \item diagnosticPlots_4panel_A.R,
#'              \item diagnosticPlots_4panel_B.R,
#'              \item hline.R,
#'              \item plotlyLayout.R}
#'
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by `generateInputList.R`
#' @param class.input.list list of control settings related to classification variables
#' @param sitedata.demtarea.class Total drainage area classification variable for calibration
#' sites.
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 &
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter
#' sub-section 5.1.2 for details)
#' @param sitedata.landuse Land use for incremental basins for diagnostics.
#' @param estimate.list list output from `estimate.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo,
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list,
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R`
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#' prediction, yield, and residuals csv and shape files
#' @param batch_mode yes/no character string indicating whether RSPARROW is being run in batch
#' mode
#' @param validation TRUE/FALSE indicating whether validation or diagnostic plots are to be
#' generated
#' @keywords internal
#' @noRd


diagnosticPlotsNLLS <- function(file.output.list, class.input.list, sitedata.demtarea.class,
                                sitedata, sitedata.landuse, estimate.list, mapping.input.list,
                                Cor.ExplanVars.list, data_names = NA, add_vars = NA, batch_mode,
                                validation = TRUE) {

  # Direct extractions (replacing unPackList)
  map_siteAttributes.list  <- mapping.input.list$map_siteAttributes.list
  LineShapeGeo             <- mapping.input.list$LineShapeGeo
  GeoLines                 <- mapping.input.list$GeoLines
  enable_plotlyMaps        <- mapping.input.list$enable_plotlyMaps
  map_years                <- mapping.input.list$map_years
  map_seasons              <- mapping.input.list$map_seasons
  mapPageGroupBy           <- mapping.input.list$mapPageGroupBy
  mapsPerPage              <- mapping.input.list$mapsPerPage
  pchPlotlyCross           <- mapping.input.list$pchPlotlyCross
  diagnosticPlotPointStyle <- mapping.input.list$diagnosticPlotPointStyle
  diagnosticPlotPointSize  <- mapping.input.list$diagnosticPlotPointSize
  showPlotGrid             <- mapping.input.list$showPlotGrid
  add_plotlyVars           <- mapping.input.list$add_plotlyVars
  loadUnits                <- mapping.input.list$loadUnits
  yieldUnits               <- mapping.input.list$yieldUnits
  path_results             <- file.output.list$path_results
  path_gis                 <- file.output.list$path_gis
  classvar                 <- class.input.list$classvar
  class_landuse            <- class.input.list$class_landuse

  # If static or dynamic
  is_dynamic <- checkDynamic(sitedata)

  # Filter site attributes to those present in sitedata
  map_siteAttributes.list <- map_siteAttributes.list[map_siteAttributes.list %in% names(sitedata)]

  existGeoLines <- checkBinaryMaps(LineShapeGeo, path_gis)
  msa_has_attr  <- length(map_siteAttributes.list) > 0
  msa_not_na    <- !identical(NA, map_siteAttributes.list)

  p.list <- list()

  if (!validation) {

    if (msa_has_attr & existGeoLines & msa_not_na) {

      # CREATE CALIBRATION SITE MAPS
      # make_siteAttrMaps removed in Plan 05D (map rendering disabled in Plan 05A)
      p.list[["calsite_maps"]] <- NULL

    }

  }

  if (is_dynamic & validation) {

    # Create validation plots directory for dynamic data
    dynValPlot_dir <- paste0(
      path_results, "estimate", .Platform$file.sep,
      "validation_plots_dynamic", .Platform$file.sep
    )
    if (!dir.exists(dynValPlot_dir)) dir.create(dynValPlot_dir)

  }

  # Build marker list (shared by est and sim plots)
  pnch <- as.character(pchPlotlyCross[pchPlotlyCross$pch == diagnosticPlotPointStyle, ]$plotly)
  markerSize <- diagnosticPlotPointSize * 10
  markerCols <- colorNumeric(c("black", "white"), 1:2)
  test <- regexpr("open", pnch) > 0
  if (test) {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1))
  } else {
    markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1),
                       line = list(color = markerCols(1), width = 0.8))
  }

  # Extract estimation diagnostics from Mdiagnostics.list
  Mdiag           <- estimate.list$Mdiagnostics.list
  predict         <- Mdiag$predict
  Obs             <- Mdiag$Obs
  yldpredict      <- Mdiag$yldpredict
  yldobs          <- Mdiag$yldobs
  Resids          <- Mdiag$Resids
  ratio.obs.pred  <- Mdiag$ratio.obs.pred
  standardResids  <- Mdiag$standardResids
  ppredict        <- Mdiag$ppredict
  pyldpredict     <- Mdiag$pyldpredict
  pyldobs         <- Mdiag$pyldobs
  pResids         <- Mdiag$pResids
  pratio.obs.pred <- Mdiag$pratio.obs.pred

  # For validation, override sim variables from vMdiagnostics.list
  if (validation) {
    vMdiag          <- estimate.list$vMdiagnostics.list
    ppredict        <- vMdiag$ppredict
    Obs             <- vMdiag$Obs
    pyldpredict     <- vMdiag$pyldpredict
    pyldobs         <- vMdiag$pyldobs
    pResids         <- vMdiag$pResids
    pratio.obs.pred <- vMdiag$pratio.obs.pred
  }

  # class matrix and group levels for grouped plots
  class <- sapply(classvar, function(var_name) as.numeric(sitedata[[var_name]]))
  if (is.null(dim(class))) dim(class) <- c(length(class), 1L)
  colnames(class) <- classvar
  grp <- as.numeric(names(table(class[, 1])))

  if (!is.na(class_landuse[1])) {
    classvar2 <- paste0(class_landuse, "_pct")
  } else {
    classvar2 <- NA
  }

  # CREATE MODEL ESTIMATION PERFORMANCE PLOTS (p1-p8, !validation only)

  if (!validation) {

    est_plots <- list()

    # p1: Obs vs Pred 4-panel (monitoring-adjusted)
    est_plots[["p1"]] <- diagnosticPlots_4panel_A(
      predict, Obs, yldpredict, yldobs, sitedata, Resids,
      plotclass = NA,
      plotTitles = c(
        "'MODEL ESTIMATION PERFORMANCE \n(Monitoring-Adjusted Predictions) \nObserved vs    Predicted Load'",
        "'MODEL ESTIMATION PERFORMANCE \nObserved vs Predicted Yield'",
        "'Residuals vs Predicted \nLoad'",
        "'Residuals vs Predicted \nYield'"
      ),
      loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
      pnch, markerCols, hline, filterClass = NA
    )

    # p2: Box/Quantile residuals (estimation)
    est_plots[["p2"]] <- diagnosticPlots_4panel_B(
      sitedata, Resids, ratio.obs.pred, standardResids, predict,
      plotTitles = c(
        "'MODEL ESTIMATION PERFORMANCE \nResiduals'",
        "'MODEL ESTIMATION PERFORMANCE \nObserved / Predicted Ratio'",
        "'Normal Q-Q Plot'",
        "'Squared Residuals vs Predicted Load'"
      ),
      loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
      pnch, markerCols, hline
    )

    # p3: Monitoring-adjusted vs simulated loads
    {
      markerText <- "~paste('</br> Simulated Load: ',ppredict,
                   '</br> Predicted Load: ',predict"
      df3 <- data.frame(ppredict = ppredict, predict = predict)
      markerText <- addMarkerText(markerText, add_plotlyVars, df3, sitedata)$markerText
      df3        <- addMarkerText(markerText, add_plotlyVars, df3, sitedata)$mapData
      pp3 <- plotlyLayout(ppredict, predict,
        log = "xy", nTicks = 5, digits = 0,
        xTitle = paste0("Simulated Load (", loadUnits, ")"), xZeroLine = FALSE,
        yTitle = paste0("Monitoring-Adjusted Load (", loadUnits, ")"), yZeroLine = FALSE,
        plotTitle = "Monitoring-Adjusted vs. Simulated Loads",
        legend = FALSE, showPlotGrid = showPlotGrid
      )
      pp3 <- plotly::add_trace(pp3, data = df3, x = ~ppredict, y = ~predict,
        type = "scatter", mode = "markers", marker = markerList,
        hoverinfo = "text", text = eval(parse(text = markerText)))
      pp3 <- plotly::add_trace(pp3, x = ppredict, y = ppredict,
        type = "scatter", mode = "lines", color = I("red"),
        hoverinfo = "text", text = "Simulated Load")
      est_plots[["p3"]] <- pp3
    }

    # p4: Ratio vs area-weighted ExplanVars
    if (!identical(Cor.ExplanVars.list, NA)) {
      est_plots[["p4"]] <- vector("list", length = length(Cor.ExplanVars.list$names))
      for (i in seq_along(Cor.ExplanVars.list$names)) {
        xv <- Cor.ExplanVars.list$cmatrixM_all[, i]
        logStr <- if (min(xv) < 0 | max(xv) < 0) "" else "x"
        markerText <- "~paste('</br>',Cor.ExplanVars.list$names[i],': ',xvar,
                   '</br> RATIO OBSERVED TO PREDICTED: ',ratio.obs.pred"
        df4 <- data.frame(xvar = xv, ratio.obs.pred = ratio.obs.pred)
        markerText <- addMarkerText(markerText, add_plotlyVars, df4, sitedata)$markerText
        df4        <- addMarkerText(markerText, add_plotlyVars, df4, sitedata)$mapData
        est_plots[["p4"]][[i]] <- plotlyLayout(xv, ratio.obs.pred,
          log = logStr, nTicks = 5, digits = 0,
          xTitle = paste0("AREA-WEIGHTED EXPLANATORY VARIABLE (",
                          Cor.ExplanVars.list$names[i], ")"),
          xZeroLine = FALSE, yTitle = "RATIO OBSERVED TO PREDICTED", yZeroLine = FALSE,
          plotTitle = paste("Observed to Predicted Ratio vs Area-Weighted Explanatory Variable",
                            "\nFor Incremental Areas between Calibration Sites; Variable Name =",
                            Cor.ExplanVars.list$names[i]),
          legend = FALSE, showPlotGrid = showPlotGrid) |>
          plotly::add_trace(data = df4, x = ~xvar, y = ~ratio.obs.pred,
            type = "scatter", mode = "markers", marker = markerList,
            hoverinfo = "text", text = eval(parse(text = markerText)))
      }
    }

    # p5: Ratio by drainage area deciles
    pp5 <- plotlyLayout(NA, ratio.obs.pred,
      log = "y", nTicks = 7, digits = 0,
      xTitle = "Upper Bound for Total Drainage Area Deciles (km2)", xZeroLine = FALSE,
      xLabs = sort(as.numeric(unique(sitedata.demtarea.class))),
      yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
      plotTitle = "Ratio Observed to Predicted by Deciles",
      legend = FALSE, showPlotGrid = showPlotGrid)
    pp5 <- plotly::add_trace(pp5, y = ratio.obs.pred, x = sitedata.demtarea.class,
      type = "box", color = I("black"), fillcolor = "white")
    est_plots[["p5"]] <- plotly::layout(pp5, shapes = list(hline(spatialAutoCorr = FALSE, 1)))

    # p6: Ratio by classvar
    if (!identical(classvar, "sitedata.demtarea.class")) {
      est_plots[["p6"]] <- vector("list", length = length(classvar))
      for (k in seq_along(classvar)) {
        vvar <- as.numeric(sitedata[[classvar[k]]])
        est_plots[["p6"]][[k]] <- plotlyLayout(NA, ratio.obs.pred,
          log = "y", nTicks = 7, digits = 0,
          xTitle = classvar[k], xZeroLine = FALSE,
          xLabs = sort(as.numeric(unique(vvar))),
          yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
          plotTitle = "Ratio Observed to Predicted",
          legend = FALSE, showPlotGrid = showPlotGrid) |>
          plotly::add_trace(y = ratio.obs.pred, x = vvar, type = "box",
            color = I("black"), fillcolor = "white") |>
          plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 1)))
      }
    }

    # p7: Ratio by landuse deciles
    if (!is.na(class_landuse[1])) {
      est_plots[["p7"]] <- vector("list", length = length(classvar2))
      for (k in seq_along(classvar2)) {
        vvar  <- as.numeric(sitedata.landuse[[classvar2[k]]])
        iprob <- 10
        chk   <- unique(quantile(vvar, probs = 0:iprob / iprob))
        chk1  <- 11 - length(chk)
        if (chk1 == 0) {
          qvars  <- as.integer(cut(vvar, quantile(vvar, probs = 0:iprob / iprob),
                                   include.lowest = TRUE))
          avars  <- quantile(vvar, probs = 0:iprob / iprob)
          qvars2 <- numeric(length(qvars))
          for (jj in 1:10) {
            for (ii in seq_along(qvars)) {
              if (qvars[ii] == jj) qvars2[ii] <- round(avars[jj + 1], digits = 0)
            }
          }
          xxlab <- paste0("Upper Bound for ", classvar2[k])
          est_plots[["p7"]][[k]] <- plotlyLayout(NA, ratio.obs.pred,
            log = "y", nTicks = 7, digits = 0,
            xTitle = xxlab, xZeroLine = FALSE,
            xLabs = sort(as.numeric(unique(qvars2))),
            yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
            plotTitle = "Ratio Observed to Predicted by Deciles",
            legend = FALSE, showPlotGrid = showPlotGrid) |>
            plotly::add_trace(y = ratio.obs.pred, x = qvars2, type = "box",
              color = I("black"), fillcolor = "white") |>
            plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 1)))
        } else {
          est_plots[["p7"]][[k]] <- plotlyLayout(NA, ratio.obs.pred,
            log = "y", nTicks = 7, digits = 0,
            xTitle = classvar2[k], xZeroLine = FALSE,
            xLabs = sort(as.numeric(unique(vvar))),
            yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
            plotTitle = "Ratio Observed to Predicted",
            legend = FALSE, showPlotGrid = showPlotGrid) |>
            plotly::add_trace(y = ratio.obs.pred, x = vvar, type = "box",
              color = I("black"), fillcolor = "white") |>
            plotly::layout(shapes = list(hline(FALSE, 1)))
        }
      }
    }

    # p8: 4-panel by classvar group (estimation)
    est_plots[["p8"]] <- vector("list", length = length(grp))
    for (i in seq_along(grp)) {
      est_plots[["p8"]][[i]] <- diagnosticPlots_4panel_A(
        predict, Obs, yldpredict, yldobs, sitedata, Resids,
        plotclass = class[, 1],
        plotTitles = c(
          "paste0('Observed vs Predicted Load \nCLASS Region = ',filterClass,'(n=',nsites,')')",
          "'Observed vs Predicted \nYield'",
          "'Residuals vs Predicted \nLoad'",
          "'Residuals vs Predicted \nYield'"
        ),
        loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
        pnch, markerCols, hline, filterClass = as.double(grp[i])
      )
    }

    p.list[["est_perfplots"]] <- est_plots

  }

  # CREATE MODEL SIMULATION PERFORMANCE PLOTS (p9-p15)

  sim_plots <- list()

  # p9: Simulation 4-panel obs vs pred
  sim_plots[["p9"]] <- diagnosticPlots_4panel_A(
    ppredict, Obs, pyldpredict, pyldobs, sitedata, pResids,
    plotclass = NA,
    plotTitles = c(
      "'MODEL SIMULATION PERFORMANCE \nObserved vs Predicted Load'",
      "'MODEL SIMULATION PERFORMANCE \nObserved vs Predicted Yield'",
      "'Residuals vs Predicted \nLoad'",
      "'Residuals vs Predicted \nYield'"
    ),
    loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
    pnch, markerCols, hline, filterClass = NA
  )

  # p10: Simulation box/quantile residuals
  sim_plots[["p10"]] <- diagnosticPlots_4panel_B(
    sitedata, pResids, pratio.obs.pred, NA, ppredict,
    plotTitles = c(
      "'MODEL SIMULATION PERFORMANCE \nResiduals'",
      "'MODEL SIMULATION PERFORMANCE \nObserved / Predicted Ratio'",
      "'Normal Q-Q Plot'",
      "'Squared Residuals vs Predicted Load'"
    ),
    loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
    pnch, markerCols, hline
  )

  # p11: Simulation ratio vs area-weighted ExplanVars (!validation only)
  if (!validation && !identical(Cor.ExplanVars.list, NA)) {
    sim_plots[["p11"]] <- vector("list", length = length(Cor.ExplanVars.list$names))
    for (i in seq_along(Cor.ExplanVars.list$names)) {
      xv <- Cor.ExplanVars.list$cmatrixM_all[, i]
      logStr <- if (min(xv) < 0 | max(xv) < 0) "" else "x"
      markerText <- "~paste('</br>',Cor.ExplanVars.list$names[i],': ',xvar,
                   '</br> RATIO OBSERVED TO PREDICTED: ',pratio.obs.pred"
      df11 <- data.frame(xvar = xv, pratio.obs.pred = pratio.obs.pred)
      markerText <- addMarkerText(markerText, add_plotlyVars, df11, sitedata)$markerText
      df11       <- addMarkerText(markerText, add_plotlyVars, df11, sitedata)$mapData
      sim_plots[["p11"]][[i]] <- plotlyLayout(xv, pratio.obs.pred,
        log = logStr, nTicks = 5, digits = 0,
        xTitle = paste0("AREA-WEIGHTED EXPLANATORY VARIABLE (",
                        Cor.ExplanVars.list$names[i], ")"),
        xZeroLine = FALSE, yTitle = "RATIO OBSERVED TO PREDICTED", yZeroLine = FALSE,
        plotTitle = paste("Observed to Predicted Ratio vs Area-Weighted Explanatory Variable",
                          "\nFor Incremental Areas between Calibration Sites; Variable Name =",
                          Cor.ExplanVars.list$names[i]),
        legend = FALSE, showPlotGrid = showPlotGrid) |>
        plotly::add_trace(data = df11, x = ~xvar, y = ~pratio.obs.pred,
          type = "scatter", mode = "markers", marker = markerList,
          hoverinfo = "text", text = eval(parse(text = markerText)))
    }
  }

  # p12: Simulation ratio by drainage area deciles
  pp12 <- plotlyLayout(NA, pratio.obs.pred,
    log = "y", nTicks = 7, digits = 0,
    xTitle = "Upper Bound for Total Drainage Area Deciles (km2)", xZeroLine = FALSE,
    xLabs = sort(as.numeric(unique(sitedata.demtarea.class))),
    yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
    plotTitle = "Ratio Observed to Predicted by Deciles",
    legend = FALSE, showPlotGrid = showPlotGrid)
  pp12 <- plotly::add_trace(pp12, y = pratio.obs.pred, x = sitedata.demtarea.class,
    type = "box", color = I("black"), fillcolor = "white")
  sim_plots[["p12"]] <- plotly::layout(pp12, shapes = list(hline(spatialAutoCorr = FALSE, 1)))

  # p13: Simulation ratio by classvar
  if (!identical(classvar, "sitedata.demtarea.class")) {
    sim_plots[["p13"]] <- vector("list", length = length(classvar))
    for (k in seq_along(classvar)) {
      vvar <- as.numeric(sitedata[[classvar[k]]])
      sim_plots[["p13"]][[k]] <- plotlyLayout(NA, pratio.obs.pred,
        log = "y", nTicks = 7, digits = 0,
        xTitle = classvar[k], xZeroLine = FALSE,
        xLabs = sort(as.numeric(unique(vvar))),
        yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
        plotTitle = "Ratio Observed to Predicted",
        legend = FALSE, showPlotGrid = showPlotGrid) |>
        plotly::add_trace(y = pratio.obs.pred, x = vvar, type = "box",
          color = I("black"), fillcolor = "white") |>
        plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 1)))
    }
  }

  # p14: Simulation ratio by landuse deciles
  if (!is.na(class_landuse[1])) {
    sim_plots[["p14"]] <- vector("list", length = length(classvar2))
    for (l in seq_along(classvar2)) {
      vvar  <- as.numeric(sitedata.landuse[[classvar2[l]]])
      iprob <- 10
      chk   <- unique(quantile(vvar, probs = 0:iprob / iprob))
      chk1  <- 11 - length(chk)
      if (chk1 == 0) {
        qvars  <- as.integer(cut(vvar, quantile(vvar, probs = 0:iprob / iprob),
                                 include.lowest = TRUE))
        avars  <- quantile(vvar, probs = 0:iprob / iprob)
        qvars2 <- numeric(length(qvars))
        for (jj in 1:10) {
          for (ii in seq_along(qvars)) {
            if (qvars[ii] == jj) qvars2[ii] <- round(avars[jj + 1], digits = 0)
          }
        }
        xxlab <- paste0("Upper Bound for ", classvar2[l])
        sim_plots[["p14"]][[l]] <- plotlyLayout(NA, pratio.obs.pred,
          log = "y", nTicks = 7, digits = 0,
          xTitle = xxlab, xZeroLine = FALSE,
          xLabs = sort(as.numeric(unique(qvars2))),
          yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
          plotTitle = "Ratio Observed to Predicted by Deciles",
          legend = FALSE, showPlotGrid = showPlotGrid) |>
          plotly::add_trace(y = pratio.obs.pred, x = qvars2, type = "box",
            color = I("black"), fillcolor = "white") |>
          plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 1)))
      } else {
        sim_plots[["p14"]][[l]] <- plotlyLayout(NA, pratio.obs.pred,
          log = "y", nTicks = 7, digits = 0,
          xTitle = classvar2[l], xZeroLine = FALSE,
          xLabs = sort(as.numeric(unique(vvar))),
          yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
          plotTitle = "Ratio Observed to Predicted",
          legend = FALSE, showPlotGrid = showPlotGrid) |>
          plotly::add_trace(y = pratio.obs.pred, x = vvar, type = "box",
            color = I("black"), fillcolor = "white") |>
          plotly::layout(shapes = list(hline(FALSE, 1)))
      }
    }
  }

  # p15: 4-panel by classvar group (simulation)
  sim_plots[["p15"]] <- vector("list", length = length(grp))
  for (i in seq_along(grp)) {
    sim_plots[["p15"]][[i]] <- diagnosticPlots_4panel_A(
      ppredict, Obs, pyldpredict, pyldobs, sitedata, pResids,
      plotclass = class[, 1],
      plotTitles = c(
        "paste0('Observed vs Predicted Load \nCLASS Region = ',filterClass,'(n=',nsites,')')",
        "'Observed vs Predicted \nYield'",
        "'Residuals vs Predicted \nLoad'",
        "'Residuals vs Predicted \nYield'"
      ),
      loadUnits, yieldUnits, showPlotGrid, markerList, add_plotlyVars,
      pnch, markerCols, hline, filterClass = as.double(grp[i])
    )
  }

  p.list[["sim_perfplots"]] <- sim_plots

  # CREATE MODEL RESIDUALS MAPS
  # make_residMaps removed in Plan 05D (map rendering disabled in Plan 05A)
  p.list[["resid_maps"]] <- NULL

  invisible(p.list)

} # end function
