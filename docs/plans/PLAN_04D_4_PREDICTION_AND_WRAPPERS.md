<plan id="04-D-4">
<name>predict.rsparrow + Wrappers + Final Verification</name>
<part_of>Plan 04-D sub-session 4 of 4 — implements Tasks 11, 12, 13 from PLAN_04D_API_IMPLEMENTATION.md</part_of>
<previous_plans>04-A through 04-C, 04-D-1 (S3 methods), 04-D-2 (read_sparrow_data),
04-D-3 (rsparrow_model)</previous_plans>

<context>
All prior sub-sessions complete. This final sub-session implements:
  Task 12: predict.rsparrow() + object_to_estimate_list() helper
  Task 11: rsparrow_bootstrap(), rsparrow_scenario(), rsparrow_validate() (thin wrappers)
  Task 13: Final R CMD check --as-cran

predict.rsparrow() wraps predict_sparrow() (renamed from predict() in Plan 03).
The three wrappers in Task 11 share a common pattern: validate input, call internal
function, store result in model$field, return updated model.
object_to_estimate_list() reconstructs the estimate.list structure from the rsparrow S3
object — this is the main implementation challenge of this sub-session.

MEDIUM complexity. Thin wrappers share a pattern. object_to_estimate_list() is the main
risk: if field names in the rsparrow object differ from what internal functions expect,
calls to predict_sparrow() / estimateBootstraps() will fail.
</context>

<prerequisites>
- ALL prior plans (04-A through 04-D-3) complete and verified
- R CMD check: 0 errors before starting
- Confirm stubs:
    grep -n "Not yet implemented" RSPARROW_master/R/predict.rsparrow.R
    grep -n "Not yet implemented" RSPARROW_master/R/rsparrow_bootstrap.R
    grep -n "Not yet implemented" RSPARROW_master/R/rsparrow_scenario.R
    grep -n "Not yet implemented" RSPARROW_master/R/rsparrow_validate.R
- Confirm %||% operator available (from 04D-1):
    grep -n "%||%" RSPARROW_master/R/rsparrow-package.R
</prerequisites>

<reference_documents>
Read before starting:
  docs/implementation/PLAN_04_SKELETON_IMPLEMENTATIONS.md
    — implementation name="predict.rsparrow"
    — implementation name="rsparrow_bootstrap"
    — implementation name="rsparrow_scenario"
    — implementation name="rsparrow_validate"
  docs/plans/PLAN_04D_API_IMPLEMENTATION.md    — task id="12", task id="11"
  docs/plans/PLAN_04D_3_MODEL_ENTRY_POINT.md   — rsparrow_object_structure (field names from 04D-3)
</reference_documents>

<verify_internal_signatures label="Run before writing any code">
Internal function signatures may have changed in Plans 04-B/C. Verify all before coding:

  # predict_sparrow (renamed from predict in Plan 03)
  grep -n "^predict_sparrow <- function" RSPARROW_master/R/predict.R
  head -20 RSPARROW_master/R/predict.R

  # estimateBootstraps
  grep -n "^estimateBootstraps <- function" RSPARROW_master/R/estimateBootstraps.R
  head -20 RSPARROW_master/R/estimateBootstraps.R

  # predictScenarios
  grep -n "^predictScenarios <- function" RSPARROW_master/R/predictScenarios.R
  head -20 RSPARROW_master/R/predictScenarios.R

  # validateMetrics (check if this function actually exists)
  grep -rn "^validateMetrics <- function" RSPARROW_master/R/
  # Alternative: check what validate function is called in the legacy flow
  grep -n "validate" RSPARROW_master/R/controlFileTasksModel.R | head -20
</verify_internal_signatures>

<scope>
<in_scope>
- Task 12: predict.rsparrow() + object_to_estimate_list() in predict.rsparrow.R
- Task 11: rsparrow_bootstrap.R, rsparrow_scenario.R, rsparrow_validate.R
- Task 13: Final R CMD check --as-cran; fix any introduced errors/warnings
</in_scope>
<out_of_scope>
- Diagnostic plot implementation in plot.rsparrow() — deferred to Plan 05
- Full logical TRUE/FALSE conversion for "yes"/"no" strings — Plan 05
- Function consolidation (predict/predictBoot/predictScenarios merge) — Plan 05
- Test suite creation — Plan 06
</out_of_scope>
</scope>

<tasks>

