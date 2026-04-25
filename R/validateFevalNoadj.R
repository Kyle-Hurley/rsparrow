#' @title validateFevalNoadj
#' @description Accumulates loads in the reach network according to the user's model
#'            specification, making comparisons of the unconditioned predictions of  load to the actual loads for
#'            monitored (validation site) reaches to return a vector of weighted residuals (difference between the
#'            actual and predicted loads). No monitoring load substitution is performed (ifadjust=0).  \cr \cr
#' Executed By: validateMetrics.R \cr
#' Executes Routines: \itemize{\item estimateFeval.R
#'             \item tnoder.for} \cr
#' @param beta0 estimated parameters (no constants)
#' @param vdepvar variable `subdata$vdepvar`
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @return `e` numeric vector of weighted residuals
#' @keywords internal
#' @noRd



validateFevalNoadj <- function(beta0, vdepvar,
                               SelParmValues, DataMatrix.list, dlvdsgn) {
  # setup global variables in function environment
  data <- DataMatrix.list$data
  beta <- DataMatrix.list$beta
  betaconstant <- SelParmValues$betaconstant
  nreach <- length(data[, 1])
  bcols <- length(beta[1, ])

  ifadjust <- 0 # no adjustment for monitoring loads

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

  # incremental delivered load
  incddsrc <- rchdcayf**0.5 * resdcayf * dddliv

  # Compute the reach transport factor
  carryf <- data[, data.index.list$jfrac] * rchdcayf * resdcayf

  nstaid <- sum(ifelse(vdepvar > 0, 1, 0)) # max(data[,jstaid])
  nnode <- max(data[, data.index.list$jtnode], data[, data.index.list$jfnode])
  ee <- matrix(0, nrow = nstaid, ncol = 1)
  e <- matrix(0, nrow = nstaid, ncol = 1)
  data2 <- matrix(0, nrow = nreach, ncol = 4)
  data2[, 1] <- data[, data.index.list$jfnode]
  data2[, 2] <- data[, data.index.list$jtnode]
  data2[, 3] <- vdepvar # data[,jdepvar]
  data2[, 4] <- data[, data.index.list$jiftran]
  incddsrc <- ifelse(is.na(incddsrc), 0, incddsrc)
  carryf <- ifelse(is.na(carryf), 0, carryf)

  # Fortran subroutine to accumulate mass climbing down the reach network
  #   compute and accumulate incremental RCHLD
  return_data <- .Fortran("tnoder",
    ifadjust = as.integer(ifadjust),
    nreach = as.integer(nreach),
    nnode = as.integer(nnode),
    data2 = as.double(data2),
    incddsrc = as.double(incddsrc),
    carryf = as.double(carryf),
    ee = as.double(ee), PACKAGE = "rsparrow"
  )
  e <- return_data$ee

  weight <- rep(1, nstaid) # no weights applied
  e <- sqrt(weight) * e



  return(e)
} # end function
