#' @title mod_read_utf8
#' @description Function to test input data1 file for accepted RSPARROW file encoding UTF-8
#'              created by modifying the source code of xfun::read_utf8 Xie Y (2024). _xfun:
#'              Supporting Functions for Packages Maintained by 'Yihui Xie'_. R package version
#'              0.42, <https://CRAN.R-project.org/package=xfun>. \cr \cr
#' Executed By: readData.R \cr
#' Executes Routines: checkFileEncoding.R \cr
#' @param con a connection or a file path
#' @return vector of rows with non-UTF-8 characters
#' @examples
#' path_data <- tempdir()
#' data1 <- data.frame(
#'   waterid = c(123454, 23456, 234566),
#'   rchname = stringi::stri_encode(c("r1", "r2", "r3"), to = "UTF-8")
#' )
#' filedata1 <- paste0(path_data, .Platform$file.sep, "data1.csv")
#' con <- file(filedata1, encoding = "UTF-8")
#' write.table(data1, file = filedata1, fileEncoding = "UTF-8")
#' mod_read_utf8(con)
#' @keywords internal
#' @noRd

mod_read_utf8 <- function(con) {
  opts <- options(encoding = "native.enc")
  on.exit(options(opts), add = TRUE)
  x <- readLines(con, encoding = "UTF-8", warn = FALSE)
  i <- xfun:::invalid_utf8(x)
  n <- length(i)
  if (n > 0) {
    i <- sapply(i, function(x) x - 1)
    message(paste0(
      "The file ", con, " is not encoded in UTF-8.\n \n"),
      paste0("There are ", n, " rows with non-UTF-8 characters.\n"), 
      "These are the first 6 rows with invalid UTF-8 characters: \n",
      paste(head(i), collapse = ", "),"\n \n"
    )
    # check fileEncoding
    checkFileEncoding(con)
    
    message("\n \nRSPARROW input .csv files MUST have ONLY characters with valid UTF-8 encoding.  
            See Section 3.1 of the RPSARROW documentation for more details on file encoding.")
  }
  return(i)
}
