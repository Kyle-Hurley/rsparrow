#' @title estimateNLLStable
#' @description Outputs all model performance and other summary metrics and diagnostics for the
#'            estimated model for calibration and validates sites to the ~/estimate/(run_id)_summary.txt
#'            file.  \cr \cr
#' Executed By: estimate.R \cr
#' Executes Routines: \itemize{\item outcharfun.R} \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param if_estimate yes/no indicating whether or not estimation is run
#' @param if_estimate_simulation character string setting from sparrow_control.R indicating
#'       whether estimation should be run in simulation mode only.
#' @param ifHess yes/no indicating whether second-order Hessian standard errors should be
#'       computed
#' @param if_sparrowEsts value of 1 `if_estimate_simulation<-'no'` indicating calculation of
#'       Jacobian diagnostics and 0 `if_estimate_simulation<-'yes'` indicating no calculation of Jacobian diagnostics
#' @param classvar character vector of user specified spatially contiguous discrete
#'       classification variables from sparrow_control.  First element is reach classification variable.
#' @param sitedata Sites selected for calibration using `subdata[(subdata$depvar > 0
#'                & subdata$calsites==1), ]`. The object contains the dataDictionary
#'                ‘sparrowNames’ variables, with records sorted in hydrological
#'                (upstream to downstream) order (see the documentation Chapter
#'                sub-section 5.1.2 for details)
#' @param numsites number of sites selected for calibration
#' @param ANOVA.list list output of  model performance-related variables for the calibration sites
#'                  from `estimateNLLSmetrics.R` contained in the estimate.list object. For more
#'                  details see documentation Section 5.2.4.8
#' @param JacobResults list output of Jacobian first-order partial derivatives of the model
#'       residuals `estimateNLLSmetrics.R` contained in the estimate.list object.  For more details see
#'       documentation Section 5.2.4.5.
#' @param HesResults list output of Hessian second-order standard errors
#'       `estimateNLLSmetrics.R` contained in the estimate.list object.  For more details see
#'       documentation Section 5.2.4.6
#' @param sparrowEsts list object contained in estimate.list `if_estimate<-'yes'`.  For more
#'       details see documentation Section 5.2.4.4.
#' @param Mdiagnostics.list list output containing summary variables for calibration sites from
#'                         `estimateNLLSmetrics.R` contained in the estimate.list object.  For
#'                         more details see documentation Section 5.2.4.7.
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R`
#' @param if_validate yes/no indicating whether or not validation is run
#' @param vANOVA.list list output of  model performance-related variables for the validation sites
#'                   from `validateMetrics.R` contained in the estimate.list object. For more details
#'                   see documentation Section 5.2.4.15
#' @param vMdiagnostics.list list output containing summary variables for validation sites from
#'                          `validateMetrics.R` contained in the estimate.list object.  For more
#'                          details see documentation Section 5.2.4.14.
#' @param betavalues data.frame of model parameters from parameters.csv
#' @param Csites.weights.list regression weights as proportional to incremental area size
#' @keywords internal
#' @noRd


estimateNLLStable <- function(file.output.list, if_estimate, if_estimate_simulation, ifHess, if_sparrowEsts,
                              classvar, sitedata, numsites,
                              estimate.list,
                              Cor.ExplanVars.list,
                              if_validate, vANOVA.list, vMdiagnostics.list,
                              betavalues, Csites.weights.list) {
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator <- file.output.list$csv_columnSeparator
  if_corrExplanVars <- file.output.list$if_corrExplanVars
  add_vars <- file.output.list$add_vars

  JacobResults <- estimate.list$JacobResults
  ANOVA.list <- estimate.list$ANOVA.list
  Mdiagnostics.list <- estimate.list$Mdiagnostics.list
  sparrowEsts <- estimate.list$sparrowEsts
  HesResults <- estimate.list$HesResults

  # Extract variables from lists
  weight <- Csites.weights.list$weight
  NLLS_weights <- Csites.weights.list$NLLS_weights
  tiarea <- Csites.weights.list$tiarea

  Obs <- Mdiagnostics.list$Obs
  predict <- Mdiagnostics.list$predict
  yldobs <- Mdiagnostics.list$yldobs
  yldpredict <- Mdiagnostics.list$yldpredict
  ratio.obs.pred <- Mdiagnostics.list$ratio.obs.pred
  xlat <- Mdiagnostics.list$xlat
  xlon <- Mdiagnostics.list$xlon
  pratio.obs.pred <- Mdiagnostics.list$pratio.obs.pred
  classgrp <- Mdiagnostics.list$classgrp
  RMSEnn <- Mdiagnostics.list$RMSEnn
  SSEclass <- Mdiagnostics.list$SSEclass
  pSSEclass <- Mdiagnostics.list$pSSEclass
  pResids <- Mdiagnostics.list$pResids
  standardResids <- Mdiagnostics.list$standardResids
  CooksD <- Mdiagnostics.list$CooksD
  CooksDpvalue <- Mdiagnostics.list$CooksDpvalue
  leverage <- Mdiagnostics.list$leverage
  leverageCrit <- Mdiagnostics.list$leverageCrit

  Parmnames <- JacobResults$Parmnames
  oEstimate <- JacobResults$oEstimate
  btype <- JacobResults$btype
  esttype <- JacobResults$esttype
  Beta.inital <- JacobResults$Beta.inital
  bmin <- JacobResults$bmin
  bmax <- JacobResults$bmax
  oSEj <- JacobResults$oSEj
  oTj <- JacobResults$oTj
  opTj <- JacobResults$opTj
  oVIF <- JacobResults$oVIF
  odesign <- JacobResults$odesign
  e_val_spread <- JacobResults$e_val_spread
  ppcc <- JacobResults$ppcc
  shap.test <- JacobResults$shap.test
  shap.p <- JacobResults$shap.p
  mean_exp_weighted_error <- JacobResults$mean_exp_weighted_error
  boot_resid <- JacobResults$boot_resid
  e_vec <- JacobResults$e_vec
  jacobian <- JacobResults$jacobian

  mobs <- ANOVA.list$mobs
  npar <- ANOVA.list$npar
  DF <- ANOVA.list$DF
  SSE <- ANOVA.list$SSE
  MSE <- ANOVA.list$MSE
  RMSE <- ANOVA.list$RMSE
  RSQ <- ANOVA.list$RSQ
  RSQ_ADJ <- ANOVA.list$RSQ_ADJ
  RSQ_YLD <- ANOVA.list$RSQ_YLD
  PBias <- ANOVA.list$PBias
  pSSE <- ANOVA.list$pSSE
  pMSE <- ANOVA.list$pMSE
  pRMSE <- ANOVA.list$pRMSE
  pRSQ <- ANOVA.list$pRSQ
  pRSQ_ADJ <- ANOVA.list$pRSQ_ADJ
  pRSQ_YLD <- ANOVA.list$pRSQ_YLD
  pPBias <- ANOVA.list$pPBias

  if (!identical(NA, Cor.ExplanVars.list)) {
    cor.allValuesM <- Cor.ExplanVars.list$cor.allValuesM
    cmatrixM_all <- Cor.ExplanVars.list$cmatrixM_all
    cmatrixM_filter <- Cor.ExplanVars.list$cmatrixM_filter
    cor.allValues <- Cor.ExplanVars.list$cor.allValues
    cor.sampleValues <- Cor.ExplanVars.list$cor.sampleValues
    cor.sampleLogValues <- Cor.ExplanVars.list$cor.sampleLogValues
    cmatrix_all <- Cor.ExplanVars.list$cmatrix_all
    cmatrix_filter <- Cor.ExplanVars.list$cmatrix_filter
    nsamples <- Cor.ExplanVars.list$nsamples
  }
  if (ifHess == "yes" & if_estimate_simulation == "no") {
    Hesnames <- HesResults$Hesnames
    oSEh <- HesResults$oSEh
    oTh <- HesResults$oTh
    opTh <- HesResults$opTh
    cov2 <- HesResults$cov2
    cor2 <- HesResults$cor2
  }

  # get description and units from betavalues
  betavalues <- betavalues[, which(names(betavalues) %in% c("sparrowNames", "description", "parmUnits"))]


  # define "space" for printing
  ch <- character(1)
  space <- data.frame(ch)
  row.names(space) <- ch
  colnames(space) <- c(" ")


  ##################################

  print(outcharfun("SPARROW NLLS MODEL SUMMARY"))
  print(outcharfun(paste0("MODEL NAME: ", run_id)))
  print(outcharfun(paste0("RESULTS PATH: ", path_results)))
  print(space)

  dd <- data.frame(mobs, npar, DF, SSE, MSE, RMSE, RSQ, RSQ_ADJ, RSQ_YLD, PBias)
  colnames(dd) <- c("MOBS", "NPARM", "DF", "SSE", "MSE", "RMSE", "RSQ", "RSQ-ADJUST", "RSQ-YIELD", "PERCENT BIAS")
  ch <- character(1)
  row.names(dd) <- ch

  # only output estimation performance is model estimated (i.e., simulation)
  if (if_estimate == "yes") {
    print(outcharfun("MODEL ESTIMATION PERFORMANCE (Monitoring-Adjusted Predictions)"))
    print(dd)
  }

  dd <- data.frame(mobs, npar, DF, pSSE, pMSE, pRMSE, pRSQ, pRSQ_ADJ, pRSQ_YLD, pPBias)
  colnames(dd) <- c("MOBS", "NPARM", "DF", "SSE", "MSE", "RMSE", "RSQ", "RSQ-ADJUST", "RSQ-YIELD", "PERCENT BIAS")
  ch <- character(1)
  row.names(dd) <- ch
  print(outcharfun("MODEL SIMULATION PERFORMANCE (Simulated Predictions)"))
  print(dd)

  if (if_estimate == "yes") {
    writeLines("\n   Simulated predictions are computed using mean coefficients from the NLLS model \n     that was estimated with monitoring-adjusted (conditioned) predictions\n")
  }

  ##########################################################

  if (if_validate == "yes" & if_estimate_simulation == "no") {
    mobs <- vANOVA.list$mobs
    pSSE <- vANOVA.list$pSSE
    pMSE <- vANOVA.list$pMSE
    pRMSE <- vANOVA.list$pRMSE
    pRSQ <- vANOVA.list$pRSQ
    pRSQ_ADJ <- vANOVA.list$pRSQ_ADJ
    pRSQ_YLD <- vANOVA.list$pRSQ_YLD
    pPBias <- vANOVA.list$pPBias
    dd <- data.frame(mobs, pSSE, pMSE, pRMSE, pRSQ, pRSQ_ADJ, pRSQ_YLD, pPBias)
    colnames(dd) <- c("MOBS", "SSE", "MSE", "RMSE", "RSQ", "RSQ-ADJUST", "RSQ-YIELD", "PERCENT BIAS")
    ch <- character(1)
    row.names(dd) <- ch
    print(outcharfun("MODEL VALIDATION PERFORMANCE (Simulated Predictions)"))
    print(dd)
  }

  print(outcharfun("PARAMETER SUMMARY"))
  # print parameter estimates w/o standard errors
  dd <- data.frame(Parmnames, oEstimate, btype, esttype, Beta.inital, bmin, bmax)
  colnames(dd) <- c("PARAMETER", "ESTIMATE", "PARM TYPE", "EST TYPE", "INITIAL VALUE", "MIN", "MAX")
  dd$rname <- as.numeric(row.names(dd))
  dd <- merge(dd, betavalues, by.y = "sparrowNames", by.x = "PARAMETER")
  dd <- dd[with(dd, order(dd$rname)), ]
  dd <- within(dd, rm(rname)) # drop rname
  colnames(dd) <- c("PARAMETER", "ESTIMATE", "PARM TYPE", "EST TYPE", "INITIAL VALUE", "MIN", "MAX", "DESCRIPTION", "PARAMETER UNITS")
  ch <- character(1) # changed from (2)  9-11-2014
  for (i in 1:length(Parmnames)) {
    ch[i] <- as.character(i)
  }
  row.names(dd) <- ch
  print(dd, right = FALSE)

  if (sum(ifelse(esttype == "Fixed", 1, 0)) > 0) { # at least one Fixed parameter type found
    writeLines("\n   A 'Fixed' parameter estimation type (EST TYPE) indicates a user choice of a constant \n     coefficient value or a coefficient estimate equal to zero, the minimum or maximum  \n     boundary value (this may indicate a statistically insignificant coefficient, a \n     coefficient with a value outside of the bounds, or an unusually small initial \n     parameter value).")
  }

  # options for weighted SPARROW optimization
  if (identical(NLLS_weights, "lnload")) {
    writeLines("\n   The model was estimated with a weighted error variance. The weights are proportional \n     to the log predicted load to account for heteroscedasticity.")
    x <- paste0("\n   NLLS_weights control setting = ", NLLS_weights)
    writeLines(x)
  }
  if (identical(NLLS_weights, "user")) {
    writeLines("\n   The model was estimated with a weighted error variance. The weights are assigned by the user, expressed as the \n     reciprocal of the variance proportional to user-selected variables.")
    x <- paste0("\n   NLLS_weights control setting = ", NLLS_weights)
    writeLines(x)
  }


  if (if_estimate_simulation == "yes") {
    print(outcharfun(" Model simulation executed using intial values of parameters"))
  }

  if (if_estimate == "yes" & if_estimate_simulation == "no") {
    # print parameter estimates with Jacobian SEs
    ddJ <- data.frame(Parmnames, btype, oEstimate, oSEj, oTj, opTj, oVIF)
    ddJ$rname <- as.numeric(row.names(ddJ))
    colnames(ddJ) <- c("PARAMETER", "PARM TYPE", "ESTIMATE", "SE(Jcb)", "T(Jcb)", "P-VALUE(Jcb)", "VIF", "rname")
    ddJ <- merge(ddJ, betavalues, by.y = "sparrowNames", by.x = "PARAMETER")
    colnames(ddJ) <- c("PARAMETER", "PARM TYPE", "ESTIMATE", "SE(Jcb)", "T(Jcb)", "P-VALUE(Jcb)", "VIF", "rname", "DESCRIPTION", "PARAMETER UNITS")
    ch <- character(1)
    for (i in 1:length(Parmnames)) {
      ch[i] <- as.character(i)
    }
    row.names(ddJ) <- ch
    if (ifHess == "no") {
      print(outcharfun("PARAMETER ESTIMATES"))
      ddJ <- ddJ[with(ddJ, order(ddJ$rname)), ]
      ddJ <- within(ddJ, rm(rname)) # drop rname
      ch <- character(1)
      for (i in 1:length(Parmnames)) {
        ch[i] <- as.character(i)
      }
      row.names(ddJ) <- ch
      print(ddJ, right = FALSE)
      print(space)
    }


    if (ifHess == "yes" & if_estimate_simulation == "no") {
      # print parameter estimates with Hessian SEs
      ddH <- data.frame(Parmnames, btype, oEstimate, oSEh, oTh, opTh)
      ddH$rname <- as.numeric(row.names(ddH))
      colnames(ddH) <- c("PARAMETER", "PARM TYPE", "ESTIMATE", "SE", "T", "P-VALUE", "rname")
      dd <- merge(ddH, ddJ, by = c("rname", "PARAMETER", "PARM TYPE", "ESTIMATE"))
      dd <- dd[with(dd, order(dd$rname)), ]
      dd <- within(dd, rm(rname, "SE(Jcb)", "T(Jcb)", "P-VALUE(Jcb)")) # drop rname and Jacobian metrics
      ch <- character(1)
      for (i in 1:length(Parmnames)) {
        ch[i] <- as.character(i)
      }
      row.names(dd) <- ch
      print(outcharfun("PARAMETER ESTIMATES"))
      print(dd, right = FALSE)
    }
    print(space)
    dd <- data.frame(e_val_spread, ppcc, shap.test, shap.p, mean_exp_weighted_error)
    colnames(dd) <- c("EigenValue Spread", " Normal PPCC", " SWilks W", " P-Value", "  Mean Exp Weighted Error")
    ch <- " "
    row.names(dd) <- ch
    print(dd)

    # print design matrix selections for model execution
    if (sum(ifelse(JacobResults$btype == "DELIVF", 1, 0)) > 0) {
      dd <- as.data.frame(odesign)
      ndeliv <- ncol(odesign)
      nsrc <- nrow(odesign)
      row.names(dd) <- Parmnames[1:nsrc]
      colnames(dd) <- Parmnames[nsrc + 1:ndeliv]
      print(outcharfun("DESIGN MATRIX"))
      print(dd)
    }
  } # end if_estimate check


  # Residuals
  print(space)
  print("LOG RESIDUALS, Station quantiles", quote = FALSE)
  print(quantile(round(sparrowEsts$resid, digits = 3), c(0.025, 0.1, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9, 0.97)))

  # Standardized Residuals
  if (if_estimate == "yes" & if_estimate_simulation == "no") {
    x <- Mdiagnostics.list$standardResids
    if (exists("x")) {
      if (is.finite(JacobResults$mean_exp_weighted_error)) {
        print(space)
        print("STANDARDIZED RESIDUALS, Station quantiles", quote = FALSE)
        print(quantile(round(Mdiagnostics.list$standardResids, digits = 3), c(0.025, 0.16, 0.2, 0.3, 0.5, 0.7, 0.84, 0.9, 0.97)))

        if (JacobResults$mean_exp_weighted_error > 1.0E+3) {
          message("
  WARNING: THE Mean Exp Weighted Error PRINTED IN THE SUMMARY TEXT FILE
  IS EXCESSIVELY LARGE. THIS IS CAUSED BY A LARGE LEVERAGE AND MODEL RESIDUAL
  FOR A STATION. CHECK THE DATA FOR THE OUTLYING STATION. ALSO CONSIDER
  RE-ESTIMATING THE MODEL USING DIFFERENT INITIAL PARAMETER VALUES OR AFTER
  ELIMINATING VARIABLES WITH SMALL AND STATISTICALLY INSIGNIFICANT
  ESTIMATED COEFFICIENTS.
  ")
        }
      } else {
        message("
   WARNING: THE Mean Exp Weighted Error IS UNDEFINED, CAUSED BY A LEVERAGE VALUE OF ONE.
   A PARAMETER MAY HAVE BEEN IMPROPERLY ESTIMATED.
   EVALUATE DIFFERENT INITIAL VALUES FOR THE PARAMETERS, INCLUDING INITIAL VALUES
   CLOSER TO THE ESTIMATED COEFFICIENT VALUES, OR ELIMINATE VARIABLES WITH SMALL
   AND STATISTICALLY INSIGNIFICANT ESTIMATED COEFFICIENTS.
   DIAGNOSTIC PLOTS WERE NOT OUTPUT.")
      }
    }
  }

  # Prediction accuracy statistics
  print(space)
  print("RATIO OF OBSERVED TO PREDICTED LOAD, Station quantiles", quote = FALSE)
  print(quantile(round(ratio.obs.pred, digits = 3), c(0.025, 0.1, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9, 0.97)))

  # Observed yield statistics
  print(space)
  print("OBSERVED YIELD, percentiles", quote = FALSE)
  print(summary(yldobs))

  # Prediction yield statistics
  print(space)
  print("PREDICTED YIELD, percentiles", quote = FALSE)
  print(summary(yldpredict))


  if (if_validate == "yes" & if_estimate_simulation == "no") {
    vresids <- vMdiagnostics.list$pResids
    vratio <- vMdiagnostics.list$pratio.obs.pred
    # Validation Residuals
    print(space)
    print(outcharfun("MODEL VALIDATION (simulated predictions)"))
    print("LOG RESIDUALS, Station quantiles", quote = FALSE)
    print(quantile(round(vresids, digits = 3), c(0.025, 0.1, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9, 0.97)))
    # Validation accuracy metrics
    print(space)
    print(outcharfun("MODEL VALIDATION (simulated predictions)"))
    print("RATIO OF OBSERVED TO PREDICTED LOAD, Station quantiles", quote = FALSE)
    print(quantile(round(vratio, digits = 3), c(0.025, 0.1, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9, 0.97)))
  }

  if (!identical(NLLS_weights, "default")) {
    # Output weights percentiles
    print(space)
    print(outcharfun("MODEL WEIGHTS"))
    print("Model residual weights, Station quantiles", quote = FALSE)
    print(quantile(round(weight, digits = 5), c(0.025, 0.1, 0.2, 0.3, 0.5, 0.7, 0.8, 0.9, 0.97)))
  }

  sitedata[, "weight"] <- NULL # eliminate 'weight' and use more current value from Csites.weights.list object


  # output largest outliers
  Resids <- sparrowEsts$resid
  residCheck <- abs(standardResids)

  dd <- data.frame(sitedata, standardResids, Resids, leverage, leverageCrit, CooksD, CooksDpvalue, residCheck, weight, tiarea)
  dd1 <- subset(dd, dd$residCheck > 3 | dd$leverage > dd$leverageCrit | dd$CooksDpvalue < 0.10)
  keeps <- c(
    "waterid", "demtarea", "rchname", "station_id", "station_name", "staid",
    classvar[1], "standardResids", "Resids", "leverage", "leverageCrit", "CooksD", "CooksDpvalue", "weight", "tiarea", "residCheck"
  )

  # output largest outlier text
  ddnew <- dd1[keeps]
  print(space)
  print("LARGEST OUTLIERS", quote = FALSE)
  print("(absolute standardized residual>3, leverage>Critical value, or Cook's D p-value<0.10)", quote = FALSE)
  print(ddnew)


  # output CLASS region performance
  print(space)
  v <- rep(1:length(RMSEnn), 1)
  dd <- data.frame(classgrp, RMSEnn, SSEclass)
  colnames(dd) <- c("REGION", "NUMBER OF SITES", "SSE")
  ch <- character(1)
  for (i in 1:length(v)) {
    ch[i] <- as.character(i)
  }
  row.names(dd) <- ch
  print(outcharfun("REGIONAL MODEL PERFORMANCE (Monitoring-Adjusted Predictions)"))
  print(dd)



  print(space)
  v <- rep(1:length(RMSEnn), 1)
  dd <- data.frame(classgrp, pSSEclass)
  colnames(dd) <- c("REGION", "SSE")
  ch <- character(1)
  for (i in 1:length(v)) {
    ch[i] <- as.character(i)
  }
  row.names(dd) <- ch
  print(outcharfun("REGIONAL MODEL PERFORMANCE (Simulated Predictions)"))
  print(dd)


  if (ifHess == "yes" & if_estimate_simulation == "no") {
    # Output parameter covariances, correlations, and Eigenvalues and Eigenvectors
    # Covariances
    dd <- data.frame(cov2)
    colnames(dd) <- Hesnames
    ch <- character(1)
    ch <- Hesnames
    row.names(dd) <- ch


    print(outcharfun("PARAMETER COVARIANCES"))
    print(dd)
    print(space)
    # Correlations
    dd <- data.frame(cor2)
    colnames(dd) <- Hesnames
    ch <- character(1)
    ch <- Hesnames
    row.names(dd) <- ch
    print(outcharfun("PARAMETER CORRELATIONS"))
    print(dd)
    print(space)
    # Eigenvectors
    dd <- data.frame(e_vec)
    ch <- " "
    colnames(dd) <- rep(ch, times = ncol(dd))
    rNames <- Hesnames
    ch <- character(1)
    ch[1] <- "EigenValues"
    for (i in 2:(length(rNames) + 1)) {
      ch[i] <- rNames[i - 1]
    }
    row.names(dd) <- ch
    print(outcharfun("X'X EIGENVALUES AND EIGENVECTORS"))
    print(dd)
    print(space)
  } # end 'ifHess'

  # Explanatory variable correlations
  if (if_corrExplanVars == "yes" & !identical(NA, Cor.ExplanVars.list)) {
    if (numsites > 2) {
      print(outcharfun("CORRELATION MATRICES FOR EXPLANATORY VARIABLES (Site Incremental Areas)"))
      print(outcharfun("SPEARMAN CORRELATIONS FOR ALL OBSERVATIONS"))
      print(cor.allValuesM)

      print(outcharfun("SUMMARY METRICS FOR EXPLANATORY VARIABLES (Site Incremental Areas)"))
      print(summary(cmatrixM_all))

      print(outcharfun("FILTERED SUMMARY METRICS FOR EXPLANATORY VARIABLES (zero values converted to minimum of non-zero values)"))
      print(summary(cmatrixM_filter))
    }

    print(space)
    print(space)
    print(outcharfun("CORRELATION MATRICES FOR EXPLANATORY VARIABLES (Reaches)"))
    print(outcharfun("SPEARMAN CORRELATIONS FOR ALL OBSERVATIONS"))
    print(cor.allValues)
    xtext <- paste0("SPEARMAN CORRELATIONS FOR SUBSAMPLE OF OBSERVATIONS (n=", nsamples, ")")
    print(outcharfun(xtext))
    print(cor.sampleValues)
    print(outcharfun("SPEARMAN CORRELATIONS FOR SUBSAMPLED LOGGED OBSERVATIONS (zero values are converted to minimum of non-zero values)"))
    print(cor.sampleLogValues)

    print(outcharfun("SUMMARY METRICS FOR EXPLANATORY VARIABLES (Reaches)"))
    print(summary(cmatrix_all))

    print(outcharfun("FILTERED SUMMARY METRICS FOR EXPLANATORY VARIABLES (zero values converted to minimum of non-zero values)"))
    print(summary(cmatrix_filter))
  }


  # output Residuals file
  Resids <- sparrowEsts$resid
  Obsyield <- Obs / sitedata$demtarea
  predictYield <- predict / sitedata$demtarea


  origWaterid <- sitedata$waterid_for_RSPARROW_mapping
  dd <- data.frame(
    sitedata, origWaterid, Obs, predict, Obsyield, predictYield, Resids, standardResids, leverage, leverageCrit,
    CooksD, CooksDpvalue, boot_resid, weight, tiarea, pResids,
    ratio.obs.pred, pratio.obs.pred, xlat, xlon
  )

  keeps <- c(
    "waterid", "origWaterid", "demtarea", "rchname", "station_id", "station_name", "staid", classvar[1], "Obs",
    "predict", "Obsyield", "predictYield", "Resids", "standardResids", "leverage", "leverageCrit", "CooksD", "CooksDpvalue", "boot_resid", "weight", "tiarea", "pResids",
    "ratio.obs.pred", "pratio.obs.pred", "xlat", "xlon"
  )
  ddnew <- dd[keeps]

  # Add jacobian derivatives to the residuals file for estimated coefficients (JacobResults object variables)
  #  Derivatives not reported for "Fixed" coefficients
  if (if_estimate == "yes" & if_estimate_simulation == "no") {
    Parmnames <- Parmnames[JacobResults$bmin < JacobResults$bmax] # eliminate user-fixed coefficients
    esttype <- esttype[JacobResults$bmin < JacobResults$bmax]
    jcolNames <- Parmnames[esttype == "Estimated"] # eliminate any Fixed coefficients (zero or outside min/max bounds)
    jcolNames <- paste0(jcolNames, "_Jgradient")
    jacobian <- jacobian[, esttype == "Estimated"]
    jacobian <- as.matrix(jacobian)
    colnames(jacobian) <- jcolNames
    ddnew <- cbind(ddnew, jacobian)
  }

  if (length(na.omit(add_vars)) != 0) {
    add_data <- data.frame(sitedata[, which(names(sitedata) %in% add_vars)])
    if (length(add_vars) == 1) {
      names(add_data) <- add_vars
    }
    ddnew <- cbind(ddnew, add_data)
  }

} # end function
