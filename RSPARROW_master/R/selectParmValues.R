#' @title selectParmValues
#' @description Creates the 'SelParmValues' object with the user-selected parameter attributes
#'            and performs consistency checks on the initial, minimum, and maximum values of the parameters.  \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item named.list.R} \cr
#' @param df betavalues - list of parameters from parameters.csv
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating
#'       whether estimation should be run in simulation mode only.
#' @return `SelParmValues` named list of selected parameters from parameters.csv using condition
#'            `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" & parmMin>=0) | parmType!="SOURCE")`
#' \tabular{ll}{
#' `sparrowNames` \tab character vector of sparrowNames from parameters.csv where selection criteria is met \cr
#' `bcols` \tab number of parameters where selection criteria is met \cr
#' `beta0` \tab numeric vector corresponding to parmInit from parameters.csv where selection criteria is met \cr
#' `betamin` \tab numeric vector corresponding to parmMin from parameters.csv where selection criteria is met \cr
#' `betamax` \tab numeric vector corresponding to parmMax from parameters.csv where selection criteria is met \cr
#' `betatype` \tab character vector corresponding to parmType from parameters.csv where selection criteria is met \cr
#' `pselect` \tab numeric binary vector where 1 indicates selection criteria met and 0 indicates parameter discarded \cr
#' `betaconstant` \tab numeric binary vector corresponding to parmConstant from parameters.csv where 1 indicates
#' parameter is to be held constant where selection criteria is met \cr
#' `bsrcconstant` \tab numeric binary vector where 1 indicates `betaconstant=1 & betatype="SOURCE"` where selection
#' criteria is met \cr
#' `bCorrGroup` \tab numeric binary vector corresponding to parmCorrGroup from parameters.csv where selection criteria
#' is met \cr
#' `srcvar` \tab character vector of `sparrowNames` where `betatype="SOURCE"`
#' `dlvvar` \tab character vector of `sparrowNames` where `betatype="DELIVF"`
#' `decvar` \tab character vector of `sparrowNames` where `betatype="STRM"`
#' `resvar` \tab character vector of `sparrowNames` where `betatype="RESV"`
#' `othervar` \tab character vector of `sparrowNames` where `betatype="OTHER"`
#' }
#'
#' @keywords internal
#' @noRd



selectParmValues <- function(df, if_estimate, if_estimate_simulation) {
  pselect <- ifelse(df$parmConstant == 1 | (df$parmMax > 0 | (df$parmType == "DELIVF" & df$parmMax >= 0)) &
    (df$parmMin < df$parmMax) &
    ((df$parmType == "SOURCE" & df$parmMin >= 0) | df$parmType != "SOURCE"),
  1, 0
  ) # identify selected variables
  srcselect <- ifelse(df$parmType == "SOURCE" & pselect == 1, 1, 0)
  dlvselect <- ifelse(df$parmType == "DELIVF" & pselect == 1, 1, 0)
  decselect <- ifelse(df$parmType == "STRM" & pselect == 1, 1, 0)
  resselect <- ifelse(df$parmType == "RESV" & pselect == 1, 1, 0)
  otherselect <- ifelse(df$parmType == "OTHER" & pselect == 1, 1, 0)
  bcols <- sum(pselect)

  # transfer parameters for selected variables
  beta0 <- df$parmInit[pselect == 1]
  betamin <- df$parmMin[pselect == 1]
  betamax <- df$parmMax[pselect == 1]
  betatype <- df$parmType[pselect == 1]
  betaconstant <- df$parmConstant[pselect == 1]
  bsrcconstant <- df$parmConstant[df$parmType == "SOURCE" & pselect == 1]
  bCorrGroup <- df$parmCorrGroup[pselect == 1]
  sparrowNames <- df$sparrowNames[pselect == 1]

  srcvar <- df$sparrowNames[srcselect == 1]
  dlvvar <- df$sparrowNames[dlvselect == 1]
  decvar <- df$sparrowNames[decselect == 1]
  resvar <- df$sparrowNames[resselect == 1]
  othervar <- df$sparrowNames[otherselect == 1]

  SelParmValues <- named.list(
    sparrowNames, bcols, beta0, betamin, betamax, betatype, pselect,
    betaconstant, bsrcconstant, bCorrGroup,
    srcvar, dlvvar, decvar, resvar, othervar
  )

  # checks on parameter values

  npar <- bcols - (sum(betaconstant))
  if (length(betamin) != bcols) {
    # wrong length lower
    if (if_estimate == "yes" | if_estimate_simulation == "yes") {
      message("INVALID NUMBER OF parmMin VALUES FOUND IN PARAMETERS FILE.\nNUMBER OF parmMin VALUES MUST EQUAL NUMBER OF PARAMETERS SELECTED\nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")
      stop("Error in selectParmValues.R. Run execution terminated.")
    }
  }
  if (length(betamax) != bcols) {
    # wrong length upper
    if (if_estimate == "yes" | if_estimate_simulation == "yes") {
      message("INVALID NUMBER OF parmMax VALUES FOUND IN PARAMETERS FILE.\nNUMBER OF parmMax VALUES MUST EQUAL NUMBER OF PARAMETERS SELECTED\nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")
      stop("Error in selectParmValues.R. Run execution terminated.")
    }
  }
  if (any(beta0 < betamin)) {
    # bad start too small
    if (if_estimate == "yes" | if_estimate_simulation == "yes") {
      message("INVALID parmInit VALUES FOUND IN PARAMETERS FILE.\nparmInit MUST SATISFY parmInit>=parmMin \nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")
      stop("Error in selectParmValues.R. Run execution terminated.")
    }
  }
  if (any(beta0 > betamax)) {
    # bad start too big
    if (if_estimate == "yes" | if_estimate_simulation == "yes") {
      message("INVALID parmInit VALUES FOUND IN PARAMETERS FILE.\nparmInit MUST SATISFY parmInit<=parmMax \nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")
      stop("Error in selectParmValues.R. Run execution terminated.")
    }
  }




  if (any(betamin > betamax)) {
    # min>max
    if (if_estimate == "yes" | if_estimate_simulation == "yes") {
      message("INVALID parmMin/parmMax VALUES FOUND IN PARAMETERS FILE.\nparmMin MUST BE LESS THAN parmMax\nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")
      stop("Error in selectParmValues.R. Run execution terminated.")
    }
  }
  if (all(beta0 == 0)) {
    # parmInit == 0
    if (if_estimate == "yes" | if_estimate_simulation == "yes") {
      message("INVALID parmInit VALUES FOUND IN PARAMETERS FILE.\nparmInit MUST NOT EQUAL ZERO FOR SELECTED PARAMETERS\nEDIT PARAMETERS FILE TO RUN ESTIMATION\nRUN EXECUTION TERMINATED.")
      stop("Error in selectParmValues.R. Run execution terminated.")
    }
  }


  return(SelParmValues)
} # end function
