#' @title test_addPlotlyvars
#' @description Test whether variables in RSPARROW user setting
#'             `add_plotlyVars` can be aggregated according to
#'             `map_years` and/or `map_seasons`\cr \cr
#' @param add_plotlyVars character vector indicating user selected variables to add to plot hover
#'                      text
#' @param subdata data.frame input data (subdata)
#' @param groupVar character string indicating column in subdata
#'                used in grouping (season or year)
#' @param maxUnique numeric required length of the grouped add_plotlyVars
#' @return character vector of all add_plotlyVars that can be grouped by
#'        groupVar and a message stating any add_plotlyVars that were
#'        removed due to not being unique within the group.
#' @keywords internal
#' @noRd



test_addPlotlyvars <- function(add_plotlyVars, subdata, groupVar, maxUnique) {
  for (v in add_plotlyVars) {
    test <- unique(subdata[c(groupVar, v)])
    if (nrow(test) > maxUnique) {
      if (v=="waterid"){
        add_plotlyVars <- add_plotlyVars[add_plotlyVars != v]
        add_plotlyVars <- c(add_plotlyVars,"mapping_waterid")
        message(paste0(v, " not unique per mapping_waterid, replaced with mapping_waterid in add_plotlyVars")) 
      }else{
      message(paste0(v, " not unique per mapping_waterid removed from add_plotlyVars"))
      add_plotlyVars <- add_plotlyVars[add_plotlyVars != v]
      }
    }
  }
  return(add_plotlyVars)
}
