test_that("Subdata matches expected", {
  # Load input of `createSubdataSorted` test
  # testdata1
  load(testthat::test_path("fixtures", "input_createSubdataSorted.rda"))
  
  # Set filter conditions
  filter_data1_conditions <-
    c("data1$year %in% c(2001,2002)", "data1$season=='spring'")
  
  # Run function
  testOut <- createSubdataSorted(filter_data1_conditions, testData1)
  
  # Compare results
  # Expected result
  out_list <- list(
    fnode = c(1934, 10748),
    tnode = c(1935, 149228),
    hydseq = c(1981L, 11015L),
    year = 2001:2002,
    season = c("spring", "spring")
  )
  expectOut <- structure(out_list, row.names = c(4L, 7L), class = "data.frame")
  
  expect_identical(testOut, expectOut)
})