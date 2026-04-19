#' @title checkDrainageareaErrors
#' 
#' @description 
#' Executes drainage area checks for newly computed areas, based on the 
#' if_verify_demtarea control setting (section 2 of the control script). If any differences are found 
#' between the user's original data for Total Drainage Area vs. Total Drainage Area calculated by 
#' RSPARROW, a plot of user's original data for Total Drainage Area vs. Total Drainage Area 
#' calculated by RSPARROW is output. For the control setting if_verify_demtarea_maps<-"yes", maps are 
#' output of `demtarea` and `hydseq` for unmatched areas as a ratio of RSPARROW calculated:original. 
#' A CSV file is output of all differences found to ~/estimate/(run_id)_diagnostic_darea_mismatches.csv.
#' 
#' Executed By: batchMaps_checkDrain.R
#' 
#' Executes Routines: \itemize{
#'              \item addMarkerText.R,
#'              \item checkBinaryMaps.R,
#'              \item plotlyLayout.R}
#' 
#' @param file.output.list list of control settings and relative paths used for input and 
#' output of external files.  Created by `generateInputList.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit, 
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo, 
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list, 
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param DAreaFailCheckObj data.frame of all rows of subdata in which the user's original 
#' data for Total Drainage Area vs. Total Drainage Area calculated by RSPARROW differ
#' @param data1 input data (data1)
#' @keywords internal
#' @noRd

checkDrainageareaErrors <- function(file.output.list, mapping.input.list, data_names,
                                    # sub1.plot,
                                    DAreaFailCheckObj, data1) {
  # Setup variable lists
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator <- file.output.list$csv_columnSeparator
  path_gis <- file.output.list$path_gis
  if_verify_demtarea_maps <- mapping.input.list$if_verify_demtarea_maps
  LineShapeGeo <- mapping.input.list$LineShapeGeo
  lineShapeName <- mapping.input.list$lineShapeName
  lineWaterid <- mapping.input.list$lineWaterid
  GeoLines <- mapping.input.list$GeoLines
  lineShape <- mapping.input.list$lineShape
  enable_plotlyMaps <- mapping.input.list$enable_plotlyMaps

  if (length(stats::na.omit(DAreaFailCheckObj$demtarea)) != 0) {

    # Build drainage area mismatch plot inline (was make_drainageAreaErrorsPlot)
    diagnosticPlotPointStyle <- mapping.input.list$diagnosticPlotPointStyle
    diagnosticPlotPointSize  <- mapping.input.list$diagnosticPlotPointSize
    pchPlotlyCross           <- mapping.input.list$pchPlotlyCross
    add_plotlyVars           <- mapping.input.list$add_plotlyVars
    showPlotGrid             <- mapping.input.list$showPlotGrid

    pnch <- as.character(pchPlotlyCross[pchPlotlyCross$pch == diagnosticPlotPointStyle, ]$plotly)
    markerSize <- diagnosticPlotPointSize * 10
    markerCols <- colorNumeric(c('black', 'white'), 1:2)
    test <- regexpr('open', pnch) > 0
    if (test) {
      markerList <- list(symbol = pnch, size = markerSize, color = markerCols(1))
    } else {
      markerList <- list(
        symbol = pnch,
        size = markerSize,
        color = markerCols(1),
        line = list(color = markerCols(1), width = 0.8)
      )
    }

    data <- data.frame(
      preCalc = DAreaFailCheckObj$demtarea,
      Calc    = DAreaFailCheckObj$demtarea_new
    )
    data1sub <- data1[which(data1$waterid %in% DAreaFailCheckObj$waterid), ]
    data1sub <- data1sub[match(DAreaFailCheckObj$waterid, data1sub$waterid), ]
    markerText <- "~paste('</br> Pre-calc Total Drainage Area: ', preCalc,
          '</br> Newly-calculated Total Drainage Area: ',Calc"
    markerText <- addMarkerText(markerText, add_plotlyVars, data, data1sub)$markerText
    data <- addMarkerText(markerText, add_plotlyVars, data, data1sub)$mapData

    darea_mismatch_plot <- plotlyLayout(
      x = data$preCalc, y = data$Calc,
      log = 'xy', nTicks = 5, digits = 0,
      xTitle = 'Pre-calculated Total Drainage Area', xZeroLine = TRUE,
      yTitle = 'Newly-calculated Total Drainage Area', yZeroLine = TRUE,
      plotTitle = 'Comparison of Total Drainage Areas',
      legend = FALSE, showPlotGrid = showPlotGrid
    )
    darea_mismatch_plot <- plotly::add_trace(
      p = darea_mismatch_plot,
      data = data, x = ~preCalc, y = ~Calc,
      type = 'scatter', mode = 'markers',
      marker = markerList, hoverinfo = 'text',
      text = eval(parse(text = markerText))
    )
    darea_mismatch_plot <- plotly::add_trace(
      p = darea_mismatch_plot,
      data = data, x = ~preCalc, y = ~preCalc,
      type = 'scatter', mode = 'lines',
      color = I('red'), hoverinfo = 'text',
      text = 'Pre-calculated Total Drainage Area'
    )

    # HTML report generation removed (Plan 05D: makeReport_* infrastructure dropped)
    # darea_mismatch_plot is available to caller if needed

  } # end if all missing original demtarea

  # Output mis-matched reach data
  waterid <- DAreaFailCheckObj$waterid
  fnode_pre <- DAreaFailCheckObj$fnode
  tnode_pre <- DAreaFailCheckObj$tnode
  frac_pre <- DAreaFailCheckObj$frac
  demtarea_pre <- DAreaFailCheckObj$demtarea
  demtarea_post <- DAreaFailCheckObj$demtarea_new
  hydseq_new <- DAreaFailCheckObj$hydseq_new
  headflag_new <- DAreaFailCheckObj$headflag_new
  headflag_check <- DAreaFailCheckObj$Headflag_NewOld
  AreaRatio_NewOld <- DAreaFailCheckObj$AreaRatio_NewOld

  origWaterid <- data1[, which(names(data1) %in% c("waterid", "waterid_for_RSPARROW_mapping"))]
  origWaterid <- origWaterid[which(origWaterid$waterid %in% waterid), ]
  origWaterid <- origWaterid[order(match(origWaterid$waterid, waterid)), ]
  origWaterid <- origWaterid$waterid_for_RSPARROW_mapping

  pout <- data.frame(
    waterid, 
    origWaterid, 
    fnode_pre, 
    tnode_pre, 
    frac_pre, 
    demtarea_pre, 
    demtarea_post, 
    hydseq_new,
    AreaRatio_NewOld, 
    headflag_new, 
    headflag_check
  )
  
  fileout <- paste0(
    path_results, 
    .Platform$file.sep, 
    "estimate", 
    .Platform$file.sep, 
    run_id, 
    "_diagnostic_darea_mismatches.csv"
  )
  
  write.table(
    pout,
    file = fileout, 
    row.names = FALSE, 
    append = FALSE, 
    quote = TRUE,
    dec = csv_decimalSeparator, 
    sep = csv_columnSeparator, 
    col.names = TRUE
  )
  
} # end function
