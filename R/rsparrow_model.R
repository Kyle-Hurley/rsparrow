# =============================================================================
# rsparrow_model.R
# Composable API: rsparrow_prepare() + rsparrow_estimate() + thin wrapper
# =============================================================================


# -----------------------------------------------------------------------------
# rsparrow_prepare() -- Step 1 of composable workflow
# -----------------------------------------------------------------------------

#' Prepare Data for SPARROW Estimation
#'
#' Validates and transforms the input data frames into a format ready for
#' \code{\link{rsparrow_estimate}}. This is the first step of the composable
#' workflow. If you want a one-call interface, use
#' \code{\link{rsparrow_model}} instead.
#'
#' @param reaches Data frame. Reach network with topology and attributes.
#'   Required columns: \code{waterid}, \code{fnode}, \code{tnode},
#'   \code{frac}, \code{iftran}, \code{rchtype}, \code{demiarea},
#'   \code{demtarea}, \code{termflag}, \code{calsites}, \code{depvar},
#'   plus any SOURCE and DELIVF variable columns named in \code{parameters}.
#'   \code{hydseq} is computed automatically if absent.
#' @param parameters Data frame. Model parameter configuration. Required
#'   columns: \code{sparrowNames}, \code{parmInit}, \code{parmMin},
#'   \code{parmMax}, \code{parmType} (\code{"SOURCE"} or \code{"DELIVF"}).
#' @param design_matrix Data frame. Binary source-delivery association matrix.
#'   First column must be \code{sparrowNames} (SOURCE parameter names);
#'   remaining columns are DELIVF parameter names with values 0 or 1.
#' @param data_dictionary Data frame or \code{NULL} (default). Maps internal
#'   SPARROW variable names (\code{sparrowNames}) to data column names
#'   (\code{data1UserNames}). Required columns: \code{varType},
#'   \code{sparrowNames}, \code{data1UserNames}, \code{varunits}.
#'   When \code{NULL}, column names in \code{reaches} are used directly as
#'   SPARROW variable names (no renaming applied).
#'
#' @return An S3 object of class \code{"rsparrow_data"} containing the
#'   validated and transformed inputs, ready for \code{\link{rsparrow_estimate}}.
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_estimate}}, \code{\link{rsparrow_model}}
#'
#' @examples
#' \donttest{
#' # Composable workflow
#' sparrow_data <- rsparrow_prepare(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix
#' )
#' print(sparrow_data)
#' model <- rsparrow_estimate(sparrow_data)
#' }
rsparrow_prepare <- function(reaches,
                              parameters,
                              design_matrix,
                              data_dictionary = NULL) {

  inputs <- prep_sparrow_inputs(
    reaches         = reaches,
    parameters      = parameters,
    design_matrix   = design_matrix,
    data_dictionary = data_dictionary
  )

  structure(
    list(
      data1      = inputs$data1,
      betavalues = inputs$betavalues,
      dmatrixin  = inputs$dmatrixin,
      data_names = inputs$data_names
    ),
    class = "rsparrow_data"
  )
}


# -----------------------------------------------------------------------------
# print.rsparrow_data() -- S3 print method
# -----------------------------------------------------------------------------

#' Print an rsparrow_data Object
#'
#' @param x An object of class \code{"rsparrow_data"}.
#' @param ... Ignored.
#' @return \code{x}, invisibly.
#' @export
print.rsparrow_data <- function(x, ...) {
  nreach <- nrow(x$data1)
  nsource <- sum(x$betavalues$parmType == "SOURCE")
  ndelivf <- sum(x$betavalues$parmType == "DELIVF")
  npar    <- nsource + ndelivf
  ncal    <- if ("calsites" %in% names(x$data1))
               sum(x$data1$calsites == 1 & x$data1$depvar > 0, na.rm = TRUE)
             else NA_integer_

  cat("rsparrow_data\n")
  cat("  Reaches     :", nreach, "\n")
  cat("  Calibration sites (depvar > 0 & calsites == 1):", ncal, "\n")
  cat("  Parameters  :", npar,
      paste0("(", nsource, " SOURCE, ", ndelivf, " DELIVF)"), "\n")
  invisible(x)
}


# -----------------------------------------------------------------------------
# rsparrow_estimate() -- Step 2 of composable workflow
# -----------------------------------------------------------------------------

