#' Write rsparrow model results to disk
#'
#' Writes model results (estimates, predictions, diagnostics) to a directory.
#' This is the single opt-in file-output function for the rsparrow package;
#' computation functions do not write files as side effects.
#'
#' @param model An \code{rsparrow} object returned by \code{\link{rsparrow_model}}.
#' @param path Character. Directory to write results into. Created recursively if
#'   it does not exist.
#' @param what Character vector of result types to write. Options:
#'   \code{"estimates"}, \code{"predictions"}, \code{"diagnostics"}, \code{"all"}.
#'   Default: \code{"all"}.
#' @return Invisibly returns a character vector of paths of the files written.
#' @export
#'
#' @examples
#' \donttest{
#' model <- rsparrow_model(
#'   sparrow_example$reaches,
#'   sparrow_example$parameters,
#'   sparrow_example$design_matrix,
#'   sparrow_example$data_dictionary
#' )
#' write_rsparrow_results(model, path = tempdir(), what = "estimates")
#' }
write_rsparrow_results <- function(model, path, what = "all") {
  stopifnot(inherits(model, "rsparrow"))
  stopifnot(is.character(path), length(path) == 1L)
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)

  all_what <- c("estimates", "predictions", "diagnostics")
  if (identical(what, "all")) what <- all_what
  what <- match.arg(what, all_what, several.ok = TRUE)

  written <- character(0)

  # Build a minimal file.output.list pointing at user's path
  run_id      <- model$metadata$run_id
  path_results <- paste0(normalizePath(path, mustWork = FALSE), .Platform$file.sep)
  fol <- list(
    path_results         = path_results,
    run_id               = run_id,
    add_vars             = model$data$file.output.list$add_vars,
    csv_decimalSeparator = model$data$file.output.list$csv_decimalSeparator,
    csv_columnSeparator  = model$data$file.output.list$csv_columnSeparator,
    if_corrExplanVars    = "no"
  )

  estimate.list       <- model$data$estimate.list
  estimate.input.list <- model$data$estimate.input.list
  SelParmValues       <- model$data$SelParmValues
  subdata             <- model$data$subdata
  data_names          <- model$data$data_names
  predict.list        <- model$predictions
  add_vars            <- model$data$file.output.list$add_vars

  if ("estimates" %in% what) {
    dir.create(file.path(path, "estimate"), recursive = TRUE, showWarnings = FALSE)

    # Write NLLS summary table (does not require predict.list)
    if (!is.null(estimate.list$ANOVA.list)) {
      classvar_val <- model$data$classvar
      if (identical(classvar_val, NA_character_)) classvar_val <- "sitedata.demtarea.class"
      sitedata_wr  <- model$data$sitedata
      numsites_wr  <- if (!is.null(sitedata_wr)) nrow(sitedata_wr) else 0L
      betavalues_wr <- model$data$SelParmValues  # has sparrowNames / description / parmUnits columns

      estimateNLLStable(
        fol,
        if_estimate           = "yes",
        if_estimate_simulation = "no",
        ifHess                = if (!is.null(estimate.list$HesResults)) "yes" else "no",
        if_sparrowEsts        = 1L,
        classvar              = classvar_val,
        sitedata              = sitedata_wr,
        numsites              = numsites_wr,
        estimate.list         = estimate.list,
        Cor.ExplanVars.list   = NA,
        if_validate           = if (!is.null(estimate.list$vANOVA.list)) "yes" else "no",
        vANOVA.list           = estimate.list$vANOVA.list,
        vMdiagnostics.list    = estimate.list$vMdiagnostics.list,
        betavalues            = betavalues_wr,
        Csites.weights.list   = model$data$Csites.weights.list
      )
    }

    # Write summary predictions CSV (requires predict.list)
    if (is.null(predict.list)) {
      message("write_rsparrow_results: no predictions available; skipping summary predictions output.")
    } else {
      class.input.list <- list(
        classvar              = model$data$classvar,
        class_landuse         = NA,
        class_landuse_percent = NA
      )
      predictSummaryOutCSV(
        fol, estimate.input.list,
        SelParmValues, estimate.list, predict.list,
        subdata, class.input.list
      )
      written <- c(written,
        file.path(path, "estimate", paste0(run_id, "_summary_predictions.csv")))
    }
  }

  if ("predictions" %in% what) {
    if (is.null(predict.list)) {
      message("write_rsparrow_results: no predictions available; skipping 'predictions' output.")
    } else {
      dir.create(file.path(path, "predict"), recursive = TRUE, showWarnings = FALSE)
      predictOutCSV(
        fol, estimate.list, predict.list, subdata,
        add_vars, data_names
      )
      written <- c(written,
        file.path(path, "predict", paste0(run_id, "_predicts_load.csv")),
        file.path(path, "predict", paste0(run_id, "_predicts_load_units.csv")),
        file.path(path, "predict", paste0(run_id, "_predicts_yield.csv")),
        file.path(path, "predict", paste0(run_id, "_predicts_yield_units.csv")))
    }
  }

  if ("diagnostics" %in% what) {
    anova <- estimate.list$ANOVA.list
    if (!is.null(anova)) {
      dir.create(file.path(path, "estimate"), recursive = TRUE, showWarnings = FALSE)
      fileout <- file.path(path, "estimate", paste0(run_id, "_anova.csv"))
      utils::write.csv(as.data.frame(anova), file = fileout, row.names = TRUE)
      written <- c(written, fileout)
    } else {
      message("write_rsparrow_results: no diagnostics data available; skipping 'diagnostics' output.")
    }
  }

  invisible(written)
}
