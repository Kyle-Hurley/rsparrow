# `readDesignMatrix` reads in the design_matrix from a csv
test_that("reading in csv works", {
  # Create temp parameters file as input
  input_list <- list(
    sparrowNames = c(
      "FacWW_P", "Pmines_v17", "urban_Seas", "FertP_Seas", "ManureP_Seas", "GeolP", "FacPmine"
    ),
    logPPT = c(0L, 0L, 1L, 1L, 1L, 1L, 1L),
    logAirTemp = c(0L, 0L, 1L, 1L, 1L, 1L, 1L),
    PrevSurfSoMoi = c(0L, 0L, 1L, 1L, 1L, 1L, 1L),
    PrevET = c(0L, 0L, 1L, 1L, 1L, 1L, 1L),
    PrevEVIMean = c(0L, 0L, 1L, 1L, 1L, 1L, 1L),
    lkfactup = c(0L, 0L, 1L, 1L, 1L, 1L, 1L)
  )
  testInput <- structure(input_list, class = "data.frame", row.names = c(NA, -7L))
  
  # Write to temp file to be read by `readDesignMatrix`
  run_id <- "testRun"
  path_results <- paste0(tempdir(), .Platform$file.sep, run_id, .Platform$file.sep)
  if (!dir.exists(path_results)) dir.create(path_results)
  saveInputPath <- paste0(path_results, run_id, "_design_matrix.csv")
  write.csv(testInput, file = saveInputPath, row.names = FALSE)
  
  file.output.list <- list(
    path_results = path_results,
    run_id = run_id,
    csv_decimalSeparator = ".",
    csv_columnSeparator = ","
  )
  
  # Load test parameters
  load(testthat::test_path("fixtures", "output_readParameters.rda"))
  
  # Run readDesignMatrix
  testOut <- readDesignMatrix(file.output.list, betavalues)
  
  # Delete saved test input
  unlink(path_results, recursive = TRUE)
  
  # Compare results
  load(testthat::test_path("fixtures", "output_readDesignMatrix.rda"))
  expect_identical(testOut, dmatrixin)
})
