#' @title setNAdf
#' @description substitute 0.0 for NAs for user-selected parameters
#'              (assumes variables already present in 'df') \cr \cr
#' Executed By: calcIncremLandUse.R \cr
#' @param df data.frame input data (subdata)
#' @param names character vector of user-selected parameters
#' @return `df`  data.frame with NAs replaced by 0.0 for `names`
#' @examples
#' data <- data.frame(
#'   group = c("red", "red", "blue", "blue", "blue"),
#'   c1 = c(1, 2, 3, NA, 5),
#'   c2 = c(NA, 20, 30, 40, 50)
#' )
#' setNAdf(data, c("c1", "c2"))
#' @keywords internal
#' @noRd
setNAdf <- function(df, names) {
  for (i in 1:length(names)) {
    df[[names[i]]] <- ifelse(is.na(df[[names[i]]]), 0.0, df[[names[i]]])
  }
  return(df)
}
