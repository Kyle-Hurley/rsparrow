#' @title createSubdataSorted
#' @description Creates a subset of `data1`, called `subdata`, sorted by `hydseq` , based on
#'            the application of the control setting 'filter_data1_conditions'. The 'subdata' object is used in
#'            model estimation, prediction, mapping, and other functions.  \cr \cr
#' Executed By: startModelRun.R \cr
#' @param filter_data1_conditions User specified additional DATA1 variables (and conditions) to
#'       be used to filter reaches from sparrow_control
#' @param data1 input data (data1)
#' @return `subdata`  data.frame used in model execution based on `data1` with
#' `filter_data1_conditions` applied and tnode>0 and fnode>0.
#' @keywords internal
#' @noRd



createSubdataSorted <- function(filter_data1_conditions, data1) {
  data1$fnode[is.na(data1$fnode)] <- 0
  data1$tnode[is.na(data1$tnode)] <- 0

  base_mask <- data1$fnode > 0 & data1$tnode > 0

  if (identical(filter_data1_conditions, NA)) {
    subdata <- data1[base_mask, ]
  } else {
    # filter_data1_conditions are user-supplied expression strings from sparrow_control.
    # This eval() is intentional — necessary for user-supplied filter expressions.
    # Hardened with tryCatch for informative errors (Plan 05C).
    filter_expr <- paste0("base_mask & ", paste(filter_data1_conditions, collapse = " & "))
    subdata <- tryCatch(
      data1[eval(parse(text = filter_expr)), ],
      error = function(e) stop(paste0(
        "Invalid filter_data1_conditions: '",
        paste(filter_data1_conditions, collapse = " & "),
        "'. Error: ", conditionMessage(e)
      ))
    )
  }

  # Sort SUBDATA by HYDSEQ
  subdata <- subdata[with(subdata, order(subdata$hydseq)), ] # removed secondary sort by waterid (1-8-2017)



  return(subdata)
} # end function
