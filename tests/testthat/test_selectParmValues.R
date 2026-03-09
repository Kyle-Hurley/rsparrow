test_that("creating parameter data list works", {
  # Load output of `readParmeters` test
  load(testthat::test_path("fixtures", "output_readParameters.rda"))
  
  # Run function
  testOut <- selectParmValues(
    betavalues,
    if_estimate = "yes",
    if_estimate_simulation = "yes"
  )
  
  # Compare results
  load(testthat::test_path("fixtures", "output_selectParmValues.rda"))
  expect_identical(testOut, SelParmValues)
})