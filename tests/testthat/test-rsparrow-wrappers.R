test_that("rsparrow_bootstrap has correct formal arguments", {
  args <- names(formals(rsparrow_bootstrap))
  expect_true("object" %in% args)
  expect_true("n_boot" %in% args)
  expect_true("seed" %in% args)
})

test_that("rsparrow_bootstrap stops with informative error for non-rsparrow input", {
  expect_error(
    rsparrow_bootstrap(list()),
    regexp = "rsparrow|class"
  )
})

test_that("rsparrow_bootstrap reproducibility contract (skipped — requires fitted model)", {
  skip("reproducibility test requires fitted model — covered in integration tests")
})

test_that("rsparrow_validate has correct formal arguments", {
  args <- names(formals(rsparrow_validate))
  expect_true("object" %in% args)
})

test_that("rsparrow_validate stops with informative error for non-rsparrow input", {
  expect_error(
    rsparrow_validate(list()),
    regexp = "rsparrow|class"
  )
})

test_that("rsparrow_validate stops with informative error when model has no validation sites", {
  mod <- make_mock_rsparrow()  # mock has Vsites.list = NULL
  err <- tryCatch(rsparrow_validate(mod), error = function(e) e)
  expect_true(!is.null(err))
  expect_true(grepl("validat|Vsites|if_validate", conditionMessage(err), ignore.case = TRUE))
})

test_that("rsparrow_scenario has correct formal arguments", {
  args <- names(formals(rsparrow_scenario))
  expect_true("object" %in% args)
  expect_true("source_changes" %in% args)
})

test_that("rsparrow_scenario stops with informative error for non-rsparrow input", {
  expect_error(
    rsparrow_scenario(list(), source_changes = list()),
    regexp = "rsparrow|class"
  )
})

test_that("rsparrow_model has correct formal arguments", {
  args <- names(formals(rsparrow_model))
  expect_true("path_main"    %in% args)
  expect_true("run_id"       %in% args)
  expect_true("if_estimate"  %in% args)
  expect_true("if_predict"   %in% args)
  expect_true("if_validate"  %in% args)
  expect_false("model_type"  %in% args)
})

test_that("rsparrow_model stops with clear error for non-existent path_main", {
  expect_error(
    rsparrow_model("/nonexistent/path/xyz"),
    regexp = "exist|path_main"
  )
})

test_that("rsparrow_model stops with clear error for missing control files", {
  td <- tempdir()
  expect_error(
    rsparrow_model(td),
    regexp = "exist|path_main|control|file|sparrow"
  )
})
