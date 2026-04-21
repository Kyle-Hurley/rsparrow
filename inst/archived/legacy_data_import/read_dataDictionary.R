# Archived in Plan 13: replaced by in-memory API (rsparrow_model() data-frame arguments)
#' @title read_dataDictionary
#' @description Reads the 'dataDictionary.csv' file. \cr \cr
#' Executed By: dataInputPrep.R \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @return `data_names` data.frame of variable metadata from data_Dictionary.csv file
#' @keywords internal
#' @noRd

read_dataDictionary <- function(file.output.list) {
  path <- file.output.list$path_results
  csv_columnSeparator <- file.output.list$csv_columnSeparator
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator

  filein <- paste0(path, file.output.list$run_id, "_dataDictionary.csv")
  Ctype <- c("character", "character", "character", "character", "character")
  NAMES <- c("varType", "sparrowNames", "data1UserNames", "varunits", "explanation")

  # import dataDictionary
  data_names <- data.table::fread(file = filein, sep = csv_columnSeparator,
    dec = csv_decimalSeparator, header = TRUE, colClasses = Ctype)
  data_names <- data_names[apply(data_names, 1, function(x) any(!is.na(x))), ]
  names(data_names) <- NAMES
  data_names <- as.data.frame(data_names)


  # trim whitespaces
  data_names$sparrowNames <- trimws(data_names$sparrowNames, which = "both")
  data_names$data1UserNames <- trimws(data_names$data1UserNames, which = "both")
  # make fixed and required names lowercase
  data_names$sparrowNames <- ifelse(tolower(data_names$sparrowNames) %in% as.character(getVarList()$varList), tolower(data_names$sparrowNames), data_names$sparrowNames)

  blankSparrow <- data_names[which(is.na(data_names$sparrowNames) | data_names$sparrowNames == ""), ]
  if (nrow(blankSparrow) != 0) {
    message(" \nsparrowName is BLANK in data dictionary at row(s) : ", paste(rownames(blankSparrow), collapse = ", "), ".  These rows have been removed.")
  }

  data_names <- data_names[which(!is.na(data_names$sparrowNames) & data_names$sparrowNames != ""), ]
  # remove exact duplicates
  data_names <- data_names[!duplicated(data_names), ]

  # test if add_vars in data_names
  add_vars <- file.output.list$add_vars
  if (!identical(NA, add_vars)) {
    if (any(!add_vars %in% data_names$sparrowNames)) {
      message(paste0("WARNING: add_vars MISSING FROM dataDictionary sparrowNames : ", paste(add_vars[which(!add_vars %in% data_names$sparrowNames)], collapse = ","), "\n \n"))
      add_vars <- add_vars[which(add_vars %in% data_names$sparrowNames)]
    }
  }


  return(data_names)
} # end function
