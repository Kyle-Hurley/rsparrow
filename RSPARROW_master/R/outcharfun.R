#' @title outcharfun
#' @description output character string as data.frame for good text file formatting. \cr \cr
#' Executed By: \itemize{\item correlationMatrix.R
#'             \item diagnosticSpatialAutoCorr.R
#'             \item estimateNLLStable.R
#'             \item modelCompare.R} \cr
#' @param char character string to convert to data.frame for text output
#' @return `outchar`  data.frame containing `char` for printing to *.txt file
#' @keywords internal
#' @noRd

outcharfun <- function(char) {
  outchar <- data.frame(char)
  row.names(outchar) <- c(" ")
  colnames(outchar) <- c(" ")
  return(outchar)
}
