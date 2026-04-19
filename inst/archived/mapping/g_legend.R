#' @title g_legend
#' @description extracts legend object from ggplot object  \cr \cr
#' Executed By: mapLoopStr.R \cr
#' @param a.gplot ggplot object with legend
#' @return `legend` ggplot legen object
#' @keywords internal
#' @noRd


g_legend <- function(a.gplot) {
  tmp <- ggplot_gtable(ggplot_build(a.gplot))
  leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
  if (length(leg) == 0) {
    legend <- NULL
  } else {
    legend <- tmp$grobs[[leg]]
  }
  return(legend)
}
