#' Shared prediction kernel for SPARROW reach-level load accumulation
#'
#' Computes reach decay, source delivery, and all per-reach load vectors shared
#' by predict_sparrow(), predictBoot(), and predictScenarios().  Returns a named
#' list keyed by Parmnames — no assign()/eval(parse()) used.
#'
#' @param data Numeric data matrix (DataMatrix.list$data), possibly
#'   scenario-modified before this call.
#' @param data.index.list Index list (DataMatrix.list$data.index.list).
#' @param Parmnames Character vector of estimated parameter names.
#' @param beta1 nreach x npar parameter matrix (already replicated across reaches).
#' @param dlvdsgn Delivery design matrix (nsrc x ndlv).
#' @param numsites Integer; number of calibration sites in data (determines
#'   whether monitoring-adjusted mpload_src is computed).
#'
#' @return Named list with elements:
#'   \item{pload_total}{Total decayed reach load (no monitoring adjustment).}
#'   \item{mpload_total}{Monitoring-adjusted total decayed load.}
#'   \item{pload_nd_total}{Total non-decayed load.}
#'   \item{pload_inc}{Incremental load delivered to reach.}
#'   \item{pload_src}{Named list of per-source decayed total loads.}
#'   \item{mpload_src}{Named list of monitoring-adjusted per-source loads.}
#'   \item{pload_nd_src}{Named list of per-source non-decayed loads.}
#'   \item{pload_inc_src}{Named list of per-source incremental loads.}
#'   \item{rchdcayf}{Reach decay factor matrix.}
#'   \item{resdcayf}{Reservoir decay factor matrix.}
#'   \item{ddliv2}{Source delivery matrix (nreach x nsrc).}
#'   \item{incdecay}{Incremental decay factor (rchdcayf^0.5 * resdcayf).}
#'   \item{totdecay}{Total decay factor (rchdcayf * resdcayf).}
#'   \item{nnode}{Maximum node index.}
#'   \item{data2}{4-column node/tran matrix used in ptnoder/mptnoder calls.}
#' @keywords internal
#' @noRd
.predict_core <- function(data, data.index.list, Parmnames, beta1, dlvdsgn, numsites) {

  nreach <- length(data[, 1])
  jjsrc  <- length(data.index.list$jsrcvar)

  # ------------------------------------------------------------------
  # Reach decay
  # ------------------------------------------------------------------
  jjdec <- length(data.index.list$jdecvar)
  if (sum(data.index.list$jdecvar) > 0) {
    rchdcayf <- matrix(1, nrow = nreach, ncol = 1)
    for (i in 1:jjdec) {
      rchdcayf[, 1] <- rchdcayf[, 1] *
        exp(-data[, data.index.list$jdecvar[i]] * beta1[, data.index.list$jbdecvar[i]])
    }
  } else {
    rchdcayf <- matrix(1, nrow = nreach, ncol = 1)
  }

  # ------------------------------------------------------------------
  # Reservoir decay
  # ------------------------------------------------------------------
  jjres <- length(data.index.list$jresvar)
  if (sum(data.index.list$jresvar) > 0) {
    resdcayf <- matrix(1, nrow = nreach, ncol = 1)
    for (i in 1:jjres) {
      resdcayf[, 1] <- resdcayf[, 1] *
        (1 / (1 + data[, data.index.list$jresvar[i]] * beta1[, data.index.list$jbresvar[i]]))
    }
  } else {
    resdcayf <- matrix(1, nrow = nreach, ncol = 1)
  }

  # ------------------------------------------------------------------
  # Source delivery
  # ------------------------------------------------------------------
  jjdlv  <- length(data.index.list$jdlvvar)
  ddliv1 <- matrix(0, nrow = nreach, ncol = jjdlv)
  if (sum(data.index.list$jdlvvar) > 0) {
    for (i in 1:jjdlv) {
      ddliv1[, i] <- beta1[, data.index.list$jbdlvvar[i]] * data[, data.index.list$jdlvvar[i]]
    }
    ddliv2 <- exp(ddliv1 %*% t(dlvdsgn))
  } else {
    ddliv2 <- matrix(1, nrow = nreach, ncol = jjsrc)
  }

  ddliv3 <- (ddliv2 * data[, data.index.list$jsrcvar]) * beta1[, data.index.list$jbsrcvar]
  if (sum(data.index.list$jsrcvar) > 0) {
    dddliv <- matrix(0, nrow = nreach, ncol = 1)
    for (i in 1:jjsrc) {
      dddliv[, 1] <- dddliv[, 1] + ddliv3[, i]
    }
  } else {
    dddliv <- matrix(1, nrow = nreach, ncol = 1)
  }

  # ------------------------------------------------------------------
  # Decay and transport factors
  # ------------------------------------------------------------------
  incdecay  <- rchdcayf^0.5 * resdcayf  # incremental reach + reservoir decay
  totdecay  <- rchdcayf * resdcayf       # total reach + reservoir decay
  carryf    <- data[, data.index.list$jfrac] * rchdcayf * resdcayf
  carryf_nd <- data[, data.index.list$jfrac]

  # ------------------------------------------------------------------
  # Incremental source loads — named list (replaces assign/srclist_inc)
  # ------------------------------------------------------------------
  pload_inc     <- as.vector(dddliv)
  pload_inc_src <- vector("list", jjsrc)
  names(pload_inc_src) <- Parmnames[seq_len(jjsrc)]
  for (j in seq_len(jjsrc)) {
    ddliv_j <- as.matrix(
      (ddliv2[, j] * data[, data.index.list$jsrcvar[j]]) * beta1[, data.index.list$jbsrcvar[j]]
    )
    pload_inc_src[[Parmnames[j]]] <- as.vector(ddliv_j)
  }

  # ------------------------------------------------------------------
  # Fortran setup (4-column node matrix, used by ptnoder / mptnoder)
  # ------------------------------------------------------------------
  nnode <- max(data[, data.index.list$jtnode], data[, data.index.list$jfnode])
  ee    <- matrix(0, nrow = nreach, ncol = 1)
  data2 <- matrix(0, nrow = nreach, ncol = 4)
  data2[, 1] <- data[, data.index.list$jfnode]
  data2[, 2] <- data[, data.index.list$jtnode]
  data2[, 3] <- data[, data.index.list$jdepvar]
  data2[, 4] <- data[, data.index.list$jiftran]

  # Cleaned total incddsrc / carryf for the aggregate Fortran calls
  incddsrc_c <- ifelse(is.na(rchdcayf^0.5 * resdcayf * dddliv), 0,
                       rchdcayf^0.5 * resdcayf * dddliv)
  carryf_c   <- ifelse(is.na(carryf), 0, carryf)

  # ------------------------------------------------------------------
  # Total decayed load (no monitoring adjustment)
  # ------------------------------------------------------------------
  return_data <- .Fortran("ptnoder",
    ifadjust = as.integer(0L),
    nreach   = as.integer(nreach),
    nnode    = as.integer(nnode),
    data2    = as.double(data2),
    incddsrc = as.double(incddsrc_c),
    carryf   = as.double(carryf_c),
    ee       = as.double(ee), PACKAGE = "rsparrow"
  )
  pload_total <- return_data$ee

  # ------------------------------------------------------------------
  # Total decayed load (with monitoring adjustment)
  # ------------------------------------------------------------------
  return_data <- .Fortran("ptnoder",
    ifadjust = as.integer(1L),
    nreach   = as.integer(nreach),
    nnode    = as.integer(nnode),
    data2    = as.double(data2),
    incddsrc = as.double(incddsrc_c),
    carryf   = as.double(carryf_c),
    ee       = as.double(ee), PACKAGE = "rsparrow"
  )
  mpload_total <- return_data$ee

  # ------------------------------------------------------------------
  # Total non-decayed load
  # ------------------------------------------------------------------
  incddsrc_nd_c <- ifelse(is.na(dddliv), 0, dddliv)
  carryf_nd_c   <- ifelse(is.na(carryf_nd), 0, carryf_nd)
  return_data <- .Fortran("ptnoder",
    ifadjust = as.integer(0L),
    nreach   = as.integer(nreach),
    nnode    = as.integer(nnode),
    data2    = as.double(data2),
    incddsrc = as.double(incddsrc_nd_c),
    carryf   = as.double(carryf_nd_c),
    ee       = as.double(ee), PACKAGE = "rsparrow"
  )
  pload_nd_total <- return_data$ee

  # ------------------------------------------------------------------
  # Per-source loads — named lists (replaces assign/srclist_total etc.)
  # ------------------------------------------------------------------
  pload_src    <- vector("list", jjsrc)
  mpload_src   <- vector("list", jjsrc)
  pload_nd_src <- vector("list", jjsrc)
  names(pload_src)    <- Parmnames[seq_len(jjsrc)]
  names(mpload_src)   <- Parmnames[seq_len(jjsrc)]
  names(pload_nd_src) <- Parmnames[seq_len(jjsrc)]

  for (j in seq_len(jjsrc)) {
    ddliv_j <- as.matrix(
      (ddliv2[, j] * data[, data.index.list$jsrcvar[j]]) * beta1[, data.index.list$jbsrcvar[j]]
    )

    # Decayed total source load
    incddsrc_j <- ifelse(is.na(rchdcayf^0.5 * resdcayf * ddliv_j), 0,
                         rchdcayf^0.5 * resdcayf * ddliv_j)
    carryf_j   <- ifelse(is.na(data[, data.index.list$jfrac] * rchdcayf * resdcayf), 0,
                         data[, data.index.list$jfrac] * rchdcayf * resdcayf)
    return_data <- .Fortran("ptnoder",
      ifadjust = as.integer(0L),
      nreach   = as.integer(nreach),
      nnode    = as.integer(nnode),
      data2    = as.double(data2),
      incddsrc = as.double(incddsrc_j),
      carryf   = as.double(carryf_j),
      ee       = as.double(ee), PACKAGE = "rsparrow"
    )
    pload_src[[Parmnames[j]]]  <- return_data$ee
    mpload_src[[Parmnames[j]]] <- return_data$ee  # initial; overwritten below if numsites > 0

    # Non-decayed total source load
    incddsrc_nd_j <- ifelse(is.na(ddliv_j), 0, ddliv_j)
    carryf_nd_j   <- ifelse(is.na(data[, data.index.list$jfrac]), 0,
                            data[, data.index.list$jfrac])
    return_data <- .Fortran("ptnoder",
      ifadjust = as.integer(0L),
      nreach   = as.integer(nreach),
      nnode    = as.integer(nnode),
      data2    = as.double(data2),
      incddsrc = as.double(incddsrc_nd_j),
      carryf   = as.double(carryf_nd_j),
      ee       = as.double(ee), PACKAGE = "rsparrow"
    )
    pload_nd_src[[Parmnames[j]]] <- return_data$ee
  }

  # ------------------------------------------------------------------
  # Monitoring-adjusted source loads (requires numsites > 0)
  # ------------------------------------------------------------------
  if (numsites > 0) {
    for (j in seq_len(jjsrc)) {
      share <- pload_src[[Parmnames[j]]] / pload_total
      share <- ifelse(is.na(share), 0, share)

      ddliv_j <- as.matrix(
        (ddliv2[, j] * data[, data.index.list$jsrcvar[j]]) * beta1[, data.index.list$jbsrcvar[j]]
      )
      incddsrc_j <- ifelse(is.na(rchdcayf^0.5 * resdcayf * ddliv_j), 0,
                           rchdcayf^0.5 * resdcayf * ddliv_j)
      carryf_j   <- ifelse(is.na(data[, data.index.list$jfrac] * rchdcayf * resdcayf), 0,
                           data[, data.index.list$jfrac] * rchdcayf * resdcayf)
      return_data <- .Fortran("mptnoder",
        ifadjust = as.integer(1L),
        share    = as.double(share),
        nreach   = as.integer(nreach),
        nnode    = as.integer(nnode),
        data2    = as.double(data2),
        incddsrc = as.double(incddsrc_j),
        carryf   = as.double(carryf_j),
        ee       = as.double(ee), PACKAGE = "rsparrow"
      )
      mpload_src[[Parmnames[j]]] <- return_data$ee
    }
  }

  list(
    pload_total    = pload_total,
    mpload_total   = mpload_total,
    pload_nd_total = pload_nd_total,
    pload_inc      = pload_inc,
    pload_src      = pload_src,
    mpload_src     = mpload_src,
    pload_nd_src   = pload_nd_src,
    pload_inc_src  = pload_inc_src,
    rchdcayf       = rchdcayf,
    resdcayf       = resdcayf,
    ddliv2         = ddliv2,
    incdecay       = incdecay,
    totdecay       = totdecay,
    nnode          = nnode,
    data2          = data2
  )
}
