#' @title checkMissingSubdataVars
#' @description Identifies REQUIRED system variables and user selected parameters with all
#'            missing/zero values in `subdata` and outputs a list of variables with all missing values as message
#'            in console. \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item checkingMissingVars.R
#'             \item getVarList.R
#'             } \cr
#' @param subdata data.frame input data (subdata)
#' @param betavalues data.frame of model parameters from parameters.csv
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @keywords internal
#' @noRd



checkMissingSubdataVars <- function(subdata, betavalues, file.output.list, data_names = NULL) {
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id

  # get missing values
  missing <- checkingMissingVars(subdata, data_names, betavalues,
    types = c("datalstCheck", "xlnames", "vrnames"),
    allMissing = TRUE, returnData = FALSE
  )
  k <- missing$k
  datalstMissingdata <- missing$datalstMissingdata
  xlnames <- missing$xlnames
  vrnames <- missing$vrnames
  datalstCheck <- missing$datalstCheck

  # output custom messages
  MissingSubdataVariableMessage <- ""
  if (k > 0) {
    fixMissingSubdataVariable <- datalstMissingdata[1:k]
    for (i in unique(fixMissingSubdataVariable)) {
      if (i %in% xlnames & i %in% datalstCheck & i %in% vrnames) {
        problemFile <- paste0("BOTH the ", path_results, run_id, "_parameters.csv and
                         the ", path_results, run_id, "_dataDictionary.csv files")
      } else if (i %in% datalstCheck) {
        problemFile <- "The required and fixed variables list"
      } else if (i %in% xlnames) {
        problemFile <- paste0("The ", path_results, run_id, "_parameters.csv file")
      } else {
        problemFile <- paste0("The ", path_results, run_id, "_dataDictionary.csv file")
      }
      if (i %in% c(getVarList()$reqNames, xlnames)) {
        msgText <- paste0(
          " \nERROR: THIS REQUIRED VARIABLE FROM \n", problemFile,
          " \nHAS ALL MISSING OR ZERO VALUES IN SUBDATA:", i, "\n \nRUN EXECUTION TERMINATED.\n "
        )
        message(msgText)
        stop("Error in checkMissingSubdataVars.R. Run execution terminated.")
      } else {
        msgText <- paste0(
          " \nWARNING: THIS REQUIRED VARIABLE FROM \n", problemFile,
          " \nHAS ALL MISSING OR ZERO VALUES IN SUBDATA:", i, "\n "
        )
      }
      message(msgText)

    }
  }
} # end function
