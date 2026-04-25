#' @title predictScenarios
#' @description Executes tasks for the management source-change scenarios, including generating
#'            load predictions for the scenario, saving the predictions to the 'predictScenarios.list', and
#'            executing the mapping function 'predictMaps'. \cr \cr
#' Executed By: \itemize{\item interactiveBatchRun.R
#'             \item controlFileTasksModel.R
#'             \item goShinyPlot.R} \cr
#' Executes Routines: \itemize{\item named.list.R
#'             \item predictScenariosOutCSV.R
#'             \item predictScenariosPrep.R
#'             \item deliv_fraction.for
#'             \item mptnoder.for
#'             \item ptnoder.for} \cr
#' @param estimate.input.list named list of sparrow_control settings: ifHess, s_offset,
#'                           NLLS_weights,if_auto_scaling, and if_mean_adjust_delivery_vars
#' @param predict.list archive with all load and yield prediction variables to provide for
#'                    the efficient access and use of predictions in subsequent execution
#'                    of the parametric bootstrap predictions and uncertainties, mapping,
#'                    and scenario evaluations.  For more details see documentation Section
#'                    5.3.1.5
#' @param scenario.input.list list of control settings related to source change scenarios
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param JacobResults list output of Jacobian first-order partial derivatives of the model
#'       residuals `estimateNLLSmetrics.R` contained in the estimate.list object.  For more details see
#'       documentation Section 5.2.4.5.
#' @param if_predict yes/no indicating whether or not prediction is run
#' @param DataMatrix.list named list of 'data' and 'beta' matrices and 'data.index.list'
#'                       for optimization
#' @param SelParmValues selected parameters from parameters.csv using condition
#'       `ifelse((parmMax > 0 | (parmType=="DELIVF" & parmMax>=0)) & (parmMin<parmMax) & ((parmType=="SOURCE" &
#'       parmMin>=0) | parmType!="SOURCE")`
#' @param subdata data.frame input data (subdata)
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#'       prediction, yield, and residuals csv and shape files
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#'                          lon_limit, master_map_list, lineShapeName, lineWaterid,
#'                          polyShapeName, ployWaterid, LineShapeGeo, LineShapeGeo, CRStext,
#'                          convertShapeToBinary.list, map_siteAttributes.list,
#'                          residual_map_breakpoints, site_mapPointScale,
#'                          if_verify_demtarea_maps
#' @param dlvdsgn design matrix imported from design_matrix.csv
#' @param RSPARROW_errorOption yes/no control setting indicating where the RPSARROW_errorOption
#'                            should be applied
#' @keywords internal
#' @noRd



