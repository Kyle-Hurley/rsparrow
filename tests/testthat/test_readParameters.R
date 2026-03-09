# `readParameters` reads in the parameters from a csv
test_that("reading in csv works", {
  # Create temp parameters file as input
  input_list <- list(
    sparrowNames = c(
      "FacWW_P", "FacPmine", "ManureP_Seas", "FertP_Seas", "Pmines_v17", "GeolP", "urban_Seas", 
      "logAirTemp", "logPPT", "PrevSurfSoMoi", "PrevET", "PrevEVIMean", "lkfactup", "rchtot", 
      "rchdecay1", "rchdecay2", "rchdecay3", "iresload"
    ),
    description = c(
      "Municipal/industrial point source", "FacPmine", "Livestock manure N", "Fertilizer N use", 
      "Pmines_v17", "GeolP", "Urban lands", "logAirTemp", "logppt", "PrevSurfSoMoi", "PrevET",
      "PrevEVIMean", "lkfactup", "contrchdecay_RRLite", "Small stream decay (mean Q<1.13 m3/s)",
      "Medium stream decay (1.13 m3/s < mean Q < 1.93 m3/s)", 
      "Large stream decay (mean Q > 1.93 m3/s)", "Reservoir decay (areal hydr. Load)"
    ), 
    parmUnits = c(
      "fraction,dimensionless", "", "", "", "", "", "kg/km2/year", "", "", "", "", "", "", "", 
      "days", "days", "days", "m/year"
    ), 
    parmInit = c(3, 0, 1, 0.1, 0.05, 0.05, 40, -1, 1, 0.4, -0.3, 4, 2, 0.8, 0, 0, 0, 100), 
    parmMin = c(
      0L, 0L, 0L, 0L, 0L, 0L, 0L, -10000L, -10000L, -10000L, -10000L, -10000L, -10000L, 0L, 0L, 0L, 
      0L, 0L
    ), 
    parmMax = c(
      10000L, 0L, 0L, 10000L, 10000L, 10000L, 10000L, 10000L, 10000L, 10000L, 10000L, 10000L, 
      10000L, 10000L, 0L, 0L, 0L, 0L
    ), 
    parmType = c(
      "SOURCE", "SOURCE", "SOURCE", "SOURCE", "SOURCE", "SOURCE", "SOURCE", "DELIVF", "DELIVF",
      "DELIVF", "DELIVF", "DELIVF", "DELIVF", "STRM", "STRM", "STRM", "STRM", "RESV"
    ), 
    parmCorrGroup = c(1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 1L, 0L, 0L, 0L, 0L)
    
  )
  testInput <- structure(input_list, class = "data.frame", row.names = c(NA, -18L))
  
  # Write temp file to be read in by `readParmaters`
  run_id <- "testRun"
  path_results <- paste0(tempdir(), .Platform$file.sep, run_id, .Platform$file.sep)
  if (!dir.exists(path_results)) dir.create(path_results)
  saveInputPath <- paste0(path_results, run_id, "_parameters.csv")
  write.csv(testInput, file = saveInputPath, row.names = FALSE)
  
  file.output.list <- list(
    path_results = path_results,
    run_id = run_id,
    csv_decimalSeparator = ".",
    csv_columnSeparator = ","
  )
  
  testOut <- readParameters(
    file.output.list = file.output.list,
    if_estimate = "yes",
    if_estimate_simulation = "yes"
  )
  
  # Delete saved test input
  unlink(path_results, recursive = TRUE)
  
  # Compare results
  load(testthat::test_path("fixtures", "output_readParameters.rda"))
  expect_identical(testOut, betavalues)
})
