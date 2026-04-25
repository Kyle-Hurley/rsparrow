#' @title predictScenariosOutCSV
#' @description Outputs the scenario load predictions to CSV files.  \cr \cr
#' Executed By: predictScenarios.R \cr
#' Executes Routines: \itemize{\item getVarList.R
#'             \item named.list.R
#'             } \cr
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param estimate.list list output from `estimate.R`
#' @param predictScenarios.list an archive with key scenario control settings and the load and
#'                             yield prediction variables that are output from the execution of
#'                             a source-change scenario evaluation. For more details see
#'                             documentation Section 5.5.9
#' @param subdata data.frame input data (subdata)
#' @param add_vars additional variables specified by the setting `add_vars` to be included in
#'       prediction, yield, and residuals csv and shape files
#' @param scenario_name User specified name of source reduction scenario from sparrow_control.
#'       Used to create directory for source reduction scenario results.
#' @param scenarioFlag binary vector indicating whether a reach is included in the source
#'       reduction scenario
#' @param data_names data.frame of variable metadata from data_Dictionary.csv file
#' @param scenarioCoefficients user specified model coefficients for the scenario
#' @keywords internal
#' @noRd



predictScenariosOutCSV <- function(
    file.output.list, estimate.list, predictScenarios.list, subdata, add_vars,
    scenario_name, scenarioFlag, data_names, scenarioCoefficients) {
  #################################################

  # define "space" for printing
  ch <- character(1)
  space <- data.frame(ch)
  row.names(space) <- ch
  colnames(space) <- c(" ")
  # extract required variables from subdata
  waterid <- subdata[["waterid"]]
  waterid_for_RSPARROW_mapping <- subdata[["waterid_for_RSPARROW_mapping"]]
  rchtype <- subdata[["rchtype"]]
  headflag <- subdata[["headflag"]]
  termflag <- subdata[["termflag"]]
  demtarea <- subdata[["demtarea"]]
  demiarea <- subdata[["demiarea"]]
  meanq <- subdata[["meanq"]]
  fnode <- subdata[["fnode"]]
  tnode <- subdata[["tnode"]]
  hydseq <- subdata[["hydseq"]]
  frac <- subdata[["frac"]]
  iftran <- subdata[["iftran"]]
  staid <- subdata[["staid"]]

  # extract from predictScenarios.list
  predmatrix <- predictScenarios.list$predmatrix
  predmatrix_chg <- predictScenarios.list$predmatrix_chg
  yldmatrix <- predictScenarios.list$yldmatrix
  yldmatrix_chg <- predictScenarios.list$yldmatrix_chg
  oparmlist <- predictScenarios.list$oparmlist
  loadunits <- predictScenarios.list$loadunits
  oyieldlist <- predictScenarios.list$oyieldlist
  yieldunits <- predictScenarios.list$yieldunits
  select_scenarioReachAreas <- predictScenarios.list$select_scenarioReachAreas
  select_targetReachWatersheds <- predictScenarios.list$select_targetReachWatersheds
  scenario_sources <- predictScenarios.list$scenario_sources
  scenario_factors <- predictScenarios.list$scenario_factors
  landuseConversion <- predictScenarios.list$landuseConversion
  scenarioCoefficients <- predictScenarios.list$scenarioCoefficients

  # extract from file.output.list
  path_results <- file.output.list$path_results
  run_id <- file.output.list$run_id
  csv_decimalSeparator <- file.output.list$csv_decimalSeparator
  csv_columnSeparator <- file.output.list$csv_columnSeparator

  # test if waterid was renumbered, if so add it to add_vars
  origWaterid <- as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames)
  if (!is.null(waterid_for_RSPARROW_mapping) &&
      unique(unique(waterid_for_RSPARROW_mapping - waterid) != 0) &
      length(unique(unique(waterid_for_RSPARROW_mapping - waterid) != 0)) == 1) {
    add_vars <- c("waterid_for_RSPARROW_mapping", add_vars)
  } else if (!identical(origWaterid, "waterid")) {
    add_vars <- c(origWaterid, add_vars)
  }

  # get user selected additional variables (add_vars)
  add_vars <- c("waterid", add_vars)
  add_vars <- add_vars[!duplicated(add_vars)]
  if (length(na.omit(add_vars)) != 0) {
    for (a in na.omit(add_vars)) {
      if (a != as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames) & a != "waterid_for_RSPARROW_mapping") {
        if (a %in% names(subdata)) {
          if (a == add_vars[1]) { # if a is first add_var
            addSubdataVars <- subdata[, which(names(subdata) %in% c("waterid", a))]
          } else {
            addSubdataVarstemp <- data.frame(temp = subdata[, which(names(subdata) %in% a)])
            names(addSubdataVarstemp) <- a
            addSubdataVars <- cbind(addSubdataVars, addSubdataVarstemp)
          }
        } # if a in subdata
      } else { # a == data1UserNames where sparrowName = waterid |a=="waterid_for_RSPARROW_mapping"
        if (a == "waterid_for_RSPARROW_mapping") {
          tempName <- "originalWaterid"
          tempCol <- "waterid_for_RSPARROW_mapping"
        } else {
          tempName <- as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames)
          tempCol <- "waterid"
        }
        if (a == add_vars[1]) { # if a is first add_var
          addSubdataVars <- data.frame(waterid = subdata[, which(names(subdata) %in% tempCol)])
          addSubdataVars <- data.frame(
            waterid = subdata[, which(names(subdata) %in% tempCol)],
            temp = subdata[, which(names(subdata) %in% tempCol)]
          )
          names(addSubdataVars)[2] <- tempName
        } else {
          addSubdataVarstemp <- data.frame(temp = subdata[, which(names(subdata) %in% tempCol)])
          names(addSubdataVarstemp)[1] <- tempName
          addSubdataVars <- cbind(addSubdataVars, addSubdataVarstemp)
        }
      } # a == data1UserNames where sparrowName = waterid
    } # for a in add_vars
    names(addSubdataVars)[1] <- "waterid"
  }
  addSubdataVars <- subset(addSubdataVars, select = which(!duplicated(names(addSubdataVars))))
  # Output load predictions with changes from load-reduction scenarios
  # prep for output to CSV
  outvars <- predmatrix



  rchname <- subdata$rchname

  predatts <- data.frame(
    waterid, rchname, rchtype, headflag, termflag, demtarea,
    demiarea, meanq, fnode, tnode, hydseq, frac, iftran, staid, scenarioFlag
  )

  outvars2 <- merge(predatts, outvars, by = "waterid", all.y = TRUE, all.x = TRUE)
  if (length(na.omit(add_vars)) != 0) {
    outvars2 <- merge(outvars2, addSubdataVars, by = "waterid", all.x = TRUE, all.y = TRUE)

    # test if origWaterid column is in addsubdataVars, if so reorder columns so that origWaterid is in column 2
    origWaterid <- names(addSubdataVars)[which(names(addSubdataVars) %in% c("originalWaterid", as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames)) &
      names(addSubdataVars) != "waterid")]
    if (length(origWaterid) != 0) {
      outvars2 <- outvars2[, match(c("waterid", origWaterid, names(outvars2)[which(!names(outvars2) %in% c("waterid", origWaterid))]), names(outvars2))]
    }
  } # if add_vars
  outvars2 <- outvars2[with(outvars2, order(outvars2$waterid)), ] # sort by waterid

  fileout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, "_predicts_load_scenario.csv")
  utils::write.csv(outvars2, file = fileout, row.names = FALSE)

  # Output the prediction variable names and units to CSV file
  lunitsOut <- data.frame(oparmlist, loadunits)
  colnames(lunitsOut) <- c("Prediction Metric Name", "Units")
  fileout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, "_predicts_load_scenario_units.csv")
  utils::write.csv(lunitsOut, file = fileout, row.names = FALSE)


  # Output load prediction changes (percent) from load-reduction scenarios
  outvars <- predmatrix_chg

  rchname <- subdata$rchname

  predatts <- data.frame(
    waterid, rchname, rchtype, headflag, termflag, demtarea,
    demiarea, meanq, fnode, tnode, hydseq, frac, iftran, staid, scenarioFlag
  )
  outvars2 <- merge(predatts, outvars, by = "waterid", all.y = TRUE, all.x = TRUE)
  if (length(na.omit(add_vars)) != 0) {
    outvars2 <- merge(outvars2, addSubdataVars, by = "waterid", all.x = TRUE, all.y = TRUE)

    # test if origWaterid column is in addsubdataVars, if so reorder columns so that origWaterid is in column 2
    origWaterid <- names(addSubdataVars)[which(names(addSubdataVars) %in% c("originalWaterid", as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames)) &
      names(addSubdataVars) != "waterid")]
    if (length(origWaterid) != 0) {
      outvars2 <- outvars2[, match(c("waterid", origWaterid, names(outvars2)[which(!names(outvars2) %in% c("waterid", origWaterid))]), names(outvars2))]
    }
  } # if add_vars
  outvars2 <- outvars2[with(outvars2, order(outvars2$waterid)), ] # sort by waterid

  fileout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, "_predicts_loadchg_scenario.csv")
  utils::write.csv(outvars2, file = fileout, row.names = FALSE)


  # Output yield predictions with changes from load-reduction scenarios
  # prep for output to CSV
  outvars <- yldmatrix



  rchname <- subdata$rchname

  predatts <- data.frame(
    waterid, rchname, rchtype, headflag, termflag, demtarea,
    demiarea, meanq, fnode, tnode, hydseq, frac, iftran, staid, scenarioFlag
  )
  outvars2 <- merge(predatts, outvars, by = "waterid", all.y = TRUE, all.x = TRUE)
  if (length(na.omit(add_vars)) != 0) {
    outvars2 <- merge(outvars2, addSubdataVars, by = "waterid", all.x = TRUE, all.y = TRUE)

    # test if origWaterid column is in addsubdataVars, if so reorder columns so that origWaterid is in column 2
    origWaterid <- names(addSubdataVars)[which(names(addSubdataVars) %in% c("originalWaterid", as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames)) &
      names(addSubdataVars) != "waterid")]
    if (length(origWaterid) != 0) {
      outvars2 <- outvars2[, match(c("waterid", origWaterid, names(outvars2)[which(!names(outvars2) %in% c("waterid", origWaterid))]), names(outvars2))]
    }
  } # if add_vars
  outvars2 <- outvars2[with(outvars2, order(outvars2$waterid)), ] # sort by waterid

  fileout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, "_predicts_yield_scenario.csv")
  utils::write.csv(outvars2, file = fileout, row.names = FALSE)

  # Output the prediction variable names and units to CSV file
  yunitsOut <- data.frame(oyieldlist, yieldunits)
  colnames(yunitsOut) <- c("Prediction Metric Name", "Units")
  fileout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, "_predicts_yield_scenario_units.csv")
  utils::write.csv(yunitsOut, file = fileout, row.names = FALSE)

  # Output yield prediction changes (percent) from load-reduction scenarios
  outvars <- yldmatrix_chg



  rchname <- subdata$rchname

  predatts <- data.frame(
    waterid, rchname, rchtype, headflag, termflag, demtarea,
    demiarea, meanq, fnode, tnode, hydseq, frac, iftran, staid, scenarioFlag
  )
  outvars2 <- merge(predatts, outvars, by = "waterid", all.y = TRUE, all.x = TRUE)
  if (length(na.omit(add_vars)) != 0) {
    outvars2 <- merge(outvars2, addSubdataVars, by = "waterid", all.x = TRUE, all.y = TRUE)

    # test if origWaterid column is in addsubdataVars, if so reorder columns so that origWaterid is in column 2
    origWaterid <- names(addSubdataVars)[which(names(addSubdataVars) %in% c("originalWaterid", as.character(data_names[which(data_names$sparrowNames == "waterid"), ]$data1UserNames)) &
      names(addSubdataVars) != "waterid")]
    if (length(origWaterid) != 0) {
      outvars2 <- outvars2[, match(c("waterid", origWaterid, names(outvars2)[which(!names(outvars2) %in% c("waterid", origWaterid))]), names(outvars2))]
    }
  } # if add_vars
  outvars2 <- outvars2[with(outvars2, order(outvars2$waterid)), ] # sort by waterid

  fileout <- paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, "_predicts_yieldchg_scenario.csv")
  fwrite(outvars2,
    file = fileout, row.names = F, append = F, showProgress = FALSE,
    dec = csv_decimalSeparator, sep = csv_columnSeparator, col.names = TRUE, na = "NA"
  )



  # save the modifySubdata routine with a record of the source change settings
  filesList <- c("_modifySubdata.R")
  sapply(filesList, function(x) {
    file.copy(
      paste0(path_results, run_id, x),
      paste0(path_results, .Platform$file.sep, "scenarios", .Platform$file.sep, scenario_name, .Platform$file.sep, scenario_name, "_", run_id, x)
    )
  })
} # end function
