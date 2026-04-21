# Archived Plan 16 (Function Audit): 0 active callers in R/.
# Both listed callers (applyUserModify.R → archived Plan 13; mapSiteAttributes.R → archived Plan 09)
# are no longer in active R/. eval(parse(envir=parent.frame())) antipattern was never fixed.

# TODO Plan 05 — parent.frame() injection antipattern (same as unPackList). Only active caller
#   is applyUserModify.R (inside dynamic function string, also TODO Plan 05).
#' @title replaceNAs
#' @description Replaces all NAs with 0's. Output is saved to parent.frame(). \cr \cr
#' Executed By: \itemize{\item applyUserModify.R
#'             \item mapSiteAttributes.R} \cr
#' @param listColumns a named list of variables in which to replace NAs.
#' @keywords internal
#' @noRd



replaceNAs <- function(listColumns) {
  columnNames <- names(listColumns)
  for (i in 1:length(columnNames)) {
    dname <- paste0(columnNames[i], "<-ifelse(is.na(", columnNames[i], "),0,", columnNames[i], ")")
    eval(parse(text = dname), envir = parent.frame())
  }
}
