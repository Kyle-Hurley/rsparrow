#' Estimate a SPARROW Water Quality Model
#'
#' Estimates a SPARROW (SPAtially Referenced Regressions On Watershed attributes)
#' model using nonlinear least squares. Reads input data from CSV control files,
#' validates the reach network, computes hydrological sequencing, and optimizes
#' model parameters using the nlmrt package.
#'
#' The function orchestrates the full SPARROW estimation workflow:
#' \enumerate{
#'   \item Reads and validates control files (parameters.csv, design_matrix.csv)
#'   \item Loads reach network and monitoring site data
#'   \item Computes hydrological sequencing via \code{\link{rsparrow_hydseq}}
#'   \item Prepares data matrices for optimization
#'   \item Calls nonlinear least squares optimizer
#'   \item Computes fit statistics and diagnostics
#' }
#'
#' @param path_main Character. Path to the main directory containing control files
#'   and data. Must contain parameters.csv, design_matrix.csv, dataDictionary.csv.
#' @param run_id Character. Name of the model run (default: "run1"). Used to match
#'   parameter specifications in the control files.
#' @param model_type Character. Either "static" for long-term mean annual models
#'   or "dynamic" for seasonal/annual time-varying models. Default: "static".
#' @param if_estimate Character. "yes" to run NLLS estimation, "no" to use
#'   previously saved parameter estimates. Default: "yes".
#' @param if_predict Character. "yes" to compute reach-level load and yield
#'   predictions after estimation. Default: "yes".
#' @param if_validate Character. "yes" to split monitoring sites into calibration
#'   and validation sets. Default: "no".
#' @param ... Additional arguments passed to the internal estimation routine.
#'
#' @return An S3 object of class "rsparrow" containing:
#'   \describe{
#'     \item{call}{The matched function call}
#'     \item{coefficients}{Named numeric vector of estimated parameters}
#'     \item{std_errors}{Standard errors of coefficients (Jacobian-based)}
#'     \item{vcov}{Variance-covariance matrix (Hessian-based; NULL if not computed)}
#'     \item{residuals}{Residuals at monitoring sites}
#'     \item{fitted_values}{Fitted loads at monitoring sites}
#'     \item{fit_stats}{List with R2, RMSE, npar, nobs, convergence}
#'     \item{data}{Input data (reach network, sites, design matrices)}
#'     \item{predictions}{Reach-level load/yield predictions (NULL until predict() called)}
#'     \item{bootstrap}{Bootstrap results (NULL until rsparrow_bootstrap() called)}
#'     \item{validation}{Validation results (NULL until rsparrow_validate() called)}
#'     \item{metadata}{Package version, timestamp, run_id, model_type, path_main}
#'   }
#'
#' @export
#'
#' @seealso \code{\link{predict.rsparrow}}, \code{\link{summary.rsparrow}},
#'   \code{\link{read_sparrow_data}}
#'
#' @examples
#' \dontrun{
#' # Estimate a static SPARROW model
#' model <- rsparrow_model(
#'   path_main = "~/sparrow_projects/my_watershed/",
#'   run_id = "baseline_2020",
#'   model_type = "static"
#' )
#'
#' # View estimation results
#' print(model)
#' summary(model)
#'
#' # Extract coefficients
#' coef(model)
#'
#' # Generate predictions
#' model <- predict(model, type = "all")
#' }
rsparrow_model <- function(path_main, run_id = "run1", model_type = "static",
                            if_estimate = "yes", if_predict = "yes",
                            if_validate = "no", ...) {

  # ── Input validation ────────────────────────────────────────────────────────
  stopifnot(is.character(path_main), length(path_main) == 1)
  if (!dir.exists(path_main)) stop("path_main does not exist: ", path_main)
  model_type <- match.arg(model_type, c("static", "dynamic"))

  # ── Step 1: Read data files ──────────────────────────────────────────────────
  sparrow_data <- read_sparrow_data(path_main, run_id = run_id)
  path_results <- sparrow_data$file.output.list$path_results
  path_data    <- sparrow_data$file.output.list$path_data

  # ── Step 2: Create required output subdirectories ────────────────────────────
  for (subdir in c("data", "estimate", "predict", "maps")) {
    dir.create(paste0(path_results, subdir),
               recursive = TRUE, showWarnings = FALSE)
  }

  # ── Step 3: Build comprehensive file.output.list ─────────────────────────────
  # Internal functions (outputSettings, readParameters, etc.) need ALL control
  # settings to be present in file.output.list.  Provide sensible defaults for
  # everything not supplied by the user; the caller may override via ... .
  file.output.list <- list(
    # ── Paths ──────────────────────────────────────────────────────────────────
    path_main               = path_main,
    run_id                  = run_id,
    path_results            = path_results,
    path_data               = path_data,
    path_master             = NA,   # package install path; not needed at run-time
    path_user               = NA,
    path_gis                = NA,
    runScript               = NA,   # legacy batch-mode script path
    run2                    = NA,   # legacy second run path

    # ── Data import ────────────────────────────────────────────────────────────
    csv_decimalSeparator    = sparrow_data$file.output.list$csv_decimalSeparator,
    csv_columnSeparator     = sparrow_data$file.output.list$csv_columnSeparator,
    input_data_fileName     = "data1.csv",
    filter_data1_conditions = NA,
    create_initial_dataDictionary        = "no",
    create_initial_parameterControlFiles = "no",
    load_previousDataImport = "no",
    if_userModifyData       = "no",
    if_reverse_hydseq       = "no",
    calculate_reach_attribute_list = NA,
    copy_PriorModelFiles    = NA,
    results_directoryName   = "results",
    data_directoryName      = "data",
    gis_directoryName       = "gis",
    edit_Parameters         = "no",
    edit_DesignMatrix       = "no",
    edit_dataDictionary     = "no",

    # ── Classification / spatial diagnostics ───────────────────────────────────
    classvar                = c(NA_character_),
    class_landuse           = NA,
    class_landuse_percent   = NA,
    if_corrExplanVars       = "no",
    if_spatialAutoCorr      = "no",
    MoranDistanceWeightFunc = "1/distance",

    # ── Site filtering ─────────────────────────────────────────────────────────
    minimum_headwater_site_area      = 0,
    minimum_reaches_separating_sites = 1,
    minimum_site_incremental_area    = 0,

    # ── Estimation ─────────────────────────────────────────────────────────────
    if_estimate             = if_estimate,
    if_estimate_simulation  = "no",
    ifHess                  = "yes",
    s_offset                = 1.0e+14,
    NLLS_weights            = "default",
    if_mean_adjust_delivery_vars = "yes",
    if_auto_scaling         = "no",

    # ── Validation / bootstrapping ─────────────────────────────────────────────
    if_validate             = if_validate,
    pvalidate               = 0.25,
    if_boot_estimate        = "no",
    if_boot_predict         = "no",
    biters                  = 0,
    iseed                   = 139933493,
    confInterval            = 0.90,

    # ── Prediction ─────────────────────────────────────────────────────────────
    if_predict              = if_predict,
    add_vars                = NA,
    loadUnits               = "kg/year",
    yieldFactor             = 0.01,
    yieldUnits              = "kg/ha/year",
    ConcFactor              = 1.0,
    ConcUnits               = "mg/L",

    # ── Mapping (all disabled by default) ──────────────────────────────────────
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

    # ── Plot cosmetics ─────────────────────────────────────────────────────────
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

    # ── Scenarios (all disabled by default) ────────────────────────────────────
    scenario_sources        = NA,
    scenario_factors        = NA,
    landuseConversion       = NA,
    select_scenarioReachAreas = "none",
    select_targetReachWatersheds = NA,
    scenario_name           = "scenario1",
    scenario_map_list       = NA,
    forecast_filename       = NA,
    use_sparrowNames        = FALSE,

    # ── Model comparison (disabled) ────────────────────────────────────────────
    compare_models          = NA,
    modelComparison_name    = NA,

    # ── Application settings ───────────────────────────────────────────────────
    RSPARROW_errorOption    = "no",
    enable_ShinyApp         = "no",
    path_shinyBrowser       = NA
  )

  # ── Step 4: Build input lists ─────────────────────────────────────────────────

  class.input.list <- list(
    classvar            = c(NA_character_),
    class_landuse       = NA,
    class_landuse_percent = NA
  )

  min.sites.list <- list(
    minimum_headwater_site_area      = 0,
    minimum_reaches_separating_sites = 1,
    minimum_site_incremental_area    = 0
  )

  estimate.input.list <- list(
    ifHess                    = "yes",
    s_offset                  = 1.0e+14,
    NLLS_weights              = "default",
    if_auto_scaling           = "no",
    if_mean_adjust_delivery_vars = "yes",
    if_corrExplanVars         = "no",
    if_spatialAutoCorr        = "no",
    diagnosticPlots_timestep  = NA,
    if_boot_estimate          = "no",
    if_boot_predict           = "no",
    yieldFactor               = 0.01,
    ConcFactor                = 1.0,
    loadUnits                 = "kg/year",
    yieldUnits                = "kg/ha/year",
    ConcUnits                 = "mg/L"
  )

  mapping.input.list <- list(
    master_map_list          = NA,
    lon_limit                = NA,
    lat_limit                = NA,
    ConcFactor               = 1.0,
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
    scenarioMapColors        = c("lightblue","blue","darkgreen","gold","red","darkred")
  )

  scenario.input.list <- list(
    scenario_sources          = NA,
    scenario_factors          = NA,
    landuseConversion         = NA,
    select_scenarioReachAreas = "none",
    select_targetReachWatersheds = NA,
    scenario_name             = "scenario1",
    scenario_map_list         = NA,
    forecast_filename         = NA,
    use_sparrowNames          = FALSE
  )

  # ── Step 5: Run data preparation and estimation ───────────────────────────────
  # startModelRun() orchestrates data prep AND calls controlFileTasksModel()
  # internally, so we only need to call it once.  It returns sparrow_state, which
  # now includes $estimate.list (added via one-line patch in startModelRun.R).
  sparrow_state <- startModelRun(
    file.output.list        = file.output.list,
    if_estimate             = if_estimate,
    if_estimate_simulation  = "no",
    if_boot_estimate        = "no",
    if_boot_predict         = "no",
    filter_data1_conditions = NA,
    data1                   = sparrow_data$data1,
    if_userModifyData       = "no",
    data_names              = sparrow_data$data_names,
    class.input.list        = class.input.list,
    min.sites.list          = min.sites.list,
    if_validate             = if_validate,
    iseed                   = 139933493,
    pvalidate               = 0.25,
    mapping.input.list      = mapping.input.list,
    estimate.input.list     = estimate.input.list,
    if_predict              = if_predict,
    biters                  = 0,
    scenario.input.list     = scenario.input.list,
    add_vars                = NA,
    RSPARROW_errorOption    = "no"
  )

  # ── Step 6: Extract estimate.list ─────────────────────────────────────────────
  estimate_list <- sparrow_state$estimate.list

  # ── Step 7: Load predict.list from saved file (if prediction was requested) ───
  predict_list <- NULL
  if (if_predict == "yes") {
    predict_file <- paste0(path_results, "predict",
                           .Platform$file.sep, run_id, "_predict.list")
    if (file.exists(predict_file)) {
      local({
        load(predict_file)
        predict_list <<- predict.list
      })
    }
  }

  # ── Step 8: Construct and return rsparrow S3 object ───────────────────────────
  # Safely extract nested fields (return NULL rather than error when absent)
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
        data_names          = sparrow_data$data_names,
        file.output.list    = file.output.list
      ),
      predictions = predict_list,
      bootstrap   = NULL,
      validation  = NULL,
      metadata = list(
        version    = utils::packageVersion("rsparrow"),
        timestamp  = Sys.time(),
        run_id     = run_id,
        model_type = model_type,
        path_main  = path_main
      )
    ),
    class = "rsparrow"
  )
}
