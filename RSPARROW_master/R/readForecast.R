#' @title readForecast
#' @description  Prepare generic external forecast file for
#'              merging with the explanatory data matrix in
#'              the DSS.\cr \cr
#' Executed By: predictScenariosPrep.R \cr
#' Executes Routines: \itemize{\item checkDynamic.R} \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param if_mean_adjust_delivery_vars yes/no character string indicating if the delivery
#'       variables are to be mean adjusted from sparrow_control
#' @param use_sparrowNames TRUE/FALSE indicating whether the forecast file
#'                        contains sparrowNames as column headers (TRUE) or
#'                        contains data1UserNames as column headers (FALSE)
#' @param subdata data.frame input data (subdata)
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) &
#'       ((parmType=="SOURCE" & parmMin>=0) | parmType!="SOURCE")`
#' @param forecast_filename character string path to forecast file
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @return data.frame of formatted forecast data for scenario
#' @keywords internal
#' @noRd

#######################################################################################################
# readForecast.R
#
# Purpose:  Prepare generic external forecast file for merging with the explanatory data matrix in the DSS.

# Tasks:
#  1. Reads external forecast file
#  2. Re-label the forecast 'waterid' variable with the 'waterid_for_RSPARROW_mapping' variable, and run checks on forecast file
#  3. Extract all reach data from 'subdata' for the time period(s) that matches the base time period(s) of the forecast file
#      (Purpose is to fill-in any missing reaches in forecast file with original values from the base time period. The
#       forecast file is expected to have from one to four seasons relected in the base time period)
#  4. Save only forecast variables that are present in the calibrated model
#  5. Mean-adjust forecast delivery variables for model where 'if_mean_adjust_delivery_vars <- "yes"' selected
#  6. Sort final forecast file (fFinal) by internal 'waterid', so that ready to merge with the 'DataMatrix.list$data' matrix.