#' Estimate a SPARROW Model
#'
#' Fits a SPARROW model using nonlinear least squares given a prepared data
#' object from \code{\link{rsparrow_prepare}}. This is the second step of the
#' composable workflow.
#'
#' @param data An object of class \code{"rsparrow_data"} returned by
#'   \code{\link{rsparrow_prepare}}.
#' @param run_id Character. Name for this model run (default: \code{"run1"}).
#' @param output_dir Character or \code{NULL}. Directory for file output.
#'   \code{NULL} (default) runs entirely in memory with no file I/O.
#' @param if_estimate Logical. \code{TRUE} (default) runs NLLS optimisation.
#'   \code{FALSE} uses initial parameter values without fitting.
#' @param if_predict Logical. \code{TRUE} (default) computes reach-level
#'   predictions after estimation.
#' @param if_validate Logical. \code{FALSE} (default). \code{TRUE} splits
#'   monitoring sites into calibration and validation sets.
#' @param hessian Logical. \code{TRUE} (default) computes the Hessian
#'   (required for \code{\link{vcov.rsparrow}}).
#' @param mean_adjust Logical. \code{TRUE} (default) applies mean-adjustment
#'   to delivery variables.
#' @param weights Character. NLLS weighting scheme. \code{"default"} (scalar
#'   1), \code{"lnload"}, or \code{"user"}.
#' @param s_offset Numeric. Offset for objective function scaling
#'   (default: \code{1e14}).
#' @param load_units Character. Units label for loads (default:
#'   \code{"kg/year"}).
#' @param yield_units Character. Units label for yields (default:
#'   \code{"kg/ha/year"}).
#' @param yield_factor Numeric. Conversion factor for yields (default:
#'   \code{0.01}).
#' @param conc_units Character. Units label for concentrations (default:
#'   \code{"mg/L"}).
#' @param conc_factor Numeric. Conversion factor for concentrations (default:
#'   \code{1.0}).
#'
#' @return An S3 object of class \code{"rsparrow"}. See
#'   \code{\link{rsparrow_model}} for the full structure description.
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_prepare}}, \code{\link{rsparrow_model}},
#'   \code{\link{predict.rsparrow}}, \code{\link{coef.rsparrow}}
#'
#' @examples
#' \donttest{
#' sparrow_data <- rsparrow_prepare(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix
#' )
#' model <- rsparrow_estimate(sparrow_data)
#' coef(model)
#' }
rsparrow_estimate <- function(data,
                               run_id       = "run1",
                               output_dir   = NULL,
                               if_estimate  = TRUE,
                               if_predict   = TRUE,
                               if_validate  = FALSE,
                               hessian      = TRUE,
                               mean_adjust  = TRUE,
                               weights      = "default",
                               s_offset     = 1.0e+14,
                               load_units   = "kg/year",
                               yield_units  = "kg/ha/year",
                               yield_factor = 0.01,
                               conc_units   = "mg/L",
                               conc_factor  = 1.0) {

  if (!inherits(data, "rsparrow_data"))
    stop("'data' must be an rsparrow_data object from rsparrow_prepare().")

  # -- Coerce logicals to "yes"/"no" strings used internally -------------------
  if_estimate_str <- if (isTRUE(if_estimate)) "yes" else "no"
  if_predict_str  <- if (isTRUE(if_predict))  "yes" else "no"
  if_validate_str <- if (isTRUE(if_validate)) "yes" else "no"
  ifHess_str      <- if (isTRUE(hessian))     "yes" else "no"
  mean_adj_str    <- if (isTRUE(mean_adjust))  "yes" else "no"

  # -- Build minimal file.output.list ------------------------------------------
  if (is.null(output_dir)) {
    path_results <- NULL
    path_data    <- NULL
    path_main    <- NULL
  } else {
    stopifnot(is.character(output_dir), length(output_dir) == 1)
    path_main    <- output_dir
    path_results <- paste0(file.path(output_dir, "results", run_id),
                           .Platform$file.sep)
    path_data    <- paste0(file.path(output_dir, "data"),
                           .Platform$file.sep)
    dir.create(path_results, recursive = TRUE, showWarnings = FALSE)
    for (subdir in c("data", "estimate", "predict", "maps")) {
      dir.create(paste0(path_results, subdir),
                 recursive = TRUE, showWarnings = FALSE)
    }
  }

  file.output.list <- .minimal_file_output_list(
    path_main    = path_main,
    path_results = path_results,
    path_data    = path_data,
    run_id       = run_id
  )

  # -- Build estimate.input.list -----------------------------------------------
  estimate.input.list <- list(
    ifHess                    = ifHess_str,
    s_offset                  = s_offset,
    NLLS_weights              = weights,
    if_auto_scaling           = "no",
    if_mean_adjust_delivery_vars = mean_adj_str,
    if_corrExplanVars         = "no",
    if_spatialAutoCorr        = "no",
    diagnosticPlots_timestep  = NA,
    if_boot_estimate          = "no",
    if_boot_predict           = "no",
    yieldFactor               = yield_factor,
    ConcFactor                = conc_factor,
    loadUnits                 = load_units,
    yieldUnits                = yield_units,
    ConcUnits                 = conc_units
  )

  # -- Build remaining internal lists (minimal, all defaults) ------------------
  class.input.list <- list(
    classvar              = c(NA_character_),
    class_landuse         = NA,
    class_landuse_percent = NA
  )

  min.sites.list <- list(
    minimum_headwater_site_area      = 0,
    minimum_reaches_separating_sites = 1,
    minimum_site_incremental_area    = 0
  )

  mapping.input.list <- .minimal_mapping_input_list(
    load_units  = load_units,
    yield_units = yield_units,
    conc_factor = conc_factor
  )

  scenario.input.list <- list(
    scenario_sources             = NA,
    scenario_factors             = NA,
    landuseConversion            = NA,
    select_scenarioReachAreas    = "none",
    select_targetReachWatersheds = NA,
    scenario_name                = "scenario1",
    scenario_map_list            = NA,
    forecast_filename            = NA,
    use_sparrowNames             = FALSE
  )

  # -- Run data preparation and estimation via startModelRun() -----------------
  sparrow_state <- startModelRun(
    file.output.list        = file.output.list,
    if_estimate             = if_estimate_str,
    if_estimate_simulation  = "no",
    if_boot_estimate        = "no",
    if_boot_predict         = "no",
    filter_data1_conditions = NA,
    data1                   = data$data1,
    data_names              = data$data_names,
    class.input.list        = class.input.list,
    min.sites.list          = min.sites.list,
    if_validate             = if_validate_str,
    iseed                   = 139933493,
    pvalidate               = 0.25,
    mapping.input.list      = mapping.input.list,
    estimate.input.list     = estimate.input.list,
    if_predict              = if_predict_str,
    biters                  = 0,
    scenario.input.list     = scenario.input.list,
    add_vars                = NA,
    RSPARROW_errorOption    = "no",
    betavalues              = data$betavalues,
    dmatrixin               = data$dmatrixin
  )

  # -- Extract results and build rsparrow S3 object ----------------------------
  estimate_list <- sparrow_state$estimate.list
  predict_list  <- sparrow_state$predict.list

  jacob <- estimate_list$JacobResults
  anova <- estimate_list$ANOVA.list
  mdiag <- estimate_list$Mdiagnostics.list
  hess  <- estimate_list$HesResults

  structure(
    list(
      call          = match.call(),
      coefficients  = if (!is.null(jacob$oEstimate))
                        stats::setNames(jacob$oEstimate, jacob$Parmnames)
                      else NULL,
      std_errors    = jacob$oSEj,
      vcov          = hess$cov2,
      residuals     = mdiag$Resids,
      fitted_values = mdiag$predict,
      fit_stats = list(
        R2          = anova$RSQ,
        RMSE        = anova$RMSE,
        npar        = length(jacob$oEstimate),
        nobs        = nrow(sparrow_state$sitedata),
        convergence = !is.null(estimate_list$sparrowEsts)
      ),
      data = list(
        subdata             = sparrow_state$subdata,
        sitedata            = sparrow_state$sitedata,
        vsitedata           = sparrow_state[["vsitedata"]],
        DataMatrix.list     = sparrow_state$DataMatrix.list,
        SelParmValues       = sparrow_state$SelParmValues,
        dlvdsgn             = sparrow_state$dlvdsgn,
        Csites.weights.list = sparrow_state$Csites.weights.list,
        Vsites.list         = sparrow_state[["Vsites.list"]],
        classvar            = sparrow_state[["classvar"]] %||% NA_character_,
        estimate.list       = sparrow_state$estimate.list,
        estimate.input.list = estimate.input.list,
        scenario.input.list = scenario.input.list,
        mapping.input.list  = mapping.input.list,
        data_names          = data$data_names,
        file.output.list    = file.output.list
      ),
      predictions = predict_list,
      bootstrap   = NULL,
      validation  = NULL,
      metadata = list(
        version    = utils::packageVersion("rsparrow"),
        timestamp  = Sys.time(),
        run_id     = run_id
      )
    ),
    class = "rsparrow"
  )
}