<task id="12" priority="critical">
<name>Implement predict.rsparrow() + object_to_estimate_list()</name>
<file>RSPARROW_master/R/predict.rsparrow.R</file>
<description>
Implement both functions in predict.rsparrow.R. object_to_estimate_list() reconstructs
the estimate.list structure from the rsparrow S3 object fields. Use the exact field names
established in sub-session 04D-3 for the rsparrow object, and the field names verified
from predict_sparrow()'s actual signature.

Implementation (adjust argument names to match actual predict_sparrow signature):

  predict.rsparrow <- function(object, type = c("all", "load", "yield"),
                                newdata = NULL, ...) {
    if (!inherits(object, "rsparrow"))
      stop("object must be of class 'rsparrow'")
    type <- match.arg(type)

    # Boot correction factor: use if bootstrap has been run
    bootcorrection <- if (!is.null(object$bootstrap))
      object$bootstrap$mean_exp_weighted_error  # verify field name
    else
      NULL

    # Call internal prediction function (renamed from predict() in Plan 03)
    predict_list <- predict_sparrow(
      estimate.list       = object_to_estimate_list(object),
      estimate.input.list = object$data$estimate.input.list,
      bootcorrection      = bootcorrection,
      DataMatrix.list     = object$data$DataMatrix.list,
      SelParmValues       = object$data$SelParmValues,
      subdata             = object$data$subdata
    )

    object$predictions <- predict_list
    object
  }

  # Internal helper: reconstruct estimate.list from rsparrow S3 object
  object_to_estimate_list <- function(object) {
    list(
      oEstimate    = unname(object$coefficients),
      Parmnames    = names(object$coefficients),
      JacobResults = list(
        Jacobse = object$std_errors,
        covar   = object$vcov,
        R2      = object$fit_stats$R2,
        RMSE    = object$fit_stats$RMSE
      ),
      Residuals    = object$residuals,
      Pload_meas   = object$fitted_values
    )
  }

IMPORTANT: The field names inside object_to_estimate_list() (oEstimate, JacobResults,
Residuals, Pload_meas, Parmnames) must match what predict_sparrow() actually expects as
elements of its estimate.list argument. Verify before finalising.

Also verify predict_sparrow()'s argument names — it may use different parameter names
than the pseudocode above. Check: head -15 RSPARROW_master/R/predict.R
</description>
<note>
object_to_estimate_list() is also used by rsparrow_bootstrap() (task 11) and potentially
rsparrow_validate() (task 11). Keep it in predict.rsparrow.R for now — it does not need
its own file. If later tasks require it, move to a utils-internal.R file.
</note>
<success>
- No stop("Not yet implemented") in predict.rsparrow.R
- predict(model) where model is a valid rsparrow object populates model$predictions
  and returns the updated object
</success>
</task>

<task id="11" priority="high">
<name>Implement rsparrow_bootstrap(), rsparrow_scenario(), rsparrow_validate()</name>
<files>
  RSPARROW_master/R/rsparrow_bootstrap.R
  RSPARROW_master/R/rsparrow_scenario.R
  RSPARROW_master/R/rsparrow_validate.R
</files>
<description>
These are thin wrappers sharing a common pattern:
  1. Validate input is class "rsparrow"
  2. Validate preconditions (e.g., predictions must exist for scenario)
  3. Call internal function with fields extracted from model$data
  4. Store result in model$bootstrap / model$predictions$scenarios / model$validation
  5. Return updated model

All three use "yes"/"no" strings for any boolean flags passed to internal functions.
The %||% operator (added in 04D-1) is used in bootstrap and validate for seed handling.

--- rsparrow_bootstrap.R ---
Calls estimateBootstraps(). Requires:
  - model$data$Csites.weights.list (set in 04D-3; verify it is not NULL)
  - object_to_estimate_list(model) — defined in predict.rsparrow.R

Pseudocode:
  rsparrow_bootstrap <- function(model, n_iter = 200, seed = NULL) {
    if (!inherits(model, "rsparrow"))
      stop("model must be of class 'rsparrow'")
    stopifnot(is.numeric(n_iter), n_iter >= 10, n_iter <= 10000)
    if (!is.null(seed)) set.seed(seed)

    boot_results <- estimateBootstraps(
      iseed               = seed %||% sample.int(.Machine$integer.max, 1),
      biters              = as.integer(n_iter),
      estimate.list       = object_to_estimate_list(model),
      DataMatrix.list     = model$data$DataMatrix.list,
      SelParmValues       = model$data$SelParmValues,
      Csites.weights.list = model$data$Csites.weights.list,
      estimate.input.list = model$data$estimate.input.list,
      dlvdsgn             = model$data$dlvdsgn,
      file.output.list    = model$data$file.output.list
    )

    model$bootstrap <- boot_results
    model
  }

