#' @title checkData1NavigationVars
#' @description Checks for excessively large integer values (maximum>1M) for the sparrowNames
#'            `waterid`, `tnode`, `fnode`, `hydseq` to avoid array storage problems in R and Fortran
#'            subroutines. Exceedence of the threshold causes a renumbering of the 'waterid' and node numbers. \cr \cr
#' Executed By: dataInputPrep.R \cr
#' Executes Routines: (none) \cr
#' @param data1 input data (data1)
#' @param if_reverse_hydseq yes/no indicating whether hydseq in the DATA1 file needs to be
#'       reversed from sparrow_control
#' @return `data1`  data1 input file as data.frame with large integer values replaced for
#'                 reach navigation variables `waterid`, `tnode`, `fnode`, `hydseq`
#' @keywords internal
#' @noRd



checkData1NavigationVars <- function(data1, if_reverse_hydseq) {
  # check for all missing or all 0 fnode, tnode, or termflag
  for (v in c("fnode", "tnode", "termflag")) {
    var <- data1[[v]]
    var <- ifelse(is.na(var), 0, var)
    var <- all(var == 0)
    if (var) {
      # all missing terminate

      cat("\n \n")
      message(paste0(
        "THE FOLLOWING REQUIRED VARIABLE HAS ALL ZERO OR MISSING VALUES\n",
        v, "\nRSPARROW UNABLE TO COMPLETE CHECK OF NETWORK NAVIGATION. IF termflag IS ZERO OR MISSING,",
        "\nTHEN TERMINAL REACHES MUST BE IDENTIFIED (SET VALUES TO 1) IN THE INPUT data1.csv FILE.",
        "\nRUN EXECUTION TERMINATED."
      ))

      stop("Error in checkData1NavigationVars.R. Run execution terminated.")
    }
  }


  intVars <- c("waterid", "hydseq", "fnode", "tnode")

  for (v in intVars) {
    if (v == "waterid") {
      if (max(data1$waterid, na.rm = TRUE) > 1.0e+6) { # renumber WATERID and store original as a character variable
        data1$waterid <- seq(1:length(data1$waterid))
      }
    } else { # not water id
      # NAs set to zero
      var <- data1[[v]]
      var[is.na(var)] <- 0

      # check if hydseq should be reversed
      if (v == "hydseq" & if_reverse_hydseq == "yes") {
        var <- var * -1
      }
      # assign to data1
      data1[[v]] <- var

      if (v == "fnode") { # create vector of fnode,tnode and remove duplicates
        var <- c(data1$fnode, data1$tnode)
        var <- var[which(!duplicated(var))]
      }

      if (max(var, na.rm = TRUE) > 1.0e+6 & v == "hydseq") { # large integer problem for hydseq
        long <- data1[[v]]
        waterid <- data1$waterid

        DF <- data.frame(waterid, long, var)
        DF <- DF[with(DF, order(DF$var)), ]
        DF$var <- seq(1:length(data1$waterid)) # assign new hydseq based on hydrologically ordered file
        names(DF) <- c("waterid", paste0(v, "_long"), v)

        data1 <- data1[, !names(data1) %in% v, drop = F]
        data1 <- merge(data1, DF, by = "waterid", all.y = FALSE, all.x = TRUE) # merge new hydseq to data1
      } else if (max(var, na.rm = TRUE) > 1.0e+6 & v == "fnode") { # large integer for fnode/tnode
        DF <- data.frame(var_long = var) # save original values for merge to data1
        DF$var <- seq(1:nrow(DF)) # create new sequence
        for (node in c("fnode", "tnode")) { # merge to data1
          names(DF) <- c(paste0(node, "_long"), node)
          names(data1)[which(names(data1) == node)] <- paste0(node, "_long")
          data1 <- merge(data1, DF, by = paste0(node, "_long"), all.y = FALSE, all.x = TRUE) # merge new fnode/tnode to data1
        }
      }
    } # not waterid
  }





  return(data1)
} # end function
