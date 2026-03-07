#' @title predictBoot
#' @description Calculates all conditioned and unconditioned model predictions for reaches for
#'            each bootstrap iteration, for the control setting if_boot_predict<-"yes".  \cr \cr
#' Executed By: predictBootstraps.R \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             \item named.list.R
#'             \item deliv_fraction.for
#'             \item mptnoder.for
#'             \item ptnoder.for} \cr
#' @param bEstimate model coefficients generated in `estimateBootstraps.R`
#' @param estimate.list list output from `estimate.R`
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#'                           NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param bootcorrectionR value of 1
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list'
#'                       for optimization
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param subdata data.frame input data (subdata)
#' @return `predictBoots.list` contains parametric bootstrap predictions for load and yield.
#'            For more details see documentation Section 5.3.2.3
#' @keywords internal
#' @noRd



predictBoot <- function(bEstimate, estimate.list, estimate.input.list, bootcorrectionR,
                        DataMatrix.list, SelParmValues, subdata, dlvdsgn) {
  #################################################

  data            <- DataMatrix.list$data
  data.index.list <- DataMatrix.list$data.index.list
  Parmnames       <- estimate.list$JacobResults$Parmnames

  waterid    <- subdata$waterid
  srcvar     <- SelParmValues$srcvar
  loadUnits  <- estimate.input.list$loadUnits
  yieldUnits <- estimate.input.list$yieldUnits
  ConcUnits  <- estimate.input.list$ConcUnits

  nreach   <- length(data[, 1])
  numsites <- sum(ifelse(data[, 10] > 0, 1, 0))  # jdepvar site load index
  jjsrc    <- length(data.index.list$jsrcvar)

  # Replicate bootstrap parameter vector across all reaches
  betalst <- bEstimate
  beta1   <- t(matrix(betalst, ncol = nreach, nrow = length(betalst)))

  # ------------------------------------------------------------------
  # Shared prediction kernel (decay, delivery, source loads)
  # ------------------------------------------------------------------
  core <- .predict_core(data, data.index.list, Parmnames, beta1, dlvdsgn, numsites)

  # ------------------------------------------------------------------
  # Column-name vectors (strings only; data accessed via core named lists)
  # ------------------------------------------------------------------
  srclist_total    <- paste0("pload_",    Parmnames[seq_len(jjsrc)])
  srclist_mtotal   <- paste0("mpload_",   Parmnames[seq_len(jjsrc)])
  srclist_nd_total <- paste0("pload_nd_", Parmnames[seq_len(jjsrc)])
  srclist_inc      <- paste0("pload_inc_", Parmnames[seq_len(jjsrc)])

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
  # Store load predictions

  srclist_inc_deliv   <- paste0(srclist_inc, "_deliv")
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

  ncols <- 7 + length(srclist_total) + length(srclist_mtotal) + length(srclist_nd_total) +
    length(srclist_inc) + length(srclist_inc) + length(srclist_inc) + length(srclist_inc)
  predmatrix <- matrix(0, nrow = nreach, ncol = ncols)
  loadunits  <- rep(loadUnits, ncols)

  predmatrix[, 1] <- subdata$waterid

  # total load
  predmatrix[, 2] <- core$pload_total * bootcorrectionR
  for (i in seq_len(jjsrc)) {
    predmatrix[, 2 + i] <- core$pload_src[[Parmnames[i]]] * bootcorrectionR

    col_share <- 7 + length(srclist_total) + length(srclist_mtotal) + length(srclist_nd_total) +
      length(srclist_inc) + length(srclist_inc) + i
    predmatrix[, col_share] <- predmatrix[, 2 + i] / predmatrix[, 2] * 100
    predmatrix[, col_share] <- ifelse(is.na(predmatrix[, col_share]), 0, predmatrix[, col_share])
    loadunits[col_share] <- "Percent"
  }
  # monitoring-adjusted total load
  col_mptot <- 3 + jjsrc
  predmatrix[, col_mptot] <- core$mpload_total
  for (i in seq_len(jjsrc)) {
    predmatrix[, col_mptot + i] <- core$mpload_src[[Parmnames[i]]]
  }
  # non-decayed (ND) total load
  col_ndtot <- 4 + jjsrc + jjsrc
  predmatrix[, col_ndtot] <- core$pload_nd_total * bootcorrectionR
  for (i in seq_len(jjsrc)) {
    predmatrix[, col_ndtot + i] <- core$pload_nd_src[[Parmnames[i]]] * bootcorrectionR
  }
  # incremental load
  col_inc <- 5 + jjsrc + jjsrc + jjsrc
  predmatrix[, col_inc] <- core$pload_inc * bootcorrectionR
  for (i in seq_len(jjsrc)) {
    predmatrix[, col_inc + i] <- core$pload_inc_src[[Parmnames[i]]] * bootcorrectionR

    col_inc_share <- 7 + length(srclist_total) + length(srclist_mtotal) +
      length(srclist_nd_total) + length(srclist_inc) + length(srclist_inc) +
      length(srclist_inc) + i
    predmatrix[, col_inc_share] <-
      predmatrix[, col_inc + i] / predmatrix[, col_inc] * 100
    predmatrix[, col_inc_share] <-
      ifelse(is.na(predmatrix[, col_inc_share]), 0, predmatrix[, col_inc_share])
    loadunits[col_inc_share] <- "Percent"
  }
  # delivery fraction
  col_deliv <- 6 + jjsrc + jjsrc + jjsrc + jjsrc
  index.deliv_frac <- col_deliv
  predmatrix[, col_deliv] <- deliv_frac
  loadunits[col_deliv] <- "Fraction Delivered"

  # delivered incremental load
  col_dload <- 7 + jjsrc + jjsrc + jjsrc + jjsrc
  dload <- predmatrix[, col_inc] * deliv_frac
  predmatrix[, col_dload] <- dload
  for (i in seq_len(jjsrc)) {
    dload <- predmatrix[, col_inc + i] * deliv_frac
    predmatrix[, col_dload + i] <- dload
  }

  # ------------------------------------------------------------------
  # Store yield ancillary metrics
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

  ncols_yld  <- 6 + jjsrc + jjsrc + jjsrc + jjsrc
  yldmatrix  <- matrix(0, nrow = nreach, ncol = ncols_yld)
  yieldunits <- rep(yieldUnits, ncols_yld)
  yieldunits[2] <- ConcUnits

  #########################################################################
  # Final list objects

  predict.source.list <- named.list(
    srclist_total, srclist_mtotal, srclist_inc, srclist_inc_deliv,
    srclist_nd_total, srclist_yield, srclist_myield, srclist_yldinc,
    srclist_yldinc_deliv
  )

  predmatrix <- ifelse(is.na(predmatrix), 0, predmatrix)

  predictBoots.list <- named.list(
    oparmlist, loadunits, predmatrix, oyieldlist, yieldunits,
    predict.source.list, index.deliv_frac
  )

  return(predictBoots.list)
} # end function
