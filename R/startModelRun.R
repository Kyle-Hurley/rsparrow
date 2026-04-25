#' @title startModelRun
#' @description executes sparrowSetup and sparrowExecution functions \cr \cr
#' Executed By: \itemize{\item batchRun.R
#'             \item executeRSPARROW.R} \cr
#' Executes Routines: \itemize{\item calcDemtareaClass.R
#'             \item checkAnyMissingSubdataVars.R
#'             \item checkClassificationVars.R
#'             \item checkMissingSubdataVars.R
#'             \item controlFileTasksModel.R
#'             \item createDataMatrix.R
#'             \item createSubdataSorted.R
#'             \item named.list.R
#'             \item selectCalibrationSites.R
#'             \item selectDesignMatrix.R
#'             \item selectParmValues.R
#'             \item selectValidationSites.R
#'             \item setNLLSWeights.R
#'             \item startEndmodifySubdata.R} \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating
#'       whether estimation should be run in simulation mode only.
#' @param if_boot_estimate yes/no control setting to specify if parametric bootstrap estimation
#'       (Monte Carlo) is to be executed
#' @param if_boot_predict yes/no control setting to specify if bootstrap predictions (mean, SE,
#'       confidence intervals) are to be executed
#' @param filter_data1_conditions User specified additional DATA1 variables (and conditions) to
#'       be used to filter reaches from sparrow_control
#' @param data1 input data (data1)
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param class.input.list list of control settings related to classification variables
#' @param min.sites.list named list of control settings `minimum_headwater_site_area`,
#'                     `minimum_reaches_separating_sites`, `minimum_site_incremental_area`
#' @param if_validate yes/no indicating whether or not validation is run
#' @param iseed User specified initial seed for the bootstraps from sparrow_control
#' @param pvalidate numeric control setting indicating a percentage of calibration sites to
#'       select for validation or if equal to 0 indicates that the user defined valsites variable should be
#'       used to select sites for validation. For more details see documentation Section 4.4.6
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#'                          lon_limit, master_map_list, lineShapeName, lineWaterid,
#'                          polyShapeName, ployWaterid, LineShapeGeo, LineShapeGeo, CRStext,
#'                          convertShapeToBinary.list, map_siteAttributes.list,
#'                          residual_map_breakpoints, site_mapPointScale,
#'                          if_verify_demtarea_maps
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#'                           NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param if_predict yes/no indicating whether or not prediction is run
#' @param biters User specified number of parametric bootstrap iterations from sparrow_control
#' @param scenario.input.list list of control settings related to source change scenarios
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#'       prediction, yield, and residuals csv and shape files
#' @param RSPARROW_errorOption yes/no control setting indicating where the RPSARROW_errorOption
#'                            should be applied
#' @keywords internal
#' @noRd



