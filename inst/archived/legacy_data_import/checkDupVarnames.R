#' @title checkDupVarnames
#' @description Checks for duplicate `sparrowNames` in the dataDictionary.csv file and outputs
#'            list of duplicates as message in console window \cr \cr
#' Executed By: dataInputPrep.R \cr
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @keywords internal
#' @noRd



checkDupVarnames <- function(data_names) {
  # test for duplicate sparrowNames


  dupSparrow <- data_names$sparrowNames[duplicated(data_names$sparrowNames)]
  msgDupSparrow <- ""
  if (length(dupSparrow) != 0) {
    for (i in dupSparrow) {
      message(paste("Duplicate sparrowNames found : ", i, sep = "\n"))
    }
  }
  # test for duplicate data1UserNames
  msgDupUserNames <- ""
  dupUserNames <- data_names$data1UserNames[duplicated(data_names$data1UserNames)]
  dupUserNames <- dupUserNames[which(!is.na(dupUserNames))]
  if (length(dupUserNames) != 0) {
    for (i in dupUserNames) {
      message(paste("Duplicate data1UserNames found : ", i, sep = "\n"))
    }
  }
} # end function
