test_that("print.rsparrow returns invisibly without error", {
  mod <- make_mock_rsparrow()
  result <- withVisible(print(mod))
  expect_false(result$visible)
  expect_identical(result$value, mod)
})

test_that("print.rsparrow output contains coefficient names", {
  mod <- make_mock_rsparrow()
  output <- capture.output(print(mod))
  expect_true(any(grepl("beta_s1", output)))
})

test_that("summary.rsparrow returns a summary.rsparrow object", {
  mod <- make_mock_rsparrow()
  s <- summary(mod)
  expect_true(inherits(s, "summary.rsparrow"))
})

test_that("summary.rsparrow contains model statistics in printed output", {
  mod <- make_mock_rsparrow()
  s <- summary(mod)
  output <- capture.output(print(s))
  expect_true(any(grepl("R-squared|R2|RMSE", output, ignore.case = TRUE)))
})

test_that("coef.rsparrow returns named numeric vector", {
  mod <- make_mock_rsparrow()
  result <- coef(mod)
  expect_true(is.numeric(result))
  expect_false(is.null(names(result)))
  expect_identical(result, mod$coefficients)
})

test_that("coef.rsparrow coefficient names match Parmnames", {
  mod <- make_mock_rsparrow()
  result <- coef(mod)
  expect_identical(names(result), c("beta_s1", "beta_d1", "beta_k1"))
})

test_that("residuals.rsparrow returns numeric vector", {
  mod <- make_mock_rsparrow()
  result <- residuals(mod)
  expect_true(is.numeric(result))
  expect_true(length(result) >= 1L)
})

test_that("vcov.rsparrow returns NULL when no Hessian computed", {
  mod <- make_mock_rsparrow()
  result <- vcov(mod)
  expect_null(result)
})

test_that("vcov.rsparrow returns matrix when Hessian available", {
  mod <- make_mock_rsparrow()
  n <- length(mod$coefficients)
  mod$vcov <- diag(n)
  result <- vcov(mod)
  expect_true(is.matrix(result))
  expect_equal(nrow(result), n)
  expect_equal(ncol(result), n)
})

test_that("print.rsparrow does not modify the object", {
  mod <- make_mock_rsparrow()
  before <- mod$coefficients
  capture.output(print(mod))
  expect_identical(mod$coefficients, before)
})

test_that("S3 dispatch is correct — methods are registered for rsparrow class", {
  # Check that S3 methods are registered and dispatch correctly
  expect_true("print.rsparrow"     %in% as.character(methods("print")))
  expect_true("summary.rsparrow"   %in% as.character(methods("summary")))
  expect_true("coef.rsparrow"      %in% as.character(methods("coef")))
  expect_true("residuals.rsparrow" %in% as.character(methods("residuals")))
  expect_true("vcov.rsparrow"      %in% as.character(methods("vcov")))
})
