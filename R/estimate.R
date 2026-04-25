#' @title estimate
#'
#' @description
#' Executes model estimation and computes performance metrics. Returns estimate.list
#' containing optimization results and diagnostics. All diagnostic plotting and file
#' output is available on-demand through \code{plot(model)} and
#' \code{write_rsparrow_results(model)}.
#'
#' Executed By: controlFileTasksModel.R
#'
#' Executes Routines: \itemize{
#'              \item estimateFevalNoadj.R,
#'              \item estimateNLLSmetrics.R,
#'              \item estimateOptimize.R,
#'              \item named.list.R,
#'              \item validateMetrics.R}
#'
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating
#' whether estimation should be run in simulation mode only.
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by \code{generateInputList.R}
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#' NLLS_weights, if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list' for
#' optimization
#' @param SelParmValues selected parameters from parameters.csv using condition
#' \code{ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) &
#' ((parmType=="SOURCE" & parmMin>=0) | parmType!="SOURCE"))}
#' @param Csites.weights.list regression weights as proportional to incremental area size
#' @param Csites.list list output from \code{selectCalibrationSites.R} modified in
#' \code{startModelRun.R}
#' @param sitedata Sites selected for calibration using
#' \code{subdata[(subdata$depvar > 0 & subdata$calsites==1), ]}
#' @param numsites number of sites selected for calibration
#' @param if_validate yes/no indicating whether or not validation is run
#' @param Vsites.list named list of sites for validation
#' @param vsitedata sitedata for validation
#' @param subdata data.frame input data (subdata)
#' @param classvar character vector of user specified spatially contiguous discrete
#' classification variables from sparrow_control
#' @param betavalues data.frame of model parameters from parameters.csv
#'
#' @return \code{estimate.list} named list of summary metrics and diagnostic output.
#'   For more details see documentation section 5.2.4
#' @keywords internal
#' @noRd

estimate <- function(if_estimate, if_estimate_simulation, file.output.list,
                     dlvdsgn, estimate.input.list,
                     DataMatrix.list, SelParmValues, Csites.weights.list, Csites.list,
                     sitedata, numsites,
                     if_validate, Vsites.list, vsitedata, subdata,
                     classvar, betavalues) {

  ifHess    <- estimate.input.list$ifHess
  yieldFactor <- estimate.input.list$yieldFactor

  estimate.list <- NULL

  if (if_estimate == "yes" & if_estimate_simulation == "no") {
    message("Running estimation...")
    sparrowEsts <- estimateOptimize(
      file.output.list, SelParmValues, estimate.input.list,
      DataMatrix.list, dlvdsgn, Csites.weights.list
    )

    if_sparrowEsts <- 1L
    estimate.metrics.list <- estimateNLLSmetrics(
      if_estimate, if_estimate_simulation, if_sparrowEsts, sparrowEsts,
      file.output.list, classvar, dlvdsgn,
      Csites.weights.list, estimate.input.list,
      Csites.list, SelParmValues, subdata, sitedata, DataMatrix.list
    )

    JacobResults      <- estimate.metrics.list$JacobResults
    HesResults        <- estimate.metrics.list$HesResults
    ANOVA.list        <- estimate.metrics.list$ANOVA.list
    Mdiagnostics.list <- estimate.metrics.list$Mdiagnostics.list

    estimate.list <- named.list(sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list)

    if (if_validate == "yes") {
      message("Running Validation...")
      validate.metrics.list <- validateMetrics(
        classvar, estimate.list, dlvdsgn, Vsites.list, yieldFactor,
        SelParmValues, subdata, vsitedata, DataMatrix.list
      )
      vANOVA.list        <- validate.metrics.list$vANOVA.list
      vMdiagnostics.list <- validate.metrics.list$vMdiagnostics.list
      estimate.list <- named.list(
        sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list,
        vANOVA.list, vMdiagnostics.list
      )
    }

  } else if (if_estimate_simulation == "yes") {
    message("Running model in simulation mode using initial values of the parameters...")
    sparrowEsts <- alist(SelParmValues = )$beta0
    sparrowEsts$coefficient <- SelParmValues$beta0

    nn <- ifelse(
      DataMatrix.list$data[, 10] > 0 & DataMatrix.list$data[, 13] == 1,
      1, 0
    )

    if (sum(nn) > 0) {
      message("Outputing performance diagnostics for simulation mode...")

      sparrowEsts$resid <- estimateFevalNoadj(
        SelParmValues$beta0,
        DataMatrix.list, SelParmValues, Csites.weights.list,
        estimate.input.list, dlvdsgn
      )
      sparrowEsts$coefficients <- SelParmValues$beta0

      if_sparrowEsts <- 0L
      estimate.metrics.list <- estimateNLLSmetrics(
        if_estimate, if_estimate_simulation, if_sparrowEsts, sparrowEsts,
        file.output.list, classvar, dlvdsgn,
        Csites.weights.list, estimate.input.list,
        Csites.list, SelParmValues, subdata, sitedata, DataMatrix.list
      )

      JacobResults      <- estimate.metrics.list$JacobResults
      HesResults        <- estimate.metrics.list$HesResults
      ANOVA.list        <- estimate.metrics.list$ANOVA.list
      Mdiagnostics.list <- estimate.metrics.list$Mdiagnostics.list
      estimate.list <- named.list(sparrowEsts, JacobResults, HesResults, ANOVA.list, Mdiagnostics.list)

    } else {
      # No monitoring loads — store starting values only for use in predictions
      JacobResults <- alist(JacobResults = )$SelParmValues$beta0
      JacobResults$oEstimate <- SelParmValues$beta0
      JacobResults$Parmnames <- noquote(c(
        SelParmValues$srcvar, SelParmValues$dlvvar,
        SelParmValues$decvar, SelParmValues$resvar
      ))
      estimate.list <- named.list(sparrowEsts, JacobResults)
    }
  }

  return(estimate.list)
}