ADJUST argument names to match actual estimateBootstraps() signature.

--- rsparrow_scenario.R ---
Calls predictScenarios(). Requires model$predictions to be populated first.

Pseudocode:
  rsparrow_scenario <- function(model, source_changes) {
    if (!inherits(model, "rsparrow"))
      stop("model must be of class 'rsparrow'")
    if (is.null(model$predictions))
      stop("Run predict(model) before rsparrow_scenario()")
    if (!is.data.frame(source_changes) && !is.list(source_changes))
      stop("source_changes must be a data.frame or named list of source multipliers")

    scenario_results <- predictScenarios(
      predict.list        = model$predictions,
      subdata             = model$data$subdata,
      DataMatrix.list     = model$data$DataMatrix.list,
      SelParmValues       = model$data$SelParmValues,
      estimate.input.list = model$data$estimate.input.list,
      dlvdsgn             = model$data$dlvdsgn,
      scenario.input.list = model$data$scenario.input.list,
      file.output.list    = model$data$file.output.list
    )

    model$predictions$scenarios <- scenario_results
    model
  }

ADJUST argument names to match actual predictScenarios() signature.

--- rsparrow_validate.R ---
Calls validateMetrics() (verify this function name exists — it may be named differently).
Check: grep -rn "^validateMetrics <- function\|^validate" RSPARROW_master/R/

Pseudocode:
  rsparrow_validate <- function(model, fraction = 0.2, seed = NULL) {
    if (!inherits(model, "rsparrow"))
      stop("model must be of class 'rsparrow'")
    stopifnot(is.numeric(fraction), fraction > 0, fraction < 1)

    val_results <- validateMetrics(
      iseed               = seed %||% sample.int(.Machine$integer.max, 1),
      pvalidate           = fraction,
      subdata             = model$data$subdata,
      DataMatrix.list     = model$data$DataMatrix.list,
      SelParmValues       = model$data$SelParmValues,
      estimate.input.list = model$data$estimate.input.list,
      dlvdsgn             = model$data$dlvdsgn,
      Csites.weights.list = model$data$Csites.weights.list
    )

    model$validation <- val_results
    model
  }
</description>
<success>No stop("Not yet implemented") remains in any of the three files.</success>
</task>

<task id="13" priority="critical">
<name>Final verification — R CMD check --as-cran</name>
<commands>
  R CMD build --no-build-vignettes RSPARROW_master/
  R CMD check --as-cran rsparrow_2.1.0.tar.gz
</commands>
<description>
Run the complete build + check cycle. The target is 0 errors, ≤1 warning, ≤1 note.
Compare against the Plan 04-C baseline (0 errors, 4 warnings, 1 note).

Any NEW errors introduced by this sub-session must be fixed before declaring 04D done.
Pre-existing warnings/notes from Plan 04-C baseline may remain.
</description>
<grep_checks label="ALL must return 0 results before running R CMD check">
  grep -r "assign.*\.GlobalEnv"          RSPARROW_master/R/
  grep -r "shell\.exec\|Rscript\.exe"    RSPARROW_master/R/
  grep -r "batch_mode"                   RSPARROW_master/R/
  grep    "eval(parse"                   RSPARROW_master/R/estimateFeval.R
  grep    "eval(parse"                   RSPARROW_master/R/predict.R
  grep -r "Not yet implemented"          RSPARROW_master/R/
</grep_checks>
<s3_dispatch_check label="All must dispatch and return without error">
  library(rsparrow)
  mock_rsparrow <- structure(
    list(
      call         = quote(rsparrow_model("path")),
      coefficients = c(beta_N_atm = 0.42, beta_N_fert = 0.18, k_reach = 0.003),
      std_errors   = c(beta_N_atm = 0.05, beta_N_fert = 0.02, k_reach = 0.0005),
      vcov         = diag(c(0.0025, 0.0004, 0.00000025)),
      residuals    = rnorm(150, 0, 0.3),
      fitted_values = exp(rnorm(150, 3, 1)),
      fit_stats    = list(R2 = 0.87, RMSE = 0.31, npar = 3, nobs = 150,
                          convergence = TRUE),
      data         = list(sitedata = data.frame(waterid = 1:150)),
      predictions  = NULL, bootstrap = NULL, validation = NULL,
      metadata     = list(version = "2.1.0", run_id = "test_model",
                          model_type = "static", path_main = "/tmp",
                          timestamp = Sys.time())
    ),
    class = "rsparrow"
  )
  print(mock_rsparrow)
  s <- summary(mock_rsparrow)
  print(s)
  coef(mock_rsparrow)
  residuals(mock_rsparrow)
  vcov(mock_rsparrow)
