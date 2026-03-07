#' @title createDataMatrix
#' @description Creates the R `DataMatrix.list` object, containing five data elements that are
#'            used to estimate the model and produce model predictions. \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             \item named.list.R
#'             } \cr
#' @param if_mean_adjust_delivery_vars yes/no character string indicating if the delivery
#'       variables are to be mean adjusted from sparrow_control
#' @param subdata data.frame input data (subdata)
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param betavalues data.frame of model parameters from parameters.csv
#' @return `DataMatrix.list`  named list containing
#' \tabular{ll}{
#' `dataNames` \tab character vector of names associated with columns in `data` including
#'                  `c("waterid","staid","fnode","tnode","frac","iftran","target",
#'                   "demtarea","demiarea","depvar","hydseq","meanq","calsites")` and
#'                   `sparrowNames` from parameters.csv \cr
#' `betaNames` \tab character vector of `sparrowNames` from parameters.csv \cr
#' `data` \tab matrix with columns from `dataNames` and data sourced from `subdata` \cr
#' `beta` \tab matrix defined with `ncol=SelParmValues$bcols` and `nrow=nrow(subdata))`
#'             containing values from `SelParmValues$beta0`
#' `data.index.list` \tab list of
#' \tabular{ll}{`jwaterid` \tab SPARROW Reach Identifier \cr
#' `jstaid` \tab SPARROW Monitoring Station Identifier \cr
#' `jfnode` \tab Upstream Reach Node Identifier \cr
#' `jtnode` \tab Downstream Reach Node Identifier \cr
#' `jfrac` \tab Fraction Upstream Flux Diverted to Reach \cr
#' `jiftran` \tab If Reach Transmits Flux (1=yes, 0=no) \cr
#' `jtarget` \tab Downstream target reach \cr
#' `jtotarea` \tab Total upstream drainage area (km2) \cr
#' `jiarea` \tab Incremental reach drainage area (km2) \cr
#' `jdepvar` \tab Dependent variable load (kg/yr) \cr
#' `jhydseq` \tab SPARROW Reach Hydrologic Sequencing Code \cr
#' `jmean_flow` \tab Mean flow (cfs) \cr
#' `jcalsites` \tab Calibration site index \cr
#' }
#' }
#' @keywords internal
#' @noRd


