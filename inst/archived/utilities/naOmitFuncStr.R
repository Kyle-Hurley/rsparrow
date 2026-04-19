#' @title naOmitFuncStr
#' @description creates string in the form 'function(x) aggFunc(x,na.rm=TRUE)' ensuring that
#'              when the `aggFunc` is executed that NA values are removed. \cr \cr
#' @param aggFunc character vector of an aggregate functions approved for RSPARROW 2.0
#'                c("mean","median","min","max")
#' @return `str` string in the form 'function(x) aggFunc(x,na.rm=TRUE)'
#' @examples
#' data <- data.frame(
#'   group = c("red", "red", "blue", "blue", "blue"),
#'   c1 = c(1, 2, 3, NA, 5),
#'   c2 = c(NA, 20, 30, 40, 50)
#' )
#' for (f in c("mean", "median", "min", "max")) {
#'   aggFunctionString <- naOmitFuncStr(f)
#'   aggData <- aggregate(data[2:3],
#'     by = list(group = data$group),
#'     FUN = eval(parse(text = aggFunctionString))
#'   )
#'   print(f)
#'   print(aggData)
#' }
#' @keywords internal
#' @noRd
naOmitFuncStr <- function(aggFunc) {
  str <- paste0("function(x) ", aggFunc, "(x,na.rm=TRUE)")
  return(str)
}