# -----------------------------------------------------------------------------
# rsparrow_model() -- convenience wrapper (backward compatible)
# -----------------------------------------------------------------------------

#' Estimate a SPARROW Water Quality Model
#'
#' Estimates a SPARROW (SPAtially Referenced Regressions On Watershed
#' attributes) model using nonlinear least squares. This is a convenience
#' wrapper that calls \code{\link{rsparrow_prepare}} followed by
#' \code{\link{rsparrow_estimate}} in a single step.
#'
#' For finer control over the workflow—data validation, estimation, prediction,
#' and post-processing as separate steps—use the composable API directly:
#'
#' \preformatted{
#' sparrow_data <- rsparrow_prepare(reaches, parameters, design_matrix)
#' model        <- rsparrow_estimate(sparrow_data)
#' predictions  <- predict(model)
#' }
#'
#' @param reaches Data frame. Reach network with topology and attributes.
#'   Required columns: \code{waterid} (integer), \code{fnode} (integer),
#'   \code{tnode} (integer), \code{hydseq} (numeric), \code{demiarea}
#'   (numeric), \code{demtarea} (numeric), \code{frac} (numeric),
#'   \code{iftran} (integer), \code{rchtype} (integer), \code{calsites}
#'   (integer), \code{depvar} (numeric). Use \code{\link{rsparrow_hydseq}}
#'   to compute \code{hydseq} if it is not already present.
#' @param parameters Data frame. Model parameter configuration. Required
#'   columns: \code{sparrowNames} (character), \code{parmInit} (numeric),
#'   \code{parmMin} (numeric), \code{parmMax} (numeric),
#'   \code{parmType} (character, values \code{"SOURCE"} or \code{"DELIVF"}).
#'   Optional columns: \code{description}, \code{parmUnits},
#'   \code{parmCorrGroup}.
#' @param design_matrix Data frame. Binary matrix associating source
#'   parameters (rows) with delivery parameters (columns). The first column
#'   must be named \code{sparrowNames} and contain the SOURCE parameter names;
#'   remaining columns are DELIVF parameter names with values 0 or 1.
#' @param data_dictionary Data frame or \code{NULL} (default). Maps internal
#'   SPARROW variable names to data column names. Required columns:
#'   \code{varType}, \code{sparrowNames}, \code{data1UserNames},
#'   \code{varunits}. Optional: \code{explanation}. When \code{NULL},
#'   column names in \code{reaches} are used directly.
#' @param run_id Character. Name of the model run (default: \code{"run1"}).
#'   Used in output file names when \code{output_dir} is provided.
#' @param output_dir Character or \code{NULL}. Path to a directory for file
#'   output (CSV results, plots, diagnostic files). \code{NULL} (the default)
#'   runs the model entirely in memory with no file I/O side effects.
#' @param if_estimate Logical. \code{TRUE} (default) to run NLLS estimation.
#'   \code{FALSE} to use initial parameter values as fixed estimates.
#' @param if_predict Logical. \code{TRUE} (default) to compute reach-level
#'   load and yield predictions after estimation.
#' @param if_validate Logical. \code{FALSE} (default). \code{TRUE} to split
#'   monitoring sites into calibration and validation sets.
#'
#' @return An S3 object of class \code{"rsparrow"} containing:
#'   \describe{
#'     \item{call}{The matched function call}
#'     \item{coefficients}{Named numeric vector of estimated parameters}
#'     \item{std_errors}{Standard errors of coefficients (Jacobian-based)}
#'     \item{vcov}{Variance-covariance matrix (Hessian-based; NULL if not
#'       computed)}
#'     \item{residuals}{Residuals at monitoring sites}
#'     \item{fitted_values}{Fitted loads at monitoring sites}
#'     \item{fit_stats}{List with R2, RMSE, npar, nobs, convergence}
#'     \item{data}{Input data (reach network, sites, design matrices)}
#'     \item{predictions}{Reach-level load/yield predictions (NULL until
#'       predict() called, or when if_predict = TRUE)}
#'     \item{bootstrap}{Bootstrap results (NULL until
#'       rsparrow_bootstrap() called)}
#'     \item{validation}{Validation results (NULL until
#'       rsparrow_validate() called)}
#'     \item{metadata}{Package version, timestamp, run_id}
#'   }
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_prepare}}, \code{\link{rsparrow_estimate}},
#'   \code{\link{predict.rsparrow}}, \code{\link{summary.rsparrow}},
#'   \code{\link{rsparrow_hydseq}}
#'
#' @examples
#' \donttest{
#' # One-call interface (convenience wrapper)
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix
#' )
#' print(model)
#' coef(model)
#'
#' # Composable workflow (same result)
#' sparrow_data <- rsparrow_prepare(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix
#' )
#' model2 <- rsparrow_estimate(sparrow_data)
#' }
rsparrow_model <- function(reaches,
                            parameters,
                            design_matrix,
                            data_dictionary = NULL,
                            run_id          = "run1",
                            output_dir      = NULL,
                            if_estimate     = TRUE,
                            if_predict      = TRUE,
                            if_validate     = FALSE) {

  # Step 1: Prepare data
  sparrow_data <- rsparrow_prepare(
    reaches         = reaches,
    parameters      = parameters,
    design_matrix   = design_matrix,
    data_dictionary = data_dictionary
  )

  # Step 2: Estimate (returns rsparrow S3 object)
  model <- rsparrow_estimate(
    data        = sparrow_data,
    run_id      = run_id,
    output_dir  = output_dir,
    if_estimate = if_estimate,
    if_predict  = if_predict,
    if_validate = if_validate
  )

  # Overwrite call slot with rsparrow_model() call for backward compatibility
  model$call <- match.call()
  model
}


