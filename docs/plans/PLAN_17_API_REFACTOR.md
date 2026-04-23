<plan id="17" label="API Refactoring for Composable Workflow" status="pending" blocked_by="16">

<objective>
Refactor the rsparrow API to follow R package conventions. Replace the monolithic
rsparrow_model() orchestrator with composable functions (rsparrow_prepare(),
rsparrow_estimate()) that users call explicitly. Eliminate the bloated configuration
lists (file.output.list, mapping.input.list) and make data_dictionary optional.
Maintain full backward compatibility via rsparrow_model() as a thin convenience wrapper.
</objective>

<context>
After Plans 13-16, the package is technically CRAN-ready (0 ERRORs, 0 WARNINGs).
However, the API design violates R package conventions:

CURRENT PROBLEMS:
  - 7 wrapper levels: rsparrow_model() -> startModelRun() -> controlFileTasksModel()
    -> estimate() -> estimateOptimize() -> nlmrt::nlfb() -> estimateFeval() -> .Fortran()
  - file.output.list: ~160 fields defined, only 19 used (12% utilization)
  - mapping.input.list: ~50+ fields, only 8 used (16% utilization)
  - rsparrow_model() is 500 lines doing data prep + estimation + prediction + validation
  - Users cannot control workflow — everything hidden behind if_* flags
  - Developer comments in rsparrow_model.R (lines 116-304) flag this as "highly unorthodox"

WHAT WORKS WELL (keep unchanged):
  - S3 methods: print, summary, coef, residuals, vcov, plot, predict
  - Post-processing: rsparrow_bootstrap(), rsparrow_scenario(), rsparrow_validate()
  - Core math: estimateFeval(), estimateOptimize(), predict_sparrow(), deliver()
  - Fortran: tnoder, ptnoder, mptnoder, deliv_fraction, sites_incr, sum_atts
  - Utilities: rsparrow_hydseq(), write_rsparrow_results()

INDUSTRY STANDARD (lme4, mgcv, stats patterns):
  - Primary function does ONE job (estimation)
  - Users compose workflow by calling functions in sequence
  - No configuration lists — explicit function parameters
  - S3 methods for predict, plot, summary
</context>

<proposed_api>
# Step 1: Prepare data (new export)
sparrow_data <- rsparrow_prepare(
  reaches,         # Network topology with required columns
  parameters,      # SOURCE/DELIVF parameter config
  design_matrix,   # Source-delivery associations
  weights = "default"
)

# Step 2: Estimate model (new export)
model <- rsparrow_estimate(
  sparrow_data,
  hessian = TRUE,
  mean_adjust = TRUE,
  load_units = "kg/year",
  yield_units = "kg/ha/year"
)

# Step 3: Predict (existing S3 method)
predictions <- predict(model)

# Step 4: Post-processing (existing functions - no changes)
model <- rsparrow_bootstrap(model, n = 100)
model <- rsparrow_validate(model, p = 0.25)
model <- rsparrow_scenario(model, sources = list(ag = 0.5))

# Step 5: Plot (existing S3 method)
plot(model, type = "residuals")

# Convenience wrapper (backward compatible)
model <- rsparrow_model(reaches, parameters, design_matrix, ...)
</proposed_api>

<design_decisions>
1. ELIMINATE data_dictionary: User provides correctly-named columns; validation
   tells them what's missing. data_dictionary kept as optional parameter for
   backward compatibility (legacy name mapping).

2. ELIMINATE file.output.list: Reduce from ~160 to ~5 fields (path_results, run_id).
   All I/O via explicit write_rsparrow_results() call.

3. ELIMINATE mapping.input.list: Move plot styling to plot.rsparrow() function
   parameters. No more nested lists for cosmetics.

4. KEEP estimate.input.list: 100% field utilization, well-designed. May rename
   internally but structure is sound.

5. EXPLICIT PARAMETERS: All estimation options become function arguments to
   rsparrow_estimate() (hessian, mean_adjust, weights, units, etc.)

6. BACKWARD COMPATIBILITY: rsparrow_model() becomes ~50-line wrapper calling
   rsparrow_prepare() -> rsparrow_estimate() -> predict() sequence.
</design_decisions>

<tasks>

<task id="17-1" status="pending">
<subject>Create rsparrow_prepare() — new export for data preparation</subject>
<description>
Extract data preparation logic from startModelRun() into standalone exported function.

