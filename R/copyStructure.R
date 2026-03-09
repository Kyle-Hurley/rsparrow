#' @title copyStructure
#' 
#' @description 
#' Creates a new nested list structure with the same names and depth as a 
#' reference list up to a specified depth.
#' 
#' Executed By: diagnosticPlotsNLLS.R
#' 
#' 
#' 
#' @param ref_list A nested list whose structure is to be copied.
#' @param depth An integer specifying the depth to which the structure should be copied. If 
#' `depth` is less than or equal to 0, or if `ref_list` is not a list, the function returns `NULL`.
#' 
#' @return A nested list with the same structure and names as `ref_list`, up to the specified 
#' `depth`.
#' 
#' @examples
#' # Create a sample nested list
#' sample_list <- list(
#'   "level1a" = list(
#'     "level2a" = list(
#'       "level3a" = 1,
#'       "level3b" = 2
#'     ),
#'     "level2b" = list(
#'       "level3c" = 3,
#'       "level3d" = 4
#'     )
#'   ),
#'   "level1b" = list(
#'     "level2c" = list(
#'       "level3e" = 5
#'     )
#'   )
#' )
#' 
#' # Copy the structure of sample_list up to depth 2
#' copied_structure <- copyStructure(sample_list, 2)
#' str(sample_list)
#' str(copied_structure)
#' 
#' # Copy the structure of sample_list up to depth 3
#' copied_structure <- copyStructure(sample_list, 3)
#' str(sample_list)
#' str(copied_structure)
#' @keywords internal
#' @noRd

copyStructure <- function(ref_list, depth) {
  if (depth <= 0 || !is.list(ref_list)) {
    return(NULL)  # Stop recursion and return NULL or any default value
  }
  
  new_list <- vector("list", length(ref_list))
  names(new_list) <- names(ref_list)
  
  if (depth > 1) {
    for (i in seq_along(ref_list)) {
      new_list[[i]] <- Recall(ref_list = ref_list[[i]], depth = depth - 1)
    }
  }
  
  return(new_list)
}