startModelRun <- function(file.output.list,
                          if_estimate, if_estimate_simulation,
                          if_boot_estimate, if_boot_predict,
                          # createSubdataSorted
                          filter_data1_conditions, data1,
                          data_names,
                          # checkClassificationVars
                          class.input.list,
                          # selectCalibrationSites
                          min.sites.list,
                          # selectValidationSites
                          if_validate, iseed, pvalidate,
                          # findMinMaxLatLon
                          mapping.input.list,
                          # controlFileTasksModel
                          estimate.input.list,
                          if_predict, biters,
                          scenario.input.list,
                          # shinyMap2
                          add_vars,
                          RSPARROW_errorOption,
                          # pre-parsed inputs from prep_sparrow_inputs()
                          betavalues,
                          dmatrixin) {
  # Extract frequently used variables from input lists
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id

  classvar <- class.input.list$classvar
  class_landuse <- class.input.list$class_landuse

  minimum_reaches_separating_sites <- min.sites.list$minimum_reaches_separating_sites

  NLLS_weights <- estimate.input.list$NLLS_weights
  if_mean_adjust_delivery_vars <- estimate.input.list$if_mean_adjust_delivery_vars

  master_map_list <- mapping.input.list$master_map_list
  lon_limit <- mapping.input.list$lon_limit
  ConcFactor <- mapping.input.list$ConcFactor
  sparrow_state <- list()

  message("Reading parameters and design matrix...")
  # (A) input parameters and settings
  # betavalues is pre-parsed by prep_sparrow_inputs() and passed in directly
  stopifnot(!is.null(betavalues))
  sparrow_state$betavalues <- betavalues

  # (B) Setup the parameter and system variables
  SelParmValues <- selectParmValues(betavalues, if_estimate, if_estimate_simulation)
  sparrow_state$SelParmValues <- SelParmValues

  # deactivates unnecessary computation of parameter correlations, Eigenvalues in cases of one predictor variable
  if (SelParmValues$bcols == 1) {
    ifHess <- "no"
    sparrow_state$ifHess <- ifHess
  }

  # (C) input source-delivery interaction matrix (includes all possible variables)
  # dmatrixin is pre-parsed by prep_sparrow_inputs() and passed in directly
  stopifnot(!is.null(dmatrixin))
  sparrow_state$dmatrixin <- dmatrixin
  # (D) Setup design/interaction matrix
  dlvdsgn <- selectDesignMatrix(SelParmValues, betavalues, dmatrixin)
  sparrow_state$dlvdsgn <- dlvdsgn

  ##############################################################
  # 4. Create SUBDATA object for model estimation and prediction
  ##############################################################
  message("Creating and Modifying subdata...")
  # (A) Create 'subdata' by filtering DATA1
  subdata <- createSubdataSorted(filter_data1_conditions, data1)

  # (B) Apply standard variable name mapping (data modifications should be
  #     applied to the data frames before calling rsparrow_model())
  subdata <- startEndmodifySubdata(data_names, class_landuse, data1)
  sparrow_state$subdata <- subdata

  message("Testing for missing variables in subdata...")
  checkClassificationVars(subdata, class.input.list)
  checkMissingSubdataVars(subdata, betavalues, file.output.list, data_names = data_names)
  ###########################################################
  # 5. Setup calibration and validation sites and loads
  ###########################################################

  # (A) Calibration site filtering, based on 'calsite' index variable
  #     Filter the monitoring sites based on user-specified criteria (above)
  #     (Generate site count summary:  numsites1, numsites2, numsites3, numsites4, nMon)
  message("Setting up calibration and validation sites...")
  Csites.list <- selectCalibrationSites(subdata, data_names, min.sites.list)

  waterid <- Csites.list$waterid
  depvar <- Csites.list$depvar
  staid <- Csites.list$staid
  staidseq <- Csites.list$staidseq
  xx <- data.frame(waterid, staid, staidseq, depvar)
  drops <- c("depvar", "staid", "staidseq")
  subdata <- subdata[, !(names(subdata) %in% drops)]
  subdata <- merge(subdata, xx, by = "waterid", all.y = FALSE, all.x = FALSE)
  subdata <- subdata[with(subdata, order(subdata$hydseq)), ] # resort by the original HYDSEQ order

  numsites1 <- Csites.list$numsites1
  numsites2 <- Csites.list$numsites2
  numsites3 <- Csites.list$numsites3
  numsites4 <- Csites.list$numsites4
  nMon <- Csites.list$nMon
  nMoncalsites <- sum(ifelse(subdata$calsites == 0 | is.na(subdata$calsites), 0, 1))

  # (B) Select validation sites
  vic <- 0
  vsitedata <- NA
  Vsites.list <- NA
  if (if_validate == "yes") {
    Vsites.list <- selectValidationSites(iseed, pvalidate, subdata, minimum_reaches_separating_sites, data_names)

    waterid <- Vsites.list$waterid
    depvar <- Vsites.list$depvar
    staid <- Vsites.list$staid
    staidseq <- Vsites.list$staidseq
    vdepvar <- Vsites.list$vdepvar
    vstaid <- Vsites.list$vstaid
    vstaidseq <- Vsites.list$vstaidseq
    xx <- data.frame(waterid, staid, staidseq, depvar, vstaid, vstaidseq, vdepvar)
    drops <- c("depvar", "staid", "staidseq")
    subdata <- subdata[, !(names(subdata) %in% drops)]
    subdata <- merge(subdata, xx, by = "waterid", all.y = FALSE, all.x = FALSE)
    subdata <- subdata[with(subdata, order(subdata$hydseq)), ] # resort by the original HYDSEQ order

    nMon <- Vsites.list$nMon
    nMoncalsites <- sum(ifelse(subdata$calsites == 0 | is.na(subdata$calsites), 0, 1))
    vic <- Vsites.list$vic
    Csites.list$depvar <- Vsites.list$depvar
    Csites.list$staid <- Vsites.list$staid
    Csites.list$nMon <- Vsites.list$nMon
    Csites.list$nMoncalsites <- nMoncalsites
    Csites.list$staidseq <- Vsites.list$staidseq
    sparrow_state$Vsites.list <- Vsites.list
  }
  print(paste0("Initial monitoring site count: ", numsites1))

  print(paste0("Monitoring sites after filtering for small headwater sites: ", numsites2))

  print(paste0("Monitoring sites after filtering for minimum number of reaches separating sites: ", numsites3))

  print(paste0("Monitoring sites after filtering for minimum incremental area between sites: ", numsites4))

  print(paste0("Number of calibration sites identified by the CALSITES variable: ", nMoncalsites))

  print(paste0("Number of selected calibration sites with non-zero observed loads: ", nMon))

  print(paste0("Number of selected validation sites with non-zero observed loads: ", vic))


  ###############################################################
  # 6. Missing data checks and data setup for estimation
  ###############################################################
  message("Setting up data for estimation...")
  # (A) Check for missing data in SUBDATA
  checkAnyMissingSubdataVars(subdata, betavalues)

  # (B) Setup 'Data' and 'beta' matrices and 'data.index.list' for optimization
  DataMatrix.list <- createDataMatrix(if_mean_adjust_delivery_vars, subdata, SelParmValues, betavalues)
  sparrow_state$DataMatrix.list <- DataMatrix.list


  # (C) Setup SITEDATA and VSITEDATA for diagnostics
  sitedata <- subdata[(subdata$depvar > 0 & subdata$calsites == 1), ] # create site attribute object
  sparrow_state$sitedata <- sitedata
  numsites <- length(sitedata$waterid)
  sparrow_state$numsites <- numsites


  sitegeolimits <- NA
  sparrow_state$sitegeolimits <- sitegeolimits

  vnumsites <- 0
  if (if_validate == "yes") {
    vsitedata <- subdata[(subdata$vdepvar > 0), ] # create site attribute object
    sparrow_state$vsitedata <- vsitedata
    vnumsites <- length(vsitedata$waterid)
    vnumsites
  }

  # (D) Setup drainage-area classification for diagnostics
  sitedata.landuse <- NA
  vsitedata.landuse <- NA
  if (numsites > 0) {
    # Obtain total drainage area classification variable for calibration sites
    sitedata.demtarea.class <- calcDemtareaClass(sitedata$demtarea)
    sparrow_state$sitedata.demtarea.class <- sitedata.demtarea.class
  }
  if (vnumsites > 0) {
    # Obtain total drainage area classification variable for validation sites
    vsitedata.demtarea.class <- calcDemtareaClass(vsitedata$demtarea)
    sparrow_state$vsitedata.demtarea.class <- vsitedata.demtarea.class
  }

  # if no classvar/classvar[1] then use sitedata.demtarea.class 5.5.17
  if (all(is.na(classvar)) | is.na(classvar[1])) {
    sitedata$sitedata.demtarea.class <- sitedata.demtarea.class
    sparrow_state$sitedata <- sitedata
    if (vnumsites > 0) {
      vsitedata$sitedata.demtarea.class <- vsitedata.demtarea.class
      sparrow_state$vsitedata <- vsitedata
    }




    classvar[1] <- "sitedata.demtarea.class"
    uniqueClasses <- unique(sitedata.demtarea.class)[order(unique(sitedata.demtarea.class))]
    demtarea.rchclass <- numeric(length(subdata$waterid))
    demtarea.rchclass <- rep(uniqueClasses[1], length(subdata$waterid))
    for (i in 1:length(subdata$waterid)) {
      for (k in 1:(length(uniqueClasses) - 1)) {
        if (uniqueClasses[k] < subdata$demtarea[i] & subdata$demtarea[i] <= uniqueClasses[k + 1]) {
          demtarea.rchclass[i] <- uniqueClasses[k + 1]
        }
      }
    }
    subdata$sitedata.demtarea.class <- demtarea.rchclass
    class.input.list$classvar <- classvar
    sparrow_state$class.input.list <- class.input.list
    sparrow_state$classvar <- classvar
  }


  Cor.ExplanVars.list <- NA

  ########################################
  ### 7. PERFORM MODEL EXECUTION TASKS ###
  ########################################

  # variables from prior data processing subroutines: numsites,data_names,sitedata.landuse,vsitedata.landuse,
  #        Csites.weights.list

  # Calculate regression weights as proportional to incremental area size
  weight <- NA
  Csites.weights.list <- named.list(weight)
  if (numsites > 0) {
    Csites.weights.list <- setNLLSWeights(
      NLLS_weights, run_id, subdata, sitedata, data_names,
      minimum_reaches_separating_sites
    )
    if (NLLS_weights == "default") {
      Csites.weights.list$weight <- rep(1, numsites) # set weights=1.0 (overide area-based weights)
    }
  }
  sparrow_state$Csites.weights.list <- Csites.weights.list
  sparrow_state$Csites.list <- Csites.list
  sparrow_state$Cor.ExplanVars.list <- Cor.ExplanVars.list
  sparrow_state$subdata <- subdata


  runTimes <- controlFileTasksModel(
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
    # estimation
    if_estimate, if_estimate_simulation, dlvdsgn,
    estimate.input.list,
    # prediction
    if_predict,
    # diagnostics and validation
    if_validate,
    # mapping
    mapping.input.list,
    # bootstrapping
    iseed, biters,
    # scenarios
    scenario.input.list,
    add_vars,
    RSPARROW_errorOption
  )





  estimate.list <- runTimes$estimate.list
  sparrow_state$estimate.list <- estimate.list  # expose to rsparrow_model()
  sparrow_state$predict.list  <- runTimes$predict.list  # expose to rsparrow_model()

  return(sparrow_state)
} # end function