</s3_dispatch_check>
<success>0 errors, ≤4 warnings (pre-existing), ≤1 note from R CMD check --as-cran</success>
</task>

</tasks>

<verification label="Full integration test with UserTutorial">
After completing tasks 12, 11, and 13 in order:

  library(rsparrow)
  # Step 1: Build and estimate model
  model <- rsparrow_model("/path/to/UserTutorial")
  class(model)          # "rsparrow"
  coef(model)           # named numeric vector
  summary(model)        # S3 dispatch

  # Step 2: Predictions (if not already populated by rsparrow_model)
  model <- predict(model)
  !is.null(model$predictions)   # TRUE

  # Step 3: Bootstrap (optional, slow)
  # model <- rsparrow_bootstrap(model, n_iter = 10, seed = 42)
  # !is.null(model$bootstrap)     # TRUE

  # Step 4: Scenario
  # source_changes <- list(N_fertilizer = 0.5)
  # model <- rsparrow_scenario(model, source_changes)

  # Step 5: Validate
  # model <- rsparrow_validate(model, fraction = 0.2, seed = 42)
  # !is.null(model$validation)    # TRUE
</verification>

<risks>
<risk name="object_to_estimate_list_field_mismatch" severity="HIGH">
estimate.list field names (oEstimate, Parmnames, Residuals, Pload_meas) are inferred
from earlier greps. predict_sparrow() may expect different names. Always verify before
coding: grep -n "estimate\.list\$" RSPARROW_master/R/predict.R | head -20
</risk>
<risk name="predict_sparrow_argument_names_changed" severity="MEDIUM">
Plans 04B/C may have modified predict_sparrow()'s signature (it was predict() in Plan 03,
renamed to predict_sparrow()). Verify current argument names before calling.
Mitigation: head -20 RSPARROW_master/R/predict.R
</risk>
<risk name="validateMetrics_function_name" severity="MEDIUM">
The internal validation function may not be named validateMetrics(). Check what function
controlFileTasksModel() calls for validation:
grep -n "validate\|Validate" RSPARROW_master/R/controlFileTasksModel.R
</risk>
<risk name="csites_weights_list_null_in_bootstrap" severity="HIGH">
If model$data$Csites.weights.list is NULL (not stored in 04D-3), rsparrow_bootstrap()
and rsparrow_validate() will fail with a missing argument error. This must be fixed in
04D-3 before 04D-4 can succeed.
Verification: stopifnot(!is.null(model$data$Csites.weights.list))
</risk>
<risk name="yes_no_strings_in_internal_calls" severity="LOW">
estimateBootstraps(), predictScenarios(), and validateMetrics() still expect "yes"/"no"
strings. Do not pass TRUE/FALSE — silent incorrect behavior results.
</risk>
</risks>

<success_criteria>
- grep -r "Not yet implemented" RSPARROW_master/R/ → 0 results
- grep -r "assign.*\.GlobalEnv" RSPARROW_master/R/ → 0 results
- grep -r "shell\.exec\|Rscript\.exe\|batch_mode" RSPARROW_master/R/ → 0 results
- grep "eval(parse" RSPARROW_master/R/estimateFeval.R → 0 results
- grep "eval(parse" RSPARROW_master/R/predict.R → 0 results
- print/summary/coef/residuals/vcov all dispatch correctly on rsparrow mock object
- predict(model) returns rsparrow object with $predictions populated
- R CMD check --as-cran: 0 errors, ≤4 warnings, ≤1 note
</success_criteria>

<failure_criteria>
- Any exported function still calls stop("Not yet implemented") → plan incomplete
- R CMD check introduces new errors vs Plan 04-C baseline → fix before declaring done
- Any assign(.GlobalEnv) or shell.exec remains → earlier sub-plan incomplete; stop and fix
- model$data$Csites.weights.list is NULL → fix in 04D-3 and re-run this sub-session
</failure_criteria>

<plan_04d_complete_when>
All 4 sub-sessions done:
  04D-1: print/summary/coef/residuals/vcov/plot + %||% ✓
  04D-2: read_sparrow_data() ✓
  04D-3: rsparrow_model() ✓
  04D-4: predict + wrappers + R CMD check ✓

Next: Plan 05 (function consolidation — predict/predictBoot/predictScenarios merge,
eval(parse) removal, "yes"/"no" → logical conversion)
</plan_04d_complete_when>

</plan>
