#' @title controlFileTasksModel
#' 
#' @description 
#' Executes all model tasks after checks have been performed, including 
#' execution of model estimation, diagnostics, prediction, scenarios, and mapping
#' 
#' Executed By: startModelRun.R
#' 
#' Executes Routines: \itemize{
#'              \item diagnosticSpatialAutoCorr.R,
#'              \item estimate.R,
#'              \item estimateBootstraps.R, 
#'              \item named.list.R, 
#'              \item outcharfun.R, 
#'              \item predict.R,
#'              \item predictBootsOutCSV.R, 
#'              \item predictBootstraps.R, 
#'              \item predictOutCSV.R, 
#'              \item predictScenarios.R}
#' 
#' @param file.output.list list of control settings and relative paths used for input and 
#' output of external files.  Created by `generateInputList.R`
#' @param SelParmValues selected parameters from parameters.csv using condition 
#' `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" & 
#' parmMin>=0) | parmType!="SOURCE")`
#' @param betavalues data.frame of model parameters from parameters.csv
#' @param Csites.list list output from `selectCalibrationSites.R` modified in `startModelRun.R`
#' @param Csites.weights.list regression weights as proportional to incremental area size
#' @param subdata data.frame input data (subdata)
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list' for 
#' optimization
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0 & 
#' subdata$calsites==1), ]`. The object contains the dataDictionary 'sparrowNames' variables, with 
#' records sorted in hydrological (upstream to downstream) order  (see the documentation Chapter 
#' sub-section 5.1.2 for details)
#' @param Vsites.list named list of sites for validation
#' @param vsitedata sitedata for validation. Calculated by `subdata[(subdata$vdepvar > 0  & 
#' subdata$calsites==1), ]`
#' @param numsites number of sites selected for calibration
#' @param class.input.list list of control settings related to classification variables
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R`
#' @param min.sites.list named list of minimum site filtering settings
#' @param minimum_reaches_separating_sites number indicating the minimum number of reaches
#' separating sites
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating 
#' whether estimation should be run in simulation mode only.
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset, 
#' NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param if_predict yes/no indicating whether or not prediction is run
#' @param if_validate yes/no indicating whether or not validation is run
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
#' @param iseed User specified initial seed for the bootstraps from sparrow_control
#' @param biters User specified number of parametric bootstrap iterations from sparrow_control
#' @param scenario.input.list list of control settings related to source change scenarios
#' @param add_vars additional variables specified by the setting `add_vars` to be included in 
#' prediction, yield, and residuals csv and shape files
#' @param RSPARROW_errorOption yes/no control setting indicating where the 
#' RPSARROW_errorOption should be applied
#' @return `runTimes`  named list of run times
#' \tabular{ll}{
#' `BootEstRunTime` \tab bootstrap estimation run time
#' `BootPredictRunTime` \tab bootstrap prediction run time
#' `MapPredictRunTime` \tab prediction mapping run time
#' `estimate.list` \tab create estimate.list run time
#' }
#' @keywords internal
#' @noRd




controlFileTasksModel <- function(
    # pathnames
    file.output.list,
    # parameters
    SelParmValues, betavalues,
    # NLR weights
    Csites.list, 
    Csites.weights.list,
    # data
    subdata, data_names, DataMatrix.list, sitedata, Vsites.list, vsitedata, numsites,
    # land use classification
    class.input.list,
    # explanatory variable correlations
    Cor.ExplanVars.list,
    # estimation
    min.sites.list,
    minimum_reaches_separating_sites,
    if_estimate, if_estimate_simulation, dlvdsgn,
    estimate.input.list,
    # prediction
    if_predict,
    # diagnostics and validation
    if_validate, sitedata.landuse, vsitedata.landuse, sitedata.demtarea.class, 
    vsitedata.demtarea.class, 
    # mapping
    mapping.input.list,
    # bootstrapping
    iseed, biters,
    # scenarios
    scenario.input.list,
    add_vars,
    RSPARROW_errorOption) {
  #####################################
  ### PERFORM MODEL EXECUTION TASKS ###
  #####################################

  #######################
  ### A. OPTIMIZATION ###
  #######################

  # Estimation options for if_estimate=""
  # (1) if_estimate="yes" - executes NLLS; calculates estimation metrics, and outputs ANOVA summary table
  # (2) if_estimate="no" and prior NLLS execution completed (sparrowEsts object) - calculates estimation,
  #      metrics, and outputs ANOVA summary table (Hessian output if previously executed)
  # (3) if_estimate="no" stores starting beta values in JacobResults for use in making predictions
  #      if monitoring loads exist, then calculates estimation metrics, and outputs ANOVA summary table
  # (4) if_predict="yes" - executes reach summary deciles; output to (prefix name)_summary_predictions.csv




  # Extract frequently used variables from input lists
  path_results <- file.output.list$path_results
  path_master <- file.output.list$path_master
  path_main <- file.output.list$path_main
  run_id <- file.output.list$run_id
  runScript <- file.output.list$runScript
  run2 <- file.output.list$run2

  if_spatialAutoCorr <- estimate.input.list$if_spatialAutoCorr
  diagnosticPlots_timestep <- estimate.input.list$diagnosticPlots_timestep
  if_boot_estimate <- estimate.input.list$if_boot_estimate
  if_boot_predict <- estimate.input.list$if_boot_predict

  master_map_list <- mapping.input.list$master_map_list
  output_map_type <- mapping.input.list$output_map_type

  # creates or checks for prior estimation objects:  sparrowEsts,JacobResults,HesResults
  estimate.list <- estimate(
    if_estimate, if_predict, file.output.list,
    class.input.list, dlvdsgn,
    estimate.input.list,
    minimum_reaches_separating_sites,
    DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list, sitedata, numsites,
    if_validate, Vsites.list, vsitedata, subdata, min.sites.list, 
    Cor.ExplanVars.list,
    sitedata.landuse, vsitedata.landuse, sitedata.demtarea.class, vsitedata.demtarea.class,
    mapping.input.list, betavalues,
    if_estimate_simulation,
    add_vars, data_names
  )


  ######################
  ### B. DIAGNOSTICS ###
  ######################
  
  if (if_spatialAutoCorr == "yes") {
    nn <- ifelse(DataMatrix.list$data[, 10] > 0 # jdepvar site load index
    & DataMatrix.list$data[, 13] == 1, # calistes ==1
    1, 0
    )


    if ((if_estimate == "yes" | if_estimate_simulation == "yes") & (sum(nn) > 0)) {
      ############################################
      ### 2. Spatial auto-correlation analysis ###
      ############################################
      # Moran's I analysis (requires execution of diagnosticPlotsNLLS)
      message("Running diagnostic spatial autocorrelation...")
      # only execute if stream 'length' available for all reaches
      if (sum(!is.na(subdata$length)) > 0) {
        diagSpatResult <- diagnosticSpatialAutoCorr(
          file.output.list = file.output.list,
          sitedata = sitedata,
          estimate.list = estimate.list,
          estimate.input.list = estimate.input.list,
          mapping.input.list = mapping.input.list,
          subdata = subdata,
          min.sites.list = min.sites.list,
          class.input.list = class.input.list,
          DataMatrix.list = DataMatrix.list
        )
      }
    } else {
      message("Diagnostic spatial autocorrelation was not executed;
      execution requires if_estimate or if_estimate_simulation = yes and monitoring site loads must be available.")
    }
  } # end if_spatialAutoCorr for production of graphics


  #####################################
  ### C. BOOTSTRAP MODEL ESTIMATION ###
  #####################################

  # Run parametric bootstrap option for parameter estimation (if_boot_estimate = "yes")
  # Obtain previous results if exist (if_boot_estimate = "no")
  BootEstRunTime <- " "
  ptm <- proc.time()

  objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_HessianResults") # needed for covariance
if (if_boot_estimate == "yes" & biters!=0){
  if (if_boot_estimate == "yes" & file.exists(objfile) == TRUE) {
    message("Estimating bootstrap model coefficients and errors...")

    BootResults <- estimateBootstraps(
      iseed, biters, estimate.list,
      DataMatrix.list, SelParmValues, Csites.weights.list,
      estimate.input.list, dlvdsgn, file.output.list
    )
  } else { # no bootstrap estimation; check to see if already exists

    objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_BootBetaest") # BootResults
    if (file.exists(objfile) == TRUE) {
      load(objfile)
    } else {
      objfile <- paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_HessianResults") # needed for covariance
      if (if_boot_estimate == "yes" & file.exists(objfile) == FALSE) {
        message(paste0(" \nWARNING : HesResults DOES NOT EXIST.  boot_estimate NOT RUN.\n "))
      }
    }
  } # end check whether bootstrap file exist
}else if (if_boot_estimate=="yes"){
  message(paste0(" \nWARNING : biters=0  boot_estimate NOT RUN.\n "))
}
  BootEstRunTime <- proc.time() - ptm


  #############################
  ### D. OUTPUT PREDICTIONS ###
  #############################

  # Load predictions:
  #   pload_total                Total load (fully decayed)
  #   pload_(sources)            Source load (fully decayed)
  #   mpload_total               Monitoring-adjusted total load (fully decayed)
  #   mpload_(sources)           Monitoring-adjusted source load (fully decayed)
  #   pload_nd_total             Total load delivered to streams (no stream decay)
  #   pload_nd_(sources)         Source load delivered to streams (no stream decay)
  #   pload_inc                  Total incremental load delivered to streams
  #   pload_inc_(sources)        Source incremental load delivered to streams
  #   deliv_frac                 Fraction of total load delivered to terminal reach
  #   pload_inc_deliv            Total incremental load delivered to terminal reach
  #   pload_inc_(sources)_deliv  Source incremental load delivered to terminal reach
  #   share_total_(sources)      Source shares for total load (percent)
  #   share_inc_(sources)        Source share for incremental load (percent)

  # Yield predictions:
  #   Concentration              Concentration based on decayed total load and discharge
  #   yield_total                Total yield (fully decayed)
  #   yield_(sources)            Source yield (fully decayed)
  #   myield_total               Monitoring-adjusted total yield (fully decayed)
  #   myield_(sources)           Monitoring-adjusted source yield (fully decayed)
  #   yield_inc                  Total incremental yield delivered to streams
  #   yield_inc_(sources)        Source incremental yield delivered to streams
  #   yield_inc_deliv            Total incremental yield delivered to terminal reach
  #   yield_inc_(sources)_deliv  Source incremental yield delivered to terminal reach

  # Uncertainty predictions (requires prior execution of bootstrap predictions):
  #   se_pload_total             Standard error of the total load (percent of mean)
  #   ci_pload_total             95% prediction interval of the total load (percent of mean)

  #############################################
  #### 1. Standard Predictions to CSV file ####
  #############################################

  BootPredictRunTime <- " "
  MapPredictRunTime <- " "
  predict.list <- NULL
  predictBoots.list <- NULL

  if (if_predict == "yes") {
    if (!is.null(estimate.list$JacobResults)) {
      message("Running predictions...")

      # Calculate and output standard bias-corrected predictions
      #  Note:  these include adjusted and nonadjusted for monitoring loads
      if (is.null(estimate.list$JacobResults$mean_exp_weighted_error) == TRUE) {
        bootcorrection <- 1.0
      } else {
        bootcorrection <- estimate.list$JacobResults$mean_exp_weighted_error
      }

      predict.list <- predict_sparrow(
        estimate.list, estimate.input.list, bootcorrection, DataMatrix.list,
        SelParmValues, subdata, dlvdsgn
      )

    } # end check on JacobResults available
  } # end if_predict

  ###############################################
  #### 2. Bootstrap Prediction to CSV file ######
  ###############################################

  # Requires prior execution of bootstrap estimation and standard predictions
  ptm <- proc.time()
  if (if_boot_predict == "yes") {
    if (file.exists(paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_BootBetaest")) &
        !is.null(predict.list)) {
      load(paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_BootBetaest"))

      message("Running bootstrap predictions...")
      predictBoots.list <- predictBootstraps(
        iseed, biters, estimate.list, estimate.input.list, predict.list, BootResults,
        DataMatrix.list, SelParmValues,
        subdata, file.output.list, dlvdsgn
      )

      predictBootsOutCSV(
        file.output.list, estimate.list, predictBoots.list, subdata,
        add_vars, data_names
      ) # edit preditBootsOutCSV accordingly
    } else if (!file.exists(paste0(path_results, .Platform$file.sep, "estimate", .Platform$file.sep, run_id, "_BootBetaest"))) {
      message(paste0(" \nWARNING : BootBetaest DOES NOT EXIST.  boot_predict NOT RUN.\n "))
    } else if (is.null(predict.list)) {
      message(paste0(" \nWARNING : predict.list NOT AVAILABLE.  Run with if_predict='yes' to enable boot_predict.\n "))
    } # end if file.exists
  } # end _BootBetaest check
  BootPredictRunTime <- proc.time() - ptm


  MapPredictRunTime <- proc.time() - proc.time()

  #######################################################
  #### 4. Prediction Load-Reduction Scenario Options ####
  #######################################################

  # NOTE: standard predictions ("if_predict = yes") must be executed to support this feature
  #       to ensure creation of load and yield matrices


  input <- list(variable = "", scLoadCheck = "", batch = "", scYieldCheck = "", domain = "", selectReaches = "", sourcesCheck = "", factors = "")
  if (exists("estimate.list") & !is.null(estimate.list)) {
    predictScenarios( # Rshiny
      input, NA, output_map_type, FALSE,
      # regular
      estimate.input.list, estimate.list,
      predict.list, scenario.input.list,
      data_names, estimate.list$JacobResults, if_predict,
      # bootcorrection,
      DataMatrix.list, SelParmValues, subdata,
      # predictStreamMapScenarios
      file.output.list,
      # scenarios out
      add_vars,
      mapping.input.list,
      dlvdsgn,
      RSPARROW_errorOption
    )
  }

  ##########################################

  runTimes <- named.list(BootEstRunTime, BootPredictRunTime, MapPredictRunTime, estimate.list, predict.list, predictBoots.list)




  return(runTimes)
} # end function