createDataMatrix <- function(if_mean_adjust_delivery_vars, subdata, SelParmValues, betavalues) {
  # setup the 12 required variables
  datalst <- as.character(getVarList()$matrixlst)

  #########################################################
  # extract SelParmValues elements
  pselect <- SelParmValues$pselect
  srcvar <- SelParmValues$srcvar
  dlvvar <- SelParmValues$dlvvar
  decvar <- SelParmValues$decvar
  resvar <- SelParmValues$resvar
  othervar <- SelParmValues$othervar
  beta0 <- SelParmValues$beta0
  bcols <- SelParmValues$bcols

  #########################################################
  # setup index values for DATA matrix by name

  jwaterid <- which(datalst %in% "waterid") # SPARROW Reach Identifier
  jstaid <- which(datalst %in% "staid") # SPARROW Monitoring Station Identifier
  jfnode <- which(datalst %in% "fnode") # Upstream Reach Node Identifier
  jtnode <- which(datalst %in% "tnode") # Downstream Reach Node Identifier
  jfrac <- which(datalst %in% "frac") # Fraction Upstream Flux Diverted to Reach
  jiftran <- which(datalst %in% "iftran") # If Reach Transmits Flux (1=yes, 0=no)
  jtarget <- which(datalst %in% "target") # Downstream target reach
  jtotarea <- which(datalst %in% "demtarea") # Total upstream drainage area (km2)
  jiarea <- which(datalst %in% "demiarea") # Incremental reach drainage area (km2)
  jdepvar <- which(datalst %in% "depvar") # Dependent variable load (kg/yr)
  jhydseq <- which(datalst %in% "hydseq") # SPARROW Reach Hydrologic Sequencing Code
  jmean_flow <- which(datalst %in% "meanq") # Mean flow (cfs)
  jcalsites <- which(datalst %in% "calsites") # Calibration site index

  ivar <- 13 # number of required network variables

  # pselect created in 'selectParmValues.R'
  srcselect <- ifelse(betavalues$parmType == "SOURCE" & pselect == 1, 1, 0)
  dlvselect <- ifelse(betavalues$parmType == "DELIVF" & pselect == 1, 1, 0)
  decselect <- ifelse(betavalues$parmType == "STRM" & pselect == 1, 1, 0)
  resselect <- ifelse(betavalues$parmType == "RESV" & pselect == 1, 1, 0)
  otherselect <- ifelse(betavalues$parmType == "OTHER" & pselect == 1, 1, 0)

  # set index values for variable types selected
  if (sum(srcselect) > 0) {
    jbsrcvar <- rep(1:sum(srcselect), 1)
    jsrcvar <- jbsrcvar + ivar
  } else {
    jbsrcvar <- 0
    jsrcvar <- 0
  }
  if (sum(dlvselect) > 0) {
    jbdlvvar <- rep(max(jbsrcvar) + 1:sum(dlvselect), 1)
    jdlvvar <- jbdlvvar + ivar
  } else {
    jbdlvvar <- 0
    jdlvvar <- 0
  }
  if (sum(decselect) > 0) {
    jbdecvar <- rep((max(jbsrcvar) + sum(dlvselect)) + 1:sum(decselect), 1)
    jdecvar <- jbdecvar + ivar
  } else {
    jbdecvar <- 0
    jdecvar <- 0
  }
  if (sum(resselect) > 0) {
    jbresvar <- rep((max(jbsrcvar) + sum(dlvselect) + sum(decselect)) + 1:sum(resselect), 1)
    jresvar <- jbresvar + ivar
  } else {
    jbresvar <- 0
    jresvar <- 0
  }

  if (sum(otherselect) > 0) {
    jbothervar <- rep((max(jbsrcvar) + sum(dlvselect) + sum(decselect) + sum(resselect)) + 1:sum(otherselect), 1)
    jothervar <- jbothervar + ivar
  } else {
    jbothervar <- 0
    jothervar <- 0
  }

  data.index.list <- named.list(
    jwaterid, jstaid, jfnode, jtnode, jfrac, jiftran, jtarget,
    jtotarea, jiarea, jdepvar, jhydseq, jmean_flow,
    jsrcvar, jdlvvar, jdecvar, jresvar, jothervar,
    jbsrcvar, jbdlvvar, jbdecvar, jbresvar, jbothervar
  )

  ######################################################
  # transfer data from vectors to 'DATA' matrix
  ncols <- ivar + bcols
  nreaches <- nrow(subdata)
  data <- matrix(1:nreaches, ncol = ncols, nrow = nreaches)

  dataNames <- c(
    "waterid", "staid", "fnode", "tnode", "frac", "iftran", "target",
    "demtarea", "demiarea", "depvar", "hydseq", "meanq", "calsites"
  )

  for (i in 1:ivar) {
    data[, i] <- subdata[[datalst[i]]] # transfer required 12 variables to data
  }


  # transfer source variables
  dataNames <- c(dataNames, srcvar)
  betaNames <- srcvar

  iend <- ivar + length(srcvar)
  j <- 0
  for (i in (ivar + 1):iend) {
    j <- j + 1
    data[, i] <- subdata[[srcvar[j]]]
  }

  # transfer delivery variables
  if (max(jdlvvar) != 0) {
    dataNames <- c(dataNames, dlvvar)
    betaNames <- c(betaNames, dlvvar)
    ibeg <- ivar + length(srcvar) + 1
    iend <- ivar + length(srcvar) + length(dlvvar)
    j <- 0
    for (i in ibeg:iend) {
      j <- j + 1
      if (if_mean_adjust_delivery_vars == "yes") {
        data[, i] <- subdata[[dlvvar[j]]] - mean(subdata[[dlvvar[j]]])
      } else {
        data[, i] <- subdata[[dlvvar[j]]]
      }
    }
  } # end length check

  # transfer reach decay variables
  if (max(jdecvar) != 0) {
    dataNames <- c(dataNames, decvar)
    betaNames <- c(betaNames, decvar)
    ibeg <- ivar + length(srcvar) + length(dlvvar) + 1
    iend <- ivar + length(srcvar) + length(dlvvar) + length(decvar)
    j <- 0
    for (i in ibeg:iend) {
      j <- j + 1
      data[, i] <- subdata[[decvar[j]]]
    }
  } # end length check

  # transfer reservoir decay variables
  if (max(jresvar) != 0) {
    dataNames <- c(dataNames, resvar)
    betaNames <- c(betaNames, resvar)
    ibeg <- ivar + length(srcvar) + length(dlvvar) + length(decvar) + 1
    iend <- ivar + length(srcvar) + length(dlvvar) + length(decvar) + length(resvar)
    j <- 0
    for (i in ibeg:iend) {
      j <- j + 1
      data[, i] <- subdata[[resvar[j]]]
    }
  } # end length check

  # transfer other variables
  if (max(jothervar) != 0) {
    dataNames <- c(dataNames, othervar)
    betaNames <- c(betaNames, othervar)
    ibeg <- ivar + length(srcvar) + length(dlvvar) + length(decvar) + length(resvar) + 1
    iend <- ivar + length(srcvar) + length(dlvvar) + length(decvar) + length(resvar) + length(othervar)
    j <- 0
    for (i in ibeg:iend) {
      j <- j + 1
      data[, i] <- subdata[[othervar[j]]]
    }
  } # end length check


  beta <- matrix(1:nreaches, ncol = bcols, nrow = nreaches)
  for (i in 1:bcols) {
    beta[, i] <- beta0[i]
  }

  DataMatrix.list <- named.list(dataNames, betaNames, data, beta, data.index.list)


  return(DataMatrix.list)
} # end function
