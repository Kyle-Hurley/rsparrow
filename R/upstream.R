#' @title upstream
#' @description Creates sequential ids for all flowlines immediately upstream of all ids in the stack
#' group that also meet the condition that every flowline downstream of stack flowlines fromnode has
#' an assigned hydrosequence value and have not previously been processed.\cr \cr
#' Executed By: \itemize{\item hydseq.R
#'                      \item hydseqTerm.R} \cr
#' Executes Routines: \itemize{\item getdindx.R
#'                             \item getuindx.R} \cr
#' @param group numeric vector defining the stack of flowlines conditionally selected to
#'              receive sequential hydrosequence numbers initially vector of terminal reach indices
#'              should be used.
#' @param ifproc fnode-referenced vector to track if the flowlines upstream of a given fnode have
#'               already been processed by assignment of hydrosequence values. Initially a vector
#'               of NA with length equal to length(fnode) should be used.
#' @param fnode  numeric vector of reach from (upstream) nodes
#' @param dnstream_list numeric vector of flowline sequence numbers downstream of a given `fnode`,
#'                      structured by fnode via the index `dnstream_list_index`
#' @param upstream_list numeric vector of flowline sequence numbers upstream of a given `fnode`,
#'                      structured by fnode via the index `upstream_list_index`
#' @param upstream_list_index data.frame containing a sequence of upstream indices based on the
#'                            values in the two columns of the list index for the requested row.
#' @param dnstream_list_index data.frame containing a sequence of downstream indices based on the
#'                            values in the two columns of the list index for the requested row.
#' @return `upgroup` numeric vector of sequential ids for all flowlines immediately upstream of
#'                   all ids in the stack
#' @keywords internal
#' @noRd



upstream <- function(group, hydseqvar, ifproc, fnode, dnstream_list, upstream_list, upstream_list_index, dnstream_list_index) {
  upgroup <- vector("numeric")
  for (i in 1:length(group)) {
    # get upstream and dnstream indexes
    ulist_subset <- getuindx(fnode[group[i]], upstream_list_index)
    dlist_subset <- dnstream_list[getdindx(fnode[group[i]], dnstream_list_index)]

    # If all reaches downstream of fnode have hydseg then get list of
    # reaches upstream of fnode to be added to upstream group
    if (length(na.omit(ulist_subset)) != 0 & !any(is.na(hydseqvar[dlist_subset])) & is.na(ifproc[fnode[group[i]]])) {
      # mark as processed
      ifproc[fnode[group[i]]] <- 1
      # save in upgroup
      upgroup <- c(upgroup, upstream_list[ulist_subset])
    } # end if (!is.na(ulist_subset) & ...
  } # for i
  list(upgroup = upgroup, ifproc = ifproc)
} # end upstream
