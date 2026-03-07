# True dynamic tests
test_that("yearly and seasonal df is dynamic", {
  testDf <- data.frame(
    waterid = c(1, 2, 3), 
    year = rep(2001, 3), 
    season = c("spring", "winter", "fall")
  )
  expect_true(checkDynamic(testDf))
})

test_that("yearly df is dynamic", {
  testDf <- data.frame(
    waterid = c(1, 2, 3), 
    year = rep(2001, 3)
  )
  expect_true(checkDynamic(testDf))
})

test_that("seasonal df is dynamic", {
  testDf <- data.frame(
    waterid = c(1, 2, 3),
    season = c("spring", "winter", "fall")
  )
  expect_true(checkDynamic(testDf))
})

test_that("seasonal with NA year df is dynamic", {
  testDf <- data.frame(
    waterid = c(1, 2, 3),
    year = rep(NA, 3),
    season = c("spring", "winter", "fall")
  )
  expect_true(checkDynamic(testDf))
})


# False dynamic tests
test_that("no seasons and years df is static", {
  testDf <- data.frame(waterid = c(1, 2, 3))
  expect_false(checkDynamic(testDf))
})

test_that("all NA seasons and years df is static", {
  testDf <- data.frame(
    waterid = c(1, 2, 3),
    year = rep(NA, 3),
    season = rep(NA, 3)
  )
  expect_false(checkDynamic(testDf))
})

test_that("NA years df is static", {
  testDf <- data.frame(
    waterid = c(1, 2, 3), 
    year = rep(NA, 3)
  )
  expect_false(checkDynamic(testDf))
})

test_that("NA seasons df is static", {
  testDf <- data.frame(
    waterid = c(1, 2, 3), 
    season = rep(NA, 3)
  )
  expect_false(checkDynamic(testDf))
})
