#' @title getdindx
#' @description Creates a sequence of downstream indices based on the values in the two columns of the list
#'             index for the requested row. \cr \cr
#' Executed By: \itemize{\item hydseq.R
#'                      \item hydseqTerm.R} \cr
#' @param inrow number associated with upstream fnode
#' @param dnstream_list_index  data.frame of indexes by fnode for all flowlines immediately downstream of a
#'                            given fnode.
#' @return `out` numeric vector of downstream indexes
#' @keywords internal
#' @noRd


getdindx <- function(inrow, dnstream_list_index) {
  list_start <- dnstream_list_index[inrow, ]
  return(seq(list_start[, 1], list_start[, 2], 1))
}
