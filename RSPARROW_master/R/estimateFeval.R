#' @title estimateFeval
#' @description SPARROW NonLinear Least Squares (NLLS) function for optimizing the model fit to
#'            the observations for the calibration sites, based on use of conditioned predictions of load.
#'            The function accumulates loads in the reach network according to the user's model specification,
#'            making comparisons of the conditioned predictions of  load to the actual loads at monitored
#'            reaches to return a vector of weighted residuals (difference between the actual and predicted
#'            loads). When ifadjust=1 (default), monitoring load substitution is performed (conditioned);
#'            when ifadjust=0, no monitoring load substitution is performed (unconditioned).  \cr \cr
#' Executed By: \itemize{\item estimate.R
#'             \item estimateBootstraps.R
#'             \item estimateNLLSmetrics.R
#'             \item estimateOptimize.R
#'             \item validateFevalNoadj.R} \cr
#' Executes Routines: \itemize{\item tnoder.for} \cr
#' @param beta0 estimated parameters (no constants)
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list'
#'                       for optimization
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param Csites.weights.list regression weights as proportional to incremental area size
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#'                           NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @param ifadjust integer; 1L (default) for conditioned predictions (monitoring load
#'   substitution); 0L for unconditioned predictions (no monitoring adjustment, unit weights).
#' @return `e` vector of weighted residuals
#' @keywords internal
#' @noRd



estimateFeval <- function(beta0,
                          DataMatrix.list, SelParmValues, Csites.weights.list,
                          estimate.input.list, dlvdsgn, ifadjust = 1L) {
  # setup global variables in function environment
  data          <- DataMatrix.list$data
  beta          <- DataMatrix.list$beta
  betaconstant  <- SelParmValues$betaconstant
  nreach        <- length(data[, 1])
  bcols         <- length(beta[1, ])

  if (ifadjust == 1L) {
    weight <- Csites.weights.list$weight         # conditioned: use NLLS weights
  } else {
    weight <- rep(1, length(Csites.weights.list$weight))  # unconditioned: unit weights
  }

  data.index.list <- DataMatrix.list$data.index.list

  # transfer estimated parameters into complete parameter vector (with constant non-estimated parameters)
  betalst <- numeric(bcols) # bcols length
  k <- 0
  for (i in 1:bcols) {
    betalst[i] <- beta[1, i]
    if (betaconstant[i] == 0) {
      k <- k + 1
      betalst[i] <- beta0[k]
    }
  }

  # Load the parameter estimates to BETA1
  beta1 <- t(matrix(betalst, ncol = nreach, nrow = bcols))

  # setup for REACH decay
  jjdec <- length(data.index.list$jdecvar)
  if (sum(data.index.list$jdecvar) > 0) {
    rchdcayf <- matrix(1, nrow = nreach, ncol = 1)
    for (i in 1:jjdec) {
      rchdcayf[, 1] <- rchdcayf[, 1] * exp(-data[, data.index.list$jdecvar[i]] * beta1[, data.index.list$jbdecvar[i]]) # "exp(-data[,data.index.list$jdecvar[i]] * beta1[,data.index.list$jbdecvar[i]])"
    }
  } else {
    rchdcayf <- matrix(1, nrow = nreach, ncol = 1)
  }

  # setup for RESERVOIR decay
  jjres <- length(data.index.list$jresvar)
  if (sum(data.index.list$jresvar) > 0) {
    resdcayf <- matrix(1, nrow = nreach, ncol = 1)
    for (i in 1:jjres) {
      resdcayf[, 1] <- resdcayf[, 1] * (1 / (1 + data[, data.index.list$jresvar[i]] * beta1[, data.index.list$jbresvar[i]])) # "(1 / (1 + data[,data.index.list$jresvar[i]] * beta1[,data.index.list$jbresvar[i]]))"
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
    ddliv2 <- matrix(1, nrow = nreach, ncol = jjsrc)
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


  # incremental delivered load
  incddsrc <- rchdcayf**0.5 * resdcayf * dddliv

  # Compute the reach transport factor
  carryf <- data[, data.index.list$jfrac] * rchdcayf * resdcayf

  nstaid <- max(data[, data.index.list$jstaid])
  nnode  <- max(data[, data.index.list$jtnode], data[, data.index.list$jfnode])
  ee     <- matrix(0, nrow = nstaid, ncol = 1)
  e      <- matrix(0, nrow = nstaid, ncol = 1)
  data2  <- matrix(0, nrow = nreach, ncol = 4)
  data2[, 1] <- data[, data.index.list$jfnode]
  data2[, 2] <- data[, data.index.list$jtnode]
  data2[, 3] <- data[, data.index.list$jdepvar]
  data2[, 4] <- data[, data.index.list$jiftran]
  incddsrc <- ifelse(is.na(incddsrc), 0, incddsrc)
  carryf   <- ifelse(is.na(carryf), 0, carryf)

  # Fortran subroutine to accumulate mass climbing down the reach network
  #   compute and accumulate incremental RCHLD
  return_data <- .Fortran("tnoder",
    ifadjust = as.integer(ifadjust),
    nreach   = as.integer(nreach),
    nnode    = as.integer(nnode),
    data2    = as.double(data2),
    incddsrc = as.double(incddsrc),
    carryf   = as.double(carryf),
    ee       = as.double(ee), PACKAGE = "rsparrow"
  )
  e <- return_data$ee

  e <- sqrt(weight) * e



  return(e)
} # end function


# Backward-compatible wrapper: unconditioned residuals (no monitoring adjustment, unit weights).
# Preserved so existing callers (estimate.R, estimateNLLSmetrics.R) need no change.
estimateFevalNoadj <- function(...) estimateFeval(..., ifadjust = 0L)
