#' @title checkFileEncoding
#' @description determine most likely file encoding for data1.csv input file using
#' `stringi::stri_enc_detect` \cr \cr
#' @param con a connection or a file path
#' @return message with table of most likely encodings
#' @examples
#' path_data <- tempdir()
#' data1 <- data.frame(
#'   waterid = c(123454, 23456, 234566),
#'   rchname = stringi::stri_encode(c("r1", "r2", "r3"), to = "UTF-8")
#' )
#' filedata1 <- paste0(path_data, .Platform$file.sep, "data1.csv")
#' con <- file(filedata1, encoding = "UTF-8")
#' write.table(data1, file = filedata1, fileEncoding = "UTF-8")
#' checkFileEncoding(con)
#' @keywords internal
#' @noRd
checkFileEncoding <- function(con) {
  # determine file encoding
  f <- rawToChar(readBin(con, "raw", 1000000))
  encodeTable <- as.data.frame(stringi::stri_enc_detect(f)[[1]])

  # get highest confidence encoding
  bestEnc <- encodeTable[[1, 1]]
  message(paste0(
    "data1.csv input file most likely file encoding has been determined to be ", bestEnc,
    "\n", "alternate file encodings include \n"))
  print(encodeTable)
  
}