WHAT IT DOES:
  - Validates reaches (required columns: waterid, fnode, tnode, frac, iftran,
    rchtype, demiarea, demtarea, termflag, calsites, depvar)
  - Computes hydseq if missing (calls rsparrow_hydseq)
  - Processes parameters (currently prep_sparrow_inputs lines 543-610)
  - Processes design_matrix (currently lines 617-654)
  - Creates SelParmValues (selectParmValues.R)
  - Creates dlvdsgn (selectDesignMatrix.R)
  - Creates subdata (createSubdataSorted.R)
  - Creates DataMatrix.list (createDataMatrix.R)
  - Sets up calibration sites (selectCalibrationSites.R)
  - Computes NLLS weights (setNLLSWeights.R)

RETURNS: S3 object of class "rsparrow_data" containing:
  - subdata, sitedata, DataMatrix.list, SelParmValues, dlvdsgn
  - Csites.weights.list, data_names, betavalues

SIGNATURE:
  rsparrow_prepare <- function(reaches, parameters, design_matrix,
                               data_dictionary = NULL,
                               weights = "default",
                               filter_conditions = NULL)

FILES TO MODIFY:
  - R/rsparrow_model.R: Add rsparrow_prepare() (~150 lines new)
  - R/startModelRun.R: Refactor to accept rsparrow_data object OR keep current
    signature and have rsparrow_prepare() call it internally
  - NAMESPACE: Add export(rsparrow_prepare)
  - man/rsparrow_prepare.Rd: New roxygen documentation

IMPLEMENTATION NOTES:
  - Can initially wrap existing prep_sparrow_inputs() + startModelRun() data prep
  - Later phases can refactor internals; first goal is clean external API
  - rsparrow_data object should be printable (add print.rsparrow_data method)
</description>
<files_modified>
  R/rsparrow_model.R (add rsparrow_prepare)
  R/startModelRun.R (refactor to work with rsparrow_data)
  NAMESPACE (add export)
</files_modified>
<success_criteria>
  - rsparrow_prepare() returns rsparrow_data S3 object
  - No file I/O side effects
  - All current tests pass
  - R CMD check: 0 new ERRORs or WARNINGs
</success_criteria>
</task>

<task id="17-2" status="pending" blocked_by="17-1">
<subject>Create rsparrow_estimate() — new export for NLLS estimation</subject>
<description>
Extract estimation logic from estimate() into standalone exported function.

WHAT IT DOES:
  - Accepts rsparrow_data object from rsparrow_prepare()
  - Calls estimateOptimize() for NLLS fitting
  - Computes metrics via estimateNLLSmetrics()
  - Builds estimate.list, JacobResults, HesResults, ANOVA.list
  - Optionally generates diagnostic plots (via parameter, not hidden flag)

RETURNS: S3 object of class "rsparrow" (same structure as current rsparrow_model output)

SIGNATURE:
  rsparrow_estimate <- function(data,
                                hessian = TRUE,
                                mean_adjust = TRUE,
                                weights = NULL,  # Overrides weights from data
                                s_offset = 1.0e+14,
                                load_units = "kg/year",
                                yield_units = "kg/ha/year",
                                conc_units = "mg/L",
                                yield_factor = 0.01,
                                conc_factor = 1.0,
                                diagnostics = TRUE)

FILES TO MODIFY:
  - R/rsparrow_model.R: Add rsparrow_estimate() (~100 lines new)
  - R/estimate.R: Refactor to be callable from rsparrow_estimate() without
    needing controlFileTasksModel context
  - NAMESPACE: Add export(rsparrow_estimate)
  - man/rsparrow_estimate.Rd: New roxygen documentation

IMPLEMENTATION NOTES:
  - estimate.input.list built internally from function parameters
  - file.output.list reduced to minimal path info (or NULL for in-memory)
  - rsparrow object structure unchanged from current API
</description>
<files_modified>
  R/rsparrow_model.R (add rsparrow_estimate)
  R/estimate.R (refactor to accept rsparrow_data)
  NAMESPACE (add export)
</files_modified>
<success_criteria>
  - rsparrow_estimate(rsparrow_data) returns rsparrow S3 object
  - No file I/O side effects (unless output_dir specified)
  - Existing S3 methods work unchanged: coef(), residuals(), predict(), plot()
  - All current tests pass
</success_criteria>
</task>

<task id="17-3" status="pending" blocked_by="17-2">
<subject>Eliminate data_dictionary requirement</subject>
<description>
Make data_dictionary optional. User provides correctly-named columns directly.

CURRENT BEHAVIOR:
  - data_dictionary maps user column names (data1UserNames) to SPARROW names
  - Required even when column names already match

NEW BEHAVIOR:
  - If data_dictionary is NULL (default), validate that required columns exist
  - If columns are missing, provide clear error message listing required names
  - If data_dictionary is provided, apply legacy name mapping (backward compat)

