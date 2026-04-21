#' rsparrow: SPARROW Water Quality Modeling in R
#'
#' Implements the USGS SPARROW (SPAtially Referenced Regressions On Watershed
#' attributes) model for estimating contaminant sources, watershed delivery,
#' and in-stream transport in river networks.
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{rsparrow_model}}: Estimate a SPARROW model
#'   \item \code{\link{predict.rsparrow}}: Predict loads and yields
#'   \item \code{\link{summary.rsparrow}}: Summarize estimation results
#'   \item \code{\link{rsparrow_hydseq}}: Compute hydrological sequencing
#' }
#'
#' @docType package
#' @name rsparrow-package
#' @aliases rsparrow
#'
#' @useDynLib rsparrow, .registration = TRUE
#'
#' @importFrom nlmrt nlfb
#' @importFrom numDeriv jacobian hessian
#'
#' @importFrom stats aggregate cor lm na.omit na.exclude pchisq pnorm qchisq
#' @importFrom stats qnorm qqline qqnorm quantile residuals sd weighted.mean
#' @importFrom stats coef predict vcov median var pt
#' @importFrom utils read.csv write.csv head tail str packageVersion
#' @importFrom grDevices dev.off pdf png colorRampPalette
#' @importFrom graphics abline legend lines par plot points text title hist
#'
#' @keywords internal
"_PACKAGE"
