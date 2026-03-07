test_that("matrix of model parameters creation works", {
  # Load output of `readParmeters`, `selectParmValues`, and `readDesignMatrix` tests
  # betavalues
  load(testthat::test_path("fixtures", "output_readParameters.rda"))
  # selParmValues
  load(testthat::test_path("fixtures", "output_selectParmValues.rda"))
  # dmatrixin
  load(testthat::test_path("fixtures", "output_readDesignMatrix.rda"))
  
  # Run function
  testOut <- selectDesignMatrix(SelParmValues, betavalues, dmatrixin)
  
  # Compare results
  load(testthat::test_path("fixtures", "output_selectDesignMatrix.rda"))
  expect_identical(testOut, dlvdsgn)
})