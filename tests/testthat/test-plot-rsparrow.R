test_that("plot.rsparrow exists and is registered as an S3 method", {
  expect_true("plot.rsparrow" %in% as.character(methods("plot")))
})

test_that("plot.rsparrow stops with informative error for invalid type", {
  mod <- make_mock_rsparrow()
  expect_error(
    plot(mod, type = "invalid_type"),
    regexp = "residuals|sensitivity|spatial"
  )
})

test_that("plot.rsparrow default type 'residuals' does not produce invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "residuals"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow accepts type='sensitivity' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "sensitivity"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow accepts type='spatial' without invalid-type error", {
  mod <- make_mock_rsparrow()
  err <- tryCatch(plot(mod, type = "spatial"), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("should be one of|invalid|type", conditionMessage(err),
                       ignore.case = TRUE))
  }
})

test_that("plot.rsparrow ... are forwarded (not consumed at dispatch level)", {
  mod <- make_mock_rsparrow()
  # unknown_arg should not cause an "unused argument" error at dispatch level;
  # any error should come from the downstream diagnostic function
  err <- tryCatch(plot(mod, type = "residuals", unknown_arg = TRUE), error = function(e) e)
  if (!is.null(err)) {
    expect_false(grepl("unused argument.*unknown_arg", conditionMessage(err)))
  }
})
