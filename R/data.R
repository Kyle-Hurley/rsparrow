#' Example SPARROW Watershed Network
#'
#' A synthetic 60-reach watershed network for demonstrating the rsparrow
#' package. The network represents a dendritic river system with four
#' headwater sub-branches draining through two tributaries to a single
#' outlet reach.
#'
#' The modelled constituent is total nitrogen (TN). One source variable
#' (agricultural N) and one land-to-water delivery variable (precipitation)
#' are included. Five monitoring sites provide calibration loads.
#'
#' @format A named list with five elements:
#' \describe{
#'   \item{reaches}{Data frame with 60 rows and 19 columns of reach
#'     attributes. Columns include network topology (\code{waterid},
#'     \code{fnode}, \code{tnode}), drainage area (\code{demiarea},
#'     \code{demtarea}), streamflow (\code{meanq}), source and delivery
#'     variables (\code{agN}, \code{ppt}), monitoring data
#'     (\code{depvar}, \code{calsites}, \code{staid}), and spatial
#'     coordinates (\code{lat}, \code{lon}).}
#'   \item{sites}{Data frame with 5 rows: subset of \code{reaches} for the
#'     five monitoring sites (columns \code{waterid}, \code{staid},
#'     \code{depvar}, \code{demtarea}, \code{lat}, \code{lon}).}
#'   \item{parameters}{Data frame in \code{parameters.csv} format with
#'     columns \code{sparrowNames}, \code{description}, \code{parmUnits},
#'     \code{parmInit}, \code{parmMin}, \code{parmMax}, \code{parmType},
#'     \code{parmCorrGroup}. Contains one SOURCE row (\code{agN}) and
#'     one DELIVF row (\code{ppt}).}
#'   \item{design_matrix}{Data frame in \code{design_matrix.csv} format.
#'     Row names are SOURCE parameter names; columns are DELIVF parameter
#'     names. A value of 1 indicates that a source uses the corresponding
#'     delivery variable.}
#'   \item{data_dictionary}{Data frame in \code{dataDictionary.csv} format
#'     with columns \code{varType}, \code{sparrowNames},
#'     \code{data1UserNames}, \code{varunits}, \code{explanation}.
#'     Maps SPARROW variable names to column names in \code{reaches}.}
#' }
#'
#' @details
#' The dataset was generated entirely from synthetic data using
#' \code{data-raw/generate_sparrow_example.R}. No real monitoring data are
#' included. The network topology is a Y-shaped dendritic structure with
#' 4 headwater sub-branches; all reach data values are internally consistent
#' (drainage areas accumulate correctly downstream; streamflow is
#' proportional to total drainage area).
#'
#' To run a full rsparrow model using this dataset, write the control CSV
#' files to a temporary directory and call \code{\link{rsparrow_model}}:
#'
#' ```r
#' td <- file.path(tempdir(), "sparrow_run")
#' dir.create(td, showWarnings = FALSE)
#' write.csv(sparrow_example$reaches,
#'           file.path(td, "data", "data1.csv"),
#'           row.names = FALSE)
#' write.csv(sparrow_example$parameters,
#'           file.path(td, "parameters.csv"), row.names = FALSE)
#' write.csv(sparrow_example$design_matrix,
#'           file.path(td, "design_matrix.csv"), row.names = TRUE)
#' write.csv(sparrow_example$data_dictionary,
#'           file.path(td, "dataDictionary.csv"), row.names = FALSE)
#' ```
#'
#' @source Synthetic data generated for package demonstration purposes.
#'   See \code{data-raw/generate_sparrow_example.R} for the generation
#'   script.
#'
#' @seealso \code{\link{rsparrow_hydseq}}, \code{\link{rsparrow_model}},
#'   \code{\link{read_sparrow_data}}
#'
#' @examples
#' data(sparrow_example)
#' str(sparrow_example$reaches)
#' sparrow_example$sites
#'
#' # Compute hydrological sequence
#' net <- rsparrow_hydseq(sparrow_example$reaches)
#' head(net[order(net$hydseq), c("waterid", "fnode", "tnode", "hydseq")])
"sparrow_example"
