#' @title diagnosticPlotsNLLS_dyn
#' @description Create diagnostic, validation, sensitivity, or spatial autocorrelation plots and
#' maps at unique timesteps. Returns a named list of plot objects.
#' (Plan 05D: create_diagnosticPlotList() calls replaced with hardcoded plot_names;
#' makeReport_header/render_report HTML rendering removed; make_dyn* calls inlined as
#' helpers dyn_diagPlotsNLLS/dyn_sensPlots/dyn_corrPlots; unPackList call removed.)
#'
#' Executed By: \itemize{
#'              \item controlFileTasksModel.R,
#'              \item estimate.R}
#'
#' Executes Routines: \itemize{
#'              \item diagnosticPlotsNLLS.R,
#'              \item diagnosticSpatialAutoCorr.R,
#'              \item predictSensitivity.R}
#'
#' @param validation TRUE/FALSE indicating whether validation or diagnostic plots are to be
#' generated
#' @param sensitivity TRUE/FALSE indicating if sensitivity plots should be generated.
#' @param spatialAutoCorr TRUE/FALSE indicating if spatial autocorrelation plots should be
#' generated.
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by `generateInputList.R`
#' @param class.input.list list of control settings related to classification variables
#' @param sitedata.demtarea.class Total drainage area classification variable for calibration
#' sites.
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 &
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter
#' sub-section 5.1.2 for details)
#' @param subdata data.frame input data (subdata)
#' @param sitedata.landuse Land use for incremental basins for diagnostics.
#' @param estimate.list list output from `estimate.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo,
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list,
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param Csites.list list output from `selectCalibrationSites.R` modified in `startModelRun.R`
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R`
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#' prediction, yield, and residuals csv and shape files
#' @param SelParmValues selected parameters from parameters.csv using condition
#' `ifelse((parmMax > 0 | (parmType==\"DELIVF\" & parmMax>=0)) & (parmMin<parmMax) & ((parmType==\"SOURCE\" &
#' parmMin>=0) | parmType!=\"SOURCE\")`
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list' for
#' optimization
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#' NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param min.sites.list named list of control settings `minimum_headwater_site_area`,
#' `minimum_reaches_separating_sites`, `minimum_site_incremental_area`
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @keywords internal
#' @noRd


diagnosticPlotsNLLS_dyn <- function(validation = FALSE, sensitivity = FALSE,
                                    spatialAutoCorr = FALSE, file.output.list, class.input.list,
                                    sitedata.demtarea.class, sitedata, subdata, sitedata.landuse,
                                    estimate.list, mapping.input.list, Csites.list,
                                    Cor.ExplanVars.list, data_names, add_vars,
                                    SelParmValues, DataMatrix.list, estimate.input.list,
                                    min.sites.list, dlvdsgn) {

  path_results <- file.output.list$path_results

  diagnosticPlots_timestep <- mapping.input.list$diagnosticPlots_timestep

  # Hardcoded plot names based on plot type (replaces create_diagnosticPlotList() filtering)
  if (sensitivity) {
    plot_names <- c("p16", "p17", "p18")
  } else if (spatialAutoCorr) {
    plot_names <- c("p19", "p20", "p21", "p22")
  } else if (validation) {
    plot_names <- c("p9", "p10", "p12", "p13", "p14", "p15")
  } else {
    plot_names <- c("p1", "p2", "p3", "p4", "p5", "p6", "p7", "p8",
                    "p9", "p10", "p11", "p12", "p13", "p14", "p15")
  }

  tstep_is_season          <- all(diagnosticPlots_timestep == "season")
  sitedata_season_not_na   <- !all(is.na(sitedata$season))
  tsteps_inc_sitedata_season <- all(diagnosticPlots_timestep) %in% sitedata$season
  tstep_is_year            <- all(diagnosticPlots_timestep == "year")
  sitedata_year_not_na     <- !all(is.na(sitedata$year))
  tsteps_inc_sitedata_year <- all(diagnosticPlots_timestep) %in% sitedata$year

  if ((tstep_is_season & sitedata_season_not_na) |
      (tsteps_inc_sitedata_season & sitedata_season_not_na)) {

    diagnosticPlots_timestep <- unique(sitedata$season)
    match_seasons  <- c("winter", "spring", "summer", "fall") %in% diagnosticPlots_timestep
    match_seasons  <- c("winter", "spring", "summer", "fall")[match_seasons]
    tstep_match    <- match(match_seasons, diagnosticPlots_timestep)
    diagnosticPlots_timestep <- diagnosticPlots_timestep[tstep_match]

  } else if ((tstep_is_year & sitedata_year_not_na) |
             (tsteps_inc_sitedata_year & sitedata_year_not_na)) {

    diagnosticPlots_timestep <- unique(sitedata$year)

  } else {

    diagnosticPlots_timestep <- NA

  }

  p.list <- list()

  if (!sensitivity & !spatialAutoCorr) {

    # Standard diagnostic and/or validation plots (p1-p15)
    for (plotIndex in plot_names) {

      dyn_plots <- dyn_diagPlotsNLLS(
        plotIndex               = plotIndex,
        sitedata                = sitedata,
        sitedata.demtarea.class = sitedata.demtarea.class,
        validation              = validation,
        mapping.input.list      = mapping.input.list,
        file.output.list        = file.output.list,
        class.input.list        = class.input.list,
        estimate.list           = estimate.list,
        diagnosticPlots_timestep = diagnosticPlots_timestep,
        Cor.ExplanVars.list     = Cor.ExplanVars.list,
        sitedata.landuse        = sitedata.landuse
      )

      if (length(dyn_plots) > 0) {
        p.list[["dyn_plots"]][[plotIndex]] <- dyn_plots
      }

    }

  } else if (sensitivity) {

    # Sensitivity plots (p16, p17, p18)
    for (plotIndex in plot_names) {

      dyn_plots <- dyn_sensPlots(
        plotIndex               = plotIndex,
        sitedata                = sitedata,
        subdata                 = subdata,
        SelParmValues           = SelParmValues,
        DataMatrix.list         = DataMatrix.list,
        estimate.list           = estimate.list,
        estimate.input.list     = estimate.input.list,
        file.output.list        = file.output.list,
        mapping.input.list      = mapping.input.list,
        class.input.list        = class.input.list,
        diagnosticPlots_timestep = diagnosticPlots_timestep,
        dlvdsgn                 = dlvdsgn
      )

      if (length(dyn_plots) > 0) {
        p.list[["sens_plots"]][[plotIndex]] <- dyn_plots
      }

    }

  } else if (spatialAutoCorr) {

    # Spatial autocorrelation plots (p19-p22): call once; corrPlots loops over timesteps
    p.list[["corr_plots"]] <- dyn_corrPlots(
      sitedata                = sitedata,
      subdata                 = subdata,
      validation              = validation,
      DataMatrix.list         = DataMatrix.list,
      Csites.list             = Csites.list,
      estimate.list           = estimate.list,
      estimate.input.list     = estimate.input.list,
      file.output.list        = file.output.list,
      mapping.input.list      = mapping.input.list,
      class.input.list        = class.input.list,
      diagnosticPlots_timestep = diagnosticPlots_timestep,
      min.sites.list          = min.sites.list,
      data_names              = data_names
    )

  }

  invisible(p.list)

} # end function


# ---------------------------------------------------------------------------
# Helper: dyn_diagPlotsNLLS
# (inlined from make_dyndiagnosticPlotsNLLS.R in Plan 05D)
# Creates various model estimation and simulation plots at each unique timestep.
# ---------------------------------------------------------------------------
#' @keywords internal
#' @noRd
dyn_diagPlotsNLLS <- function(
    plotIndex,
    sitedata,
    sitedata.demtarea.class,
    validation,
    mapping.input.list,
    file.output.list,
    class.input.list,
    estimate.list,
    diagnosticPlots_timestep,
    Cor.ExplanVars.list,
    sitedata.landuse) {

  mapping.input.list$diagnosticPlots_timestep <- diagnosticPlots_timestep

  # Direct extractions from mapping.input.list
  pchPlotlyCross           <- mapping.input.list$pchPlotlyCross
  diagnosticPlotPointStyle <- mapping.input.list$diagnosticPlotPointStyle
  diagnosticPlotPointSize  <- mapping.input.list$diagnosticPlotPointSize
  showPlotGrid             <- mapping.input.list$showPlotGrid
  add_plotlyVars           <- mapping.input.list$add_plotlyVars
  loadUnits                <- mapping.input.list$loadUnits
  yieldUnits               <- mapping.input.list$yieldUnits

  # Direct extractions from class.input.list
  classvar      <- class.input.list$classvar
  class_landuse <- class.input.list$class_landuse

  # Set up Mdiagnostics and handle validation-specific adjustments
  if (!validation) {
    Mdiagnostics.list <- estimate.list$Mdiagnostics.list
  } else {
    Mdiagnostics.list <- estimate.list$vMdiagnostics.list
    sitedata$staid <- sitedata$vstaid
  }

  # Build marker list
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

  # Class variables
  class <- as.array(sapply(classvar, function(var) as.numeric(sitedata[[var]])))

  if (!is.na(class_landuse[1])) {
    classvar2 <- paste0(class_landuse, "_pct")
  }

  # Obtain CLASS region numbers
  grp <- table(class[, 1])
  xx  <- as.data.frame(grp)
  grp <- as.numeric(levels(xx$Var1)[xx$Var1])

  sitedata_orig                <- sitedata
  sitedata.demtarea.class_orig <- sitedata.demtarea.class
  sitedata.landuse_orig        <- sitedata.landuse
  Cor.ExplanVars.list_orig     <- Cor.ExplanVars.list
  p.list <- list()

  if (!plotIndex %in% c("p4", "p6", "p7", "p8", "p11", "p13", "p14", "p15", "p16")) {

    # --- Simple (non-grouped) loop: p1, p2, p3, p5, p9, p10, p12 ---
    for (t in diagnosticPlots_timestep) {

      if (!validation) {
        MdiagSub <- estimate.list$Mdiagnostics.list
      } else {
        MdiagSub <- estimate.list$vMdiagnostics.list
      }

      if (all(diagnosticPlots_timestep %in% unique(sitedata_orig$year))) {
        subStaid <- sitedata_orig[sitedata_orig$year == t, ]$staid
      } else {
        subStaid <- sitedata_orig[sitedata_orig$season == t, ]$staid
      }

      MdiagSub <- lapply(Mdiagnostics.list, function(x) x[which(MdiagSub$xstaid %in% subStaid)])

      sitedata <- sitedata_orig[sitedata_orig$staid %in% subStaid, ]
      sitedata.demtarea.class <- sitedata.demtarea.class_orig[which(sitedata$staid %in% subStaid)]

      # Unpack MdiagSub into typed local variables
      predict         <- MdiagSub$predict
      Obs             <- MdiagSub$Obs
      yldpredict      <- MdiagSub$yldpredict
      yldobs          <- MdiagSub$yldobs
      Resids          <- MdiagSub$Resids
      ratio.obs.pred  <- MdiagSub$ratio.obs.pred
      standardResids  <- MdiagSub$standardResids
      ppredict        <- MdiagSub$ppredict
      pyldpredict     <- MdiagSub$pyldpredict
      pyldobs         <- MdiagSub$pyldobs
      pResids         <- MdiagSub$pResids
      pratio.obs.pred <- MdiagSub$pratio.obs.pred

      p <- if (plotIndex == "p1" && !validation) {
        diagnosticPlots_4panel_A(
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
      } else if (plotIndex == "p2" && !validation) {
        diagnosticPlots_4panel_B(
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
      } else if (plotIndex == "p3" && !validation) {
        markerText <- "~paste('</br> Simulated Load: ',ppredict,
                   '</br> Predicted Load: ',predict"
        df3 <- data.frame(ppredict = ppredict, predict = predict)
        markerText <- addMarkerText(markerText, add_plotlyVars, df3, sitedata)$markerText
        df3 <- addMarkerText(markerText, add_plotlyVars, df3, sitedata)$mapData
        pp <- plotlyLayout(ppredict, predict,
          log = "xy", nTicks = 5, digits = 0,
          xTitle = paste0("Simulated Load (", loadUnits, ")"), xZeroLine = FALSE,
          yTitle = paste0("Monitoring-Adjusted Load (", loadUnits, ")"), yZeroLine = FALSE,
          plotTitle = "Monitoring-Adjusted vs. Simulated Loads",
          legend = FALSE, showPlotGrid = showPlotGrid
        )
        pp <- plotly::add_trace(pp, data = df3, x = ~ppredict, y = ~predict,
          type = "scatter", mode = "markers", marker = markerList,
          hoverinfo = "text", text = eval(parse(text = markerText)))
        pp <- plotly::add_trace(pp, x = ppredict, y = ppredict,
          type = "scatter", mode = "lines", color = I("red"),
          hoverinfo = "text", text = "Simulated Load")
        pp
      } else if (plotIndex == "p5") {
        pp <- plotlyLayout(NA, ratio.obs.pred,
          log = "y", nTicks = 7, digits = 0,
          xTitle = "Upper Bound for Total Drainage Area Deciles (km2)", xZeroLine = FALSE,
          xLabs = sort(as.numeric(unique(sitedata.demtarea.class))),
          yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
          plotTitle = "Ratio Observed to Predicted by Deciles",
          legend = FALSE, showPlotGrid = showPlotGrid)
        pp <- plotly::add_trace(pp, y = ratio.obs.pred, x = sitedata.demtarea.class,
          type = "box", color = I("black"), fillcolor = "white")
        plotly::layout(pp, shapes = list(hline(spatialAutoCorr = FALSE, 1)))
      } else if (plotIndex == "p9") {
        diagnosticPlots_4panel_A(
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
      } else if (plotIndex == "p10") {
        diagnosticPlots_4panel_B(
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
      } else if (plotIndex == "p12") {
        pp <- plotlyLayout(NA, pratio.obs.pred,
          log = "y", nTicks = 7, digits = 0,
          xTitle = "Upper Bound for Total Drainage Area Deciles (km2)", xZeroLine = FALSE,
          xLabs = sort(as.numeric(unique(sitedata.demtarea.class))),
          yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
          plotTitle = "Ratio Observed to Predicted by Deciles",
          legend = FALSE, showPlotGrid = showPlotGrid)
        pp <- plotly::add_trace(pp, y = pratio.obs.pred, x = sitedata.demtarea.class,
          type = "box", color = I("black"), fillcolor = "white")
        plotly::layout(pp, shapes = list(hline(spatialAutoCorr = FALSE, 1)))
      } else {
        NULL
      }

      if (!is.null(p)) {
        p.list[[as.character(t)]] <- p
      }
    }

  } else {

    # --- Grouped loop: p4, p6, p7, p8, p11, p13, p14, p15 ---
    if (plotIndex %in% c("p4", "p11")) {
      condList <- !identical(NA, Cor.ExplanVars.list_orig)
    } else if (plotIndex %in% c("p6", "p13")) {
      condList <- !identical(classvar, 'sitedata.demtarea.class')
    } else if (plotIndex %in% c("p7", "p14")) {
      condList <- !is.na(class_landuse[1])
    } else if (plotIndex %in% c("p8", "p15")) {
      condList <- TRUE
    } else {
      condList <- FALSE
    }

    if (condList) {
      if (plotIndex %in% c("p4", "p11")) {
        condLoop <- Cor.ExplanVars.list_orig$names
      } else if (plotIndex %in% c("p6", "p13")) {
        condLoop <- classvar
      } else if (plotIndex %in% c("p7", "p14")) {
        condLoop <- classvar2
      } else { # p8, p15
        condLoop <- grp
      }

      for (i in seq_along(condLoop)) {
        k <- i  # alias used by classvar / classvar2 subscript

        for (t in diagnosticPlots_timestep) {

          if (!validation) {
            MdiagSub <- estimate.list$Mdiagnostics.list
          } else {
            MdiagSub <- estimate.list$vMdiagnostics.list
          }

          if (all(diagnosticPlots_timestep %in% unique(sitedata_orig$year))) {
            subStaid <- sitedata_orig[sitedata_orig$year == t, ]$staid
          } else {
            subStaid <- sitedata_orig[sitedata_orig$season == t, ]$staid
          }

          MdiagSub <- lapply(
            Mdiagnostics.list,
            function(x) x[which(MdiagSub$xstaid %in% subStaid)]
          )

          predict         <- MdiagSub$predict
          Obs             <- MdiagSub$Obs
          yldpredict      <- MdiagSub$yldpredict
          yldobs          <- MdiagSub$yldobs
          Resids          <- MdiagSub$Resids
          ratio.obs.pred  <- MdiagSub$ratio.obs.pred
          ppredict        <- MdiagSub$ppredict
          pyldpredict     <- MdiagSub$pyldpredict
          pyldobs         <- MdiagSub$pyldobs
          pResids         <- MdiagSub$pResids
          pratio.obs.pred <- MdiagSub$pratio.obs.pred

          # Determine corrData and boxvar based on plotIndex
          corrData <- if (plotIndex %in% c("p4")) ratio.obs.pred else pratio.obs.pred
          boxvar   <- if (plotIndex %in% c("p6", "p7")) ratio.obs.pred else pratio.obs.pred

          sitedata <- sitedata_orig[sitedata_orig$staid %in% subStaid, ]

          if (!validation) {
            sitedata.landuse <- sitedata.landuse_orig[
              which(estimate.list$Mdiagnostics.list$xstaid %in% subStaid), ]
          } else {
            sitedata.landuse <- sitedata.landuse_orig[
              which(estimate.list$vMdiagnostics.list$xstaid %in% subStaid), ]
          }

          if (!identical(NA, Cor.ExplanVars.list_orig) & plotIndex %in% c("p4", "p11")) {
            Cor.ExplanVars.list$cmatrixM_all <- Cor.ExplanVars.list_orig$cmatrixM_all[
              which(estimate.list$Mdiagnostics.list$xstaid %in% subStaid), ]
          }

          p <- if (plotIndex %in% c("p4", "p11") && !validation) {
            xv <- Cor.ExplanVars.list$cmatrixM_all[, i]
            logStr <- if (min(xv) < 0 | max(xv) < 0) "" else "x"
            markerText <- "~paste('</br>',Cor.ExplanVars.list$names[i],': ',xvar,
                   '</br> RATIO OBSERVED TO PREDICTED: ',corrData"
            df4 <- data.frame(xvar = xv, corrData = corrData)
            markerText <- addMarkerText(markerText, add_plotlyVars, df4, sitedata)$markerText
            df4 <- addMarkerText(markerText, add_plotlyVars, df4, sitedata)$mapData
            plotlyLayout(xv, corrData,
              log = logStr, nTicks = 5, digits = 0,
              xTitle = paste0("AREA-WEIGHTED EXPLANATORY VARIABLE (",
                              Cor.ExplanVars.list$names[i], ")"),
              xZeroLine = FALSE, yTitle = "RATIO OBSERVED TO PREDICTED", yZeroLine = FALSE,
              plotTitle = paste("Observed to Predicted Ratio vs Area-Weighted Explanatory Variable",
                                "\nFor Incremental Areas between Calibration Sites; Variable Name =",
                                Cor.ExplanVars.list$names[i]),
              legend = FALSE, showPlotGrid = showPlotGrid) |>
              plotly::add_trace(data = df4, x = ~xvar, y = ~corrData,
                type = "scatter", mode = "markers", marker = markerList,
                hoverinfo = "text", text = eval(parse(text = markerText)))
          } else if (plotIndex %in% c("p6", "p13")) {
            vvar <- as.numeric(sitedata[[classvar[k]]])
            plotlyLayout(NA, boxvar,
              log = "y", nTicks = 7, digits = 0,
              xTitle = classvar[k], xZeroLine = FALSE,
              xLabs = sort(as.numeric(unique(vvar))),
              yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
              plotTitle = "Ratio Observed to Predicted",
              legend = FALSE, showPlotGrid = showPlotGrid) |>
              plotly::add_trace(y = boxvar, x = vvar, type = "box",
                color = I("black"), fillcolor = "white") |>
              plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 1)))
          } else if (plotIndex %in% c("p7", "p14")) {
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
                for (ii in 1:length(qvars)) {
                  if (qvars[ii] == jj) qvars2[ii] <- round(avars[jj + 1], digits = 0)
                }
              }
              xxlab <- paste0("Upper Bound for ", classvar2[k])
              plotlyLayout(NA, boxvar,
                log = "y", nTicks = 7, digits = 0,
                xTitle = xxlab, xZeroLine = FALSE,
                xLabs = sort(as.numeric(unique(qvars2))),
                yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
                plotTitle = "Ratio Observed to Predicted by Deciles",
                legend = FALSE, showPlotGrid = showPlotGrid) |>
                plotly::add_trace(y = boxvar, x = qvars2, type = "box",
                  color = I("black"), fillcolor = "white") |>
                plotly::layout(shapes = list(hline(spatialAutoCorr = FALSE, 1)))
            } else {
              plotlyLayout(NA, boxvar,
                log = "y", nTicks = 7, digits = 0,
                xTitle = classvar2[k], xZeroLine = FALSE,
                xLabs = sort(as.numeric(unique(vvar))),
                yTitle = "Observed to Predicted Ratio", yZeroLine = FALSE,
                plotTitle = "Ratio Observed to Predicted",
                legend = FALSE, showPlotGrid = showPlotGrid) |>
                plotly::add_trace(y = boxvar, x = vvar, type = "box",
                  color = I("black"), fillcolor = "white") |>
                plotly::layout(shapes = list(hline(FALSE, 1)))
            }
          } else if (plotIndex == "p8") {
            diagnosticPlots_4panel_A(
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
          } else if (plotIndex == "p15") {
            diagnosticPlots_4panel_A(
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
          } else {
            NULL
          }

          if (!is.null(p)) {
            p.list[[as.character(condLoop[i])]][[as.character(t)]] <- p
          }
        }
      }
    }
  }

  return(p.list)
}


# ---------------------------------------------------------------------------
# Helper: dyn_sensPlots
# (inlined from make_dyndiagnosticPlotsNLLS_sensPlots.R in Plan 05D)
# Creates parameter sensitivity plots at each unique timestep.
# ---------------------------------------------------------------------------
#' @keywords internal
#' @noRd
dyn_sensPlots <- function(plotIndex, sitedata, subdata,
                          SelParmValues, DataMatrix.list, estimate.list,
                          estimate.input.list, file.output.list,
                          mapping.input.list, class.input.list,
                          diagnosticPlots_timestep, dlvdsgn) {

  mapping.input.list$diagnosticPlots_timestep <- diagnosticPlots_timestep

  # Direct extractions from SelParmValues
  betaconstant                  <- SelParmValues$betaconstant
  incr_delivery_specification   <- estimate.input.list$incr_delivery_specification
  reach_decay_specification     <- estimate.input.list$reach_decay_specification
  reservoir_decay_specification <- estimate.input.list$reservoir_decay_specification

  # Direct extractions from estimate.list$JacobResults
  oEstimate  <- estimate.list$JacobResults$oEstimate
  Parmnames  <- estimate.list$JacobResults$Parmnames

  # Direct extractions from mapping.input.list
  pchPlotlyCross           <- mapping.input.list$pchPlotlyCross
  diagnosticPlotPointStyle <- mapping.input.list$diagnosticPlotPointStyle
  diagnosticPlotPointSize  <- mapping.input.list$diagnosticPlotPointSize
  showPlotGrid             <- mapping.input.list$showPlotGrid

  # Direct extractions from class.input.list
  classvar <- class.input.list$classvar

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

  class <- as.array(
    sapply(classvar, function(var) as.numeric(sitedata[[var]]))
  )

  Estimate <- oEstimate  # initial baseline estimates

  ct   <- length(Estimate)
  xiqr <- matrix(0, nrow = 4, ncol = sum(ct))
  xmed <- numeric(sum(ct))
  xparm <- character(sum(ct))
  xvalue2 <- numeric(sum(ct))

  p.list <- list()

  if (plotIndex %in% c("p17", "p18")) {

    for (t in diagnosticPlots_timestep) {

      if (all(diagnosticPlots_timestep %in% unique(sitedata$year))) {
        subWaterId <- subdata[subdata$year == t, ]$waterid
      } else {
        subWaterId <- subdata[subdata$season == t, ]$waterid
      }
      subdataTstep <- subdata[subdata$waterid %in% subWaterId, ]
      DMLdatasub   <- DataMatrix.list$data
      DMLdatasub   <- DMLdatasub[which(DMLdatasub[, c(1)] %in% subWaterId), ]
      subDataMatrix.list       <- DataMatrix.list
      subDataMatrix.list$data  <- DMLdatasub
      depvar <- subdataTstep$depvar
      xclass <- subdataTstep[[classvar[1]]]  # replaced eval/parse

      predict <- predictSensitivity(
        AEstimate = Estimate,
        estimate.list = estimate.list,
        DataMatrix.list = subDataMatrix.list,
        SelParmValues = SelParmValues,
        incr_delivery_specification = incr_delivery_specification,
        reach_decay_specification = reach_decay_specification,
        reservoir_decay_specification = reservoir_decay_specification,
        subdata = subdataTstep, dlvdsgn
      )

      apredict     <- predict
      apredict_sum <- matrix(1, nrow = length(depvar), ncol = length(Estimate))
      xsens        <- matrix(0, nrow = sum(depvar > 0), ncol = length(Estimate))

      for (j in 1:length(Estimate)) {
        if (betaconstant[j] == 0) {
          AEstimate    <- Estimate
          AEstimate[j] <- Estimate[j] * 0.99
          apredict <- predictSensitivity(
            AEstimate = AEstimate,
            estimate.list = estimate.list,
            DataMatrix.list = subDataMatrix.list,
            SelParmValues = SelParmValues,
            incr_delivery_specification = incr_delivery_specification,
            reach_decay_specification = reach_decay_specification,
            reservoir_decay_specification = reservoir_decay_specification,
            subdata = subdataTstep, dlvdsgn
          )
          apredict_sum[, j] <- abs((apredict - predict) / predict * 100) / 1.0
        }
      }

      # Build sensitivity summary stats
      for (idx in 1:length(Estimate)) {
        x1   <- apredict_sum[, idx]
        xx   <- data.frame(x1, depvar, xclass)
        ps   <- xx[(xx$depvar > 0), ]
        xvalue2[idx] <- idx
        xiqr[, idx]  <- quantile(ps$x1, c(0.05, 0.25, 0.75, 0.95))
        xmed[idx]    <- median(ps$x1)
        xparm[idx]   <- Parmnames[idx]
        xsens[, idx] <- ps$x1
      }

      xx       <- xiqr[1, (xiqr[1, ] > 0)]
      xminimum <- min(xx)
      xminimum <- ifelse(is.infinite(xminimum), 0, xminimum)
      xmed_p   <- ifelse(xmed == 0, xminimum, xmed)
      xiqr_p   <- ifelse(xiqr == 0, xminimum, xiqr)

      xupper <- xiqr_p[3, ] - xmed_p
      xlower <- xmed_p - xiqr_p[2, ]
      supper <- xiqr_p[4, ] - xmed_p
      slower <- xmed_p - xiqr_p[1, ]

      xupper <- ifelse(xupper == 0, xminimum, xupper)
      supper <- ifelse(supper == 0, xminimum, supper)
      xlower <- ifelse(xlower == 0, xminimum, xlower)
      slower <- ifelse(slower == 0, xminimum, slower)

      xd   <- data.frame(xmed_p, xlower, xupper, supper, slower, xparm)
      xd   <- xd[with(xd, order(xd$xmed_p)), ]
      ymin <- min(xiqr_p)
      ymax <- max(xiqr_p)

      data <- data.frame(x = xvalue2)
      data <- cbind(data, xd)

      log_arg <- if (plotIndex == "p18") "y" else ""

      p <- plotlyLayout(NA, data$xmed_p,
        log = log_arg, nTicks = 5, digits = 0,
        xTitle = "", xZeroLine = FALSE, xLabs = as.character(data$xparm),
        yTitle = "CHANGE IN PREDICTED VALUES (%)", yZeroLine = FALSE,
        ymin = ymin, ymax = ymax,
        plotTitle = "PARAMETER SENSITIVITY TO 1% CHANGE",
        legend = TRUE, showPlotGrid = showPlotGrid
      ) |>
        plotly::add_trace(
          data = data, x = ~xparm, y = ~xmed_p, type = "scatter", mode = "markers",
          color = I("#0000FF"), name = "90% Interval",
          error_y = ~list(symetric = FALSE, array = supper, arrayminus = slower,
                          color = "#0000FF")
        ) |>
        plotly::add_trace(
          data = data, x = ~xparm, y = ~xmed_p, type = "scatter", mode = "markers",
          color = I("#FF0000"), name = "50% Interval",
          error_y = ~list(symetric = FALSE, array = xupper, arrayminus = xlower,
                          color = "#FF0000")
        ) |>
        plotly::add_trace(
          data = data, x = ~xparm, y = ~xmed_p, type = "scatter", mode = "markers",
          color = I("black"), name = "median"
        )

      p.list[[as.character(t)]] <- p
    }

  } else {
    # plotIndex == "p16": boxplot per parameter per timestep

    for (i in seq_along(Estimate)) {

      for (t in diagnosticPlots_timestep) {

        if (all(diagnosticPlots_timestep %in% unique(sitedata$year))) {
          subWaterId <- subdata[subdata$year == t, ]$waterid
        } else {
          subWaterId <- subdata[subdata$season == t, ]$waterid
        }

        subdataTstep <- subdata[subdata$waterid %in% subWaterId, ]
        DMLdatasub   <- DataMatrix.list$data
        DMLdatasub   <- DMLdatasub[which(DMLdatasub[, c(1)] %in% subWaterId), ]
        subDataMatrix.list      <- DataMatrix.list
        subDataMatrix.list$data <- DMLdatasub
        depvar <- subdataTstep$depvar
        xclass <- subdataTstep[[classvar[1]]]  # replaced eval/parse

        predict <- predictSensitivity(
          AEstimate = Estimate,
          estimate.list = estimate.list,
          DataMatrix.list = subDataMatrix.list,
          SelParmValues = SelParmValues,
          incr_delivery_specification = incr_delivery_specification,
          reach_decay_specification = reach_decay_specification,
          reservoir_decay_specification = reservoir_decay_specification,
          subdata = subdataTstep, dlvdsgn
        )

        apredict     <- predict
        apredict_sum <- matrix(1, nrow = length(depvar), ncol = length(Estimate))
        xsens        <- matrix(0, nrow = sum(depvar > 0), ncol = length(Estimate))

        for (j in 1:length(Estimate)) {
          if (betaconstant[j] == 0) {
            AEstimate    <- Estimate
            AEstimate[j] <- Estimate[j] * 0.99
            apredict <- predictSensitivity(
              AEstimate = AEstimate,
              estimate.list = estimate.list,
              DataMatrix.list = subDataMatrix.list,
              SelParmValues = SelParmValues,
              incr_delivery_specification = incr_delivery_specification,
              reach_decay_specification = reach_decay_specification,
              reservoir_decay_specification = reservoir_decay_specification,
              subdata = subdataTstep, dlvdsgn
            )
            apredict_sum[, j] <- abs((apredict - predict) / predict * 100) / 1.0
          }
        }

        # p16: boxplot of sensitivity for parameter i
        x1       <- apredict_sum[, i]
        xx       <- data.frame(x1, depvar, xclass)
        parmsens <- xx[(xx$depvar > 0), ]

        p <- plotlyLayout(NA, parmsens$x1,
          log = "", nTicks = 5, digits = 0,
          xTitle = "", xZeroLine = FALSE, xLabs = parmsens$xclass,
          yTitle = "Prediction Change (%) Relative to 1% Change", yZeroLine = FALSE,
          plotTitle = paste0("Parameter Sensitivity:  ", Parmnames[i]),
          legend = FALSE, showPlotGrid = showPlotGrid
        ) |>
          plotly::add_trace(
            y = parmsens$x1, x = parmsens$xclass,
            type = "box", name = Parmnames[i], color = I("black"), fillcolor = "white"
          )

        p.list[[Parmnames[i]]][[as.character(t)]] <- p
      }
    }
  }

  return(p.list)
}


# ---------------------------------------------------------------------------
# Helper: dyn_corrPlots
# (inlined from make_dyndiagnosticPlotsNLLS_corrPlots.R in Plan 05D)
# Creates spatial autocorrelation plots at each unique timestep.
# ---------------------------------------------------------------------------
#' @keywords internal
#' @noRd
dyn_corrPlots <- function(sitedata, subdata,
                          validation, DataMatrix.list,
                          Csites.list, estimate.list, estimate.input.list,
                          file.output.list, mapping.input.list,
                          class.input.list, diagnosticPlots_timestep,
                          min.sites.list, data_names) {

  data.index.list <- DataMatrix.list$data.index.list
  mapping.input.list$diagnosticPlots_timestep <- diagnosticPlots_timestep

  Mdiagnostics.list <- estimate.list$Mdiagnostics.list
  set.ZeroPolicyOption(TRUE)

  subdata_orig          <- subdata
  Csites.list_orig      <- Csites.list
  DataMatrix.list_orig  <- DataMatrix.list
  sitedata_orig         <- sitedata
  Mdiagnostics.list_orig <- Mdiagnostics.list

  p.list <- list(p19 = list(), p20 = list(), p21 = list(), p22 = list())

  for (t in diagnosticPlots_timestep) {

    if (all(diagnosticPlots_timestep %in% unique(sitedata_orig$year))) {
      subWaterId <- subdata_orig[subdata_orig$year == t, ]$waterid
    } else {
      subWaterId <- subdata_orig[subdata_orig$season == t, ]$waterid
    }

    subdata <- subdata_orig[subdata_orig$waterid %in% subWaterId, ]

    Csites.list <- selectCalibrationSites(subdata, data_names, min.sites.list)

    waterid   <- Csites.list$waterid
    depvar    <- Csites.list$depvar
    staid     <- Csites.list$staid
    staidseq  <- Csites.list$staidseq
    xx        <- data.frame(waterid, staid, staidseq, depvar)
    xx        <- xx[xx$waterid %in% subWaterId, ]
    drops     <- c("depvar", "staid", "staidseq")
    subdata   <- subdata[, !(names(subdata) %in% drops)]
    subdata   <- merge(subdata, xx, by = "waterid", all.y = FALSE, all.x = FALSE)
    subdata   <- subdata[with(subdata, order(subdata$hydseq)), ]

    DMLdatasub <- DataMatrix.list_orig$data
    DMLdatasub <- DMLdatasub[which(DMLdatasub[, c(1)] %in% subWaterId), ]
    subDataMatrix.list       <- DataMatrix.list_orig
    subDataMatrix.list$data  <- DMLdatasub
    DataMatrix.list          <- subDataMatrix.list

    sitedata <- sitedata_orig[sitedata_orig$waterid %in% subWaterId, ]
    sitedata <- sitedata[, names(sitedata) != "staid"]
    sitedata <- merge(sitedata, subdata[c("waterid", "staid")], by = "waterid")

    MdiagSub <- Mdiagnostics.list_orig
    MdiagSub <- lapply(
      Mdiagnostics.list_orig,
      function(x) x[which(MdiagSub$xstaid %in% sitedata$staid)]
    )

    # Build modified estimate.list with subsetted diagnostics for this timestep
    sub_estimate <- estimate.list
    sub_estimate$Mdiagnostics.list <- MdiagSub

    # Call diagnosticSpatialAutoCorr with subsetted data
    spatial_plots <- diagnosticSpatialAutoCorr(
      file.output.list    = file.output.list,
      sitedata            = sitedata,
      estimate.list       = sub_estimate,
      estimate.input.list = estimate.input.list,
      mapping.input.list  = mapping.input.list,
      subdata             = subdata,
      min.sites.list      = min.sites.list,
      class.input.list    = class.input.list,
      DataMatrix.list     = DataMatrix.list
    )

    t_key <- as.character(t)
    if (!is.null(spatial_plots$p19)) p.list[["p19"]][[t_key]] <- spatial_plots$p19
    if (!is.null(spatial_plots$p20)) p.list[["p20"]][[t_key]] <- spatial_plots$p20
    if (!is.null(spatial_plots$p21)) p.list[["p21"]][[t_key]] <- spatial_plots$p21
    if (!is.null(spatial_plots$p22)) p.list[["p22"]][[t_key]] <- spatial_plots$p22
  }

  return(p.list)
}
