#' @title checkDynamic
#' @description Determine whether the model is dynamic or static using the
#'             presence of "year" and/or "season" data in subdata \cr \cr
#' Executed By: \itemize{
#'              \item checkDrainageareaMapPrep.R, 
#'              \item controlFileTasksModel.R, 
#'              \item createVerifyReachAttr.R, 
#'              \item diagnosticPlotsNLLS.R, 
#'              \item diagnosticSensitivity.R, 
#'              \item diagnosticSpatialAutoCorr.R, 
#'              \item estimate.R, 
#'              \item estimateNLLSmetrics.R, 
#'              \item make_diagnosticPlotsNLLS_timeSeries.R, 
#'              \item make_drainageAreaErrorsMaps.R, 
#'              \item mapSiteAttributes.R, 
#'              \item predictScenariosPrep.R, 
#'              \item readForecast.R, 
#'              \item shinyMap2.R, 
#'              \item startModelRun.R}
#' 
#' @param subdata data.frame input data (subdata)
#' @return logical TRUE/FALSE indicating whether `subdata` is dynamic
#' @keywords internal
#' @noRd

checkDynamic <- function(subdata) {
  dynamic <- TRUE
  if (length(names(subdata)[names(subdata) %in% c("year", "season")]) == 0) {
    dynamic <- FALSE
  } else if (length(names(subdata)[names(subdata) == "year"]) != 0) {
    if (all(is.na(subdata$year))) {
      if (length(names(subdata)[names(subdata) == "season"]) != 0) {
        if (all(is.na(subdata$season))) {
          dynamic <- FALSE
        }
      } else { # no season found
        dynamic <- FALSE
      }
    }
  } else { # no year found
    if (length(names(subdata)[names(subdata) == "season"]) != 0) {
      if (all(is.na(subdata$season))) {
        dynamic <- FALSE
      }
    } else { # noseason found
      dynamic <- FALSE
    }
  }
  return(dynamic)
}
