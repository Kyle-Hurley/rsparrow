#' @title deliver
#' @description execute the Fortran deliv_fraction.dll to calculate a numeric vector containing
#'              the delivery fraction for all waterids. \cr \cr
#' Executed By: \itemize{\item predict.R
#'             \item predictBoot.R
#'             \item estimateNLLStable.R
#'             \item predictScenarios.R} \cr
#' @param nreach number of reaches for which delivery fraction should be calculated
#' @param waterid numeric vector of waterid for which delivery fraction should be calculated
#' @param nnode number indicating the max of `fnode` and `tnode`
#' @param data2 matrix containing `fnode`, `tnode`, `depvar` and `iftran`
#' @param incdecay numeric vector of incremental reach and reservoir decay
#' @param totdecay numeric vector of total reach and reservoir decay
#' @return `outchar`  data.frame containing `char` for printing to *.txt file
#' @keywords internal
#' @noRd


deliver <- function(nreach, waterid, nnode, data2, incdecay, totdecay) {
  sumatt <- matrix(0, nrow = nreach, ncol = 1)
  fsumatt <- matrix(0, nrow = nreach, ncol = 1)
  return_data <- .Fortran("deliv_fraction",
    numrchs = as.integer(nreach),
    waterid = as.integer(waterid),
    nnode = as.integer(nnode),
    data2 = as.double(data2),
    incdecay = as.double(incdecay),
    totdecay = as.double(totdecay),
    sumatt = as.double(sumatt), PACKAGE = "rsparrow"
  )
  fsumatt <- return_data$sumatt
  return(fsumatt)
} # end sumatts function
