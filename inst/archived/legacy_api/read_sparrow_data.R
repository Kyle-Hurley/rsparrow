# Archived in Plan 13: replaced by in-memory API (rsparrow_model() data-frame arguments)
#' Read and Validate SPARROW Input Data
#'
#' Reads SPARROW input data from CSV control files and returns the raw data
#' objects needed for model fitting. This separates data I/O from model
#' estimation, enabling programmatic data inspection before fitting.
#'
#' @param path_main Character. Path to the main project directory containing
#'   control files (parameters.csv, design_matrix.csv, dataDictionary.csv).
#' @param run_id Character. Name of the model run (default: "run1"). Used to
#'   name output files and subdirectories under the results directory.
#' @param data_file Character. Name of the input data CSV file (default:
#'   "data1.csv"). Looked for first in \code{path_main/data/}, then directly
#'   in \code{path_main}.
#' @param csv_decimalSeparator Character. Decimal separator used in CSV files
#'   (default: ".").
#' @param csv_columnSeparator Character. Column separator used in CSV files
#'   (default: ",").
#'
#' @return A list with components:
#'   \describe{
#'     \item{file.output.list}{Named list of paths and settings used by
#'       internal SPARROW functions.}
#'     \item{data1}{Data.frame of raw reach network data read from
#'       \code{data_file}.}
#'     \item{data_names}{Data.frame of variable metadata from
#'       dataDictionary.csv (columns: varType, sparrowNames, data1UserNames,
#'       varunits, explanation).}
#'   }
#'
#' @seealso \code{\link{rsparrow_model}}, \code{\link{rsparrow_hydseq}}
#'
#' @examples
#' \donttest{
#' td <- tempdir()
#' write.csv(sparrow_example$data_dictionary,
#'           file.path(td, "dataDictionary.csv"), row.names = FALSE)
#' write.csv(sparrow_example$parameters,
#'           file.path(td, "parameters.csv"), row.names = FALSE)
#' write.csv(sparrow_example$design_matrix,
#'           file.path(td, "design_matrix.csv"), row.names = FALSE)
#' reaches <- rsparrow_hydseq(sparrow_example$reaches)
#' write.csv(reaches, file.path(td, "data1.csv"), row.names = FALSE)
#' sparrow_data <- read_sparrow_data(td, run_id = "ex")
#' names(sparrow_data)       # "file.output.list" "data1" "data_names"
#' nrow(sparrow_data$data1)  # 60 reaches
#' }
read_sparrow_data <- function(path_main, run_id = "run1",
                               data_file = "data1.csv",
                               csv_decimalSeparator = ".",
                               csv_columnSeparator = ",") {
  # 1. Validate path_main
  if (!dir.exists(path_main))
    stop("path_main does not exist: ", path_main)

  # 2. Check for required control files in path_main
  required_files <- c("parameters.csv", "design_matrix.csv", "dataDictionary.csv")
  missing_files <- required_files[
    !file.exists(file.path(path_main, required_files))
  ]
  if (length(missing_files) > 0)
    stop("Missing required control files: ",
         paste(missing_files, collapse = ", "),
         "\n  Expected in: ", path_main)

  # 3. Create run-specific results directory.
  #    path_results must end with file separator because internal functions
  #    construct filenames as paste0(path_results, run_id, "_foo.csv").
  path_results <- paste0(file.path(path_main, "results", run_id),
                         .Platform$file.sep)
  dir.create(path_results, recursive = TRUE, showWarnings = FALSE)

  # Copy control files into results dir with run_id prefix so that
  # readParameters(), readDesignMatrix(), and read_dataDictionary() can find
  # them at paste0(path_results, run_id, "_<file>.csv").
  for (ctlfile in c("dataDictionary.csv", "parameters.csv", "design_matrix.csv")) {
    file.copy(
      file.path(path_main, ctlfile),
      paste0(path_results, run_id, "_", ctlfile),
      overwrite = TRUE
    )
  }

  # 4. Locate data file: look in path_main/data/ first, then path_main/.
  #    path_data must end with file separator (readData uses paste0(path_data, filename)).
  path_data_sub <- file.path(path_main, "data")
  if (file.exists(file.path(path_data_sub, data_file))) {
    path_data <- paste0(path_data_sub, .Platform$file.sep)
  } else if (file.exists(file.path(path_main, data_file))) {
    path_data <- paste0(path_main, .Platform$file.sep)
  } else {
    stop("Data file '", data_file, "' not found.\n",
         "  Looked in: ", path_data_sub, "\n",
         "  Looked in: ", path_main)
  }

  # 5. Build file.output.list with all fields required by the internal functions:
  #    read_dataDictionary() needs: path_results, run_id, add_vars,
  #                                 csv_decimalSeparator, csv_columnSeparator
  #    readData()            needs: path_data, csv_decimalSeparator,
  #                                 csv_columnSeparator
  file.output.list <- list(
    path_main            = path_main,
    run_id               = run_id,
    path_results         = path_results,
    path_data            = path_data,
    add_vars             = NA,
    csv_decimalSeparator = csv_decimalSeparator,
    csv_columnSeparator  = csv_columnSeparator
  )

  # 6. Read variable metadata from dataDictionary.csv
  data_names <- read_dataDictionary(file.output.list)

  # 7. Read reach network data
  data1 <- readData(file.output.list, data_file)

  # 8. Return named list consumed by rsparrow_model() / startModelRun()
  list(
    file.output.list = file.output.list,
    data1            = data1,
    data_names       = data_names
  )
}
