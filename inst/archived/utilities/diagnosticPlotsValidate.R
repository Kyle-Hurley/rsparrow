# Archived Plan 16 (Function Audit): thin wrapper — call inlined into estimate.R.
# diagnosticPlotsNLLS() already has a `validation` parameter; the wrapper added no logic.
# Replaced in estimate.R with a direct call to diagnosticPlotsNLLS(..., validation=TRUE).

#' @title diagnosticPlotsValidate
#'
#' @description
#' Creates diagnostic plots and maps for validation sites output to
#' ~/estimate/(run_id)_validation_plots.pdf, and saves residual maps as shape files.
#'
#' Executed By: estimate.R
#'
#' Executes Routines: \itemize{
#'              \item diagnosticPlotsNLLS.R}
#'
#' @param file.output.list list of control settings and relative paths used for input and
#' output of external files.  Created by `generateInputList.R`
#' @param class.input.list list of control settings related to classification variables
#' @param vsitedata.demtarea.class Total drainage area classification variable for validation
#' sites.
#' @param vsitedata sitedata for validation. Calculated by `subdata[(subdata$vdepvar > 0  &
#' subdata$calsites==1), ]`
#' @param vsitedata.landuse Land use for incremental basins for diagnostics for validation
#' sites.
#' @param estimate.list list output from `estimate.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#' lon_limit, master_map_list, lineShapeName, lineWaterid, polyShapeName, ployWaterid, LineShapeGeo,
#' LineShapeGeo, CRStext, convertShapeToBinary.list, map_siteAttributes.list,
#' residual_map_breakpoints, site_mapPointScale, if_verify_demtarea_maps
#' @param Cor.ExplanVars.list list output from `correlationMatrix.R` (or NA if not computed)
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#' prediction, yield, and residuals csv and shape files
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param batch_mode yes/no character string indicating whether RSPARROW is being run in batch
#' mode
#' @keywords internal
#' @noRd

diagnosticPlotsValidate <- function(file.output.list, class.input.list, vsitedata.demtarea.class,
                                    vsitedata, vsitedata.landuse, estimate.list, mapping.input.list,
                                    Cor.ExplanVars.list = NA, add_vars, data_names,
                                    batch_mode = "no") {

  # Generate Validation Plots Report(s)
  diagnosticPlotsNLLS(
    file.output.list = file.output.list,
    class.input.list = class.input.list,
    sitedata.demtarea.class = vsitedata.demtarea.class,
    sitedata = vsitedata,
    sitedata.landuse = vsitedata.landuse,
    estimate.list = estimate.list,
    mapping.input.list = mapping.input.list,
    Cor.ExplanVars.list = Cor.ExplanVars.list,
    data_names = data_names,
    add_vars = NA,
    batch_mode = batch_mode,
    validation = TRUE
  )

} # end function
