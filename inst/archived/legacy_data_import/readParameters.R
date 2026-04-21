# Archived in Plan 13: replaced by in-memory API (rsparrow_model() data-frame arguments)
#' @title readParameters
#' @description Reads the 'parameters.csv' file. \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating
#'       whether estimation should be run in simulation mode only.
#' @return `betavalues` data.frame of model parameters from parameters.csv
#' @keywords internal
#' @noRd



readParameters <- function(file.output.list, if_estimate, if_estimate_simulation) {
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id

  path <- path_results


  csv_columnSeparator <- file.output.list$csv_columnSeparator
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator

  # define column classes and names
  filebetas <- paste0(path, run_id, "_parameters.csv")
  Ctype <- c("character", "character", "character", "numeric", "numeric", "numeric", "character", "numeric")
  NAMES <- c("sparrowNames", "description", "parmUnits", "parmInit", "parmMin", "parmMax", "parmType", "parmCorrGroup")

  # read file
  betavalues <- data.table::fread(file = filebetas, sep = csv_columnSeparator,
    dec = csv_decimalSeparator, header = TRUE, colClasses = Ctype)
  betavalues <- betavalues[apply(betavalues, 1, function(x) any(!is.na(x))), ]
  names(betavalues) <- NAMES
  betavalues <- as.data.frame(betavalues)

  # trim whitespaces
  betavalues$sparrowNames <- trimws(betavalues$sparrowNames, which = "both")
  # make fixed and required names lowercase
  betavalues$sparrowNames <- ifelse(tolower(betavalues$sparrowNames) %in% as.character(getVarList()$varList), tolower(betavalues$sparrowNames), betavalues$sparrowNames)



  # replace NAs with 0 in numeric columns
  for (c in names(betavalues)) {
    test <- betavalues[[c]]
    if (identical(class(test), "numeric")) {
      test <- ifelse(is.na(test), 0, test)
      betavalues[[c]] <- test
    }
  }


  # create parmConstant
  betavalues$parmConstant <- ifelse(betavalues$parmInit == betavalues$parmMax & betavalues$parmInit == betavalues$parmMin & betavalues$parmInit != 0, 1, 0)
  betavalues <- as.data.frame(betavalues)
  betavalues <- betavalues[, match(c("sparrowNames", "description", "parmUnits", "parmInit", "parmMin", "parmMax", "parmType", "parmConstant", "parmCorrGroup"), names(betavalues))]

  # test for "SOURCE" in parmType column
  sources <- betavalues[which(betavalues$parmType == "SOURCE"), ]
  if (nrow(sources) == 0) {
    message("NO SOURCES FOUND IN PARAMETERS FILE.\nRUN EXECUTION TERMINATED.")

    stop("Error in readParameters.R. Run execution terminated.")
  }

  # test for no parameters (parmMax==0)
  testMax <- betavalues[which(betavalues$parmMax != 0), ]
  if (nrow(testMax) == 0 & (if_estimate == "yes" | if_estimate_simulation == "yes")) {
    message("NO PARAMETERS FOUND FOR ESTIMATION IN PARAMETERS FILE.\nALL PARAMETERS FOUND HAVE parmMAX==0\nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")

    stop("Error in readParameters.R. Run execution terminated.")
  }

  # test for missing values
  missing <- character(0)
  for (c in 4:length(betavalues)) {
    testNA <- betavalues[c]
    testNA <- which(is.na(testNA))
    if (length(testNA) != 0) {
      missing <- c(missing, names(betavalues)[c])
    }
  }
  if (length(missing) != 0) {
    message(paste0(" \nMISSING VALUES FOUND IN THE FOLLOWING COLUMNS OF THE PARAMETERS FILE:\n \n", paste(missing, collapse = "\n"), "\n \nRUN EXECUTION TERMINATED."))

    stop("Error in readParameters.R. Run execution terminated.")
  }




  return(betavalues)
} # end function