REQUIRED COLUMNS (reaches):
  waterid, fnode, tnode, frac, iftran, rchtype, demiarea, demtarea, termflag,
  calsites, depvar, plus any SOURCE/DELIVF variable columns from parameters

IMPLEMENTATION:
  rsparrow_prepare <- function(reaches, parameters, design_matrix,
                               data_dictionary = NULL, ...) {
    required_cols <- c("waterid", "fnode", "tnode", "frac", "iftran",
                       "rchtype", "demiarea", "demtarea", "termflag",
                       "calsites", "depvar")
    # Add SOURCE/DELIVF columns from parameters$sparrowNames
    param_cols <- parameters$sparrowNames[parameters$parmType %in% c("SOURCE", "DELIVF")]
    required_cols <- c(required_cols, param_cols)

    missing <- setdiff(required_cols, names(reaches))
    if (length(missing) > 0 && is.null(data_dictionary)) {
      stop("Missing required columns in 'reaches': ",
           paste(missing, collapse = ", "),
           "\n  Either add these columns or provide 'data_dictionary' for name mapping.")
    }

    if (!is.null(data_dictionary)) {
      reaches <- .apply_data_dictionary(reaches, data_dictionary)
    }
    # ... rest of preparation
  }

FILES TO MODIFY:
  - R/rsparrow_model.R: Update rsparrow_prepare() validation logic
  - man/rsparrow_prepare.Rd: Document required column names clearly

UPDATE EXAMPLES:
  - Vignette: Show workflow without data_dictionary
  - sparrow_example: Ensure column names match required names
</description>
<files_modified>
  R/rsparrow_model.R
  man/rsparrow_prepare.Rd
  vignettes/rsparrow_vignette.Rmd
</files_modified>
<success_criteria>
  - rsparrow_prepare(reaches, params, design) works when columns named correctly
  - Clear error message when columns missing
  - Backward compatible: data_dictionary still works if provided
  - sparrow_example works without data_dictionary
</success_criteria>
</task>

<task id="17-4" status="pending" blocked_by="17-2">
<subject>Prune file.output.list and mapping.input.list</subject>
<description>
Drastically reduce configuration list bloat.

FILE.OUTPUT.LIST (current: ~160 fields, used: 19):
  KEEP (5 fields):
    - path_results, run_id (for file output when output_dir specified)
    - path_main (for backward compat)

  MOVE TO FUNCTION PARAMS (already done in 17-2):
    - NLLS_weights -> rsparrow_estimate(weights=)
    - ifHess -> rsparrow_estimate(hessian=)
    - if_mean_adjust_delivery_vars -> rsparrow_estimate(mean_adjust=)
    - s_offset -> rsparrow_estimate(s_offset=)
    - loadUnits, yieldUnits, etc. -> rsparrow_estimate(load_units=, ...)

  ELIMINATE (~140 fields):
    - All csv_*, path_* (except path_results, path_main)
    - All *_directoryName, create_initial_*, load_*, edit_*, copy_*
    - All mapping cosmetics (predictionTitleSize, residualColors, etc.)
    - All scenario config (moved to rsparrow_scenario params)
    - All Shiny/RShiny fields
    - All disabled features (dynamic model, ESRI maps, etc.)

MAPPING.INPUT.LIST (current: ~50 fields, used: 8):
  ELIMINATE ENTIRELY:
    - Move used fields (lon_limit, lat_limit) to plot.rsparrow() params
    - Styling (colors, sizes, breakpoints) -> plot() defaults with overrides

INTERNAL IMPLEMENTATION:
  Create minimal internal helper:
    .create_minimal_config <- function(output_dir = NULL, run_id = "run1") {
      list(
        path_results = if (!is.null(output_dir))
                         file.path(output_dir, "results", run_id) else NULL,
        run_id = run_id
      )
    }

FILES TO MODIFY:
  - R/rsparrow_model.R: Replace 160-line file.output.list with minimal version
  - R/plot.rsparrow.R: Add styling parameters (colors, sizes, etc.)
  - R/estimate.R: Update to use function params instead of list fields
  - R/controlFileTasksModel.R: Update list access patterns
</description>
<files_modified>
  R/rsparrow_model.R
  R/plot.rsparrow.R
  R/estimate.R
  R/controlFileTasksModel.R
</files_modified>
<success_criteria>
  - file.output.list reduced from ~160 to ~5 fields
  - mapping.input.list eliminated (or reduced to ~3 fields)
  - Plot styling via plot(model, colors=..., point_size=...) parameters
  - All current tests pass
  - No functional regression