# =============================================================================
# Internal helpers
# =============================================================================

# Build minimal file.output.list (only fields needed by internal functions)
.minimal_file_output_list <- function(path_main    = NULL,
                                       path_results = NULL,
                                       path_data    = NULL,
                                       run_id       = "run1") {
  list(
    path_main               = path_main,
    run_id                  = run_id,
    path_results            = path_results,
    path_data               = path_data,
    path_master             = NA,
    path_user               = NA,
    path_gis                = NA,
    runScript               = NA,
    run2                    = NA,
    csv_decimalSeparator    = ".",
    csv_columnSeparator     = ",",
    input_data_fileName     = "data1.csv",
    filter_data1_conditions = NA,
    create_initial_dataDictionary        = "no",
    create_initial_parameterControlFiles = "no",
    load_previousDataImport = "no",
    if_reverse_hydseq       = "no",
    calculate_reach_attribute_list = NA,
    copy_PriorModelFiles    = NA,
    results_directoryName   = "results",
    data_directoryName      = "data",
    gis_directoryName       = "gis",
    edit_Parameters         = "no",
    edit_DesignMatrix       = "no",
    edit_dataDictionary     = "no",
    classvar                = c(NA_character_),
    class_landuse           = NA,
    class_landuse_percent   = NA,
    if_corrExplanVars       = "no",
    if_spatialAutoCorr      = "no",
    MoranDistanceWeightFunc = "1/distance",
    minimum_headwater_site_area      = 0,
    minimum_reaches_separating_sites = 1,
    minimum_site_incremental_area    = 0,
    if_estimate             = "yes",
    if_estimate_simulation  = "no",
    ifHess                  = "yes",
    s_offset                = 1.0e+14,
    NLLS_weights            = "default",
    if_mean_adjust_delivery_vars = "yes",
    if_auto_scaling         = "no",
    if_validate             = "no",
    pvalidate               = 0.25,
    if_boot_estimate        = "no",
    if_boot_predict         = "no",
    biters                  = 0,
    iseed                   = 139933493,
    confInterval            = 0.90,
    if_predict              = "yes",
    add_vars                = NA,
    loadUnits               = "kg/year",
    yieldFactor             = 0.01,
    yieldUnits              = "kg/ha/year",
    ConcFactor              = 1.0,
    ConcUnits               = "mg/L",
    master_map_list         = NA,
    output_map_type         = NA,
    if_create_binary_maps   = "no",
    if_verify_demtarea      = "no",
    if_verify_demtarea_maps = "no",
    lineShapeName           = NA,
    lineWaterid             = NA,
    polyShapeName           = NA,
    polyWaterid             = NA,
    LineShapeGeo            = NA,
    CRStext                 = NA,
    convertShapeToBinary.list = NA,
    map_siteAttributes.list = NA,
    lat_limit               = NA,
    lon_limit               = NA,
    outputESRImaps          = c("no", "no", "no", "no"),
    enable_plotlyMaps       = "no",
    add_plotlyVars          = NA,
    showPlotGrid            = "no",
    map_years               = NA,
    map_seasons             = NA,
    mapsPerPage             = NA,
    mapPageGroupBy          = NA,
    predictionTitleSize     = 16,
    predictionLegendSize    = 0.5,
    predictionLegendBackground = "white",
    predictionMapColors     = c("blue", "darkgreen", "gold", "red", "darkred"),
    predictionClassRounding = 3,
    predictionMapBackground = "white",
    lineWidth               = 0.5,
    residual_map_breakpoints = c(-2.5, -1.0, -0.5, 0, 0.5, 1.0, 2.5),
    ratio_map_breakpoints   = c(0.3, 0.5, 0.8, 1, 1.25, 2, 3.3),
    residualColors          = c("red","red","gold","gold","darkgreen","darkgreen","blue","blue"),
    residualMapBackground   = "white",
    residualTitleSize       = 1,
    residualLegendSize      = 1,
    residualPointStyle      = c(2, 2, 1, 1, 1, 1, 6, 6),
    residualPointSize_breakpoints = c(0.75, 0.5, 0.4, 0.25, 0.25, 0.4, 0.5, 0.75),
    residualPointSize_factor = 1,
    siteAttrColors          = c("blue", "green4", "yellow", "orange", "red"),
    siteAttrMapBackground   = "white",
    siteAttrTitleSize       = 16,
    siteAttrLegendSize      = 0.5,
    siteAttrClassRounding   = 2,
    siteAttr_mapPointStyle  = 16,
    siteAttr_mapPointSize   = 1,
    diagnosticPlotPointSize = 0.4,
    diagnosticPlotPointStyle = 1,
    diagnosticPlots_timestep = NA,
    diagnostic_timeSeriesPlots = "no",
    scenarioMapColors       = c("lightblue","blue","darkgreen","gold","red","darkred"),
    scenario_sources        = NA,
    scenario_factors        = NA,
    landuseConversion       = NA,
    select_scenarioReachAreas = "none",
    select_targetReachWatersheds = NA,
    scenario_name           = "scenario1",
    scenario_map_list       = NA,
    forecast_filename       = NA,
    use_sparrowNames        = FALSE,
    compare_models          = NA,
    modelComparison_name    = NA,
    RSPARROW_errorOption    = "no",
    enable_ShinyApp         = "no",
    path_shinyBrowser       = NA
  )
}