predictScenarios <- function(
    estimate.input.list, estimate.list,
    predict.list, scenario.input.list,
    data_names, JacobResults, if_predict,
    # bootcorrection,
    DataMatrix.list, SelParmValues, subdata,
    # predictStreamMapScenarios
    file.output.list,
    # scenarios out
    add_vars,
    mapping.input.list,
    dlvdsgn,
    RSPARROW_errorOption) {
  #
  # Output matrices in returned object 'predictScenarios.list':
  #  predmatrix - absolute loads reflecting change from load-reduction scenarios
  #  yldmatrix - absolute concentration and yields reflecting change from load-reduction scenarios
  #  predmatrix_chg - change from baseline loads, expressed as ratio of new to baseline load
  #  yldmatrix_chg - change from baseline concentration and yields, expressed as a ratio of new to baseline conditions

  #################################################


  # extract from file.output.list
  path_results         <- file.output.list$path_results
  run_id               <- file.output.list$run_id
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator  <- file.output.list$csv_columnSeparator

  # extract from scenario.input.list
  scenario_name              <- scenario.input.list$scenario_name
  scenario_sources           <- scenario.input.list$scenario_sources
  select_scenarioReachAreas  <- scenario.input.list$select_scenarioReachAreas
  forecast_filename          <- scenario.input.list$forecast_filename
  scenario_map_list          <- scenario.input.list$scenario_map_list
  scenario_factors           <- scenario.input.list$scenario_factors
  landuseConversion          <- scenario.input.list$landuseConversion
  select_targetReachWatersheds <- scenario.input.list$select_targetReachWatersheds

  # extract from estimate.input.list
  ConcFactor  <- estimate.input.list$ConcFactor
  yieldFactor <- estimate.input.list$yieldFactor
  loadUnits   <- estimate.input.list$loadUnits
  yieldUnits  <- estimate.input.list$yieldUnits
  ConcUnits   <- estimate.input.list$ConcUnits

  # delete files in subdirectory
  dirout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep)
  if (dir.exists(dirout)) {
    filesList <- list.files(dirout, recursive = TRUE, full.names = TRUE)
    if (length(filesList) != 0) {
      unlink(filesList, recursive = TRUE)
    }
  }


  if (select_scenarioReachAreas != "none" | !is.na(forecast_filename)) {

    # Calculate and output with bias-corrected predictions
    if (is.null(JacobResults$mean_exp_weighted_error)) {
      bootcorrection <- 1.0
    } else {
      bootcorrection <- JacobResults$mean_exp_weighted_error
    }
    if (file.exists(paste0(path_results, .Platform$file.sep, "predict", .Platform$file.sep, run_id, "_predict.list")) | if_predict == "yes") {
      if (if_predict == "no") {
        load(paste0(path_results, .Platform$file.sep, "predict", .Platform$file.sep, run_id, "_predict.list"))
      }

      # perform checks on scenario variable names designated by user
      #  scenario only executed if all source variables match
      vcheck <- 0
      if (length(forecast_filename) == 0 | forecast_filename == "" | is.na(forecast_filename)) {
        for (i in 1:length(JacobResults$Parmnames)) {
          for (j in 1:length(scenario_sources)) {
            if (scenario_sources[j] == JacobResults$Parmnames[i]) {
              vcheck <- vcheck + 1
            }
          }
        }
      }
      if (vcheck == length(scenario_sources) |
        (length(forecast_filename) != 0 & forecast_filename != "")) { # source names match

        message("Running predict scenarios...")

        # set data object for predictScenarios
        data <- DataMatrix.list$data

        scenarioPrep.list <- predictScenariosPrep(
          scenario.input.list,
          data_names,
          if_predict,
          # data
          data,
          # SelParmValues$srcvar,DataMatrix.list$data.index.list$jsrcvar,
          c(SelParmValues$srcvar, SelParmValues$dlvvar), c(DataMatrix.list$data.index.list$jsrcvar, DataMatrix.list$data.index.list$jdlvvar),
          DataMatrix.list$dataNames, JacobResults,
          subdata, SelParmValues,
          # paths
          file.output.list
        )


        # extract from JacobResults
        Parmnames <- JacobResults$Parmnames

        # extract required variables from subdata
        waterid  <- subdata[["waterid"]]
        demtarea <- subdata[["demtarea"]]
        demiarea <- subdata[["demiarea"]]
        meanq    <- subdata[["meanq"]]

        # extract from SelParmValues
        srcvar <- SelParmValues$srcvar

        # extract from DataMatrix.list$data.index.list
        data.index.list <- DataMatrix.list$data.index.list
        jsrcvar         <- data.index.list$jsrcvar
        jfrac           <- data.index.list$jfrac
        jfnode          <- data.index.list$jfnode
        jtnode          <- data.index.list$jtnode
        jiftran         <- data.index.list$jiftran
        jtarget         <- data.index.list$jtarget

        # extract from scenarioPrep.list
        # NOTE: data is the scenario-modified matrix — must be passed to .predict_core AFTER
        # scenario source modifications have been applied (risk noted in Plan 05B)
        data                       <- scenarioPrep.list$data
        scenario_name              <- scenarioPrep.list$scenario_name
        scenario_sources           <- scenarioPrep.list$scenario_sources
        select_scenarioReachAreas  <- scenarioPrep.list$select_scenarioReachAreas
        select_targetReachWatersheds <- scenarioPrep.list$select_targetReachWatersheds
        scenario_factors           <- scenarioPrep.list$scenario_factors
        landuseConversion          <- scenarioPrep.list$landuseConversion
        scenarioFlag               <- scenarioPrep.list$scenarioFlag
        beta1                      <- scenarioPrep.list$beta1
        scenarioCoefficients       <- scenarioPrep.list$scenarioCoefficients
        scenarioError              <- scenarioPrep.list$scenarioError
        ###################################

        if (!scenarioError) {
          # transfer the baseline predictions for load and yield
          predmatrix_base <- predict.list$predmatrix
          yldmatrix_base  <- predict.list$yldmatrix

          ################################
          # Setup variables for prediction

          nreach   <- length(data[, 1])
          numsites <- sum(ifelse(data[, 10] > 0, 1, 0))  # jdepvar site load index
          jjsrc    <- length(jsrcvar)

          # ------------------------------------------------------------------
          # Shared prediction kernel (decay, delivery, source loads)
          # Receives the scenario-modified data matrix
          # ------------------------------------------------------------------
          core <- .predict_core(data, data.index.list, Parmnames, beta1, dlvdsgn, numsites)

          # ------------------------------------------------------------------
          # Column-name vectors (strings only; data accessed via core named lists)
          # ------------------------------------------------------------------
          srclist_total    <- paste0("pload_",    Parmnames[seq_len(jjsrc)])
          srclist_mtotal   <- paste0("mpload_",   Parmnames[seq_len(jjsrc)])
          srclist_nd_total <- paste0("pload_nd_", Parmnames[seq_len(jjsrc)])
          srclist_inc      <- paste0("pload_inc_", Parmnames[seq_len(jjsrc)])

          # ------------------------------------------------------------------
          # Delivery fraction
          # ------------------------------------------------------------------
          data2_deliv <- matrix(0, nrow = nreach, ncol = 5)
          data2_deliv[, 1] <- data[, jfnode]
          data2_deliv[, 2] <- data[, jtnode]
          data2_deliv[, 3] <- data[, jfrac]
          data2_deliv[, 4] <- data[, jiftran]
          data2_deliv[, 5] <- data[, jtarget]

          deliv_frac <- deliver(nreach, waterid, core$nnode, data2_deliv,
                                core$incdecay, core$totdecay)

          #######################################
          # Output load predictions

          srclist_inc_deliv   <- paste0(srclist_inc, "_deliv")
          srclist_inc_share   <- paste0("share_inc_",   srcvar[seq_len(jjsrc)])
          srclist_total_share <- paste0("share_total_", srcvar[seq_len(jjsrc)])

          oparmlist <- c(
            "waterid", "pload_total", srclist_total,
            "mpload_total", srclist_mtotal,
            "pload_nd_total", srclist_nd_total,
            "pload_inc", srclist_inc,
            "deliv_frac",
            "pload_inc_deliv", srclist_inc_deliv,
            srclist_total_share, srclist_inc_share
          )

          ncols <- 7 + length(srclist_total) + length(srclist_mtotal) + length(srclist_nd_total) +
            length(srclist_inc) + length(srclist_inc) + length(srclist_inc) + length(srclist_inc)
          predmatrix <- matrix(0, nrow = nreach, ncol = ncols)

          predmatrix[, 1] <- subdata$waterid

          # total load
          col_mptot <- 3 + jjsrc
          col_ndtot <- 4 + jjsrc + jjsrc
          col_inc   <- 5 + jjsrc + jjsrc + jjsrc
          col_deliv <- 6 + jjsrc + jjsrc + jjsrc + jjsrc
          col_dload <- 7 + jjsrc + jjsrc + jjsrc + jjsrc

          predmatrix[, 2] <- core$pload_total * as.vector(bootcorrection)
          for (i in seq_len(jjsrc)) {
            predmatrix[, 2 + i] <- core$pload_src[[Parmnames[i]]] * as.vector(bootcorrection)

            col_share <- 7 + length(srclist_total) + length(srclist_mtotal) +
              length(srclist_nd_total) + length(srclist_inc) + length(srclist_inc) + i
            predmatrix[, col_share] <- predmatrix[, 2 + i] / predmatrix[, 2] * 100
            predmatrix[, col_share] <- ifelse(is.na(predmatrix[, col_share]), 0, predmatrix[, col_share])
          }
          # monitoring-adjusted total load
          predmatrix[, col_mptot] <- core$mpload_total
          for (i in seq_len(jjsrc)) {
            predmatrix[, col_mptot + i] <- core$mpload_src[[Parmnames[i]]]
          }
          # non-decayed (ND) total load
          predmatrix[, col_ndtot] <- core$pload_nd_total * as.vector(bootcorrection)
          for (i in seq_len(jjsrc)) {
            predmatrix[, col_ndtot + i] <- core$pload_nd_src[[Parmnames[i]]] * as.vector(bootcorrection)
          }
          # incremental load
          predmatrix[, col_inc] <- core$pload_inc * as.vector(bootcorrection)
          for (i in seq_len(jjsrc)) {
            predmatrix[, col_inc + i] <- core$pload_inc_src[[Parmnames[i]]] * as.vector(bootcorrection)

            col_inc_share <- 7 + length(srclist_total) + length(srclist_mtotal) +
              length(srclist_nd_total) + length(srclist_inc) + length(srclist_inc) +
              length(srclist_inc) + i
            predmatrix[, col_inc_share] <-
              predmatrix[, col_inc + i] / predmatrix[, col_inc] * 100
            predmatrix[, col_inc_share] <-
              ifelse(is.na(predmatrix[, col_inc_share]), 0, predmatrix[, col_inc_share])
          }
          # delivery fraction
          predmatrix[, col_deliv] <- deliv_frac

          # delivered incremental load
          dload <- predmatrix[, col_inc] * deliv_frac
          predmatrix[, col_dload] <- dload
          for (i in seq_len(jjsrc)) {
            dload <- predmatrix[, col_inc + i] * deliv_frac
            predmatrix[, col_dload + i] <- dload
          }

          # Output yield predictions

          srclist_yield        <- gsub("pload", "yield", srclist_total)
          srclist_myield       <- gsub("pload", "yield", srclist_mtotal)
          srclist_yldinc       <- gsub("pload", "yield", srclist_inc)
          srclist_yldinc_deliv <- gsub("pload", "yield", srclist_inc_deliv)

          oyieldlist <- c(
            "waterid", "concentration", "yield_total", srclist_yield,
            "myield_total", srclist_myield,
            "yield_inc", srclist_yldinc,
            "yield_inc_deliv", srclist_yldinc_deliv
          )

          ncols_yld <- 6 + jjsrc + jjsrc + jjsrc + jjsrc
          yldmatrix <- matrix(0, nrow = nreach, ncol = ncols_yld)

          yldmatrix[, 1] <- subdata$waterid
          # total yield
          col_yld_inc   <- 5 + jjsrc + jjsrc
          col_yld_dload <- 6 + jjsrc + jjsrc + jjsrc
          for (i in seq_len(nreach)) {
            if (demtarea[i] > 0) {
              if (meanq[i] > 0) {
                yldmatrix[i, 2] <- predmatrix[i, 2] / meanq[i] * ConcFactor
              } # concentration
              yldmatrix[i, 3] <- predmatrix[i, 2] / demtarea[i] * yieldFactor

              for (j in seq_len(jjsrc)) {
                yldmatrix[i, 3 + j] <- predmatrix[i, 2 + j] / demtarea[i] * yieldFactor
              }
              # monitoring-adjusted total yield
              yldmatrix[i, 4 + jjsrc] <- predmatrix[i, col_mptot] / demtarea[i] * yieldFactor
              for (j in seq_len(jjsrc)) {
                yldmatrix[i, 4 + jjsrc + j] <- predmatrix[i, col_mptot + j] / demtarea[i] * yieldFactor
              }
            }
          }
          # incremental yield
          for (i in seq_len(nreach)) {
            if (demiarea[i] > 0) {
              yldmatrix[i, col_yld_inc] <- predmatrix[i, col_inc] / demiarea[i]

              for (j in seq_len(jjsrc)) {
                yldmatrix[i, col_yld_inc + j] <- predmatrix[i, col_inc + j] / demiarea[i]
              }

              # delivered incremental yield
              yldmatrix[i, col_yld_dload] <-
                predmatrix[i, col_dload] / demiarea[i]

              for (j in seq_len(jjsrc)) {
                yldmatrix[i, col_yld_dload + j] <-
                  predmatrix[i, col_dload + j] / demiarea[i]
              }
            }
          }


          # Do not include monitoring-adjusted (conditional) prediction label objects in saved list
          predict.source.list <- named.list(
            srclist_total, srclist_inc, srclist_inc_deliv,
            srclist_nd_total, srclist_yield, srclist_yldinc,
            srclist_yldinc_deliv
          )


          # Compute the change from load-reduction scenarios, expressed as ratio of new to baseline load
          predmatrix_chg <- matrix(0, nrow = nreach, ncol = ncol(predmatrix_base))
          yldmatrix_chg  <- matrix(0, nrow = nreach, ncol = ncol(yldmatrix_base))

          predmatrix_chg[, 1] <- predmatrix[, 1]
          yldmatrix_chg[, 1]  <- yldmatrix[, 1]
          for (i in 2:ncol(predmatrix_base)) {
            temp <- predmatrix[, i] / predmatrix_base[, i]
            temp <- ifelse(is.na(temp), 0, temp)
            predmatrix_chg[, i] <- ifelse(temp == 0, 1, temp)
            predmatrix_chg[, i] <- ifelse(is.infinite(predmatrix_chg[, i]), NA, predmatrix_chg[, i])
          }
          for (i in 2:ncol(yldmatrix_base)) {
            temp <- yldmatrix[, i] / yldmatrix_base[, i]
            temp <- ifelse(is.na(temp), 0, temp)
            yldmatrix_chg[, i] <- ifelse(temp == 0, 1, temp)
            yldmatrix_chg[, i] <- ifelse(is.infinite(yldmatrix_chg[, i]), NA, yldmatrix_chg[, i])
          }


          # Convert matrices to data frames with column headers (previously performed in the predictScenariosOutCSV.R function)
          predmatrix <- as.data.frame(predmatrix)
          colnames(predmatrix) <- oparmlist

          yldmatrix <- as.data.frame(yldmatrix)
          colnames(yldmatrix) <- oyieldlist

          predmatrix_chg <- as.data.frame(predmatrix_chg)
          colnames(predmatrix_chg) <- oparmlist

          yldmatrix_chg <- as.data.frame(yldmatrix_chg)
          colnames(yldmatrix_chg) <- oyieldlist

          # Drop monitoring-adjusted (conditional) predictions from objects (headers and predictions)
          dropLoadNames  <- c("mpload_total", srclist_mtotal, "deliv_frac")
          dropYieldNames <- c("myield_total", srclist_myield)

          oparmlist <- c(
            "waterid", "pload_total", srclist_total,
            "pload_nd_total", srclist_nd_total,
            "pload_inc", srclist_inc,
            "pload_inc_deliv", srclist_inc_deliv,
            srclist_total_share, srclist_inc_share
          )
          oyieldlist <- c(
            "waterid", "concentration", "yield_total", srclist_yield,
            "yield_inc", srclist_yldinc,
            "yield_inc_deliv", srclist_yldinc_deliv
          )

          predmatrix <- predmatrix[, !(colnames(predmatrix) %in% dropLoadNames)]
          yldmatrix  <- yldmatrix[, !(colnames(yldmatrix) %in% dropYieldNames)]
          predmatrix_chg <- predmatrix_chg[, !(colnames(predmatrix_chg) %in% dropLoadNames)]
          yldmatrix_chg  <- yldmatrix_chg[, !(colnames(yldmatrix_chg) %in% dropYieldNames)]

          # Assign the load and yield units
          loadunits    <- rep(loadUnits, ncol(predmatrix))
          loadunits[1] <- "Reach ID Number"
          for (i in seq_len(jjsrc)) {
            loadunits[(5 + length(srclist_total) + length(srclist_nd_total) + length(srclist_inc) + length(srclist_inc) + i)] <- "Percent"
            loadunits[(5 + length(srclist_total) + length(srclist_nd_total) + length(srclist_inc) + length(srclist_inc) + length(srclist_inc) + i)] <- "Percent"
          }
          yieldunits    <- rep(yieldUnits, ncol(yldmatrix))
          yieldunits[1] <- "Reach ID Number"
          yieldunits[2] <- ConcUnits


          predictScenarios.list <- named.list(
            select_scenarioReachAreas, select_targetReachWatersheds, scenario_name,
            scenario_sources, scenario_factors, landuseConversion,
            oparmlist, loadunits, predmatrix, oyieldlist, yieldunits, yldmatrix,
            predict.source.list, predmatrix_chg, yldmatrix_chg, scenarioCoefficients, scenarioFlag
          )


          #########################################
          #########################################
          ################## end predictScenarios#######

          # output csv files (skipped in in-memory mode when path_results is NULL)
          if (!is.null(file.output.list$path_results)) {
            predictScenariosOutCSV(
              file.output.list, estimate.list, predictScenarios.list, subdata, add_vars,
              scenario_name, scenarioFlag, data_names, scenarioCoefficients
            )
          }

          # NOTE: Batch and Shiny mapping removed (Plan 05A).

          return(predictScenarios.list)

          #############################################
          #############################################
        } # scenarioError
      } else { # check on variable names; names do not match
        message(" \nWARNING : No scenarios executed because source variables are not correct in scenario_sources setting\n ")
      } # conditions from controlfiletaskmodel
    } # initial condition
  } # if predict scenarios
} # end function
