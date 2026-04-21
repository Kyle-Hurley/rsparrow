# Archived in Plan 13: replaced by in-memory API (rsparrow_model() data-frame arguments)
#' @title readData
#' @description Reads the users input data (either .csv or binary format) \cr \cr
#' Executed By: \itemize{\item createInitialDataDictionary.R
#'             \item dataInputPrep.R} \cr
#' Executes Routines: \itemize{\item mod_read_utf8.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param input_data_fileName name of users data1 file
#' @return `data1` input data (data1 file)
#' @keywords internal
#' @noRd



readData <- function(file.output.list, input_data_fileName) {
  path_data <- file.output.list$path_data
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator <- file.output.list$csv_columnSeparator

  path <- path_data

  ptm <- proc.time()

  filedata1 <- paste0(path, input_data_fileName)



  if (regexpr(".csv", input_data_fileName) > 0) {
    # test file encoding for non-UTF-8 characters
    badRows <- mod_read_utf8(filedata1)

    if (length(badRows) > 0) {
      stop("Error in readData.R. Run execution terminated.")
    }
    data1 <- data.table::fread(filedata1,
      header = TRUE, stringsAsFactors = FALSE,
      dec = csv_decimalSeparator, sep = csv_columnSeparator
    )
    data1<-as.data.frame(data1)
    data1BinaryName <- gsub(".csv", "", input_data_fileName)
    save(data1, file = paste0(path_data, data1BinaryName))
  } else {
    load(filedata1)
  }


  message("head(data1)")
  print(head(data1))
  message("nrow(data1)")
  print(nrow(data1))
  message("Time elapsed during data import.")
  print(proc.time() - ptm)


  return(data1)
} # end function
