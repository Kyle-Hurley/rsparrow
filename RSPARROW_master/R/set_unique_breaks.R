#' @title set_unique_breaks
#' @description Creates mapping color breakpoints based on data quantiles.  \cr \cr
#' Executed By: \itemize{\item checkDrainageareaMapPrep.R
#'             \item checkDrainageareaMapPrep_static.R
#'             \item mapBreaks.R} \cr
#' @param x mapping variable as vector
#' @param ip number of breakpoints to attempt
#' @param rp vector of constants found in data quantiles to be removed, default `numeric(0)`
#'           if NA constants not removed.
#' @return named.list including
#' \tabular{ll}{
#' `ip` \tab number of breakpoints created
#' to `map_years` and `map_seasons` \cr
#' `chk1` \tab numeric vector of breakpoints in data based on quantiles
#' }
#' @keywords internal
#' @noRd


set_unique_breaks <- function(x, ip, rp = NA) {
  # link MAPCOLORS for variable to shape object (https://gist.github.com/mbacou/5880859)
  chk1 <- quantile(x, probs = 0:ip / ip)
  chk <- unique(quantile(x, probs = 0:ip / ip)) # define quartiles

  if (length(rp)!=0){
    if (is.na(rp)){
      removeConstants<-FALSE
    }else{
      removeConstants<-TRUE
    }
  }else{
      removeConstants<-TRUE
  }
  
  if (removeConstants){#remove constants
  constChk <- plyr::count(chk1)
  constChk <- constChk[which(constChk$freq != 1), ]

  if (nrow(constChk) != 0) { # if constants exist in quantiles
    removeConst <- constChk[which(constChk$freq == max(constChk$freq)), ]$x
    x <- x[which(!x %in% removeConst)]
    ip <- ip - length(removeConst)
    rp <- c(rp, removeConst)
    Recall(x, ip, rp)
  } else {
    if (length(chk1) == length(chk)) {
      ip <- ip + length(rp)
      chk1 <- as.vector(chk1)
      chk1 <- sort(c(rp, chk1))

      return(named.list(ip, chk1))
    }


    ip <- ip - 1
    Recall(x, ip, rp)
  } # run the function again
  }else{
  # exit if the condition is met
  if (length(chk1) == length(chk)) return(named.list(ip, chk1))
  ip<-ip-1
  Recall(x,ip) # run the function again
  }
}
