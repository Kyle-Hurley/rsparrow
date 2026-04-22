#' @title estimateOptimize
#' @description Executes the SPARROW NLLS model estimation via calls to the 'nlfb' NLMRT
#'            library optimization function and the 'jacobian' function.  \cr \cr
#' Executed By: estimate.R \cr
#' Executes Routines: \itemize{\item estimateFeval.R
#'             \item named.list.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#'                           NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list'
#'                       for optimization
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @return `sparrowEsts` list object contained in estimate.list `if_estimate<-'yes'`.  For more
#'            details see documentation Section 5.2.4.4.
#' @keywords internal
#' @noRd



estimateOptimize <- function(file.output.list, SelParmValues, estimate.input.list,
                             DataMatrix.list, dlvdsgn, Csites.weights.list) {
  s_offset <- estimate.input.list$s_offset
  if_mean_adjust_delivery_vars <- estimate.input.list$if_mean_adjust_delivery_vars

  # Provide initial values for BETA0 for use in optimization (identify parameters to be estimated)
  ebcols <- SelParmValues$bcols - (sum(SelParmValues$betaconstant)) # number of parameters for estimation
  beta0 <- numeric(ebcols)
  betalst <- numeric(ebcols)
  betamn <- numeric(ebcols)
  betamx <- numeric(ebcols)
  k <- 0
  # check min/max values to ensure that they bound initial value
  for (i in 1:SelParmValues$bcols) {
    if (SelParmValues$betaconstant[i] == 0) {
      k <- k + 1
      beta0[k] <- DataMatrix.list$beta[1, i]
      betamn[k] <- SelParmValues$betamin[i]
      if (betamn[k] > beta0[k]) {
        betamn[k] <- beta0[k] / 10
      }
      betamx[k] <- SelParmValues$betamax[i]
      if (betamx[k] < beta0[k]) {
        betamx[k] <- beta0[k] * 10
      }
    }
  }


  ptm <- proc.time()

  jacfun <- function(beta0,
                     DataMatrix.list, SelParmValues, Csites.weights.list,
                     estimate.input.list, dlvdsgn) {
    Jac <- jacobian(estimateFeval, beta0,
      DataMatrix.list = DataMatrix.list,
      SelParmValues = SelParmValues,
      Csites.weights.list = Csites.weights.list,
      estimate.input.list = estimate.input.list,
      dlvdsgn = dlvdsgn,
      method = "Richardson"
    )
  }
  nlfbOut <- nlfb(beta0, estimateFeval,
    DataMatrix.list = DataMatrix.list,
    SelParmValues = SelParmValues,
    Csites.weights.list = Csites.weights.list,
    estimate.input.list = estimate.input.list,
    dlvdsgn = dlvdsgn,
    jacfun, trace = TRUE,
    lower = betamn, upper = betamx, control = list(offset = s_offset, ndstep = 1e-07)
  )


  sparrowEsts <- nlfbOut[c("resid", "jacobian", "feval", "jeval", "coefficients", "ssquares", "lower", "upper", "maskidx")]

  # femax = Maximum function (sum of squares) evaluations. Default is 10000, which is extremely aggressive.
  # offset = Shift to test for floating-point equality. Default is 100.
  # jemax = Maximum number of Jacobian evaluations. Default is 5000.
  # ndstep = Stepsize to use to computer numerical Jacobian approximatin. Default is 1e-7.

  xtime <- proc.time() - ptm
  message("Time elapsed in optimization")
  print(xtime)

  sparrowEsts$betamn <- betamn
  sparrowEsts$betamx <- betamx
  sparrowEsts$if_mean_adjust_delivery_vars <- if_mean_adjust_delivery_vars
  sparrowEsts$NLLS_weights <- estimate.input.list$NLLS_weights
  sparrowEsts$dlvdsgn <- dlvdsgn



  return(sparrowEsts)
} # end function
