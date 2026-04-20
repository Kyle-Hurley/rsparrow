#' @title applyUserModify
#' @description reads `userModifyData.R` control file as text, unpacks all variables in the
#'            data1 file and applies user modifications, creates the `subdata` object for use in all model
#'            execution statements \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item named.list.R
#'             \item replaceNAs.R} \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param betavalues data.frame of model parameters from parameters.csv
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param subdata data.frame input data (subdata)
#' @param class_landuse character vector of class_landuses from sparrow_control.R
#' @param lon_limit User specified geographic units minimum/maximum longitude limits for
#'       mapping of Residuals and prediction maps
#' @return `subdata`  data.frame with all user designated modifications from userModifyData.R
#' @keywords internal
#' @noRd



applyUserModify <- function(file.output.list,
                            # modifySubdata arguments
                            betavalues, data_names, subdata, class_landuse, lon_limit) {
  # extract required elements from file.output.list
  path_user <- file.output.list$path_user
  results_directoryName <- file.output.list$results_directoryName

  pathToUserMod <- paste0(path_user, .Platform$file.sep, results_directoryName, .Platform$file.sep, "userModifyData.R")

  # read userModifyData file as text
  userMod <- readLines(pathToUserMod)

  # header text (Plan 05C: replaced unPackList with explicit assign loops)
  top <- "modifySubdata <- function(betavalues,data_names,subdata,class_landuse,lon_limit,
                                  file.output.list) {

  # Extract subdata columns and settings as local variables
  for (.vname in data_names$sparrowNames) {
    if (.vname %in% names(subdata)) assign(.vname, subdata[[.vname]])
  }
  for (.vname in betavalues$sparrowNames) {
    if (.vname %in% names(subdata)) assign(.vname, subdata[[.vname]])
  }
  for (.vname in names(file.output.list)) assign(.vname, file.output.list[[.vname]])
  rm(.vname)
  "

  # footer text (Plan 05C: replaced eval(parse()) with direct R calls)
  bottom <- "

#check for missing landuse class
missingLanduseClass<-class_landuse[which(!class_landuse %in% data_names$sparrowNames)]
  if (length(na.omit(missingLanduseClass))!=0){
  for (i in 1:length(missingLanduseClass)){
  message('FATAL ERROR: MISSING class_landuse: ', missingLanduseClass[i])
  }
  }

  # substitute 0.0 for NAs for user-selected parameters
  # set NAs for explanatory variables associated with the selected parameters
  null_params <- betavalues$sparrowNames[betavalues$parmMax != 0]
  replaceNAs(setNames(mget(null_params), null_params))

  # Transfer global variables to SUBDATA

  # Refresh variables in 'subdata' (this allows subsequent use of subdata values)
  #  (accounts for any modification to these variables to replace NAs or
  #   following calculations in the data modifications section)
  datalstreq <- data_names$sparrowNames
  for (i in seq_along(datalstreq)) {
  if (exists(datalstreq[i], inherits = FALSE)) subdata[[datalstreq[i]]] <- get(datalstreq[i], inherits = FALSE)
  }

  # Ensure that variables associated with user-selected parameters are reassigned to SUBDATA
  for (i in seq_along(betavalues$sparrowNames)) {
  if(betavalues$parmMax[i]>0){
  if (exists(betavalues$sparrowNames[i], inherits = FALSE)) subdata[[betavalues$sparrowNames[i]]] <- get(betavalues$sparrowNames[i], inherits = FALSE)
  }
  }

  return(subdata)
  }"



  # add header and footers
  userMod <- paste(top, "\n", paste(userMod, collapse = "\n"), "\n", bottom)

  # evaluate modifySubdata as text
  eval(parse(text = userMod))

  # create subdata
  subdata <- modifySubdata(
    betavalues, data_names, subdata, class_landuse, lon_limit,
    file.output.list
  )

  # return subdata
  return(subdata)
}