</success_criteria>
</task>

<task id="17-5" status="pending" blocked_by="17-1,17-2,17-3,17-4">
<subject>Refactor rsparrow_model() as thin convenience wrapper</subject>
<description>
Reduce rsparrow_model() from ~500 lines to ~50 lines by delegating to new functions.

NEW IMPLEMENTATION:
  rsparrow_model <- function(reaches,
                             parameters,
                             design_matrix,
                             data_dictionary = NULL,
                             run_id = "run1",
                             output_dir = NULL,
                             if_estimate = TRUE,
                             if_predict = TRUE,
                             if_validate = FALSE,
                             # Pass-through to rsparrow_estimate:
                             hessian = TRUE,
                             mean_adjust = TRUE,
                             weights = "default",
                             load_units = "kg/year",
                             yield_units = "kg/ha/year",
                             ...) {

    # Step 1: Prepare data
    sparrow_data <- rsparrow_prepare(
      reaches = reaches,
      parameters = parameters,
      design_matrix = design_matrix,
      data_dictionary = data_dictionary,
      weights = weights
    )

    # Step 2: Estimate (if requested)
    if (isTRUE(if_estimate)) {
      model <- rsparrow_estimate(
        sparrow_data,
        hessian = hessian,
        mean_adjust = mean_adjust,
        load_units = load_units,
        yield_units = yield_units,
        ...
      )
    } else {
      # Use initial parameter values without optimization
      model <- .rsparrow_from_initial(sparrow_data)
    }

    # Step 3: Predict (if requested)
    if (isTRUE(if_predict)) {
      model$predictions <- predict(model)
    }

    # Step 4: Validate (if requested)
    if (isTRUE(if_validate)) {
      model <- rsparrow_validate(model, p = 0.25)
    }

    # Step 5: Write results (if output_dir provided)
    if (!is.null(output_dir)) {
      write_rsparrow_results(model, output_dir, run_id)
    }

    model
  }

BACKWARD COMPATIBILITY:
  - Same function signature (9 parameters)
  - Same return value (rsparrow S3 object)
  - Same behavior when if_estimate=TRUE, if_predict=TRUE, if_validate=FALSE

FILES TO MODIFY:
  - R/rsparrow_model.R: Rewrite rsparrow_model() as wrapper
  - Delete: prep_sparrow_inputs (merged into rsparrow_prepare)
  - Delete: inline file.output.list construction (replaced by minimal config)
</description>
<files_modified>
  R/rsparrow_model.R (major rewrite)
</files_modified>
<success_criteria>
  - rsparrow_model() reduced from ~500 to ~50 lines
  - All existing tests pass (backward compatibility)
  - sparrow_example workflow unchanged
  - R CMD check: 0 ERRORs, 0 WARNINGs
</success_criteria>
</task>

<task id="17-6" status="pending" blocked_by="17-5">
<subject>Update documentation and examples</subject>
<description>
Comprehensive documentation update for new API.

NEW MAN PAGES:
  - man/rsparrow_prepare.Rd: Document rsparrow_prepare() with required columns
  - man/rsparrow_estimate.Rd: Document rsparrow_estimate() with all parameters
  - man/rsparrow_data.Rd: Document rsparrow_data S3 class structure

UPDATED MAN PAGES:
  - man/rsparrow_model.Rd: Show as convenience wrapper; point to composable API
  - man/rsparrow-package.Rd: Package-level overview of both workflows
  - man/plot.rsparrow.Rd: Add new styling parameters

VIGNETTE UPDATE (vignettes/rsparrow_vignette.Rmd):
  Add new section "Composable Workflow" showing:
    1. rsparrow_prepare() for data setup
    2. rsparrow_estimate() for model fitting
    3. predict() for predictions
    4. rsparrow_bootstrap() / rsparrow_validate() for uncertainty
    5. plot() for diagnostics

  Keep existing "Quick Start" section using rsparrow_model() for simple use case.

EXAMPLES UPDATE:
  - All @examples in new functions use sparrow_example dataset
  - Show both convenience and composable workflows
</description>
<files_modified>
  man/rsparrow_prepare.Rd (new)
  man/rsparrow_estimate.Rd (new)
  man/rsparrow_data.Rd (new)
  man/rsparrow_model.Rd (update)
  man/rsparrow-package.Rd (update)
  man/plot.rsparrow.Rd (update)
  vignettes/rsparrow_vignette.Rmd (add composable workflow section)
</files_modified>
<success_criteria>
  - All exported functions have complete roxygen documentation
  - Vignette demonstrates both convenience and composable workflows
  - All examples run without error
  - R CMD check: 0 WARNINGs about documentation
