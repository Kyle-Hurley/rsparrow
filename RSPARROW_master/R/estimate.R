#' @title estimate
#' 
#' @description 
#' Executes all model tasks related to model estimation, diagnostics plotting 
#' and mapping, parameter sensitivities, validation diagnostics, and the output of tabular 
#' summary metrics.
#' 
#' Executed By: controlFileTasksModel.R
#' 
#' Executes Routines: \itemize{
#'              \item checkDynamic.R, 
#'              \item diagnosticPlotsNLLS.R, 
#'              \item diagnosticPlotsNLLS_dyn.R, 
#'              \item diagnosticPlotsValidate.R, 
#'              \item diagnosticSensitivity.R, 
#'              \item estimateFevalNoadj.R, 
#'              \item estimateNLLSmetrics.R, 
#'              \item estimateNLLStable.R, 
#'              \item estimateOptimize.R, 
#'              \item named.list.R, 
#'              \item predict.R, 
#'              \item predictSummaryOutCSV.R, 
#'              \item validateMetrics.R}
#' 
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_predict yes/no indicating whether or not prediction is run
#' @param file.output.list list of control settings and relative paths used for input and 
#' output of external files.  Created by `generateInputList.R`
#' @param class.input.list list of control settings related to classification variables
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset, 
#' NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param minimum_reaches_separating_sites number indicating the minimum number of reaches 
#' separating sites
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list' for 
#' optimization
#' @param SelParmValues selected parameters from parameters.csv using condition 
#' `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" & 
#' parmMin>=0) | parmType!="SOURCE")`
#' @param Csites.weights.list regression weights as proportional to incremental area size
#' @param Csites.list list output from `selectCalibrationSites.R` modified in `startModelRun.R`
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 & 
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with 
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter 
#' sub-section 5.1.2 for details)
#' @param numsites number of sites selected for calibration
#' @param if_validate yes/no indicating whether or not validation is run
#' @param Vsites.list named list of sites for validation
#' @param vsitedata sitedata for validation. Calculated by `subdata[(subdata$vdepvar > 0  & 
#' subdata$calsites==1), ]`
#' @param subdata data.frame input data (subdata)
#' @param min.sites.list named list of control settings `minimum_headwater_site_area`, 
#' `minimum_reaches_separating_sites`, `minimum_site_incremental_area`
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R`
#' @param sitedata.landuse Land use for incremental basins for diagnostics.
#' @param vsitedata.landuse Land use for incremental basins for diagnostics for validation 
#' sites.
#' @param sitedata.demtarea.class Total drainage area classification variable for calibration 
#' sites.
#' @param vsitedata.demtarea.class Total drainage area classification variable for validation 
#' sites.
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit, 
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo, 
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list, 
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param betavalues data.frame of model parameters from parameters.csv
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating 
#' whether estimation should be run in simulation mode only.
#' @param add_vars additional variables specified by the setting `add_vars` to be included in 
#' prediction, yield, and residuals csv and shape files
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' 
#' @return `estimate.list` named list of summary metrics and diagnostic output. For more
#'            details see documentation section 5.2.4
#' @keywords internal
#' @noRd



estimate <- function(if_estimate, if_predict, file.output.list,
                     class.input.list, dlvdsgn,
                     estimate.input.list,
                     minimum_reaches_separating_sites,
                     DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list, sitedata, numsites,
                     if_validate, Vsites.list, vsitedata, subdata, min.sites.list, 
                     Cor.ExplanVars.list,
                     sitedata.landuse, vsitedata.landuse, sitedata.demtarea.class, vsitedata.demtarea.class,
                     mapping.input.list, betavalues,
                     if_estimate_simulation,
                     add_vars, data_names) {
  #########################################

  ifHess <- estimate.input.list$ifHess
  yieldFactor <- estimate.input.list$yieldFactor

  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator <- file.output.list$csv_columnSeparator
  outputESRImaps <- file.output.list$outputESRImaps
  add_vars <- file.output.list$add_vars
  CRStext <- file.output.list$CRStext
  map_siteAttributes.list <- file.output.list$map_siteAttributes.list

  classvar <- class.input.list$classvar
  
  estimate.list <- NULL
  
  dynamic <- checkDynamic(subdata) # check for dynamic model (TRUE, FALSE)
  
  if (if_estimate == "yes" & if_estimate_simulation == "no") {
    message("Running estimation...")
    sparrowEsts <- estimateOptimize(
      file.output.list, SelParmValues, estimate.input.list,
      DataMatrix.list, dlvdsgn, Csites.weights.list
    )

    #   Resids <- sparrowEsts$resid / sqrt(Csites.weights.list$weight)  # re-express residuals in original units
    # Calculate estimation diagnostic metrics (JacobResults, HesResults)
    if_sparrowEsts <- 1 # calculation of Jacobian diagnostics
    estimate.metrics.list <- estimateNLLSmetrics(
      if_estimate, if_estimate_simulation, if_sparrowEsts, sparrowEsts,
      file.output.list, classvar, dlvdsgn,
      Csites.weights.list, estimate.input.list,
      Csites.list, SelParmValues, subdata, sitedata, DataMatrix.list
    )

    # unpack estimate.metrics.list for return
    JacobResults <- estimate.metrics.list$JacobResults
    HesResults <- estimate.metrics.list$HesResults
    ANOVA.list <- estimate.metrics.list$ANOVA.list
    Mdiagnostics.list <- estimate.metrics.list$Mdiagnostics.list

    # check for dynamic model for generation of summary metrics
    if (dynamic) {
      ANOVAdynamic.list <- estimate.metrics.list$ANOVAdynamic.list
      estimate.list <- named.list(sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list, ANOVAdynamic.list)
    } else {
      estimate.list <- named.list(sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list)
    }
    
    if (if_validate == "yes") {
      message("Running Validation...")
      validate.metrics.list <- validateMetrics(
        classvar, estimate.list, dlvdsgn, Vsites.list, yieldFactor,
        SelParmValues, subdata, vsitedata, DataMatrix.list
      )
      vANOVA.list <- validate.metrics.list$vANOVA.list
      vMdiagnostics.list <- validate.metrics.list$vMdiagnostics.list
      estimate.list <- named.list(
        sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list,
        vANOVA.list, vMdiagnostics.list
      )
      if (dynamic) {
        estimate.list <- named.list(
          sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list, ANOVAdynamic.list,
          vANOVA.list, vMdiagnostics.list
        )
      }
    }
    
    # Output summary metrics
    estimateNLLStable(
      file.output.list, if_estimate, if_estimate_simulation, ifHess, if_sparrowEsts,
      classvar, sitedata, numsites,
      estimate.list,
      Cor.ExplanVars.list,
      if_validate, vANOVA.list, vMdiagnostics.list, betavalues, Csites.weights.list
    )
    
    ####################################################
    ### 1. Output diagnostic graphics (plots & maps) ###
    
    message("Running diagnostic plots and sensitivity analysis...")
    if (is.finite(JacobResults$mean_exp_weighted_error)) { 
      
      # mean error and standardized residuals must be available
      diagnosticPlotsNLLS(
        file.output.list = file.output.list,
        class.input.list = class.input.list,
        sitedata.demtarea.class = sitedata.demtarea.class,
        sitedata = sitedata,
        sitedata.landuse = sitedata.landuse,
        estimate.list = estimate.list,
        mapping.input.list = mapping.input.list,
        Cor.ExplanVars.list = Cor.ExplanVars.list,
        data_names = data_names,
        add_vars = add_vars,
        validation = FALSE
      )
      
      # output siteAttr shapefile
      if (outputESRImaps[4] == "yes") {
        siteAttrshape <- data.frame(
          waterid = sitedata$waterid,
          originalWaterid = sitedata$waterid_for_RSPARROW_mapping,
          xlat, xlon
        )
        for (s in 1:length(map_siteAttributes.list)) {
          if (length(names(sitedata)[which(names(sitedata) == map_siteAttributes.list[s])]) != 0) {
            siteAttr <- eval(
              parse(
                text = paste0(
                  "data.frame(", 
                  map_siteAttributes.list[s], 
                  "=sitedata$", 
                  map_siteAttributes.list[s], 
                  ")"
                )
              )
            )
            siteAttrshape <- data.frame(siteAttrshape, siteAttr)
            names(siteAttrshape)[length(siteAttrshape)] <- map_siteAttributes.list[s]
          }
        }
        
        
        esri_path <- paste0(
          path_results,
          "maps",
          .Platform$file.sep,
          "ESRI_ShapeFiles",
          .Platform$file.sep
        )
        if (!dir.exists(esri_path)) {
          dir.create(esri_path, showWarnings = FALSE)
        }
        if (!dir.exists(paste0(esri_path, "siteAttributes", .Platform$file.sep))) {
          dir.create(paste0(esri_path, "siteAttributes", .Platform$file.sep), showWarnings = FALSE)
        }
        sf::st_write(
          sf::st_as_sf(siteAttrshape, coords = c("xlon", "xlat"), crs = sf::st_crs(CRStext)),
          paste0(esri_path, "siteAttributes", .Platform$file.sep, "siteAttrshape.shp"),
          driver = "ESRI Shapefile", 
          overwrite = TRUE
          
        )
      }
      
      # output residuals shapefile
      if (outputESRImaps[3] == "yes") {
        Resids <- estimate.list$sparrowEsts$resid
        Obsyield <- Obs / sitedata$demtarea
        
        predictYield <- predict / sitedata$demtarea
        leverage <- estimate.list$JacobResults$leverage
        boot_resid <- estimate.list$JacobResults$boot_resid
        tiarea <- Csites.weights.list$tiarea
        weight <- Csites.weights.list$weight
        origWaterid <- sitedata$waterid_for_RSPARROW_mapping
        
        dd <- data.frame(
          sitedata,
          origWaterid,
          Obs,
          predict,
          Obsyield,
          predictYield,
          Resids,
          standardResids,
          leverage,
          boot_resid,
          weight,
          tiarea,
          pResids,
          ratio.obs.pred,
          pratio.obs.pred,
          xlat,
          xlon
        )
        keeps <- c(
          "waterid", "origWaterid", "demtarea", "rchname", "station_id", "station_name", "staid",
          classvar[1], "Obs", "predict", "Obsyield", "predictYield", "Resids", "standardResids",
          "leverage", "boot_resid", "weight", "tiarea", "pResids", "ratio.obs.pred",
          "pratio.obs.pred", "xlat", "xlon"
        )
        residShape <- dd[keeps]
        
        if (length(na.omit(add_vars)) != 0) {
          add_data <- data.frame(sitedata[, which(names(sitedata) %in% add_vars)])
          if (length(add_vars) == 1) {
            names(add_data) <- add_vars
          }
          residShape <- cbind(residShape, add_data)
        }
        
        esri_path <- paste0(
          path_results,
          "maps",
          .Platform$file.sep,
          "ESRI_ShapeFiles",
          .Platform$file.sep
        )
        if (!dir.exists(esri_path)) {
          dir.create(esri_path, showWarnings = FALSE)
        }
        if (!dir.exists(paste0(esri_path, "residuals", .Platform$file.sep))) {
          dir.create(paste0(esri_path, "residuals", .Platform$file.sep), showWarnings = FALSE)
        }
        
        sf::st_write(
          sf::st_as_sf(residShape, coords = c("xlon", "xlat"), crs = sf::st_crs(CRStext)),
          paste0(esri_path, "residuals", .Platform$file.sep, "residShape.shp"),
          driver = "ESRI Shapefile",
          overwrite = TRUE
        )
      }
      
    }
    
    # dyn_diagnostics_reports ---------------------------------------------------------------------
    
    if (!identical(NA, mapping.input.list$diagnosticPlots_timestep) & dynamic) {
      
      diagnosticPlotsNLLS_dyn(
        validation = FALSE,
        sensitivity = FALSE,
        spatialAutoCorr = FALSE,
        file.output.list = file.output.list,
        class.input.list = class.input.list,
        sitedata.demtarea.class = sitedata.demtarea.class,
        sitedata = sitedata,
        subdata = subdata,
        sitedata.landuse = sitedata.landuse,
        estimate.list = estimate.list,
        mapping.input.list = mapping.input.list,
        Csites.list = Csites.list,
        Cor.ExplanVars.list = Cor.ExplanVars.list,
        data_names = data_names,
        add_vars = add_vars,
        SelParmValues = SelParmValues,
        DataMatrix.list = DataMatrix.list,
        estimate.input.list = estimate.input.list,
        min.sites.list = min.sites.list,dlvdsgn
      )
      
    }
    
    if (dynamic & mapping.input.list$diagnostic_timeSeriesPlots == "yes") {
      
      diagnosticPlotsNLLS_timeSeries(
        mapping.input.list = mapping.input.list, 
        file.output.list = file.output.list, 
        estimate.list = estimate.list, 
        sitedata = sitedata
      )
      
    }
    
    ##############################################
    ### 3. Sensitivity analyses for parameters ###
    
    diagnosticSensitivity(
      file.output.list = file.output.list,
      class.input.list = class.input.list,
      estimate.list = estimate.list,
      estimate.input.list = estimate.input.list,
      DataMatrix.list = DataMatrix.list,
      SelParmValues = SelParmValues,
      subdata = subdata,
      sitedata.demtarea.class = sitedata.demtarea.class,
      mapping.input.list = mapping.input.list,dlvdsgn
    )
    
    # if dynamic data
    if (dynamic) {
      
      if (!identical(NA, diagnosticPlots_timestep)) {
        
        diagnosticPlotsNLLS_dyn(
          validation = FALSE,
          sensitivity = TRUE,
          spatialAutoCorr = FALSE,
          file.output.list = file.output.list,
          class.input.list = class.input.list,
          sitedata.demtarea.class = sitedata.demtarea.class,
          sitedata = sitedata,
          subdata = subdata,
          sitedata.landuse = sitedata.landuse,
          estimate.list = estimate.list,
          mapping.input.list = mapping.input.list,
          Csites.list = Csites.list,
          Cor.ExplanVars.list = Cor.ExplanVars.list,
          data_names = data_names,
          add_vars = add_vars,
          SelParmValues = SelParmValues,
          DataMatrix.list = DataMatrix.list,
          estimate.input.list = estimate.input.list,
          min.sites.list = min.sites.list,dlvdsgn
        )
        
      }
      
    }
    
    #####################################
    ### 4. Output validation metrics  ###
    
    if (if_validate == "yes") {
      
      diagnosticPlotsValidate(
        file.output.list = file.output.list,
        class.input.list = class.input.list,
        vsitedata.demtarea.class = vsitedata.demtarea.class,
        vsitedata = vsitedata,
        vsitedata.landuse = vsitedata.landuse,
        estimate.list = estimate.list,
        mapping.input.list = mapping.input.list,
        add_vars = add_vars,
        data_names = data_names
      )
      
      if (checkDynamic(vsitedata)) {
        
        if (!identical(NA, diagnosticPlots_timestep)) {
          
          diagnosticPlotsNLLS_dyn(
            validation = TRUE,
            sensitivity = FALSE,
            spatialAutoCorr = FALSE,
            file.output.list = file.output.list,
            class.input.list = class.input.list,
            sitedata.demtarea.class = vsitedata.demtarea.class,
            sitedata = vsitedata,
            subdata = subdata,
            sitedata.landuse = vsitedata.landuse,
            estimate.list = estimate.list,
            mapping.input.list = mapping.input.list,
            Csites.list = Csites.list,
            Cor.ExplanVars.list = Cor.ExplanVars.list,
            data_names = data_names,
            add_vars = add_vars,
            SelParmValues = SelParmValues,
            DataMatrix.list = DataMatrix.list,
            estimate.input.list = estimate.input.list,
            min.sites.list = min.sites.list,dlvdsgn
          )
          
        }
        
      }
      
      # output residuals shapefile
      if (outputESRImaps[3] == "yes") {
        
        Obsyield <- Obs / vsitedata$demtarea
        predictYield <- ppredict / vsitedata$demtarea
        origWaterid <- vsitedata$waterid_for_RSPARROW_mapping
        
        dd <- data.frame(
          vsitedata,
          origWaterid,
          Obs,
          ppredict,
          Obsyield,
          predictYield,
          pResids,
          pratio.obs.pred,
          xlat,
          xlon
        )
        
        keeps <- c(
          "waterid", "origWaterid", "demtarea", "rchname", "station_id", "station_name", "staid", 
          classvar[1], "Obs", "ppredict", "Obsyield", "predictYield", "pResids", "pratio.obs.pred", 
          "xlat", "xlon"
        )
        
        validationResidShape <- dd[keeps]
        
        if (length(na.omit(add_vars)) != 0) {
          add_data <- data.frame(vsitedata[, which(names(vsitedata) %in% add_vars)])
          if (length(add_vars) == 1) {
            names(add_data) <- add_vars
          }
          validationResidShape <- cbind(validationResidShape, add_data)
        }
        
        esri_path <- paste0(
          path_results,
          "maps",
          .Platform$file.sep,
          "ESRI_ShapeFiles",
          .Platform$file.sep
        )
        if (!dir.exists(esri_path)) {
          dir.create(esri_path, showWarnings = FALSE)
        }
        if (!dir.exists(paste0(esri_path, "residuals", .Platform$file.sep))) {
          dir.create(paste0(esri_path, "residuals", .Platform$file.sep), showWarnings = FALSE)
        }
        
        sf::st_write(
          sf::st_as_sf(validationResidShape, coords = c("xlon", "xlat"), crs = sf::st_crs(CRStext)),
          paste0(esri_path, "residuals", .Platform$file.sep, "validationResidShape.shp"),
          driver = "ESRI Shapefile", 
          overwrite = TRUE
        )
        
      }
      
    } # end validate loop
    ##########################################
  } else {
    # No estimation desired; load previous results if exist, including Jacobian to support prediction
    #   Files checked include:  sparrowEsts, HessianResults, JacobResults
    #   These files are needed for prediction and bootstrap prediction

    objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_sparrowEsts")
    if (file.exists(objfile) == TRUE & if_estimate_simulation == "no") {
      load(objfile)
      # Load SPARROW object file from a prior run if available
      # Contents of "sparrowEsts" object:
      # $resid - station model residuals
      # $jacobian - jacobian results
      # $coefficients - estimated NLLS values

      # $ssquares - total sum of square of error for the NLLS
      # $lower - lower parameter bounds for the least squares estimation
      # $upper - upper parameter bounds for the least squares estimation


      objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_JacobResults")
      if (file.exists(objfile) == TRUE) {
        load(objfile)
      }

      estimate.list <- named.list(sparrowEsts, JacobResults)

      # load the Hessian results if object exists
      objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_HessianResults")
      if (file.exists(objfile) == TRUE) {
        load(objfile)
        estimate.list <- named.list(sparrowEsts, JacobResults, HesResults)
      }

      ##########################################
    } else { # no prior estimates, thus use starting values to make predictions
      #  and create 'sparrowEsts' and 'JacobResults' objects for return

      if (if_estimate_simulation == "yes") {
        message("Running model in simulation mode using initial values of the parameters...")
        sparrowEsts <- alist(SelParmValues = )$beta0
        sparrowEsts$coefficient <- SelParmValues$beta0 # starting values


        nn <- ifelse(DataMatrix.list$data[, 10] > 0 # jdepvar site load index
        & DataMatrix.list$data[, 13] == 1, # calistes ==1
        1, 0
        )

        # if monitoring loads exist (but not estimating coefs), run residuals, performance measures,
        #     and save JacobResults objects

        if (sum(nn) > 0) {
          message("Outputing performance diagnostics for simulation mode...")

          # compute Resids
          sparrowEsts$resid <- estimateFevalNoadj(
            SelParmValues$beta0,
            DataMatrix.list, SelParmValues, Csites.weights.list,
            estimate.input.list, dlvdsgn
          ) # estimate using starting values
          sparrowEsts$coefficients <- SelParmValues$beta0

          # OUTPUT ESTIMATION METRICS & SUMMARY TABLE
          if_sparrowEsts <- 0 # no calculation of Jacobian diagnostics
          estimate.metrics.list <- estimateNLLSmetrics(
            if_estimate, if_estimate_simulation, if_sparrowEsts, sparrowEsts,
            file.output.list, classvar, dlvdsgn,
            Csites.weights.list, estimate.input.list,
            Csites.list, SelParmValues, subdata, sitedata, DataMatrix.list
          )

          # unpack estimate.metrics.list for return
          JacobResults <- estimate.metrics.list$JacobResults
          HesResults <- estimate.metrics.list$HesResults
          ANOVA.list <- estimate.metrics.list$ANOVA.list
          Mdiagnostics.list <- estimate.metrics.list$Mdiagnostics.list
          estimate.list <- named.list(sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list)

          # save sparrowEsts file to support prediction
          objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_sparrowEsts")
          save(sparrowEsts, file = objfile)



          estimateNLLStable(
            file.output.list, if_estimate, if_estimate_simulation, ifHess, if_sparrowEsts,
            classvar, sitedata, numsites,
            estimate.list,
            Cor.ExplanVars.list,
            if_validate, vANOVA.list, vMdiagnostics.list, betavalues, Csites.weights.list
          )

          ### Output diagnostic graphics (plots & maps) ###
          message("Running diagnostic plots and sensitivity analysis...")
          diagnosticPlotsNLLS(
            file.output.list = file.output.list, 
            class.input.list = class.input.list, 
            sitedata.demtarea.class = sitedata.demtarea.class,
            sitedata = sitedata, 
            sitedata.landuse = sitedata.landuse, 
            estimate.list = estimate.list, 
            mapping.input.list = mapping.input.list, 
            Cor.ExplanVars.list = Cor.ExplanVars.list,
            data_names = data_names, 
            add_vars = add_vars,
            validation = FALSE
          )
          
          # output siteAttr shapefile
          if (outputESRImaps[4] == "yes") {
            siteAttrshape <- data.frame(
              waterid = sitedata$waterid,
              originalWaterid = sitedata$waterid_for_RSPARROW_mapping,
              xlat, xlon
            )
            for (s in 1:length(map_siteAttributes.list)) {
              if (length(names(sitedata)[which(names(sitedata) == map_siteAttributes.list[s])]) != 0) {
                siteAttr <- eval(
                  parse(
                    text = paste0(
                      "data.frame(", 
                      map_siteAttributes.list[s], 
                      "=sitedata$", 
                      map_siteAttributes.list[s], 
                      ")"
                    )
                  )
                )
                siteAttrshape <- data.frame(siteAttrshape, siteAttr)
                names(siteAttrshape)[length(siteAttrshape)] <- map_siteAttributes.list[s]
              }
            }
            
            
            esri_path <- paste0(
              path_results,
              "maps",
              .Platform$file.sep,
              "ESRI_ShapeFiles",
              .Platform$file.sep
            )
            if (!dir.exists(esri_path)) {
              dir.create(esri_path, showWarnings = FALSE)
            }
            if (!dir.exists(paste0(esri_path, "siteAttributes", .Platform$file.sep))) {
              dir.create(paste0(esri_path, "siteAttributes", .Platform$file.sep), showWarnings = FALSE)
            }
            sf::st_write(
              sf::st_as_sf(siteAttrshape, coords = c("xlon", "xlat"), crs = sf::st_crs(CRStext)),
              paste0(esri_path, "siteAttributes", .Platform$file.sep, "siteAttrshape.shp"),
              driver = "ESRI Shapefile", 
              overwrite = TRUE
              
            )
          }
          
          # output residuals shapefile
          if (outputESRImaps[3] == "yes") {
            Resids <- estimate.list$sparrowEsts$resid
            Obsyield <- Obs / sitedata$demtarea
            
            predictYield <- predict / sitedata$demtarea
            leverage <- estimate.list$JacobResults$leverage
            boot_resid <- estimate.list$JacobResults$boot_resid
            tiarea <- Csites.weights.list$tiarea
            weight <- Csites.weights.list$weight
            origWaterid <- sitedata$waterid_for_RSPARROW_mapping
            
            dd <- data.frame(
              sitedata,
              origWaterid,
              Obs,
              predict,
              Obsyield,
              predictYield,
              Resids,
              standardResids,
              leverage,
              boot_resid,
              weight,
              tiarea,
              pResids,
              ratio.obs.pred,
              pratio.obs.pred,
              xlat,
              xlon
            )
            keeps <- c(
              "waterid", "origWaterid", "demtarea", "rchname", "station_id", "station_name", "staid",
              classvar[1], "Obs", "predict", "Obsyield", "predictYield", "Resids", "standardResids",
              "leverage", "boot_resid", "weight", "tiarea", "pResids", "ratio.obs.pred",
              "pratio.obs.pred", "xlat", "xlon"
            )
            residShape <- dd[keeps]
            
            if (length(na.omit(add_vars)) != 0) {
              add_data <- data.frame(sitedata[, which(names(sitedata) %in% add_vars)])
              if (length(add_vars) == 1) {
                names(add_data) <- add_vars
              }
              residShape <- cbind(residShape, add_data)
            }
            
            esri_path <- paste0(
              path_results,
              "maps",
              .Platform$file.sep,
              "ESRI_ShapeFiles",
              .Platform$file.sep
            )
            if (!dir.exists(esri_path)) {
              dir.create(esri_path, showWarnings = FALSE)
            }
            if (!dir.exists(paste0(esri_path, "residuals", .Platform$file.sep))) {
              dir.create(paste0(esri_path, "residuals", .Platform$file.sep), showWarnings = FALSE)
            }
            
            sf::st_write(
              sf::st_as_sf(residShape, coords = c("xlon", "xlat"), crs = sf::st_crs(CRStext)),
              paste0(esri_path, "residuals", .Platform$file.sep, "residShape.shp"),
              driver = "ESRI Shapefile",
              overwrite = TRUE
            )
          }
          
          if (!identical(NA, mapping.input.list$diagnosticPlots_timestep) & dynamic) {
            
            diagnosticPlotsNLLS_dyn(
              validation = FALSE,
              sensitivity = FALSE,
              spatialAutoCorr = FALSE,
              file.output.list = file.output.list,
              class.input.list = class.input.list,
              sitedata.demtarea.class = sitedata.demtarea.class,
              sitedata = sitedata,
              subdata = subdata,
              sitedata.landuse = sitedata.landuse,
              estimate.list = estimate.list,
              mapping.input.list = mapping.input.list,
              Csites.list = Csites.list,
              Cor.ExplanVars.list = Cor.ExplanVars.list,
              data_names = data_names,
              add_vars = add_vars,
              SelParmValues = SelParmValues,
              DataMatrix.list = DataMatrix.list,
              estimate.input.list = estimate.input.list,
              min.sites.list = min.sites.list,dlvdsgn
            )
            
          }
          
          if (dynamic & mapping.input.list$diagnostic_timeSeriesPlots == "yes") {
            
            diagnosticPlotsNLLS_timeSeries(
              mapping.input.list = mapping.input.list, 
              file.output.list = file.output.list, 
              estimate.list = estimate.list, 
              sitedata = sitedata
            )
            
          }
          
          ### Sensitivity analyses for parameters ###
          
          diagnosticSensitivity(
            file.output.list = file.output.list,
            class.input.list = class.input.list,
            estimate.list = estimate.list,
            estimate.input.list = estimate.input.list,
            DataMatrix.list = DataMatrix.list,
            SelParmValues = SelParmValues,
            subdata = subdata,
            sitedata.demtarea.class = sitedata.demtarea.class,
            mapping.input.list = mapping.input.list,dlvdsgn
          )
          
          if (dynamic) {
            
            if (!identical(NA, diagnosticPlots_timestep)) {
              
              diagnosticPlotsNLLS_dyn(
                validation = FALSE,
                sensitivity = TRUE,
                spatialAutoCorr = FALSE,
                file.output.list = file.output.list,
                class.input.list = class.input.list,
                sitedata.demtarea.class = sitedata.demtarea.class,
                sitedata = sitedata,
                subdata = subdata,
                sitedata.landuse = sitedata.landuse,
                estimate.list = estimate.list,
                mapping.input.list = mapping.input.list,
                Csites.list = Csites.list,
                Cor.ExplanVars.list = Cor.ExplanVars.list,
                data_names = data_names,
                add_vars = add_vars,
                SelParmValues = SelParmValues,
                DataMatrix.list = DataMatrix.list,
                estimate.input.list = estimate.input.list,
                min.sites.list = min.sites.list,dlvdsgn
              )
              
            }
            
          }
          
        } else {
          # if no monitoring loads, store Jacobian estimates in object as list for use in making predictions only
          JacobResults <- alist(JacobResults = )$SelParmValues$beta0 # starting values
          JacobResults$oEstimate <- SelParmValues$beta0
          JacobResults$Parmnames <- noquote(c(
            SelParmValues$srcvar, SelParmValues$dlvvar,
            SelParmValues$decvar, SelParmValues$resvar
          ))


          objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_JacobResults")
          save(JacobResults, file = objfile)

          objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_sparrowEsts")
          save(sparrowEsts, file = objfile)

          estimate.list <- named.list(sparrowEsts, JacobResults)
        }
      } # end if_estimate_simulation check
    } # end else for 'no prior estimates exist' case
  } # end "if_estimate" check


  ##########################################
  # Compute summary statistics for predictions

  if (if_predict == "yes" & if_estimate == "yes") {
    # Calculate and output standard bias-corrected predictions
    #  Note:  these include adjusted and nonadjusted for monitoring loads
    if (is.null(estimate.list$JacobResults$mean_exp_weighted_error) == TRUE) {
      bootcorrection <- 1.0
    } else {
      bootcorrection <- estimate.list$JacobResults$mean_exp_weighted_error
    }

    if (is.finite(bootcorrection)) {
      message("Running summary predictions...")
      predict.list <- predict_sparrow(
        estimate.list, estimate.input.list, bootcorrection, DataMatrix.list,
        SelParmValues, subdata, dlvdsgn
      )

      predictSummaryOutCSV(
        file.output.list, estimate.input.list,
        SelParmValues, estimate.list, predict.list,
        subdata, class.input.list
      )
    } else {
      message("Summary predictions not executed; mean_exp_weighted_error and predictions = infinity;
               check standardized residuals for outliers...")
    }
  }

  ##########################################
  if (if_estimate == "yes" | if_estimate_simulation == "yes") {
    if ("Mdiagnostics.list" %in% names(estimate.list)) {
      # store Mdiagnostics.list and ANOVA.list objects to disk
      Mdiagnostics.list <- estimate.list$Mdiagnostics.list
      objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_Mdiagnostics.list")
      save(Mdiagnostics.list, file = objfile)
      ANOVA.list <- estimate.list$ANOVA.list
      objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_ANOVA.list")
      save(ANOVA.list, file = objfile)

      if (if_validate == "yes" & if_estimate_simulation == "no") {
        # store vMdiagnostics.list and vANOVA.list objects to disk
        vMdiagnostics.list <- estimate.list$vMdiagnostics.list
        objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_vMdiagnostics.list")
        save(vMdiagnostics.list, file = objfile)
        vANOVA.list <- estimate.list$vANOVA.list
        objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_vANOVA.list")
        save(vANOVA.list, file = objfile)
      }
    }
  }

  return(estimate.list)
} # end function  # return
