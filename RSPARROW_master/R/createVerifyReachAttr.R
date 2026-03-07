#' @title createVerifyReachAttr
#' @description Calculates REQUIRED system reach attributes for reaches with `fnode>0`,
#'            `tnode>0` and `termflag!=3`from `calculate_reach_attribute_list` control setting and verifies
#'            `demtarea` if `if_verify_demtarea<-"yes"` \cr \cr
#' Executed By: dataInputPrep.R \cr
#' Executes Routines: \itemize{\item accumulateIncrArea.R
#'             \item calcHeadflag.R
#'             \item calcTermflag.R
#'             \item hydseq.R
#'             \item verifyDemtarea.R} \cr
#' @param if_verify_demtarea specify whether or not to verify demtarea
#' @param calculate_reach_attribute_list list of attributes to calculate
#' @param data1 input data (data1)
#' @param file.output.list list of control settings and relative paths used for input and
#'                        output of external files.  Created by `generateInputList.R`
#' @param mapping.input.list Named list of sparrow_control settings for mapping: lat_limit,
#'                          lon_limit, master_map_list, lineShapeName, lineWaterid,
#'                          polyShapeName, ployWaterid, LineShapeGeo, LineShapeGeo, CRStext,
#'                          convertShapeToBinary.list, map_siteAttributes.list,
#'                          residual_map_breakpoints, site_mapPointScale,
#'                          if_verify_demtarea_maps
#' @return `data1`  data.frame from user input `data1` file with calculated reach
#' attributes replaced
#' @keywords internal
#' @noRd



