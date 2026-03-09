#' @title calcHeadflag
#' @description Calculates the system variable headflag (translated from SAS hydseq code) \\cr \\cr
#' Executed By: createVerifyReachAttr.R \\cr
#' Executes Routines: \\itemize\{\\item getVarList.R
#'             \} \\cr
#' @param data1 input data (data1)
#' @return `outdata`  data.frame with waterid and headflag identifying the upstream reach head
#' @keywords internal
#' @noRd



calcHeadflag <- function(data1) {
  # extract required navigation variables from data1
  tnode <- data1$tnode
  fnode <- data1$fnode

  # create sequence variable
  SEQ <- data.frame(seqvar = seq(1, nrow(data1), 1))
  # add seqvar to tnode and fnode
  tnode <- as.data.frame(cbind(SEQ, tnode))
  fnode <- as.data.frame(cbind(SEQ, fnode))

  # sort data
  tnode <- tnode[order(tnode$tnode), ]
  fnode <- fnode[order(fnode$fnode), ]

  # save rownumbers
  fnode$Row <- seq(1, nrow(fnode), 1)
  tnode$Row <- seq(1, nrow(tnode), 1)

  fnode <- data.frame(fnode = unique(fnode$fnode))

  # save as headwaterflag in data1
  ifhead <- na.omit(fnode[which(!tnode$tnode %in% fnode$fnode), ])
  data1$headflag <- ifelse(data1$fnode %in% ifhead, 1, 0)

  outdata <- data1[, which(names(data1) %in% c("waterid", "headflag"))]
  return(outdata)
} # end function
