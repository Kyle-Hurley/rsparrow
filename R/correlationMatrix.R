#' @title correlationMatrix
#' @description Calculates summary metrics and bivariate correlations between user-selected
#'            variables in `subdata` for incremental areas of monitoring sites and for all reaches. Outputs
#'            (run_id)_explvars_correlations.txt and (run_id)_explvars_correlations.pdf files. \cr \cr
#' Executed By: startModelRun.R \cr
#' Executes Routines: \itemize{\item named.list.R
#'             \item outcharfun.R
#'             \item sumIncremAttributes.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param subdata data.frame input data (subdata)
#' @return `outchar`  named list output `Cor.ExplanVars.list` containing
#' \tabular{ll}{
#' `names` \tab  character vector defined as
#'               `SelParmValues$sparrowNames[SelParmValues$bCorrGroup==1]` where
#'               `SelParmValues` is the data.frame of selected parameters \cr
#' `cmatrixM_all` \tab matrix for summary metric checks where `nrow=max(subdata$staidseq)`
#'                     and `ncol=length(names)` data from merge of `subdata` and
#'                     `siteiarea` which is output of `sumIncremAttributes()` \cr
#' `cmatrixM_filter` \tab `cmatrixM_all` with zeros replaced by column minimums \cr
#' `cor.allValuesM` \tab output of `stats::cor()` function with spearman method applied to
#'                       `cmatrixM_all` \cr
#' `cmatrix_all` \tab matrix for summary metric checks where `nrow=nrow(subdata)`
#'                     and `ncol=length(names)` data from  `subdata`  \cr
#' `cmatrix_filter` \tab `cmatrix_all` with zeros replaced by column minimums \cr
#' `cor.allValues` \tab output of `stats::cor()` function with spearman method applied to
#'                       `cmatrix_all` \cr
#' `cor.sampleValues` \tab output of `stats::cor()` function with spearman method applied
#'                         to a sample of `cmatrix_all`.  Sampling created by `dplyr::sample_n()`
#'                         function where number of samples is 500 unless `nrow(cmatrix_all)<0`
#'                         then number of samples equal to `nrow(cmatrix_all)`
#' `cor.sampleLogValues` \tab similar to `cor.sampleValues` but applied to `log10(cmatrix_all)`
#' `nsamples` \tab number of samples used to create `cor.sampleValues` and `cor.sampleLogValues`
#'                 equal to 500 unless `nrow(cmatrix_all)<500` then `nsamples=nrow(cmatrix_all)`
#' }
#' @keywords internal
#' @noRd