# Build minimal mapping.input.list
.minimal_mapping_input_list <- function(load_units  = "kg/year",
                                         yield_units = "kg/ha/year",
                                         conc_factor = 1.0) {
  list(
    master_map_list          = NA,
    lon_limit                = NA,
    lat_limit                = NA,
    ConcFactor               = conc_factor,
    output_map_type          = NA,
    if_verify_demtarea_maps  = "no",
    lineShapeName            = NA,
    lineWaterid              = NA,
    polyShapeName            = NA,
    polyWaterid              = NA,
    LineShapeGeo             = NA,
    CRStext                  = NA,
    convertShapeToBinary.list = NA,
    map_siteAttributes.list  = NA,
    residual_map_breakpoints = c(-2.5, -1.0, -0.5, 0, 0.5, 1.0, 2.5),
    ratio_map_breakpoints    = c(0.3, 0.5, 0.8, 1, 1.25, 2, 3.3),
    residualColors           = c("red","red","gold","gold","darkgreen","darkgreen","blue","blue"),
    residualMapBackground    = "white",
    residualTitleSize        = 1,
    residualLegendSize       = 1,
    residualPointStyle       = c(2, 2, 1, 1, 1, 1, 6, 6),
    residualPointSize_breakpoints = c(0.75, 0.5, 0.4, 0.25, 0.25, 0.4, 0.5, 0.75),
    residualPointSize_factor = 1,
    siteAttrColors           = c("blue", "green4", "yellow", "orange", "red"),
    siteAttrMapBackground    = "white",
    siteAttrTitleSize        = 16,
    siteAttrLegendSize       = 0.5,
    siteAttrClassRounding    = 2,
    siteAttr_mapPointStyle   = 16,
    siteAttr_mapPointSize    = 1,
    site_mapPointScale       = 1,
    site_mapPointStyle       = 16,
    site_mapPointSize        = 1,
    predictionTitleSize      = 16,
    predictionLegendSize     = 0.5,
    predictionLegendBackground = "white",
    predictionMapColors      = c("blue", "darkgreen", "gold", "red", "darkred"),
    predictionClassRounding  = 3,
    predictionMapBackground  = "white",
    lineWidth                = 0.5,
    outputESRImaps           = c("no","no","no","no"),
    enable_plotlyMaps        = "no",
    add_plotlyVars           = NA,
    showPlotGrid             = "no",
    diagnosticPlots_timestep = NA,
    diagnostic_timeSeriesPlots = "no",
    map_years                = NA,
    map_seasons              = NA,
    mapsPerPage              = NA,
    mapPageGroupBy           = NA,
    scenarioMapColors        = c("lightblue","blue","darkgreen","gold","red","darkred"),
    diagnosticPlotPointStyle = 1,
    diagnosticPlotPointSize  = 0.4,
    loadUnits                = load_units,
    yieldUnits               = yield_units,
    pchPlotlyCross           = data.frame(
      pch    = c(0L, 1L, 2L, 3L, 4L, 5L, 6L, 7L, 8L, 9L, 10L, 11L, 12L,
                 13L, 14L, 15L, 16L, 17L, 18L, 19L, 20L, 21L, 22L, 23L, 24L, 25L),
      plotly = c("square-open","circle-open","triangle-up-open","cross-thin-open",
                 "x-thin-open","diamond-open","triangle-down-open","square-x-open",
                 "asterisk-open","diamond-x-open","circle-x-open","star-triangle-up-open",
                 "square-cross-open","circle-x-open","triangle-up-open",
                 "square","circle","triangle-up","diamond","circle","circle",
                 "circle","square","diamond","triangle-up","triangle-down"),
      stringsAsFactors = FALSE
    )
  )
}


