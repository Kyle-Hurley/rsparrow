#' @title dataInputPrep
#' @description Imports data1.csv and dataDictionary.csv files, checks for duplicate
#'            `sparrowNames`, replaces `data1UserNames` with `sparrowNames` in the `data1` object, checksreach
#'            navigation variables for large integers and/or all missing values, creates and/or verifies navigation
#'            variables and `demtarea`, saves `data1` and `data_names` (dataDictionary.csv import object)
#'            objects as binary file in top level of results (input_data_fileName)_priorImport, and saves
#'            `data_names` and `data1` to `.GlobalEnv` \cr \cr
#' Executed By: \itemize{\item batchRun.R
#'             \item executeRSPARROW.R} \cr
#' Executes Routines: \itemize{\item checkData1NavigationVars.R
#'             \item checkDupVarnames.R
#'             \item checkMissingData1Vars.R
#'             \item createVerifyReachAttr.R
#'             \item read_dataDictionary.R
#'             \item readData.R
#'             \item replaceData1Names.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param input_data_fileName name of users data1 file
#' @param if_reverse_hydseq yes/no indicating whether hydseq in the DATA1 file needs to be
#'       reversed from sparrow_control
#' @param if_verify_demtarea specify whether or not to verify demtarea
#' @param calculate_reach_attribute_list list of attributes to calculate
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#'                          lon_limit, master_map_list, lineShapeName, lineWaterid,
#'                          polyShapeName, ployWaterid, LineShapeGeo, LineShapeGeo, CRStext,
#'                          convertShapeToBinary.list, map_siteAttributes.list,
#'                          residual_map_breakpoints, site_mapPointScale,
#'                          if_verify_demtarea_maps
#' @keywords internal
#' @noRd



dataInputPrep <- function(
    # for readData
    file.output.list, input_data_fileName,
    # for checkData1NavigationVars
    if_reverse_hydseq,
    # for createVerifyNavigationVars
    if_verify_demtarea, calculate_reach_attribute_list,
    mapping.input.list) {
  ######################################
  # 2. DATA1 input and data preparation
  ######################################
  path_results <- file.output.list$path_results

  message("Running Data import and prep...")

  # (A) Input DATA1 CSV file
  data1 <- readData(file.output.list, input_data_fileName)


  # (B) input VARNAMES (data dictionary) CSV file
  #     (should contain all required network variables plus any new variables
  #      needed for mapping, plus any variables in SUBDATA used to make calculations)
  data_names <- as.data.frame(read_dataDictionary(file.output.list))

  # (B1) check varNames for duplicates
  checkDupVarnames(data_names)

  # (C) Replace the column names in DATA1 with the required column names
  #    Set default setting for 'calsites' index if missing or all NAs
  replace_result <- replaceData1Names(data_names, data1)
  data1 <- replace_result$data1
  data_names <- replace_result$data_names

  # (C1) Checks for excessively large integer values for navigation variables and
  #      replacement of values if necessary
  data1 <- checkData1NavigationVars(data1, if_reverse_hydseq)


  # (D) Optional processing of NETWORK ATTRIBUTES AND VERIFY DRAINAGE AREA
  data1 <- createVerifyReachAttr(
    if_verify_demtarea, calculate_reach_attribute_list, data1,
    file.output.list, mapping.input.list
  )



  # (E) Check for missing required variables in DATA1 as specified in varnames file
  data1 <- checkMissingData1Vars(data1)


  # save dataInputPrep objects to binary file for future use
  fileList <- c("data1", "data_names")
  fileList <- fileList[which(fileList %in% ls())]
  fileName <- strsplit(path_results, .Platform$file.sep)[[1]]
  fileName <- paste(fileName[1:length(fileName) - 1], collapse = .Platform$file.sep)
  fileName <- paste0(fileName, .Platform$file.sep, gsub(".csv", "", input_data_fileName), "_priorImport")
  save(list = fileList, file = fileName)




  return(list(data1 = data1, data_names = data_names))
} # end function
