#' Compute Hydrological Sequence for Stream Network
#'
#' Orders stream reaches from upstream to downstream based on network topology.
#' This is a key preprocessing step for SPARROW models, ensuring that load
#' accumulation occurs in the correct hydrological order.
#'
#' The algorithm assigns sequential numbers starting from terminal (outlet)
#' reaches and working upstream. Reaches are numbered so that downstream
#' reaches have lower sequence numbers (more negative values), ensuring
#' correct accumulation order when sorted.
#'
#' @param data A data.frame containing reach network topology. Must include
#'   columns for upstream node IDs, downstream node IDs, and a reach
#'   identifier named \code{waterid}.
#' @param from_col Character. Name of column containing upstream (from) node
#'   IDs (default: "fnode").
#' @param to_col Character. Name of column containing downstream (to) node
#'   IDs (default: "tnode").
#'
#' @return The input data.frame with a \code{hydseq} column appended. Values
#'   are negative integers where more negative = further downstream. Headwater
#'   reaches have the largest (least negative) values.
#'
#' @export
#'
#' @seealso \code{\link{rsparrow_model}}
#'
#' @examples
#' # Order the example network reaches from upstream to downstream
#' reaches <- rsparrow_hydseq(sparrow_example$reaches)
#' head(reaches[order(reaches$hydseq), c("waterid", "fnode", "tnode", "hydseq")])
rsparrow_hydseq <- function(data, from_col = "fnode", to_col = "tnode") {
  stopifnot(is.data.frame(data))
  stopifnot(from_col %in% names(data))
  stopifnot(to_col %in% names(data))
  stopifnot("waterid" %in% names(data))

  # hydseq() expects columns named fnode/tnode; rename if needed
  orig_names <- names(data)
  if (from_col != "fnode") names(data)[names(data) == from_col] <- "fnode"
  if (to_col != "tnode") names(data)[names(data) == to_col] <- "tnode"

  result <- hydseq(data, calculate_reach_attribute_list = c("hydseq"))

  # Restore original column names (except hydseq which is new)
  if (from_col != "fnode") names(result)[names(result) == "fnode"] <- from_col
  if (to_col != "tnode") names(result)[names(result) == "tnode"] <- to_col

  result
}
