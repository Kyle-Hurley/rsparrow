#' @title predictSensitivity
#' @description Supports the calculation of parameter sensitivities, executed by the
#'            'diagnosticSensitivity' function, by calculating the unconditioned predictions for an individual parameter. \cr \cr
#' Executed By: diagnosticSensitivity.R \cr
#' Executes Routines: \itemize{\item ptnoder.for} \cr
#' @param AEstimate parameter estimates (original or adjusted by 1 percent)
#' @param estimate.list list output from `estimate.R`
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list'
#'                       for optimization
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param subdata data.frame input data (subdata)
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @return `pload_total` numeric vector of non-adjusted total load
#' @keywords internal
#' @noRd



predictSensitivity <- function(AEstimate, estimate.list, DataMatrix.list, SelParmValues,
                               subdata, dlvdsgn) {
  #################################################



  data <- DataMatrix.list$data

  # Extract estimation results
  oEstimate <- estimate.list$JacobResults$oEstimate
  Parmnames <- estimate.list$JacobResults$Parmnames

  # Extract data index list
  data.index.list <- DataMatrix.list$data.index.list
  

  # Setup variables for prediction

  nreach <- length(data[, 1])
  numsites <- sum(ifelse(data[, 10] > 0, 1, 0)) # data.index.list$jdepvar site load index

  # transfer estimated parameters into complete parameter vector (inclusive of non-estimated constants)
  # values are perturbed in subsequent function calls in sensitivity analysis
  betalst <- AEstimate

  # Load the parameter estimates to BETA1
  beta1 <- t(matrix(betalst, ncol = nreach, nrow = length(oEstimate)))

  # setup for REACH decay
  jjdec <- length(data.index.list$jdecvar)
  if (sum(data.index.list$jdecvar) > 0) {
    rchdcayf <- matrix(1, nrow = nreach, ncol = 1)
    for (i in 1:jjdec) {
      rchdcayf[, 1] <- rchdcayf[, 1] * exp(-data[, data.index.list$jdecvar[i]] * beta1[, data.index.list$jbdecvar[i]])
    }
  } else {
    rchdcayf <- matrix(1, nrow = nreach, ncol = 1)
  }

  # setup for RESERVOIR decay
  jjres <- length(data.index.list$jresvar)
  if (sum(data.index.list$jresvar) > 0) {
    resdcayf <- matrix(1, nrow = nreach, ncol = 1)
    for (i in 1:jjres) {
      resdcayf[, 1] <- resdcayf[, 1] * (1 / (1 + data[, data.index.list$jresvar[i]] * beta1[, data.index.list$jbresvar[i]]))
    }
  } else {
    resdcayf <- matrix(1, nrow = nreach, ncol = 1)
  }

  # Setup for SOURCE DELIVERY # (nreach X nsources)
  jjdlv <- length(data.index.list$jdlvvar)
  jjsrc <- length(data.index.list$jsrcvar)

  ddliv1 <- matrix(0, nrow = nreach, ncol = jjdlv)
  if (sum(data.index.list$jdlvvar) > 0) {
    for (i in 1:jjdlv) {
      ddliv1[, i] <- (beta1[, data.index.list$jbdlvvar[i]] * data[, data.index.list$jdlvvar[i]])
    }
    ddliv2 <- matrix(0, nrow = nreach, ncol = jjsrc)
    ddliv2 <- exp(ddliv1 %*% t(dlvdsgn)) # "exp(ddliv1 %*% t(dlvdsgn))"
  } else {
    ddliv2 <- matrix(1, nrow = nreach, ncol = jjsrc) # change ncol from =1 to =jjsrc to avoid non-conformity error (2-19-2013)
  }

  # Setup for SOURCE
  ddliv3 <- (ddliv2 * data[, data.index.list$jsrcvar]) * beta1[, data.index.list$jbsrcvar]
  if (sum(data.index.list$jsrcvar) > 0) {
    dddliv <- matrix(0, nrow = nreach, ncol = 1)
    for (i in 1:jjsrc) {
      dddliv[, 1] <- dddliv[, 1] + ddliv3[, i]
    }
  } else {
    dddliv <- matrix(1, nrow = nreach, ncol = 1)
  }

  ####################################################
  # incremental delivered load for decayed and nondecayed portions

  incdecay <- rchdcayf**0.5 * resdcayf # incremental reach and reservoir decay
  totdecay <- rchdcayf * resdcayf # total reach and reservoir decay

  incddsrc <- rchdcayf**0.5 * resdcayf * dddliv
  incddsrc_nd <- dddliv

  # Compute the reach transport factor
  carryf <- data[, data.index.list$jfrac] * rchdcayf * resdcayf
  carryf_nd <- data[, data.index.list$jfrac]

  ####################################################
  # Store the incremental loads for total and sources

  pload_inc <- as.vector(dddliv) # create incremental load variable

  srclist_inc <- character(length(data.index.list$jsrcvar))

  for (j in 1:length(data.index.list$jsrcvar)) {
    ddliv <- as.matrix((ddliv2[, j] * data[, data.index.list$jsrcvar[j]]) * beta1[, data.index.list$jbsrcvar[j]])
    assign(paste0("pload_inc_", Parmnames[j]), as.vector(ddliv)) # create variable 'pload_inc_(source name)'
    srclist_inc[j] <- paste0("pload_inc_", Parmnames[j])
  }

  ####################################################
  # Store the total decayed and nondecayed loads

  nnode <- max(data[, data.index.list$jtnode], data[, data.index.list$jfnode])
  ee <- matrix(0, nrow = nreach, ncol = 1)
  pred <- matrix(0, nrow = nreach, ncol = 1)

  i_obs <- 1

  data2 <- matrix(0, nrow = nreach, ncol = 4)
  data2[, 1] <- data[, data.index.list$jfnode]
  data2[, 2] <- data[, data.index.list$jtnode]
  data2[, 3] <- data[, data.index.list$jdepvar]
  data2[, 4] <- data[, data.index.list$jiftran]


  # Total decayed load (no monitoring adjustment)

  incddsrc <- ifelse(is.na(incddsrc), 0, incddsrc)
  carryf <- ifelse(is.na(carryf), 0, carryf)
  ifadjust <- 0 # no monitoring load adjustment

  # accumulate loads
  return_data <- .Fortran("ptnoder",
    ifadjust = as.integer(ifadjust),
    nreach = as.integer(nreach),
    nnode = as.integer(nnode),
    data2 = as.double(data2),
    incddsrc = as.double(incddsrc),
    carryf = as.double(carryf),
    ee = as.double(ee), PACKAGE = "rsparrow"
  )
  pred <- return_data$ee

  pload_total <- pred # nonadjusted total load



  return(pload_total)
} # end function