createVerifyReachAttr <- function(if_verify_demtarea, calculate_reach_attribute_list, data1,
                                  file.output.list, mapping.input.list) {

  # Select reaches to be included in the analysis (exclude coastal shorelines)
  # NAs removed first or will create NA records in 'sub1'
  for (c in c("termflag", "fnode", "tnode", "demiarea", "demtarea")) {
    data1[[c]] <- ifelse(is.na(data1[[c]]), 0, data1[[c]])
  }

  sub1 <- data1[(data1$fnode > 0 & data1$tnode > 0 & data1$termflag != 3), ]

  if (!identical(calculate_reach_attribute_list, NA)) {
    if (nrow(sub1) == 0) {
      cat("\n \n")
      message(paste0("HYDSEQ VARIABLE CANNOT BE CALCULATED\n DATASET WITH FNODE>0, TNODE>0 and TERMFLAG!=0 IS EMPTY\nRUN EXECUTION TERMINATED."))
      # stop execution
      stop("Error in createVerifyReachAttr.R. Run execution terminated.")
    } else {
      nreach <- length(sub1$waterid)


      # calculate reach attributes if on the list
      if (length(grep("hydseq", calculate_reach_attribute_list)) != 0) {
        message("Running calculation of HYDSEQ (hydrologic sequencing numbers)...")
        # calculate hydseq variable, also headflag and demtarea if called for
        if (checkDynamic(sub1)) {
          if (length(names(sub1)[names(sub1) == "year"]) != 0) {
            if (all(is.na(sub1$year))) {
              # loop through seasons
              hydseq_data <- sub1[0, ]
              for (s in unique(sub1$season)[match(c("winter", "spring", "summer", "fall"), unique(sub1$season))]) {
                data1_sub <- sub1[sub1$season == s, ]
                if (nrow(data1_sub) != 0) {
                  startSeq <- nrow(hydseq_data) + 1
                  hydseq_datasub <- hydseq(data1_sub, calculate_reach_attribute_list, startSeq)
                  hydseq_data <- rbind(hydseq_data, hydseq_datasub)
                }
              }
            } else if (length(names(sub1)[names(sub1) == "season"]) == 0 | all(is.na(sub1$season))) {
              # loop through year
              hydseq_data <- sub1[0, ]
              for (y in sort(unique(sub1$year))) {
                data1_sub <- sub1[sub1$year == y, ]
                if (nrow(data1_sub) != 0) {
                  startSeq <- nrow(hydseq_data) + 1
                  hydseq_datasub <- hydseq(data1_sub, calculate_reach_attribute_list, startSeq)
                  hydseq_data <- rbind(hydseq_data, hydseq_datasub)
                }
              }
            } else if (length(names(sub1)[names(sub1) == "season"]) != 0) {
              if (!all(is.na(sub1$season))) { # loop through season and year
                hydseq_data <- sub1[0, ]
                for (y in sort(unique(sub1$year))) {
                  for (s in unique(sub1$season)[match(c("winter", "spring", "summer", "fall"), unique(sub1$season))]) {
                    data1_sub <- sub1[sub1$year == y & sub1$season == s, ]
                    if (nrow(data1_sub) != 0) {
                      startSeq <- nrow(hydseq_data) + 1
                      hydseq_datasub <- hydseq(data1_sub, calculate_reach_attribute_list, startSeq)
                      hydseq_data <- rbind(hydseq_data, hydseq_datasub)
                    }
                  } # end for s
                } # end for y
              } # end for !all(is.na(seasons))
            } # names seasons
          } else { # no year in names
            if (length(names(sub1)[names(sub1) == "season"]) != 0) {
              if (!all(is.na(sub1$season))) { # loop through season
                # loop through seasons
                hydseq_data <- sub1[0, ]
                for (s in unique(sub1$season)[match(c("winter", "spring", "summer", "fall"), unique(sub1$season))]) {
                  data1_sub <- sub1[sub1$season == s, ]
                  if (nrow(data1_sub) != 0) {
                    startSeq <- nrow(hydseq_data) + 1
                    hydseq_datasub <- hydseq(data1_sub, calculate_reach_attribute_list, startSeq)
                    hydseq_data <- rbind(hydseq_data, hydseq_datasub)
                  }
                }
              }
            }
          } # no year in names
        } else {
          hydseq_data <- hydseq(sub1, calculate_reach_attribute_list)
        }


        waterid <- hydseq_data$waterid
        hydseq <- hydseq_data$hydseq
        headflag <- hydseq_data$headflag
        demtarea <- hydseq_data$demtarea
      } else if (length(grep("demtarea", calculate_reach_attribute_list)) != 0) {
        waterid <- sub1$waterid
        hydseq <- sub1$hydseq

        # calculate headflag if called for
        if (length(grep("headflag", calculate_reach_attribute_list)) != 0) {
          headflag_new <- calcHeadflag(sub1)
          headflag_new <- headflag_new[match(sub1$waterid, headflag_new$waterid), ]
          headflag <- headflag_new$headflag
        } else {
          headflag <- sub1$headflag
        }



        # calculate demtarea
        demtarea_new <- accumulateIncrArea(sub1, c("demiarea"), c("demtarea"))
        demtarea_new <- demtarea_new[match(sub1$waterid, demtarea_new$waterid), ]
        demtarea <- demtarea_new$demtarea
      } else if (length(grep("headflag", calculate_reach_attribute_list)) != 0) {
        waterid <- sub1$waterid
        hydseq <- sub1$hydseq
        demtarea <- sub1$demtarea

        # calculate headflag
        headflag_new <- calcHeadflag(sub1)
        headflag_new <- headflag_new[match(sub1$waterid, headflag_new$waterid), ]
        headflag <- headflag_new$headflag
      } else if (length(grep("termflag", calculate_reach_attribute_list)) != 0) {
        waterid <- sub1$waterid
        hydseq <- sub1$hydseq
        demtarea <- sub1$demtarea
      }

      # verifyDemtarea
      compareData <- data.frame(
        waterid = waterid,
        hydseq = hydseq,
        headflag = headflag,
        demtarea = demtarea
      )

      verifyDemtarea(
        if_verify_demtarea, sub1, compareData,
        # for checkDrainageErrors
        file.output.list, mapping.input.list
      )

      # replace reach attributes
      # remove attributes from data1
      drops <- calculate_reach_attribute_list
      data1 <- data1[, !(names(data1) %in% drops)]

      # add attributes to data1
      for (i in 1:length(calculate_reach_attribute_list)) {
        attr_name <- calculate_reach_attribute_list[i]
        hs_data <- data.frame(waterid = waterid, val = get(attr_name))
        names(hs_data)[2] <- attr_name
        hs_data <- hs_data[hs_data$waterid != 0, ] # eliminate 0 cases where vector dimension max > no. reaches
        data1 <- merge(data1, hs_data, by = "waterid", all.y = TRUE, all.x = TRUE)
      }
    } # if no error
  } else { # if no calc_reach_attr
    if (if_verify_demtarea == "yes") {
      waterid <- sub1$waterid
      hydseq <- sub1$hydseq
      headflag <- sub1$headflag

      # calculate demtarea
      demtarea_new <- accumulateIncrArea(sub1, c("demiarea"), c("demtarea"))
      demtarea_new <- demtarea_new[match(sub1$waterid, demtarea_new$waterid), ]
      demtarea <- demtarea_new$demtarea

      # verifyDemtarea
      compareData <- data.frame(
        waterid = waterid,
        hydseq = hydseq,
        headflag = headflag,
        demtarea = demtarea
      )

      verifyDemtarea(
        if_verify_demtarea, sub1, compareData,
        # for checkDrainageErrors
        file.output.list, mapping.input.list
      )
    } # end if_verify_demtarea
  } # end if no calc reach attr

  return(data1)
} # end function
