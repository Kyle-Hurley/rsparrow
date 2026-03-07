#' @title getuindx
#' @description Creates a sequence of upstream indices based on the values in the two columns of the list
#'             index for the requested row. \cr \cr
#' Executed By: \itemize{\item hydseq.R
#'                      \item hydseqTerm.R} \cr
#' @param inrow number associated with upstream fnode
#' @param upstream_list_index  data.frame of indexes by fnode for all flowlines immediately upstream of a
#'                            given fnode.
#' @return `out` numeric vector of upstream indexes
#' @keywords internal
#' @noRd


getuindx <- function(inrow, upstream_list_index) {
  list_start <- upstream_list_index[inrow, ]
  if (nrow(na.omit(list_start)) == 0) {
    out <- NA
  } else {
    out <- seq(list_start[, 1], list_start[, 2], 1)
  }
  return(out)
}