######################################################
readForecast <- function(file.output.list, if_mean_adjust_delivery_vars, use_sparrowNames,
                         subdata, SelParmValues, forecast_filename, data_names) {
  path_data <- file.output.list$path_data
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator <- file.output.list$csv_columnSeparator


  # 1. Read external forecast file
  filefData <- paste0(path_data, forecast_filename)
  
  # test file encoding for non-UTF-8 characters
  badRows <- mod_read_utf8(filefData)
  
  if (length(badRows) > 0) {
    stop("Error in readForecast.R. Run execution terminated.")
  }
  fData <- data.table::fread(
    filefData,
    header = TRUE, stringsAsFactors = FALSE,
    dec = csv_decimalSeparator, sep = csv_columnSeparator
  )
  fData <- as.data.frame(fData)

  # test for names in data_names
  if (!use_sparrowNames) {
    for (n in names(fData)) {
      if (!n %in% data_names$data1UserNames) {
        message(paste0(n, "  NOT FOUND in dataDictionary.REMOVED FROM FORECASTING SCENARIO"))
        fData <- fData[, names(fData) != n]
      } else {
        names(fData)[names(fData) == n] <- as.character(na.omit(data_names[data_names$data1UserNames == n, ]$sparrowNames))
        use_sparrowNames <- TRUE
      }
    } # for each n
  } else { # use sparrowNames
    for (n in names(fData)) {
      if (!n %in% data_names$sparrowNames) {
        message(paste0(n, "  NOT FOUND in dataDictionary.REMOVED FROM FORECASTING SCENARIO"))
        fData <- fData[, names(fData) != n]
      }
    }
  }

  ######################################################
  # 2. Re-label the forecast 'waterid' variable with the 'waterid_for_RSPARROW_mapping' variable, and check variables in forecast file

  # test whether vars exist
  if (length(fData) == 1) {
    message("ERROR: NO VARIABLES FOUND IN FORECAST SCENARIO DATA. SCENARIO NOT RUN.")
    #   errorOccurred("readForecast.R")
  }

  # Convert data1UserNames to sparrowNames 'waterid', and/or convert sparrowNames 'waterid' to 'waterid_for_RSPARROW_mapping'
  if (use_sparrowNames == TRUE) {
    # convert the sparrowNames 'waterid' to 'waterid_for_RSPARROW_mapping' to merge with the original values in 'subdata'
    fData <- setNames(fData, replace(names(fData), names(fData) == "waterid", "waterid_for_RSPARROW_mapping"))
  } else {
    # match the sparrowNames 'waterid' to obtain the data1UserNames and convert to 'waterid_for_RSPARROW_mapping'
    vc <- ""
    for (i in 1:length(data_names$varType)) {
      if (data_names$sparrowNames[i] == "waterid") {
        vc <- data_names$data1UserNames[i]
      }
    }
    fData <- setNames(fData, replace(names(fData), names(fData) == vc, "waterid_for_RSPARROW_mapping"))
  }


  # test for original waterid variable
  if (!any(names(fData) == "waterid_for_RSPARROW_mapping")) {
    message("ERROR: VALID REACH IDENTIFICATION NUMBER NOT FOUND IN FORECAST SCENARIO DATAFILE. SCENARIO NOT RUN.")
    #   errorOccurred("readForecast.R")
  }

  # Eliminate source or delivery variables in forecast file that are missing from model explanatory variable list
  for (n in names(fData)) {
    if (!n %in% SelParmValues$sparrowNames[SelParmValues$betatype == "SOURCE" | SelParmValues$betatype == "DELIVF"] & n != "waterid_for_RSPARROW_mapping") {
      message(paste0(n, "  NOT FOUND IN SOURCE OR DELIV PARAMS AND REMOVED FROM FORECASTING SCENARIO."))
      fData <- fData[names(fData) != n]
    }
  }
  fDataNames <- names(fData)

  # test whether vars exist after eliminating forecast variables missing from the SPARROW model
  if (length(fData) == 1) {
    message("ERROR: NO SPARROW MODEL PARAMS FOUND IN FORECAST SCENARIO DATA. SCENARIO NOT RUN.")
    #   errorOccurred("readForecast.R")
  }

  # Save SPARROW model names and types for the source and delivery variables in the forecast file
  fNames <- SelParmValues$sparrowNames[(SelParmValues$sparrowNames[SelParmValues$betatype == "SOURCE" | SelParmValues$betatype == "DELIVF"] %in% fDataNames) == TRUE]
  fbetatype <- SelParmValues$betatype[(SelParmValues$sparrowNames[SelParmValues$betatype == "SOURCE" | SelParmValues$betatype == "DELIVF"] %in% fDataNames) == TRUE]

  ######################################################
  # 3. Extract data for all reaches from 'subdata', and check for 'subdata' matches with forecast reaches and time periods.
  #    For dynamic model, extract reaches for the time period that matches the base time period
  #     in the forecast file (number of records = total number reaches for each time step)
  #    Note that the forecast file may have some missing reaches; therefore, a match on the
  #     time period(s) ensures that 'subdata' values are extracted/saved for all reach records for a given base time period.
  #    The forecast file is expected to have from one to four (full year) seasons of data for the base time period
  #     for seasonal and mean seasonal SPARROW models and one year for a mean annual model.

  #   3a. For dynamic model, execute first processing of 'subdata' to obtain the base time period for the forecasts
  dynamic <- checkDynamic(subdata)
  dynseas <- FALSE
  dynyear <- FALSE
  if ("season" %in% names(subdata)) {
    if (!any(is.na(subdata$season))) {
      dynseas <- TRUE
    }
  }
  if ("year" %in% names(subdata)) {
    if (!any(is.na(subdata$year))) {
      dynyear <- TRUE
    }
  }

  if (dynamic) {
    if (dynseas & dynyear) {
      Names1 <- c("waterid_for_RSPARROW_mapping", "waterid", "season", "year")
      fsubdata <- subdata[names(subdata) %in% Names1]
      fData <- merge(fData, fsubdata, by = "waterid_for_RSPARROW_mapping", all = FALSE)

      BaseSeason <- unique(fData$season) # from 1 to 4 seasons expected
      BaseYear <- unique(fData$year) # only one year expected
    } else {
      if (dyseas) {
        Names1 <- c("waterid_for_RSPARROW_mapping", "waterid", "season")
        fsubdata <- subdata[names(subdata) %in% Names1]
        fData <- merge(fData, fsubdata, by = "waterid_for_RSPARROW_mapping", all = FALSE)
        BaseSeason <- unique(fData$season)
        BaseYear <- NA
      }
      if (dynyear) {
        Names1 <- c("waterid_for_RSPARROW_mapping", "waterid", "year")
        fsubdata <- subdata[names(subdata) %in% Names1]
        fData <- merge(fData, fsubdata, by = "waterid_for_RSPARROW_mapping", all = FALSE)
        BaseSeason <- NA
        BaseYear <- unique(fData$year)
      }
    }
  } else {
    # static model (save all reaches that match)
    Names1 <- c("waterid_for_RSPARROW_mapping", "waterid")
    fsubdata <- subdata[names(subdata) %in% Names1]
    fData <- merge(fData, fsubdata, by = "waterid_for_RSPARROW_mapping", all = FALSE)
    BaseSeason <- NA
    BaseYear <- NA
  }

  # Check for case where forecast file 'waterid' does not match the 'waterid' in the subdata calibration object
  #   Terminate scenario if no matches found
  if (length(fData$waterid_for_RSPARROW_mapping) == 0) {
    message("ERROR: NO MATCHES FOUND IN THE CALIBRATION DATA FOR THE FORECAST SCENARIO REACHES. SCENARIO NOT RUN.")
  }

  # For dynamic model, test whether forecast base time period includes data for more than one year
  if (dynamic) {
    if (length(BaseSeason) > 4 | length(BaseYear) > 1) {
      message("ERROR: THE FORECAST SCENARIO INCLUDES DATA FOR MORE THAN ONE YEAR. A SINGLE BASE TIME PERIOD
              CANNOT BE ESTABLISHED FOR COMPARING FORECASTS. SCENARIO NOT RUN.")
    }
  }

  #  3b. Execute the second processing of 'subdata' to flag and extract 'subdata' values for the forecast variables.
  #      Procedure flags 'subdata$tcondition' for all reaches for the selected base time periods.

  if (dynamic) {
    subdata$tcondition <- FALSE
    if (dynseas & dynyear) {
      for (i in 1:length(BaseSeason)) {
        subdata$tcondition <- ifelse(subdata$year == BaseYear & subdata$season == BaseSeason[i], TRUE, subdata$tcondition)
      }
    } else {
      if (dynseas) {
        for (i in 1:length(BaseSeason)) {
          subdata$tcondition <- ifelse(subdata$season == BaseSeason[i], TRUE, subdata$tcondition)
        }
      }
      if (dynyear) {
        for (i in 1:length(BaseSeason)) {
          subdata$tcondition <- ifelse(subdata$year == BaseYear, TRUE, subdata$tcondition)
        }
      }
    }
  } else {
    subdata$tcondition <- TRUE
  }
  fsubdata <- subdata[which(subdata$tcondition == TRUE), names(subdata) %in% names(fData)] # subset records for 'tcondition'

  #  3c. Merge forecast file (fData) with the object 'fsubdata', which contains all reaches (and time periods from the forecast file)
  fData2 <- merge(fData, fsubdata, by = "waterid_for_RSPARROW_mapping", all = TRUE) # keep all records


  #  fcheck <- fData2[is.na(fData2$logPPT.x),names(fData2)]   # 55 records with NAs for TB TP model

  #  3d. Process the final forecast variables in 'fData2' object
  #       Procedure replaces missing forecast values (.x) with the original base time period data values in 'fsubdata' (.y)
  #       Save only the forecast variables present in the calibrated model

  # For each forecast variable, fill missing forecast values (.x) with original values (.y)
  forecast_vals <- vector("list", length(fNames))
  names(forecast_vals) <- fNames
  for (i in 1:length(fNames)) {
    dname <- fNames[i]
    x_col <- fData2[[paste0(dname, ".x")]]
    y_col <- fData2[[paste0(dname, ".y")]]
    forecast_vals[[dname]] <- ifelse(is.na(x_col), y_col, x_col)
  }

  ######################################################
  #  4. Create final forecast dataframe from the named forecast variables

  waterid <- fData2$waterid.y # select waterid from the complete fsubdata object
  waterid_for_RSPARROW_mapping <- fData2$waterid_for_RSPARROW_mapping

  if (dynamic) { # time period variables kept for reference for dynamic model
    if (dynseas & dynyear) {
      season <- fData2$season.y
      year <- fData2$year.y
      fFinal <- data.frame(waterid_for_RSPARROW_mapping, waterid, season, year)
    } else {
      if (dynseas) {
        season <- fData2$season.y
        fFinal <- data.frame(waterid_for_RSPARROW_mapping, waterid, season)
      }
      if (dynyear) {
        year <- fData2$year.y
        fFinal <- data.frame(waterid_for_RSPARROW_mapping, waterid, year)
      }
    }
  }

  for (i in 1:length(fNames)) {
    fFinal[[fNames[i]]] <- forecast_vals[[fNames[i]]]
  }

  fFinal1 <- fFinal

  ######################################################
  # 5. mean-adjust all forecast delivery variables included in model, using mean of original data from 'subdata' object

  for (j in 1:length(fNames)) {
    if (fbetatype[j] == "DELIVF" & if_mean_adjust_delivery_vars == "yes") {
      fFinal[[fNames[j]]] <- fFinal[[fNames[j]]] - mean(subdata[[fNames[j]]])
    }
  }

  ######################################################
  # 6. sort final data frame by 'waterid' (internal); ready to match to the internal data matrix used by DSS

  fFinal <- fFinal[with(fFinal, order(fFinal$waterid)), ]


  # clear out extra variables
  fFinal <- fFinal[, names(fFinal) != "waterid_for_RSPARROW_mapping"]

  if ("season" %in% names(fFinal)) {
    fFinal <- fFinal[, names(fFinal) != "season"]
  }

  if ("year" %in% names(fFinal)) {
    fFinal <- fFinal[, names(fFinal) != "year"]
  }

  return(fFinal)
}
