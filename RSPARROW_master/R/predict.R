#' @title predict
#' @description Calculates all conditioned and unconditioned model predictions for reaches for
#'            the control setting if_predict<-"yes".  \cr \cr
#' Executed By: \itemize{\item controlFileTasksModel.R
#'             \item estimate.R} \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             \item named.list.R
#'             \item deliv_fraction.for
#'             \item mptnoder.for
#'             \item ptnoder.for} \cr
#' @param estimate.list list output from `estimate.R`
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#'                           NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param bootcorrection numeric vector equal to
#'       `estimate.list$JacobResults$mean_exp_weighted_error` unless NULL, then reset to 1.0
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list'
#'                       for optimization
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param subdata data.frame input data (subdata)
#' @return `predict.list` archive with all load and yield prediction variables to provide for
#'            the efficient access and use of predictions in subsequent execution of the parametric bootstrap
#'            predictions and uncertainties, mapping, and scenario evaluations.  For more details see
#'            documentation Section 5.3.1.5
#' @keywords internal
#' @noRd



predict_sparrow <- function(estimate.list, estimate.input.list, bootcorrection, DataMatrix.list,
                    SelParmValues, subdata, dlvdsgn) {
  #################################################

  data             <- DataMatrix.list$data
  data.index.list  <- DataMatrix.list$data.index.list
  oEstimate        <- estimate.list$JacobResults$oEstimate
  Parmnames        <- estimate.list$JacobResults$Parmnames

  waterid  <- subdata$waterid
  demtarea <- subdata$demtarea
  meanq    <- subdata$meanq
  demiarea <- subdata$demiarea

  srcvar     <- SelParmValues$srcvar
  loadUnits  <- estimate.input.list$loadUnits
  yieldUnits <- estimate.input.list$yieldUnits
  ConcUnits  <- estimate.input.list$ConcUnits
  ConcFactor <- estimate.input.list$ConcFactor
  yieldFactor <- estimate.input.list$yieldFactor

  nreach   <- length(data[, 1])
  numsites <- sum(ifelse(data[, 10] > 0, 1, 0))  # jdepvar site load index
  jjsrc    <- length(data.index.list$jsrcvar)

  # Replicate parameter vector across all reaches
  betalst <- oEstimate
  beta1   <- t(matrix(betalst, ncol = nreach, nrow = length(oEstimate)))

  # ------------------------------------------------------------------
  # Shared prediction kernel (decay, delivery, source loads)
  # ------------------------------------------------------------------
  core <- .predict_core(data, data.index.list, Parmnames, beta1, dlvdsgn, numsites)

  # ------------------------------------------------------------------
  # Column-name vectors (strings only; data accessed via core named lists)
  # ------------------------------------------------------------------
  srclist_total  <- paste0("pload_",    Parmnames[seq_len(jjsrc)])
  srclist_mtotal <- paste0("mpload_",   Parmnames[seq_len(jjsrc)])
  srclist_nd_total <- paste0("pload_nd_", Parmnames[seq_len(jjsrc)])
  srclist_inc    <- paste0("pload_inc_", Parmnames[seq_len(jjsrc)])

  # ------------------------------------------------------------------
  # mpload_decay and mpload_fraction (unique to predict_sparrow)
  # ------------------------------------------------------------------
  carryf  <- data[, data.index.list$jfrac] * core$rchdcayf * core$resdcayf
  carryf  <- ifelse(is.na(carryf), 0, carryf)
  inczero <- rep(0, nreach)
  ee      <- matrix(0, nrow = nreach, ncol = 1)

  return_data <- .Fortran("ptnoder",
    ifadjust = as.integer(1L),
    nreach   = as.integer(nreach),
    nnode    = as.integer(core$nnode),
    data2    = as.double(core$data2),
    incddsrc = as.double(inczero),
    carryf   = as.double(carryf),
    ee       = as.double(ee), PACKAGE = "rsparrow"
  )
  mpload_decay <- return_data$ee

  mpload_fraction <- vapply(seq_len(nreach), function(i) {
    ifelse(core$mpload_total[i] > 0 & !is.na(core$mpload_total[i]),
           mpload_decay[i] / core$mpload_total[i], NA)
  }, FUN.VALUE = numeric(1))

  # ------------------------------------------------------------------
  # Delivery fraction
  # ------------------------------------------------------------------
  data2_deliv <- matrix(0, nrow = nreach, ncol = 5)
  data2_deliv[, 1] <- data[, data.index.list$jfnode]
  data2_deliv[, 2] <- data[, data.index.list$jtnode]
  data2_deliv[, 3] <- data[, data.index.list$jfrac]
  data2_deliv[, 4] <- data[, data.index.list$jiftran]
  data2_deliv[, 5] <- data[, data.index.list$jtarget]

  deliv_frac <- deliver(nreach, waterid, core$nnode, data2_deliv,
                        core$incdecay, core$totdecay)

  #######################################
  # Output load predictions

  srclist_inc_deliv <- paste0(srclist_inc, "_deliv")
  srclist_inc_share   <- paste0("share_inc_",   srcvar[seq_len(jjsrc)])
  srclist_total_share <- paste0("share_total_", srcvar[seq_len(jjsrc)])

  oparmlist <- c(
    "waterid", "pload_total", srclist_total,
    "mpload_total", srclist_mtotal,
    "pload_nd_total", srclist_nd_total,
    "pload_inc", srclist_inc,
    "deliv_frac",
    "pload_inc_deliv", srclist_inc_deliv,
    srclist_total_share, srclist_inc_share
  )

  oparmlistExpl <- character(length(oparmlist))

  ncols <- 7 + length(srclist_total) + length(srclist_mtotal) + length(srclist_nd_total) +
    length(srclist_inc) + length(srclist_inc) + length(srclist_inc) + length(srclist_inc)
  predmatrix <- matrix(0, nrow = nreach, ncol = ncols)
  loadunits  <- rep(loadUnits, ncols)
  loadunits[1] <- "Reach ID Number"

  predmatrix[, 1] <- subdata$waterid
  oparmlistExpl[1] <- "Reach ID Number"

  # total load
  predmatrix[, 2] <- core$pload_total * as.vector(bootcorrection)
  oparmlistExpl[2] <- "Total load (fully decayed)"
  for (i in seq_len(jjsrc)) {
    predmatrix[, 2 + i] <- core$pload_src[[Parmnames[i]]] * as.vector(bootcorrection)
    oparmlistExpl[2 + i] <- "Total source load (fully decayed)"

    col_share <- 7 + length(srclist_total) + length(srclist_mtotal) + length(srclist_nd_total) +
      length(srclist_inc) + length(srclist_inc) + i
    predmatrix[, col_share] <- predmatrix[, 2 + i] / predmatrix[, 2] * 100
    predmatrix[, col_share] <- ifelse(is.na(predmatrix[, col_share]), 0, predmatrix[, col_share])
    loadunits[col_share] <- "Percent"
    oparmlistExpl[col_share] <- "Source shares for total load"
  }
  # monitoring-adjusted total load
  col_mptot <- 3 + length(srclist_total)
  predmatrix[, col_mptot] <- core$mpload_total * as.vector(bootcorrection)
  oparmlistExpl[col_mptot] <- "Monitoring-adjusted (conditional) total load (fully decayed)"
  for (i in seq_len(jjsrc)) {
    predmatrix[, col_mptot + i] <- core$mpload_src[[Parmnames[i]]] * as.vector(bootcorrection)
    oparmlistExpl[col_mptot + i] <- "Monitoring-adjusted (conditional) total source load (fully decayed)"
  }
  # non-decayed (ND) total load
  col_ndtot <- 4 + length(srclist_total) + length(srclist_mtotal)
  predmatrix[, col_ndtot] <- core$pload_nd_total * as.vector(bootcorrection)
  oparmlistExpl[col_ndtot] <- "Total load delivered to streams (no stream decay)"
  for (i in seq_len(jjsrc)) {
    predmatrix[, col_ndtot + i] <- core$pload_nd_src[[Parmnames[i]]] * as.vector(bootcorrection)
    oparmlistExpl[col_ndtot + i] <- "Total source load delivered to streams (no stream decay)"
  }
  # incremental load
  col_inc <- 5 + length(srclist_total) + length(srclist_mtotal) + length(srclist_nd_total)
  predmatrix[, col_inc] <- core$pload_inc * as.vector(bootcorrection)
  oparmlistExpl[col_inc] <- "Total incremental load delivered to reach (with one-half of reach decay)"
  for (i in seq_len(jjsrc)) {
    predmatrix[, col_inc + i] <- core$pload_inc_src[[Parmnames[i]]] * as.vector(bootcorrection)
    oparmlistExpl[col_inc + i] <- "Total incremental source load delivered to reach (with one-half of reach decay)"

    col_inc_share <- 7 + length(srclist_total) + length(srclist_mtotal) +
      length(srclist_nd_total) + length(srclist_inc) + length(srclist_inc) +
      length(srclist_inc) + i
    predmatrix[, col_inc_share] <-
      predmatrix[, col_inc + i] / predmatrix[, col_inc] * 100
    predmatrix[, col_inc_share] <-
      ifelse(is.na(predmatrix[, col_inc_share]), 0, predmatrix[, col_inc_share])
    loadunits[col_inc_share] <- "Percent"
    oparmlistExpl[col_inc_share] <- "Source shares for incremental load"
  }
  # delivery fraction
  col_deliv <- 6 + length(srclist_total) + length(srclist_mtotal) +
    length(srclist_nd_total) + length(srclist_inc)
  predmatrix[, col_deliv] <- deliv_frac
  loadunits[col_deliv] <- "Fraction"
  oparmlistExpl[col_deliv] <- "Fraction of total load delivered to terminal reach"

  # delivered incremental load
  col_dload <- 7 + length(srclist_total) + length(srclist_mtotal) +
    length(srclist_nd_total) + length(srclist_inc)
  dload <- predmatrix[, col_inc] * deliv_frac
  predmatrix[, col_dload] <- dload
  oparmlistExpl[col_dload] <- "Total incremental load delivered to terminal reach"
  for (i in seq_len(jjsrc)) {
    dload <- predmatrix[, col_inc + i] * deliv_frac
    predmatrix[, col_dload + i] <- dload
    oparmlistExpl[col_dload + i] <- "Total incremental source load delivered to terminal reach"
  }

  # ------------------------------------------------------------------
  # Output yield predictions
  # ------------------------------------------------------------------
  srclist_yield        <- gsub("pload", "yield", srclist_total)
  srclist_myield       <- gsub("pload", "yield", srclist_mtotal)
  srclist_yldinc       <- gsub("pload", "yield", srclist_inc)
  srclist_yldinc_deliv <- gsub("pload", "yield", srclist_inc_deliv)

  oyieldlist <- c(
    "waterid", "concentration", "yield_total", srclist_yield,
    "myield_total", srclist_myield,
    "yield_inc", srclist_yldinc,
    "yield_inc_deliv", srclist_yldinc_deliv
  )

  oyieldlistExpl <- character(length(oyieldlist))

  ncols_yld <- 6 + length(srclist_yield) + length(srclist_myield) +
    length(srclist_yldinc) + length(srclist_yldinc_deliv)
  yldmatrix  <- matrix(0, nrow = nreach, ncol = ncols_yld)
  yieldunits <- rep(yieldUnits, ncols_yld)
  yieldunits[1] <- "Reach ID Number"
  yieldunits[2] <- ConcUnits

  yldmatrix[, 1] <- subdata$waterid
  oyieldlistExpl[1] <- "Reach ID Number"

  # total yield
  for (i in seq_len(nreach)) {
    if (demtarea[i] > 0) {
      if (meanq[i] > 0) {
        yldmatrix[i, 2] <- predmatrix[i, 2] / meanq[i] * ConcFactor
      }
      oyieldlistExpl[2] <- "Flow-weighted concentration based on decayed total load and mean discharge"

      yldmatrix[i, 3] <- predmatrix[i, 2] / demtarea[i] * yieldFactor
      oyieldlistExpl[3] <- "Total yield (fully decayed)"

      for (j in seq_len(jjsrc)) {
        yldmatrix[i, 3 + j] <- predmatrix[i, 2 + j] / demtarea[i] * yieldFactor
        oyieldlistExpl[3 + j] <- "Total source yield (fully decayed)"
      }
      # monitoring-adjusted total yield
      yldmatrix[i, 4 + jjsrc] <- predmatrix[i, col_mptot] / demtarea[i] * yieldFactor
      oyieldlistExpl[4 + jjsrc] <- "Monitoring-adjusted (conditional) total yield (fully decayed)"
      for (j in seq_len(jjsrc)) {
        yldmatrix[i, 4 + jjsrc + j] <- predmatrix[i, col_mptot + j] / demtarea[i] * yieldFactor
        oyieldlistExpl[4 + jjsrc + j] <- "Monitoring-adjusted (conditional) total source yield (fully decayed)"
      }
    }
  }
  # incremental yield
  col_yld_inc <- 5 + jjsrc + jjsrc  # 5 + length(srclist_total) + length(srclist_mtotal)
  for (i in seq_len(nreach)) {
    if (demiarea[i] > 0) {
      yldmatrix[i, col_yld_inc] <- predmatrix[i, col_inc] / demiarea[i] * yieldFactor
      oyieldlistExpl[col_yld_inc] <- "Total incremental yield delivered to reach (with one-half of reach decay)"
      for (j in seq_len(jjsrc)) {
        yldmatrix[i, col_yld_inc + j] <- predmatrix[i, col_inc + j] / demiarea[i] * yieldFactor
        oyieldlistExpl[col_yld_inc + j] <- "Total incremental source yield delivered to reach (with one-half of reach decay)"
      }

      col_yld_dload <- 6 + jjsrc + jjsrc + jjsrc
      yldmatrix[i, col_yld_dload] <-
        predmatrix[i, col_dload] / demiarea[i] * yieldFactor
      oyieldlistExpl[col_yld_dload] <- "Total incremental yield delivered to terminal reach"
      for (j in seq_len(jjsrc)) {
        yldmatrix[i, col_yld_dload + j] <-
          predmatrix[i, col_dload + j] / demiarea[i] * yieldFactor
        oyieldlistExpl[col_yld_dload + j] <- "Total incremental source yield delivered to terminal reach"
      }
    }
  }

  predict.source.list <- named.list(
    srclist_total, srclist_mtotal, srclist_inc, srclist_inc_deliv,
    srclist_nd_total, srclist_yield, srclist_myield, srclist_yldinc,
    srclist_yldinc_deliv
  )

  predict.list <- named.list(
    oparmlist, loadunits, predmatrix, oyieldlist, yieldunits, yldmatrix, predict.source.list,
    oparmlistExpl, oyieldlistExpl,
    mpload_decay, mpload_fraction
  )
  return(predict.list)
} # end function
