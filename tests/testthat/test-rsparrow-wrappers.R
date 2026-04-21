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

test_that("rsparrow_model has correct formal arguments (Plan 13 in-memory API)", {
  args <- names(formals(rsparrow_model))
  expect_true("reaches"         %in% args)
  expect_true("parameters"      %in% args)
  expect_true("design_matrix"   %in% args)
  expect_true("data_dictionary" %in% args)
  expect_true("run_id"          %in% args)
  expect_true("output_dir"      %in% args)
  expect_true("if_estimate"     %in% args)
  expect_true("if_predict"      %in% args)
  expect_true("if_validate"     %in% args)
  expect_false("path_main"      %in% args)
})

test_that("rsparrow_model stops with clear error for missing required reaches columns", {
  expect_error(
    rsparrow_model(
      reaches         = data.frame(x = 1),
      parameters      = sparrow_example$parameters,
      design_matrix   = sparrow_example$design_matrix,
      data_dictionary = sparrow_example$data_dictionary
    ),
    regexp = "missing required columns|reaches"
  )
})

test_that("rsparrow_model stops with clear error for missing SOURCE in parameters", {
  bad_params <- sparrow_example$parameters
  bad_params$parmType <- "DELIVF"  # no SOURCE row
  expect_error(
    rsparrow_model(
      reaches         = sparrow_example$reaches,
      parameters      = bad_params,
      design_matrix   = sparrow_example$design_matrix,
      data_dictionary = sparrow_example$data_dictionary
    ),
    regexp = "SOURCE"
  )
})
