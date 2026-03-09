#' @title named.list
#' @description Supports the creation of a list object by specifying unquoted variable names in
#'            the argument list. \cr \cr
#' Executed By: \itemize{\item batchRun.R
#'             \item addMarkerText.R
#'             \item aggDynamicMapdata.R
#'             \item applyUserModify.R
#'             \item checkDrainageareaMapPrep.R
#'             \item checkDrainageareaMapPrep_static.R
#'             \item controlFileTasksModel.R
#'             \item correlationMatrix.R
#'             \item create_diagnosticPlotList.R
#'             \item createDataMatrix.R
#'             \item createRTables.R
#'             \item diagnosticSensitivity.R
#'             \item estimate.R
#'             \item estimateBootstraps.R
#'             \item estimateNLLSmetrics.R
#'             \item estimateOptimize.R
#'             \item estimateWeightedErrors.R
#'             \item findMinMaxLatLon.R
#'             \item generateInputLists.R
#'             \item getVarList.R
#'             \item mapBreaks.R
#'             \item mapSiteAttributes.R
#'             \item predict.R
#'             \item predictBoot.R
#'             \item predictBootstraps.R
#'             \item predictMaps_single.R
#'             \item predictScenarios.R
#'             \item predictScenariosOutCSV.R
#'             \item predictScenariosPrep.R
#'             \item selectCalibrationSites.R
#'             \item selectParmValues.R
#'             \item selectValidationSites.R
#'             \item set_unique_breaks.R
#'             \item setNLLSWeights.R
#'             \item startModelRun.R
#'             \item testCosmetic.R
#'             \item testRedTbl.R
#'             \item validateMetrics.R} \cr
#' @param ... objects to compile into a named list
#' @return list object containing objects with names in `...`
#' @keywords internal
#' @noRd



named.list <- function(...) {
  l <- setNames(list(...), as.character(match.call()[-1]))
  l
}