# =============================================================================
# prep_sparrow_inputs() -- internal data validation and transformation
# =============================================================================
#
# Validates and transforms the four input data frames so that
# startModelRun() receives pre-parsed objects.
#
# Returns a named list: data1, betavalues, dmatrixin, data_names

prep_sparrow_inputs <- function(reaches, parameters, design_matrix,
                                data_dictionary = NULL) {

  # -- Validate reaches ---------------------------------------------------------
  required_reach_cols <- c("waterid", "fnode", "tnode", "frac", "iftran",
                            "rchtype", "demiarea", "termflag", "calsites",
                            "depvar")
  missing_reach <- setdiff(required_reach_cols, names(reaches))
  if (length(missing_reach) > 0)
    stop("reaches is missing required columns: ",
         paste(missing_reach, collapse = ", "))

  # Compute hydseq if not present
  if (!"hydseq" %in% names(reaches)) {
    message("hydseq not found in reaches -- computing via rsparrow_hydseq().")
    reaches <- rsparrow_hydseq(reaches)
  }
  data1 <- as.data.frame(reaches)

  # -- Validate parameters ------------------------------------------------------
  required_param_cols <- c("sparrowNames", "parmInit", "parmMin",
                            "parmMax", "parmType")
  missing_param <- setdiff(required_param_cols, names(parameters))
  if (length(missing_param) > 0)
    stop("parameters is missing required columns: ",
         paste(missing_param, collapse = ", "))

  # -- Process parameters (mirrors readParameters()) ---------------------------
  betavalues <- as.data.frame(parameters)

  # Add optional columns with defaults if absent
  if (!"description"   %in% names(betavalues)) betavalues$description   <- ""
  if (!"parmUnits"     %in% names(betavalues)) betavalues$parmUnits     <- ""
  if (!"parmCorrGroup" %in% names(betavalues)) betavalues$parmCorrGroup <- 0

  # Remove all-NA rows
  betavalues <- betavalues[apply(betavalues, 1, function(x) any(!is.na(x))), ,
                            drop = FALSE]

  # Standardise column order
  NAMES <- c("sparrowNames", "description", "parmUnits",
             "parmInit", "parmMin", "parmMax", "parmType", "parmCorrGroup")
  betavalues <- betavalues[, intersect(NAMES, names(betavalues)), drop = FALSE]
  for (nm in NAMES) {
    if (!nm %in% names(betavalues))
      betavalues[[nm]] <- if (nm %in% c("parmInit","parmMin","parmMax","parmCorrGroup")) 0 else ""
  }
  betavalues <- betavalues[, NAMES, drop = FALSE]

  # Trim whitespace and lowercase fixed varList names in sparrowNames
  betavalues$sparrowNames <- trimws(betavalues$sparrowNames, which = "both")
  varList <- as.character(getVarList()$varList)
  betavalues$sparrowNames <- ifelse(
    tolower(betavalues$sparrowNames) %in% varList,
    tolower(betavalues$sparrowNames),
    betavalues$sparrowNames
  )

  # Replace NA with 0 in numeric columns
  for (cn in names(betavalues)) {
    v <- betavalues[[cn]]
    if (is.numeric(v)) betavalues[[cn]] <- ifelse(is.na(v), 0, v)
  }

  # Compute parmConstant
  betavalues$parmConstant <- as.integer(
    betavalues$parmInit == betavalues$parmMax &
    betavalues$parmInit == betavalues$parmMin &
    betavalues$parmInit != 0
  )

  # Final column order
  final_cols <- c("sparrowNames", "description", "parmUnits",
                  "parmInit", "parmMin", "parmMax",
                  "parmType", "parmConstant", "parmCorrGroup")
  betavalues <- betavalues[, final_cols, drop = FALSE]
  betavalues <- as.data.frame(betavalues)

  # Validate SOURCE presence
  if (nrow(betavalues[betavalues$parmType == "SOURCE", ]) == 0)
    stop("No SOURCE parameters found in parameters data frame. ",
         "At least one row must have parmType = 'SOURCE'.")

  # Validate parameter range
  if (nrow(betavalues[betavalues$parmMax != 0, ]) == 0)
    stop("No parameters with parmMax != 0 found. ",
         "Set parmMax > 0 for at least one parameter.")

  # Validate no missing values in numeric columns
  num_cols <- c("parmInit", "parmMin", "parmMax", "parmCorrGroup")
  for (cn in num_cols) {
    if (any(is.na(betavalues[[cn]])))
      stop("Missing values in parameters column: ", cn)
  }

  # -- Validate design_matrix ---------------------------------------------------
  if (!"sparrowNames" %in% names(design_matrix))
    stop("design_matrix must have a 'sparrowNames' column containing SOURCE parameter names.")

  # -- Process design_matrix (mirrors readDesignMatrix()) ----------------------
  dm <- as.data.frame(design_matrix)

  # Extract SOURCE row labels from sparrowNames column, set as row names
  rnames <- trimws(dm$sparrowNames, which = "both")
  rnames <- ifelse(tolower(rnames) %in% varList, tolower(rnames), rnames)
  dm <- dm[, names(dm) != "sparrowNames", drop = FALSE]
  rownames(dm) <- rnames

  # Column names are DELIVF parameter names -- trim and lowercase as needed
  cnames <- trimws(names(dm), which = "both")
  cnames <- ifelse(tolower(cnames) %in% varList, tolower(cnames), cnames)
  names(dm) <- cnames

  # Determine DELIVF column names expected from betavalues
  DELIVF_names <- betavalues[betavalues$parmType == "DELIVF", ]$sparrowNames
  SOURCE_names <- betavalues[betavalues$parmType == "SOURCE", ]$sparrowNames

  # Re-order rows to match SOURCE order in betavalues
  row_order <- match(SOURCE_names, rownames(dm))
  if (any(is.na(row_order)))
    stop("design_matrix is missing SOURCE rows for: ",
         paste(SOURCE_names[is.na(row_order)], collapse = ", "))
  dm <- dm[row_order, , drop = FALSE]

  # Re-order / subset columns to match DELIVF order in betavalues
  if (length(DELIVF_names) > 0) {
    col_order <- match(DELIVF_names, names(dm))
    if (any(is.na(col_order)))
      stop("design_matrix is missing DELIVF columns for: ",
           paste(DELIVF_names[is.na(col_order)], collapse = ", "))
    dm <- dm[, col_order, drop = FALSE]
    names(dm) <- DELIVF_names
  }

  # Ensure values are numeric
  for (cn in names(dm)) dm[[cn]] <- as.numeric(dm[[cn]])
  dmatrixin <- as.data.frame(dm)
  rownames(dmatrixin) <- SOURCE_names

  # -- Process data_dictionary (optional) --------------------------------------
  if (is.null(data_dictionary)) {
    # Auto-generate identity mapping: sparrowNames == data1UserNames
    all_cols <- names(data1)
    data_names <- data.frame(
      varType       = "reach",
      sparrowNames  = all_cols,
      data1UserNames = all_cols,
      varunits      = "",
      explanation   = "",
      stringsAsFactors = FALSE
    )
  } else {
    # Validate data_dictionary
    required_dict_cols <- c("varType", "sparrowNames", "data1UserNames", "varunits")
    missing_dict <- setdiff(required_dict_cols, names(data_dictionary))
    if (length(missing_dict) > 0)
      stop("data_dictionary is missing required columns: ",
           paste(missing_dict, collapse = ", "))

    # Process data_dictionary (mirrors read_dataDictionary())
    data_names <- as.data.frame(data_dictionary)
    if (!"explanation" %in% names(data_names)) data_names$explanation <- ""

    NAMES_dd <- c("varType", "sparrowNames", "data1UserNames", "varunits", "explanation")
    data_names <- data_names[, intersect(NAMES_dd, names(data_names)), drop = FALSE]
    for (nm in NAMES_dd) {
      if (!nm %in% names(data_names)) data_names[[nm]] <- ""
    }
    data_names <- data_names[, NAMES_dd, drop = FALSE]

    # Remove all-NA rows
    data_names <- data_names[apply(data_names, 1, function(x) any(!is.na(x))), ,
                               drop = FALSE]

    # Trim and lowercase sparrowNames
    data_names$sparrowNames  <- trimws(data_names$sparrowNames,  which = "both")
    data_names$data1UserNames <- trimws(data_names$data1UserNames, which = "both")
    data_names$sparrowNames <- ifelse(
      tolower(data_names$sparrowNames) %in% varList,
      tolower(data_names$sparrowNames),
      data_names$sparrowNames
    )

    # Remove blank sparrowNames
    blank <- is.na(data_names$sparrowNames) | data_names$sparrowNames == ""
    if (any(blank))
      message("prep_sparrow_inputs: ", sum(blank),
              " row(s) with blank sparrowNames removed from data_dictionary.")
    data_names <- data_names[!blank, , drop = FALSE]

    # Remove exact duplicates
    data_names <- data_names[!duplicated(data_names), , drop = FALSE]
    data_names <- as.data.frame(data_names)
  }

  list(
    data1      = data1,
    betavalues = betavalues,
    dmatrixin  = dmatrixin,
    data_names = data_names
  )
}