correlationMatrix <- function(file.output.list, SelParmValues, subdata) {
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id

  # set max samples
  maxsamples <- 500
  # select user-specified names from 'parmCorrGroup' in the parameters.csv file
  names <- SelParmValues$sparrowNames[SelParmValues$bCorrGroup == 1]
  ntype <- SelParmValues$betatype[SelParmValues$bCorrGroup == 1]

  if (!requireNamespace("car", quietly = TRUE))
    stop("Package 'car' is needed. Install with: install.packages('car')", call. = FALSE)
  if (!requireNamespace("dplyr", quietly = TRUE))
    stop("Package 'dplyr' is needed. Install with: install.packages('dplyr')", call. = FALSE)

  rows <- nrow(subdata)
  cmatrix <- matrix(0, nrow = rows, ncol = length(names))
  for (i in 1:length(names)) {
    xx <- subdata[[names[i]]]
    cmatrix[, i] <- xx
  }
  colnames(cmatrix) <- names


  # Store matrices for summary metric checks
  cmatrix_all <- cmatrix
  # convert 0 values to minimum positive value to allow log transformation
  cmatrix_filter <- cmatrix
  for (i in 1:length(names)) {
    cmin <- min(cmatrix[cmatrix[, i] != 0, i])
    cmatrix_filter[, i] <- ifelse(cmatrix[, i] == 0, cmin, cmatrix[, i])
  }

  ################################################
  # obtain matrix with area-weighted mean explanatory variable for incremental areas between nested monitoring sites

  # setup 'df' with incremental site area for use in area-weighting each metric
  waterid <- subdata$waterid
  demiarea <- subdata$demiarea
  idseq <- subdata$staidseq
  df <- data.frame(waterid, demiarea, idseq)
  siteiarea <- sumIncremAttributes(idseq, demiarea, "siteincarea") # sum incremental area by unique siteIDs
  df <- siteiarea

  # Code executes 'sumIncremAttributes' function for each explanatory variable:
  # Forest percentage example
  # siteiarea <- sumIncremAttributes(idseq,subdata$forest,"forest_pct")
  # df <- merge(df,siteiarea,by="idseq",all.y=FALSE,all.x=TRUE)
  # df$forest_pct <- df$forest_pct / df$siteincarea * 100
  numsites <- max(subdata$staidseq)
  cmatrixM <- matrix(0, nrow = numsites, ncol = length(names))
  if (numsites > 10) {
    for (i in 1:length(names)) {
      xx <- subdata[[names[i]]] * demiarea # area weight variable
      siteiarea <- sumIncremAttributes(idseq, xx, names[i])
      df <- merge(df, siteiarea, by = "idseq", all.y = FALSE, all.x = TRUE)
      df <- df[with(df, order(df$idseq)), ] # sort by site ID
      cmatrixM[, i] <- df[[names[i]]] / df$siteincarea # compute mean
    }
    colnames(cmatrixM) <- names

    # Store matrices for summary metric checks
    cmatrixM_all <- cmatrixM
    # convert 0 values to minimum positive value to allow log transformation
    cmatrixM_filter <- cmatrixM
    for (i in 1:length(names)) {
      cmin <- min(cmatrixM[cmatrixM[, i] != 0, i])
      cmatrixM_filter[, i] <- ifelse(cmatrixM[, i] == 0, cmin, cmatrixM[, i])
    }
  }


  ################################################
  # Output Results



  #################################################
  # Area-weighted means for the incremental area of monitoring sites

  if (numsites > 10) {
    par(mfrow = c(1, 1))
    strExplanation <- paste("
      Correlation plots for incremental area of monitoring sites includes the following:
        -Scatter Plot Matrix with Lowess smooths for the raw data
        -Boxplots of the logged raw values of the explanatory variables
      ")

    gplots::textplot(strExplanation, valign = "top", cex = 0.7)
    title("Correlation Results for Explanatory Variables (Site Inc. Areas)")

    # plots
    cmatrixM <- na.omit(cmatrixM) # omit rows with NA values
    df <- data.frame(cmatrixM)
    colnames(df) <- names
    cor.allValuesM <- cor(df, method = c("spearman"), use = "pairwise.complete.obs")

    # car::scatterplotMatrix(df,diagonal="boxplot",reg.line=FALSE,use="pairwise.complete.obs",spread=FALSE,smooth=TRUE)
    car::scatterplotMatrix(df,
      diagonal = "boxplot", reg.line = FALSE, use = "pairwise.complete.obs", spread = FALSE,
      smooth = list(smoother = loessLine, var = FALSE, lty.var = 2, lty.var = 4)
    )
    boxplot(log(df))
  }

  #################################################
  # Reach-level raw data

  par(mfrow = c(1, 1))
  strExplanation <- paste("
      Correlation plots for reach-level data includes the following:
        -Scatter Plot Matrix with Lowess smooths for the raw data
        -Boxplots of the raw values of the explanatory variables
        -Scatter Plot Matrix with Lowess smooths for the log-transformed data
        -Boxplots of the log-transformed values of the explanatory variables

         (note that zero values are converted to minimum of non-zero values for the
          log-transformed data)
      ")

  gplots::textplot(strExplanation, valign = "top", cex = 0.7)
  title("Correlation Results for Explanatory Variables (Reaches)")


  # plots
  cmatrix <- na.omit(cmatrix) # omit rows with NA values
  df <- data.frame(cmatrix)
  colnames(df) <- names
  cor.allValues <- cor(df, method = c("spearman"), use = "pairwise.complete.obs")

  nsamples <- ifelse(rows < maxsamples, rows, maxsamples)

  # Untransformed data
  sdf <- dplyr::sample_n(df, nsamples)
  cor.sampleValues <- cor(sdf, method = c("spearman"), use = "pairwise.complete.obs")
  # maximum size limited to 6472 observations
  car::scatterplotMatrix(sdf,
    diagonal = "boxplot", reg.line = FALSE, use = "pairwise.complete.obs", spread = FALSE,
    smooth = list(smoother = loessLine, var = FALSE, lty.var = 2, lty.var = 4)
  )

  boxplot(sdf)

  # Transformed data
  # convert 0 values to minimum positive value to allow log transformation
  for (i in 1:length(names)) {
    cmin <- min(cmatrix[cmatrix[, i] != 0, i])
    cmatrix[, i] <- ifelse(cmatrix[, i] == 0, cmin, cmatrix[, i])
  }
  cmatrix <- data.frame(log10(cmatrix)) # log transformation
  df <- data.frame(cmatrix)
  colnames(df) <- names
  sdf <- dplyr::sample_n(df, nsamples)
  cor.sampleLogValues <- cor(sdf, method = c("spearman"), use = "pairwise.complete.obs")

  # remove variables based on correlations with NAs and resample transformed data
  xnames <- numeric(length(names))
  for (i in 2:length(names)) {
    for (j in 1:(i - 1)) {
      if (is.na(cor.sampleLogValues[i, j])) {
        xnames[i] <- 1 + xnames[i]
        xnames[j] <- 1 + xnames[j]
      }
    }
  }
  cols <- sum(ifelse(xnames <= 1, 1, 0))
  cmatrix <- matrix(0, nrow = rows, ncol = cols)
  nnames <- names[xnames <= 1]
  j <- 0
  for (i in 1:length(xnames)) {
    if (xnames[i] <= 1) {
      j <- j + 1
      xx <- subdata[[nnames[j]]]
      cmatrix[, j] <- xx
    }
  }
  colnames(cmatrix) <- nnames

  cmatrix <- na.omit(cmatrix) # omit rows with NA values
  # convert 0 values to minimum positive value to allow log transformation
  for (i in 1:length(nnames)) {
    cmin <- min(cmatrix[cmatrix[, i] != 0, i])
    cmatrix[, i] <- ifelse(cmatrix[, i] == 0, cmin, cmatrix[, i])
  }
  cmatrix <- data.frame(log10(cmatrix)) # log transformation
  df <- data.frame(cmatrix)
  nsamples <- ifelse(rows < maxsamples, rows, maxsamples)
  sdf <- dplyr::sample_n(df, nsamples)
  # maximum size limited to 6472 observations
  car::scatterplotMatrix(sdf,
    diagonal = "boxplot", reg.line = FALSE, use = "pairwise.complete.obs", spread = FALSE,
    smooth = list(smoother = loessLine, var = FALSE, lty.var = 2, lty.var = 4)
  )
  boxplot(sdf)



  # save correlation matrices for output to tables
  Cor.ExplanVars.list <- named.list(
    names, cmatrixM_all, cmatrixM_filter, cor.allValuesM,
    cmatrix_all, cmatrix_filter, cor.allValues, cor.sampleValues, cor.sampleLogValues,
    nsamples
  )


  ###################################################
  # Output text file

  # define "space" for printing
  ch <- character(1)
  space <- data.frame(ch)
  row.names(space) <- ch
  colnames(space) <- c(" ")


  #########################################
  # Monitoring site incremental area results

  if (numsites > 10) {
    print(outcharfun("CORRELATION MATRICES FOR EXPLANATORY VARIABLES (Site Incremental Areas)"))

    print(outcharfun("SPEARMAN CORRELATIONS FOR ALL OBSERVATIONS"))
    print(cor.allValuesM)

    print(space)
    print(outcharfun("SUMMARY METRICS FOR EXPLANATORY VARIABLES (Site Incremental Areas)"))
    print(summary(cmatrixM_all))

    print(outcharfun("FILTERED SUMMARY METRICS FOR EXPLANATORY VARIABLES (zero values converted to minimum of non-zero values)"))
    print(summary(cmatrixM_filter))
  }

  #########################################
  # Reach-level results

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


  print(space)
  print(outcharfun("SUMMARY METRICS FOR EXPLANATORY VARIABLES (Reaches)"))
  print(summary(cmatrix_all))

  print(outcharfun("FILTERED SUMMARY METRICS FOR EXPLANATORY VARIABLES (zero values converted to minimum of non-zero values)"))
  print(summary(cmatrix_filter))


  return(Cor.ExplanVars.list)
} # end function
