#' @title mapBreaks
#' @description Creates mapping color breakpoints.  \cr \cr
#' Executed By: \itemize{\item mapSiteAttributes.R
#'             \item predictMaps.R} \cr
#' Executes Routines: \itemize{\item named.list.R
#'                             \item set_unique_breaks.R} \cr
#' @param vvar mapping variable as vector
#' @param colors character vector of colors used in mapping with the number of colors
#'       indicating the number of breaks in the legend
#' @return `outBrks` named list of iprob which is the number of breakpoints and brks
#'                   which contains a numeric vector of legend breakpoints for mapping
#' @keywords internal
#' @noRd



mapBreaks <- function(vvar, colors) {
  # link MAPCOLORS for variable to shape object (https://gist.github.com/mbacou/5880859)

  iprob <- length(colors)

  iprob <- set_unique_breaks(vvar, iprob, rp = numeric(0))$ip

  brks <- set_unique_breaks(vvar, iprob, rp = numeric(0))$chk1

  outBrks <- named.list(brks, iprob)

  return(outBrks)
}
