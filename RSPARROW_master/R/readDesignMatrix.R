#' @title readDesignMatrix
#' @description Reads the land-to-water and source interaction matrix in the
#'            'design_matrix.csv' file.  \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param betavalues data.frame of model parameters from parameters.csv
#' @return `dmatrixin` imported data.frame from design_matrix.csv
#' @keywords internal
#' @noRd



readDesignMatrix <- function(file.output.list, betavalues) {
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id
  csv_columnSeparator <- file.output.list$csv_columnSeparator
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator

  filed <- paste0(path_results, run_id, "_design_matrix.csv")

  # columns for DELIVF
  NAMES <- betavalues[which(betavalues$parmType == "DELIVF"), ]$sparrowNames

  # read file (design_matrix uses row.names to preserve SOURCE row labels)
  dmatrixin <- read.csv(filed, header = TRUE, row.names = 1,
    dec = csv_decimalSeparator, sep = csv_columnSeparator)
  dmatrixin <- as.data.frame(matrix(dmatrixin[apply(dmatrixin, 1, function(x) any(!is.na(x))), ],
    ncol = ncol(dmatrixin), nrow = nrow(dmatrixin),
    dimnames = list(rownames(dmatrixin), colnames(dmatrixin))))
  names(dmatrixin) <- NAMES

  # trim whitespaces
  rownames(dmatrixin) <- trimws(rownames(dmatrixin), which = "both")
  names(dmatrixin) <- trimws(names(dmatrixin), which = "both")
  # make fixed and required names lowercase
  rownames(dmatrixin) <- ifelse(tolower(rownames(dmatrixin)) %in% as.character(getVarList()$varList), tolower(rownames(dmatrixin)), rownames(dmatrixin))
  names(dmatrixin) <- ifelse(tolower(names(dmatrixin)) %in% as.character(getVarList()$varList), tolower(names(dmatrixin)), names(dmatrixin))

  # order according to parameters
  dmatrixin <- as.data.frame(matrix(dmatrixin[match(betavalues[which(betavalues$parmType == "SOURCE"), ]$sparrowNames, rownames(dmatrixin)), ],
    ncol = ncol(dmatrixin), nrow = nrow(dmatrixin), dimnames = list(rownames(dmatrixin), colnames(dmatrixin))
  ))
  dmatrixin <- as.data.frame(matrix(dmatrixin[, match(betavalues[which(betavalues$parmType == "DELIVF"), ]$sparrowNames, names(dmatrixin))],
    ncol = ncol(dmatrixin), nrow = nrow(dmatrixin), dimnames = list(rownames(dmatrixin), colnames(dmatrixin))
  ))


  return(dmatrixin)
} # end function
