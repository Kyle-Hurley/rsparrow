#' @title makeAESvector
#' @description Creates numeric vector of classes for legend.  \cr \cr
#' Executed By: diagnosticMaps.R \cr
#' @param mapdata data.frame of data for mapping
#' @param values numeric vector of legend breakpoint indexes
#' @param breaks numeric vector of breakpoints in data based on quantiles
#' @param include character string indicating how many breakpoints to include
#' in legend classes.  Default value of "all", options include "first", "last",
#' and "all"
#' @return numeric vector of classes for legend
#' 
#' @keywords internal
#' @noRd

makeAESvector<-function(mapdata, values, breaks,include = "all"){
  #first break
  if (include %in% c("all","first")){
    colData<-ifelse(mapdata$mapColumn<=breaks[1],values[1],NA)
  }else{
    colData<-rep(NA,nrow(mapdata))
  }
  for (k in 1:(length(breaks)-1)) {
    colData<-ifelse(mapdata$mapColumn > breaks[k] & mapdata$mapColumn <= breaks[k+1],
                    values[k+1],
                    colData)
  }
  #last break
  if (include %in% c("all","last")){
    colData<-ifelse(mapdata$mapColumn>breaks[(length(breaks)-1)],values[length(breaks)],colData)
  }
  return(colData)
}