#' @title checkBinaryMaps
#' @description Checks if binary mapping objects exist and loads binary files \cr \cr
#' Executed By: \itemize{\item checkDrainageareaErrors.R
#'             \item diagnosticPlotsNLLS.R
#'             \item diagnosticPlotsValidate.R
#'             \item mapSiteAttributes.R
#'             \item predictMaps.R} \cr
#' @param mapSetting setting in control file that user sets to use to load the binary map
#'       (`lineShapeName`, `polyShapeName`, or `LineShapeGeo`)
#' @param path_gis path to users gis data
#' @return `fileLoaded`  logical TRUE/FALSE indicating whether or not file is loaded
#' @keywords internal
#' @noRd



checkBinaryMaps <- function(mapSetting, path_gis) {
  # get name of setting
  settingName <- deparse(substitute(mapSetting))

  # set name of output object
  if (grepl("lineShapeName", settingName)) {
    outObj <- "lineShape"
  } else if (grepl("LineShapeGeo", settingName)) {
    outObj <- "GeoLines"
  } else {
    outObj <- "polyShape"
  }
  objfile <- paste0(path_gis, .Platform$file.sep, outObj)

  if (!identical(mapSetting, NA) & file.exists(objfile)) {
    e <- new.env(parent = emptyenv())
    load(objfile, envir = e)
    if (!exists(outObj, envir = e, inherits = FALSE)) {
      message(paste0(settingName, " <- ", mapSetting, " NOT FOUND MAPPING CANNOT COMPLETE.\nSet if_create_binary_maps<-'yes' to create binary files."))
      return(list(fileLoaded = FALSE, mapObj = NULL))
    }
    return(list(fileLoaded = TRUE, mapObj = get(outObj, envir = e, inherits = FALSE)))
  }

  return(list(fileLoaded = FALSE, mapObj = NULL))
} # end function
