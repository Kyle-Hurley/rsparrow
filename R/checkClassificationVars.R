#' @title checkClassificationVars
#' @description Checks for missing or zero values in classification variables in section 5 of
#'            the control script. If missing and/or zeros are found, a critical error has been found and
#'            program execution will terminate. \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: (none) \cr
#' @param subdata data.frame input data (subdata)
#' @param class.input.list list of control settings related to classification variables
#' @keywords internal
#' @noRd



checkClassificationVars <- function(subdata, class.input.list) {
  classvar <- class.input.list$classvar
  class_landuse <- class.input.list$class_landuse

  if (!identical(classvar, NA)) {
    # test for class var in names subdata
    testClassvar <- classvar[which(!classvar %in% names(subdata))]
    if (length(testClassvar) != 0) {
      message(paste0("INVALID classvar ", paste(testClassvar, collapse = ", "), " NOT FOUND IN dataDictionary.csv \nRUN EXECUTION TERMINATED"))
      stop("Error in checkClassificationVars.R. Run execution terminated.")
    }
  }

  # check that no NAs exist in the user definced classvar and class_landuse variables
  colsOrder <- c(na.omit(c(classvar, class_landuse)))
  if (length(colsOrder) != 0) {
    cols <- subdata[, which(names(subdata) %in% colsOrder), drop = FALSE]
    cols <- cols[, match(colsOrder, names(cols))]
    for (c in 1:length(cols)) {
      check <- cols[[c]]
      check <- check[which(is.na(check))]
      if (length(check) != 0) {
        if (names(cols)[c] %in% classvar) {
          type <- "classvar"
        } else {
          type <- "class_landuse"
        }
        message(paste("ERROR the following ", type, " variable has MISSING values : ", names(cols)[c]))
        message(paste("\nMISSING VALUES IN 'classvar' AND/OR 'class_landuse' VARIABLES WILL CAUSE PROGRAM FAILURE!"))
        stop("Error in checkClassificationVars.R. Run execution terminated.")
      }
    }
  }
} # end function