</success_criteria>
</task>

<task id="17-7" status="pending" blocked_by="17-6">
<subject>Add tests for new API and run final verification</subject>
<description>
Comprehensive testing of new composable API.

NEW TESTS (tests/testthat/test-composable-api.R):
  test_that("rsparrow_prepare returns rsparrow_data object")
  test_that("rsparrow_prepare validates required columns")
  test_that("rsparrow_prepare works without data_dictionary")
  test_that("rsparrow_prepare works with data_dictionary (backward compat)")
  test_that("rsparrow_estimate accepts rsparrow_data")
  test_that("rsparrow_estimate returns rsparrow object")
  test_that("rsparrow_estimate parameters override defaults")
  test_that("composable workflow matches rsparrow_model output")
  test_that("print.rsparrow_data works")

REGRESSION TESTS:
  Verify all existing tests pass (163 tests)

FINAL VERIFICATION:
  source scripts/renv.sh
  R CMD build --no-build-vignettes .
  R CMD check --no-manual rsparrow_2.1.0.tar.gz

  # Test composable API:
  Rscript -e "
    library(rsparrow)
    data <- rsparrow_prepare(
      sparrow_example\$reaches,
      sparrow_example\$parameters,
      sparrow_example\$design_matrix
    )
    print(data)
    model <- rsparrow_estimate(data)
    print(model)
    coef(model)
    plot(model, type = 'residuals')
  "
</description>
<files_modified>
  tests/testthat/test-composable-api.R (new)
</files_modified>
<success_criteria>
  - New test file with ~10 tests for composable API
  - All 163+ tests pass
  - R CMD check: 0 ERRORs, 0 WARNINGs, <= 2 NOTEs
  - Composable workflow produces same coefficients as rsparrow_model()
</success_criteria>
</task>

</tasks>

<success_criteria>
<criterion>rsparrow_prepare() and rsparrow_estimate() are new exports with complete documentation</criterion>
<criterion>Users can call rsparrow_prepare() -> rsparrow_estimate() -> predict() as separate steps</criterion>
<criterion>data_dictionary is optional (backward compatible if provided)</criterion>
<criterion>file.output.list reduced from ~160 to ~5 fields</criterion>
<criterion>rsparrow_model() reduced from ~500 to ~50 lines (thin wrapper)</criterion>
<criterion>Full backward compatibility: existing rsparrow_model() usage unchanged</criterion>
<criterion>All 163+ tests pass</criterion>
<criterion>R CMD check: 0 ERRORs, 0 WARNINGs</criterion>
</success_criteria>

<failure_criteria>
<criterion>Breaking change to rsparrow_model() API (must remain backward compatible)</criterion>
<criterion>Change to rsparrow S3 object structure (existing code using model$coefficients must work)</criterion>
<criterion>Change to core math functions (estimateFeval, predict_sparrow, Fortran routines)</criterion>
<criterion>Test regression: any existing test fails</criterion>
</failure_criteria>

<risks>
<risk level="medium">
  Internal function signatures will change (startModelRun, estimate, controlFileTasksModel).
  Mitigation: Each phase is independently testable; regression tests run after each phase.
</risk>
<risk level="low">
  rsparrow_bootstrap/scenario/validate may need minor updates to work with new rsparrow_data.
  Mitigation: These functions currently extract data from model$data; structure unchanged.
</risk>
<risk level="low">
  Shiny DSS (inst/shiny_dss/) may break if it depends on file.output.list fields.
  Mitigation: Shiny code is separate from CRAN package; can be updated independently.
</risk>
</risks>

<estimated_effort>
Phase 1 (17-1, rsparrow_prepare): 1 session
Phase 2 (17-2, rsparrow_estimate): 1 session
Phase 3 (17-3, 17-4, eliminate bloat): 1 session
Phase 4 (17-5, refactor wrapper): 0.5 session
Phase 5 (17-6, 17-7, docs + tests): 1 session

Total: ~4-5 focused sessions
</estimated_effort>

<notes>
- This plan builds on Plans 13-16 (in-memory API, dependency reduction, function audit)
- The monolith decomposition issues flagged in Plan 16 (GH #24, #25) are partially
  addressed here by reducing estimate.R's role to a helper for rsparrow_estimate()
- controlFileTasksModel.R may become vestigial after this plan; could be archived
  in a future Plan 18
- The "yes"/"no" string flags (technical debt from Plan 16) are NOT addressed here;
  they remain as internal implementation detail hidden behind clean API
</notes>

</plan>
